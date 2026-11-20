import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'pro_toolkit.dart';

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
    final unique = PlaylistToolsPro.dedupeTracks(tracks.toList());
    final buffer = StringBuffer('${PlaylistToolsPro.m3uHeader()}\n');
    for (final track in unique) {
      buffer.writeln(
        PlaylistToolsPro.m3uEntry(
          track.sourceUrl,
          '${track.artist} - ${track.title}',
          track.durationMs,
        ),
      );
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

  static String _csvCell(Object? value) {
    final text = value?.toString() ?? '';
    final needsQuotes = text.contains(',') ||
        text.contains('"') ||
        text.contains('\n');
    if (!needsQuotes) return text;
    return '"${text.replaceAll('"', '""')}"';
  }
}
