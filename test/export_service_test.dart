import 'package:flutter_test/flutter_test.dart';
import 'package:soundbox/core/export_service.dart';
import 'package:soundbox/core/models.dart';

Track _track({required String title, required String path}) => Track(
      id: path,
      title: title,
      artist: 'Prueba',
      sourceUrl: path,
      isLocal: true,
      format: 'mp3',
    );

void main() {
  test('el nombre exportado conserva la extension y limpia caracteres', () {
    final track = _track(
      title: 'Mi cancion: parte 1/2',
      path: '/datos/music/cancion.mp3',
    );

    expect(
      ExportService.fileNameFor(track),
      'Mi cancion_ parte 1_2.mp3',
    );
  });

  test('el MIME se deduce del formato', () {
    final mp3 = _track(title: 'A', path: '/a.mp3');
    final m4a = Track(
      id: '/a.m4a',
      title: 'A',
      artist: 'Prueba',
      sourceUrl: '/a.m4a',
      format: 'm4a',
    );

    expect(ExportService.mimeFor(mp3), 'audio/mpeg');
    expect(ExportService.mimeFor(m4a), 'audio/mp4');
  });
}
