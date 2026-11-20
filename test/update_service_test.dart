import 'package:flutter_test/flutter_test.dart';
import 'package:soundbox/core/update_service.dart';

Map<String, dynamic> releaseJson(String tag, List<String> assets) => {
      'tag_name': tag,
      'name': 'SoundBox Beta 22',
      'body': 'Novedades de la version',
      'html_url': 'https://github.com/JesusJK0915/soundbox/releases/tag/$tag',
      'published_at': '2026-11-19T19:00:00Z',
      'assets': [
        for (final name in assets)
          <String, dynamic>{
            'name': name,
            'size': 68743458,
            'browser_download_url':
                'https://github.com/JesusJK0915/soundbox/releases/download/$tag/$name',
          },
      ],
    };

void main() {
  group('Actualizaciones automaticas', () {
    test('extrae el numero de build del final de la etiqueta', () {
      expect(UpdateService.buildFromTag('v0.2.0-beta.22'), 22);
      expect(UpdateService.buildFromTag('v0.1.0-alpha.25'), 25);
      expect(UpdateService.buildFromTag('v1.0.3'), 103);
      expect(UpdateService.buildFromTag('v1.1.0'), 110);
      expect(UpdateService.buildFromTag('sin-numero'), 0);
    });

    test('solo considera nueva una version mayor con build conocido', () {
      expect(UpdateService.isNewerTag('v0.2.0-beta.23', 22), isTrue);
      expect(UpdateService.isNewerTag('v0.2.0-beta.22', 22), isFalse);
      expect(UpdateService.isNewerTag('v0.2.0-beta.21', 22), isFalse);
      expect(UpdateService.isNewerTag('v0.2.0-beta.99', 0), isFalse);
    });

    test('elige el APK correcto segun canal y ABI', () {
      expect(
        UpdateService.assetNameFor(UpdateChannel.beta, 'arm64-v8a'),
        'app-arm64-v8a-release.apk',
      );
      expect(
        UpdateService.assetNameFor(UpdateChannel.beta, 'x86_64'),
        'app-x86_64-release.apk',
      );
      expect(
        UpdateService.assetNameFor(UpdateChannel.beta, 'armeabi-v7a'),
        'app-armeabi-v7a-release.apk',
      );
      expect(
        UpdateService.assetNameFor(UpdateChannel.alpha, 'arm64-v8a'),
        'app-debug.apk',
      );
    });

    test('parsea un release y selecciona el asset del dispositivo', () {
      final release = UpdateService.parseRelease(
        releaseJson('v0.2.0-beta.22', [
          'app-armeabi-v7a-release.apk',
          'app-arm64-v8a-release.apk',
        ]),
        UpdateChannel.beta,
        'arm64-v8a',
      );

      expect(release, isNotNull);
      expect(release!.tag, 'v0.2.0-beta.22');
      expect(release.buildNumber, 22);
      expect(release.assetName, 'app-arm64-v8a-release.apk');
      expect(release.assetUrl, contains('app-arm64-v8a-release.apk'));
      expect(release.publishedAt, isNotNull);
    });

    test('ignora releases de otro canal', () {
      final release = UpdateService.parseRelease(
        releaseJson('v0.1.0-alpha.25', ['app-debug.apk']),
        UpdateChannel.beta,
        'arm64-v8a',
      );
      expect(release, isNull);
    });

    test('el canal estable ignora pre-releases y usa version semantica', () {
      expect(UpdateService.channelFromName('stable'), UpdateChannel.stable);
      expect(UpdateService.assetNameFor(UpdateChannel.stable, 'arm64-v8a'),
          'app-arm64-v8a-release.apk');

      final stable = UpdateService.parseRelease(
        releaseJson('v1.0.3', ['app-arm64-v8a-release.apk']),
        UpdateChannel.stable,
        'arm64-v8a',
      );
      expect(stable, isNotNull);
      expect(stable!.buildNumber, 103);

      final prerelease = UpdateService.parseRelease(
        releaseJson('v0.2.0-beta.47', ['app-arm64-v8a-release.apk']),
        UpdateChannel.stable,
        'arm64-v8a',
      );
      expect(prerelease, isNull);
      expect(UpdateService.isNewerTag('v1.0.3', 102), isTrue);
    });

    test('elige el build mas alto aunque la API no venga ordenada', () {
      final latest = UpdateService.pickLatest(
        [
          releaseJson('v0.2.0-beta.9', ['app-arm64-v8a-release.apk']),
          releaseJson('v0.2.0-beta.23', ['app-arm64-v8a-release.apk']),
          releaseJson('v0.2.0-beta.22', ['app-arm64-v8a-release.apk']),
        ],
        UpdateChannel.beta,
        'arm64-v8a',
      );

      expect(latest, isNotNull);
      expect(latest!.tag, 'v0.2.0-beta.23');
    });
  });
}
