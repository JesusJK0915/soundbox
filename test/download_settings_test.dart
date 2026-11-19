import 'package:flutter_test/flutter_test.dart';
import 'package:soundbox/core/download_settings.dart';

void main() {
  test('los valores por defecto son MP3 a 192 kbps', () {
    final settings = DownloadSettingsService();

    expect(settings.format, AudioFormat.mp3);
    expect(settings.bitrate, 192);
    expect(settings.extension, '.mp3');
    expect(settings.isLossy, isTrue);
  });

  test('MP3 usa libmp3lame y el bitrate elegido', () {
    final args = DownloadSettingsService.argumentsFor(
      input: '/datos/original.ogg',
      output: '/datos/final.mp3',
      format: AudioFormat.mp3,
      bitrate: 320,
    );

    expect(args, contains('-codec:a'));
    expect(args, contains('libmp3lame'));
    expect(args, contains('320k'));
    expect(args.last, '/datos/final.mp3');
  });

  test('FLAC no aplica bitrate', () {
    final args = DownloadSettingsService.argumentsFor(
      input: '/datos/original.mp3',
      output: '/datos/final.flac',
      format: AudioFormat.flac,
      bitrate: 192,
    );

    expect(args, contains('flac'));
    expect(args, isNot(contains('192k')));
  });
}
