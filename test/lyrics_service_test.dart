import 'package:flutter_test/flutter_test.dart';
import 'package:soundbox/core/lyrics_service.dart';
import 'package:soundbox/core/models.dart';
import 'package:soundbox/core/subtitle_parser.dart';

void main() {
  group('parser LRC', () {
    test('parsea timestamps multiples y calcula el fin con el siguiente cue', () {
      final cues = parseSubtitles(
        '[00:01.00]Primera\n[00:03.50][00:06.00]Segunda\n[00:08.00]Tercera',
      );
      expect(cues.length, 4);
      expect(cues.first.start, const Duration(milliseconds: 1000));
      expect(cues.first.end, const Duration(milliseconds: 3500));
      expect(cues.first.text, 'Primera');
      expect(cues[1].start, const Duration(milliseconds: 3500));
      expect(cues[1].end, const Duration(milliseconds: 6000));
      expect(cues[1].text, 'Segunda');
      expect(cues[2].start, const Duration(milliseconds: 6000));
      expect(cues[2].end, const Duration(milliseconds: 8000));
      expect(cues.last.text, 'Tercera');
    });

    test('no confunde VTT con LRC', () {
      const vtt = '1\n00:00:01,000 --> 00:00:03,000\nHola';
      expect(looksLikeLrc(vtt), isFalse);
      expect(parseSubtitles(vtt).single.text, 'Hola');
    });

    test('cueAt encuentra la linea activa', () {
      final cues = parseSubtitles('[00:01.00]A\n[00:03.00]B');
      expect(cueAt(cues, const Duration(seconds: 2)), 'A');
      expect(cueAt(cues, const Duration(seconds: 4)), 'B');
    });
  });

  group('resultado LRCLIB', () {
    test('convierte letra plana a LRC para el overlay', () {
      final result = LyricsResult.fromJson({
        'id': 42,
        'trackName': 'Cancion',
        'artistName': 'Artista',
        'duration': 180,
        'plainLyrics': 'Linea uno\nLinea dos',
        'syncedLyrics': null,
      });
      expect(result.id, 42);
      expect(result.lrcContent, contains('[00:00.00]Linea uno'));
      expect(result.lrcContent, contains('[00:00.00]Linea dos'));
    });

    test('prefiere letra sincronizada', () {
      final result = LyricsResult.fromJson({
        'id': 1,
        'trackName': 'Cancion',
        'artistName': 'Artista',
        'syncedLyrics': '[00:01.00]Sincronizada',
        'plainLyrics': 'Plana',
        'hasWordSync': true,
      });
      expect(result.hasWordSync, isTrue);
      expect(result.lrcContent, '[00:01.00]Sincronizada');
    });

    test('elige la coincidencia por titulo, artista y duracion', () {
      const track = Track(
        id: '1',
        title: 'Song',
        artist: 'Artist',
        sourceUrl: 'file:///song.mp3',
        durationMs: 120000,
      );
      final match = LyricsService.pickBestMatch(
        [
          {
            'id': 1,
            'trackName': 'Otra',
            'artistName': 'Artist',
            'duration': 120,
            'plainLyrics': 'x',
          },
          {
            'id': 2,
            'trackName': 'Song',
            'artistName': 'Artist',
            'duration': 121,
            'syncedLyrics': '[00:01.00]Letra',
          },
        ],
        track,
        120,
      );
      expect(match?.id, 2);
    });
  });
}
