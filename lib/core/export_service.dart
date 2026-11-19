import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Guarda copias de la biblioteca fuera del almacenamiento privado usando
/// Storage Access Framework (el selector de carpetas/archivos de Android).
class ExportService extends ChangeNotifier {
  static const _channel = MethodChannel('com.soundbox.app/export');
  static const _folderKey = 'export_folder_uri';

  ExportService(this._prefs);

  final SharedPreferences _prefs;

  bool get available => Platform.isAndroid;

  String? get folderUri => _prefs.getString(_folderKey);

  bool get hasFolder => folderUri != null;

  /// Abre el selector de carpetas y recuerda la elegida.
  Future<String?> chooseFolder() async {
    if (!available) return null;
    final uri = await _channel.invokeMethod<String>('pickFolder');
    if (uri != null) {
      await _prefs.setString(_folderKey, uri);
      notifyListeners();
    }
    return uri;
  }

  Future<void> clearFolder() async {
    await _prefs.remove(_folderKey);
    notifyListeners();
  }

  /// Guarda una cancion en la ubicacion que elija el usuario.
  /// Devuelve null si cancela o si el archivo local ya no existe.
  Future<String?> saveFile(Track track) async {
    if (!available) return null;
    if (!await File(track.sourceUrl).exists()) return null;
    return _channel.invokeMethod<String>('saveFile', <String, Object?>{
      'path': track.sourceUrl,
      'name': fileNameFor(track),
      'mime': mimeFor(track),
    });
  }

  /// Copia varias canciones a una carpeta SAF ya elegida.
  Future<int> exportToFolder(String treeUri, List<Track> tracks) async {
    if (!available) return 0;
    final files = <Map<String, String>>[];
    for (final track in tracks) {
      if (!await File(track.sourceUrl).exists()) continue;
      files.add(<String, String>{
        'path': track.sourceUrl,
        'name': fileNameFor(track),
        'mime': mimeFor(track),
      });
    }
    if (files.isEmpty) return 0;
    final count = await _channel.invokeMethod<int>('exportFiles', <String, Object?>{
      'tree': treeUri,
      'files': files,
    });
    return count ?? 0;
  }

  static String fileNameFor(Track track) {
    final clean = track.title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    final base = clean.isEmpty ? 'cancion' : clean;
    final extension = p.extension(track.sourceUrl);
    if (extension.isNotEmpty) return '$base$extension';
    final format = (track.format ?? '').replaceFirst('.', '').toLowerCase();
    return format.isEmpty ? '$base.mp3' : '$base.$format';
  }

  static String mimeFor(Track track) {
    final format = (track.format ?? p.extension(track.sourceUrl))
        .replaceFirst('.', '')
        .toLowerCase();
    switch (format) {
      case 'm4a':
        return 'audio/mp4';
      case 'ogg':
      case 'opus':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'audio/mpeg';
    }
  }
}
