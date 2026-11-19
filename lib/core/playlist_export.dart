import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Exporta colas, listas e historial a formatos portátiles (M3U/CSV/JSON).
class PlaylistExportService {
  static const lastExportKey = 'export.last_playlist';

  final SharedPreferences _prefs;

  PlaylistExportService(this._prefs);

  String? get lastExport => _prefs.getString(lastExportKey);

  Future<void> rememberExport(String content) async {
    await _prefs.setString(lastExportKey, content);
  }

  /// M3U sencillo con rutas locales o URLs según la pista.
  String toM3u(Iterable<Track> tracks) {
    final buffer = StringBuffer('#EXTM3U\n');
    for (final track in tracks) {
      final seconds = track.durationMs == null
          ? -1
          : (track.durationMs! ~/ 1000).toInt();
      buffer.writeln('#EXTINF:$seconds,${track.artist} - ${track.title}');
      buffer.writeln(track.sourceUrl);
    }
    return buffer.toString();
  }

  String toJson(Iterable<Track> tracks) =>
      jsonEncode(tracks.map((track) => track.toJson()).toList());

  String toCsv(Iterable<Track> tracks) {
    final buffer = StringBuffer('titulo,artista,album,anio,formato,ruta\n');
    for (final track in tracks) {
      buffer.writeln([
        track.title,
        track.artist,
        track.album ?? '',
        track.year ?? '',
        track.format ?? '',
        track.sourceUrl,
      ].map(_csvCell).join(','));
    }
    return buffer.toString();
  }

  static String _csvCell(String value) {
    final needsQuotes = value.contains(',') ||
        value.contains('"') ||
        value.contains('\n');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
