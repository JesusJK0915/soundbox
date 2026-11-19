import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundbox/core/models.dart';
import 'package:soundbox/core/playlist_export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PlaylistExportService> freshService() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return PlaylistExportService(await SharedPreferences.getInstance());
  }

  final tracks = [
    const Track(
      id: '1',
      title: 'Cancion, con coma',
      artist: 'Artista',
      sourceUrl: '/tmp/uno.mp3',
      durationMs: 120000,
    ),
    const Track(
      id: '2',
      title: 'Otra',
      artist: 'Artista',
      sourceUrl: 'https://example.com/dos.mp3',
    ),
  ];

  test('genera M3U con EXTINF y rutas', () async {
    final service = await freshService();
    final m3u = service.toM3u(tracks);
    expect(m3u, startsWith('#EXTM3U\n'));
    expect(m3u, contains('#EXTINF:120,Artista - Cancion, con coma'));
    expect(m3u, contains('/tmp/uno.mp3'));
    expect(m3u, contains('https://example.com/dos.mp3'));
  });

  test('csv entrecomilla campos con coma', () async {
    final service = await freshService();
    final csv = service.toCsv(tracks);
    expect(csv, contains('"Cancion, con coma"'));
    expect(csv, contains('titulo,artista,album,anio,formato,ruta'));
  });

  test('json y ultima exportacion persisten', () async {
    final service = await freshService();
    final json = service.toJson(tracks);
    expect(json, contains('"id":"1"'));
    await service.rememberExport(json);
    final restored = PlaylistExportService(await SharedPreferences.getInstance());
    expect(restored.lastExport, json);
  });
}
