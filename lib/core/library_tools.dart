import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'pro_toolkit.dart';

/// Grupo de pistas consideradas duplicadas por título/artista/duración.
class DuplicateGroup {
  final String key;
  final List<Track> tracks;

  const DuplicateGroup({required this.key, required this.tracks});
}

/// Playlist local sencilla: nombre + ids de pistas.
class Playlist {
  final String id;
  final String name;
  final List<String> trackIds;

  const Playlist({
    required this.id,
    required this.name,
    required this.trackIds,
  });

  Playlist copyWith({String? name, List<String>? trackIds}) => Playlist(
        id: id,
        name: name ?? this.name,
        trackIds: trackIds ?? this.trackIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'trackIds': trackIds,
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? 'Sin nombre',
        trackIds: (json['trackIds'] as List?)?.map((v) => v.toString()).toList() ??
            <String>[],
      );
}

/// Banda del ecualizador paramétrico de 5 bandas.
class EqBand {
  final double frequency;
  double gain;

  EqBand(this.frequency, [this.gain = 0]);
}

/// Utilidades avanzadas de biblioteca: duplicados, carpetas, playlists,
/// ecualizador, normalización y reglas de listas inteligentes.
class LibraryToolsService extends ChangeNotifier {
  static const playlistsKey = 'tools.playlists';
  static const eqKey = 'tools.equalizer';
  static const normalizeKey = 'tools.normalize';
  static const replayGainKey = 'tools.replaygain';
  static const smartRulesKey = 'tools.smart_rules';

  final SharedPreferences _prefs;
  final List<Playlist> _playlists = <Playlist>[];
  late final List<EqBand> _bands;
  bool _normalize = false;
  bool _replayGain = false;
  final Map<String, String> _smartRules = <String, String>{};

  LibraryToolsService(this._prefs) {
    final raw = _prefs.getStringList(playlistsKey) ?? <String>[];
    _playlists.addAll(
      raw
          .map((value) => jsonDecode(value) as Map<String, dynamic>)
          .map(Playlist.fromJson),
    );
    final gains = _readGains();
    _bands = <EqBand>[
      EqBand(60, gains[0]),
      EqBand(230, gains[1]),
      EqBand(910, gains[2]),
      EqBand(3600, gains[3]),
      EqBand(14000, gains[4]),
    ];
    _normalize = _prefs.getBool(normalizeKey) ?? false;
    _replayGain = _prefs.getBool(replayGainKey) ?? false;
    final rules = _prefs.getString(smartRulesKey);
    if (rules != null) {
      try {
        final decoded = jsonDecode(rules) as Map<String, dynamic>;
        _smartRules.addAll(
          decoded.map((key, value) => MapEntry(key, value.toString())),
        );
      } catch (_) {}
    }
  }

  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<EqBand> get bands => _bands;
  bool get normalize => _normalize;
  bool get replayGain => _replayGain;
  Map<String, String> get smartRules => Map.unmodifiable(_smartRules);

  Future<void> _persistPlaylists() async {
    await _prefs.setStringList(
      playlistsKey,
      _playlists.map((playlist) => jsonEncode(playlist.toJson())).toList(),
    );
    notifyListeners();
  }

