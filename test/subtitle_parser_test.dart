import 'package:flutter_test/flutter_test.dart';
import 'package:soundbox/core/subtitle_parser.dart';

void main() {
  test('parsea SRT y busca el subtitulo activo', () {
    const srt = '''
1
00:00:01,000 --> 00:00:03,000
Hola mundo

2
00:00:04,500 --> 00:00:06,000
Adios
''';

    final cues = parseSubtitles(srt);
    expect(cues.length, 2);
    expect(cues.first.start, const Duration(seconds: 1));
    expect(cueAt(cues, const Duration(seconds: 2)), 'Hola mundo');
    expect(cueAt(cues, const Duration(seconds: 7)), isNull);
  });

  test('parsea WebVTT', () {
    const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:02.000
Subtitulo VTT
''';

    final cues = parseSubtitles(vtt);
    expect(cues.single.text, 'Subtitulo VTT');
  });
}
