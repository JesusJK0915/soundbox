import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'metadata_service.dart';
import 'models.dart';

const _videoFormats = <String>{
  'mp4',
  'mkv',
  'webm',
  'mov',
  'avi',
  'm4v',
  'video',
};

const _audioFormats = <String>{
  'mp3',
  'm4a',
  'ogg',
  'flac',
  'wav',
  'aac',
  'opus',
};

bool _isVideoFormat(String? format) =>
    _videoFormats.contains((format ?? '').toLowerCase().replaceFirst('.', ''));

class LibraryService extends ChangeNotifier {
  static const _storageKey = 'soundbox_tracks_v1';

  final SharedPreferences _prefs;

  late final Directory rootDir;
  late final Directory audioDir;
  late final Directory downloadDir;
  late final Directory subtitleDir;
  late final Directory artworkDir;

  final List<Track> _tracks = <Track>[];

  LibraryService(this._prefs);

  List<Track> get tracks => List.unmodifiable(_tracks);
  List<Track> get playableTracks =>
      List.unmodifiable(_tracks.where((t) => !t.isSubtitle));

  Future<void> initialize() async {
    final docs = await getApplicationDocumentsDirectory();
    rootDir = Directory(p.join(docs.path, 'soundbox'));
    audioDir = Directory(p.join(rootDir.path, 'audio'));
    downloadDir = Directory(p.join(rootDir.path, 'downloads'));
    subtitleDir = Directory(p.join(rootDir.path, 'subtitles'));
    artworkDir = Directory(p.join(rootDir.path, 'artwork'));

    for (final dir in [audioDir, downloadDir, subtitleDir, artworkDir]) {
      await dir.create(recursive: true);
    }

    // Versiones anteriores guardaban videos: se retiran y se borra su carpeta.
    final legacyVideoDir = Directory(p.join(rootDir.path, 'video'));
    if (await legacyVideoDir.exists()) {
      await legacyVideoDir.delete(recursive: true);
    }

    final raw = _prefs.getStringList(_storageKey) ?? <String>[];
    _tracks
      ..clear()
      ..addAll(
        raw
            .map((value) => jsonDecode(value) as Map<String, dynamic>)
            .map(Track.fromJson)
            .where((track) => !_isVideoFormat(track.format)),
      );
    await _persist();
  }

