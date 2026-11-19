import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

bool _isVideoFormat(String? format) =>
    _videoFormats.contains((format ?? '').toLowerCase().replaceFirst('.', ''));

class LibraryService extends ChangeNotifier {
  static const _storageKey = 'soundbox_tracks_v1';

  final SharedPreferences _prefs;

  late final Directory rootDir;
  late final Directory audioDir;
  late final Directory downloadDir;
  late final Directory subtitleDir;

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

    for (final dir in [audioDir, downloadDir, subtitleDir]) {
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

    final old = _tracks[index];
    _tracks[index] = Track(
      id: old.id,
      title: old.title,
      artist: old.artist,
      album: old.album,
      artworkUrl: old.artworkUrl,
      sourceUrl: old.sourceUrl,
      isLocal: old.isLocal,
      format: old.format,
      durationMs: old.durationMs,
      license: old.license,
      subtitlePath: target,
      downloaded: old.downloaded,
      source: old.source,
    );
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

    final track = Track(
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
    await addTrack(track);
    return track;
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

    final track = Track(
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
    await addTrack(track);
    return track;
  }

  Future<void> _persist() async {
    final encoded = _tracks.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs.setStringList(_storageKey, encoded);
    notifyListeners();
  }
}