  Future<Playlist> createPlaylist(String name) async {
    final playlist = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Nueva lista' : name.trim(),
      trackIds: <String>[],
    );
    _playlists.add(playlist);
    await _persistPlaylists();
    return playlist;
  }

  Future<void> renamePlaylist(String id, String name) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == id);
    if (index == -1) return;
    _playlists[index] = _playlists[index].copyWith(name: name);
    await _persistPlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((playlist) => playlist.id == id);
    await _persistPlaylists();
  }

  Future<void> addToPlaylist(String id, String trackId) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == id);
    if (index == -1 || _playlists[index].trackIds.contains(trackId)) return;
    final ids = List<String>.from(_playlists[index].trackIds)..add(trackId);
    _playlists[index] = _playlists[index].copyWith(trackIds: ids);
    await _persistPlaylists();
  }

  Future<void> removeFromPlaylist(String id, String trackId) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == id);
    if (index == -1) return;
    final ids = _playlists[index].trackIds
        .where((value) => value != trackId)
        .toList();
    _playlists[index] = _playlists[index].copyWith(trackIds: ids);
    await _persistPlaylists();
  }

  List<Track> tracksOf(Playlist playlist, Iterable<Track> tracks) {
    final byId = <String, Track>{for (final track in tracks) track.id: track};
    return playlist.trackIds
        .map((id) => byId[id])
        .where((track) => track != null)
        .cast<Track>()
        .toList();
  }

  /// Agrupa pistas por título+artista+duración approximate.
  List<DuplicateGroup> findDuplicates(List<Track> tracks) {
    final groups = <String, List<Track>>{};
    for (final track in tracks) {
      final duration = ((track.durationMs ?? 0) ~/ 1000).toString();
      final key = [
        LibraryToolsPro.titleKey(track.title),
        LibraryToolsPro.artistKey(track.artist),
        duration,
      ].join('|');
      groups.putIfAbsent(key, () => <Track>[]).add(track);
    }
    return groups.entries
        .where((entry) => entry.value.length > 1)
        .map(
          (entry) => DuplicateGroup(key: entry.key, tracks: entry.value),
        )
        .toList();
  }

  /// Rutas de carpeta de las pistas locales (para favoritos por carpeta).
  Map<String, List<Track>> groupByFolder(Iterable<Track> tracks) {
    final result = <String, List<Track>>{};
    for (final track in tracks.where((track) => track.isLocal)) {
      final folder = p.dirname(track.sourceUrl);
      result.putIfAbsent(folder, () => <Track>[]).add(track);
    }
    return result;
  }

  Future<void> setBandGain(int index, double gain) async {
    if (index < 0 || index >= _bands.length) return;
    _bands[index].gain = gain.clamp(-12.0, 12.0);
    await _persistEq();
  }

  Future<void> resetEqualizer() async {
    for (final band in _bands) {
      band.gain = 0;
    }
    await _persistEq();
  }

  List<double> _readGains() {
    final raw = _prefs.getString(eqKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List;
        final gains = decoded.map((value) => (value as num).toDouble()).toList();
        if (gains.length == 5) return gains;
      } catch (_) {}
    }
    return <double>[0, 0, 0, 0, 0];
  }

  Future<void> _persistEq() async {
    await _prefs.setString(
      eqKey,
      jsonEncode(_bands.map((band) => band.gain).toList()),
    );
    notifyListeners();
  }

  Future<void> setNormalize(bool value) async {
    _normalize = value;
    await _prefs.setBool(normalizeKey, value);
    notifyListeners();
  }

  Future<void> setReplayGain(bool value) async {
    _replayGain = value;
    await _prefs.setBool(replayGainKey, value);
    notifyListeners();
  }

  /// Presets listos para aplicar al ecualizador.
  static const eqPresets = <String, List<double>>{
    'Plano': [0, 0, 0, 0, 0],
    'Bass boost': [6, 4, 0, -1, 1],
    'Vocales': [-2, 1, 4, 3, 0],
    'Rock': [4, 2, -1, 3, 4],
    'Electrónica': [7, 3, 0, 2, 5],
    'Acústica': [2, 1, 2, 2, 1],
  };

  Future<void> applyPreset(String name) async {
    final gains = eqPresets[name];
    if (gains == null) return;
    for (var i = 0; i < _bands.length && i < gains.length; i++) {
      _bands[i].gain = gains[i];
    }
    await _persistEq();
  }

  Future<void> setSmartRule(String name, String rule) async {
    _smartRules[name] = rule;
    await _prefs.setString(smartRulesKey, jsonEncode(_smartRules));
    notifyListeners();
  }

  /// Evalúa una regla simple: `year>2010`, `plays>5`, `genre=Rock`, `favorite`.
  List<Track> smartPlaylist(
    String rule,
    Iterable<Track> tracks, {
    int Function(String id)? playCount,
    Set<String>? favorites,
  }) {
    final normalized = rule.trim().toLowerCase();
    if (normalized.isEmpty) return tracks.toList();
    if (normalized == 'favorite' || normalized == 'favoritas') {
      return tracks.where((track) => favorites?.contains(track.id) ?? false).toList();
    }
    final match = RegExp(r'^(\w+)\s*(>=|<=|>|<|=)\s*(.+)$').firstMatch(normalized);
    if (match == null) return tracks.toList();
    final field = match.group(1)!;
    final op = match.group(2)!;
    final rawValue = match.group(3)!.trim();
    return tracks.where((track) {
      Object? value;
      switch (field) {
        case 'year':
          value = track.year;
        case 'plays':
          value = playCount?.call(track.id) ?? 0;
        case 'genre':
          value = track.genre?.toLowerCase();
        case 'bitrate':
          value = track.bitrateBps;
        case 'format':
          value = track.format?.toLowerCase();
        default:
          return false;
      }
      if (value == null) return false;
      final expected = num.tryParse(rawValue);
      if (value is num && expected != null) {
        return switch (op) {
          '>' => value > expected,
          '<' => value < expected,
          '>=' => value >= expected,
          '<=' => value <= expected,
          _ => value == expected,
        };
      }
      final text = value.toString();
      return switch (op) {
        '=' => text == rawValue,
        '>' => text.compareTo(rawValue) > 0,
        '<' => text.compareTo(rawValue) < 0,
        _ => false,
      };
    }).toList();
  }

  /// Cuenta cuántos archivos de audio hay en una carpeta (útil al escanear).
  static int countAudioIn(String folder) {
    final dir = Directory(folder);
    if (!dir.existsSync()) return 0;
    const audio = <String>{'mp3', 'm4a', 'ogg', 'flac', 'wav', 'aac', 'opus'};
    return dir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where(
          (file) => audio.contains(
            p.extension(file.path).toLowerCase().replaceFirst('.', ''),
          ),
        )
        .length;
  }
}