  Future<void> importFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.audio,
    );
    if (result == null) return;

    for (final file in result.files) {
      final path = file.path;
      if (path == null || _isVideoFormat(p.extension(path))) continue;
      await _copyToLibrary(
        sourcePath: path,
        targetDir: audioDir,
        downloaded: false,
      );
    }
    await _persist();
  }

  /// Elige una carpeta, busca archivos de audio y los copia a la biblioteca.
  Future<int> scanAudioFolder() async {
    final audioPermission = await Permission.audio.request();
    if (!audioPermission.isGranted) {
      final storagePermission = await Permission.storage.request();
      if (!storagePermission.isGranted) {
        throw StateError('Falta permiso para leer archivos de audio');
      }
    }

    final folder = await FilePicker.platform.getDirectoryPath();
    if (folder == null || folder == '/') return 0;

    final directory = Directory(folder);
    if (!await directory.exists()) return 0;

    var imported = 0;
    try {
      await for (final entity
          in directory.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final extension = p
            .extension(entity.path)
            .toLowerCase()
            .replaceFirst('.', '');
        if (!_audioFormats.contains(extension)) continue;
        await _copyToLibrary(
          sourcePath: entity.path,
          targetDir: audioDir,
          downloaded: false,
        );
        imported++;
      }
    } on FileSystemException {
      // Algunas rutas SAF de Android no se pueden listar con dart:io.
      // En ese caso el usuario selecciona los archivos manualmente.
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.audio,
      );
      if (picked == null) return 0;
      for (final file in picked.files) {
        final path = file.path;
        if (path == null || _isVideoFormat(p.extension(path))) continue;
        await _copyToLibrary(
          sourcePath: path,
          targetDir: audioDir,
          downloaded: false,
        );
        imported++;
      }
    }
    await _persist();
    return imported;
  }

  Future<String?> pickSubtitlePath() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['srt', 'vtt'],
    );
    return result?.files.single.path;
  }

  Future<void> attachSubtitle(String trackId, String sourcePath) async {
    final index = _tracks.indexWhere((t) => t.id == trackId);
    if (index == -1) return;

    final extension = p.extension(sourcePath);
    final target = p.join(
      subtitleDir.path,
      '${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    await File(sourcePath).copy(target);

    _tracks[index] = _tracks[index].copyWith(subtitlePath: target);
    await _persist();
  }

  Future<void> addTrack(Track track) async {
    final index = _tracks.indexWhere((t) => t.id == track.id);
    if (index >= 0) {
      _tracks[index] = track;
    } else {
      _tracks.add(track);
    }
    await _persist();
  }

  Future<void> remove(String id) async {
    final index = _tracks.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final track = _tracks[index];

    try {
      final file = File(track.sourceUrl);
      if (await file.exists()) await file.delete();
    } catch (_) {}

    try {
      if (track.subtitlePath != null) {
        final subtitle = File(track.subtitlePath!);
        if (await subtitle.exists()) await subtitle.delete();
      }
    } catch (_) {}

    try {
      if (track.artworkPath != null) {
        final artwork = File(track.artworkPath!);
        if (await artwork.exists()) await artwork.delete();
      }
    } catch (_) {}

    _tracks.removeAt(index);
    await _persist();
  }

  Future<Track?> _copyToLibrary({
    required String sourcePath,
    required Directory targetDir,
    required bool downloaded,
    String? titleOverride,
    String? license,
    String? artworkUrl,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) return null;

    final extension = p.extension(sourcePath);
    final name = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final target = File(p.join(targetDir.path, name));
    await source.copy(target.path);

    final base = Track(
      id: target.path,
      title: titleOverride ?? p.basenameWithoutExtension(sourcePath),
      artist: downloaded ? 'Descargado' : 'Local',
      sourceUrl: target.path,
      isLocal: true,
      format: extension.replaceFirst('.', '').toLowerCase(),
      license: license,
      artworkUrl: artworkUrl,
      downloaded: downloaded,
    );
    final track = await _withMetadata(base);
    await addTrack(track);
    return track;
  }

  /// Combina la pista con las etiquetas leidas del archivo.
  Future<Track> _withMetadata(Track base) async {
    final meta = await readTrackMetadata(
      filePath: base.sourceUrl,
      artworkDir: artworkDir.path,
    );
    if (meta == null) return base.copyWith(tagsRead: true);
    return base.copyWith(
      title: meta.title ?? base.title,
      artist: meta.artist ?? base.artist,
      album: meta.album ?? base.album,
      albumArtist: meta.albumArtist,
      year: meta.year,
      genre: meta.genre,
      trackNumber: meta.trackNumber,
      trackTotal: meta.trackTotal,
      discNumber: meta.discNumber,
      durationMs: meta.durationMs ?? base.durationMs,
      bitrateBps: meta.bitrateBps,
      sampleRate: meta.sampleRate,
      artworkPath: meta.artworkPath ?? base.artworkPath,
      extraTags: meta.extraTags.isEmpty ? null : meta.extraTags,
      tagsRead: true,
    );
  }

  /// Vuelve a leer las etiquetas de la biblioteca local. Por defecto solo
  /// procesa las pistas que aun no tienen metadatos leidos.
  Future<int> refreshMetadata({bool force = false}) async {
    var updated = 0;
    for (var index = 0; index < _tracks.length; index++) {
      final track = _tracks[index];
      if (!track.isLocal || track.isSubtitle) continue;
      if (track.tagsRead && !force) continue;
      if (!File(track.sourceUrl).existsSync()) continue;
      _tracks[index] = await _withMetadata(track);
      updated++;
    }
    if (updated > 0) await _persist();
    return updated;
  }

  Future<Track> addDownloadedFile({
    required String sourcePath,
    required String title,
    required String artist,
    String? license,
    String? artworkUrl,
  }) async {
    final target = sourcePath;
    final extension = p.extension(sourcePath);

    final base = Track(
      id: target,
      title: title,
      artist: artist,
      sourceUrl: target,
      isLocal: true,
      format: extension.replaceFirst('.', '').toLowerCase(),
      license: license,
      artworkUrl: artworkUrl,
      downloaded: true,
    );
    final track = await _withMetadata(base);
    await addTrack(track);
    return track;
  }

  Future<void> _persist() async {
    final encoded = _tracks.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs.setStringList(_storageKey, encoded);
    notifyListeners();
  }
}
