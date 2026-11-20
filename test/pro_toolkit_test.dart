import 'package:flutter_test/flutter_test.dart';
import 'package:soundbox/core/models.dart';
import 'package:soundbox/core/pro_toolkit.dart';

Track track(String id, String title, String artist,
        {String? album, int? durationMs, String? genre}) =>
    Track(
      id: id,
      title: title,
      artist: artist,
      sourceUrl: 'file:///$id.mp3',
      album: album,
      durationMs: durationMs,
      genre: genre,
    );

void main() {
  group('Pro toolkit · biblioteca', () {
    test('normaliza texto y claves de busqueda', () {
      expect(LibraryToolsPro.normalizeText('  Ámór   '), 'amor');
      expect(LibraryToolsPro.titleKey('Virgen (Letra Oficial)'), 'virgen');
      expect(LibraryToolsPro.artistKey('A & B feat. C'), 'a b c');
      expect(LibraryToolsPro.splitArtists('A, B; C').length, 3);
    });

    test('detecta variantes y calcula salud de biblioteca', () {
      expect(LibraryToolsPro.isLive('Concierto live 2020'), isTrue);
      expect(LibraryToolsPro.isRemix('Cancion remix'), isTrue);
      expect(LibraryToolsPro.isInstrumental('Piano instrumental'), isTrue);
      expect(LibraryToolsPro.isCover('Cover acustico'), isTrue);
      expect(
        LibraryToolsPro.libraryHealth([
          track('1', 'A', 'B', genre: 'Pop'),
        ]),
        inRange(0, 100),
      );
    });

    test('agrupa, busca y detecta duplicados', () {
      final tracks = [
        track('1', 'Igual', 'Artista', album: 'Disco', durationMs: 1000),
        track('2', 'Igual', 'Artista', album: 'Disco', durationMs: 1000),
        track('3', 'Otra', 'Otro', album: 'Otro', durationMs: 2000),
      ];
      expect(LibraryToolsPro.groupByAlbum(tracks).length, 2);
      expect(LibraryToolsPro.groupByArtist(tracks).length, 2);
      expect(LibraryToolsPro.duplicateGroups(tracks).length, 1);
      expect(LibraryToolsPro.searchScore('Igual', 'Igual'), 100);
      expect(LibraryToolsPro.searchTokens('la cancion del sol').length, 4);
      expect(LibraryToolsPro.fileSizeLabel(2 * 1024 * 1024), '2.0 MB');
      expect(LibraryToolsPro.durationLabel(const Duration(seconds: 65)), '01:05');
    });
  });

  group('Pro toolkit · reproduccion', () {
    test('indices y cola', () {
      expect(PlaybackToolsPro.nextIndex(2, 3, false), 2);
      expect(PlaybackToolsPro.nextIndex(2, 3, true), 0);
      expect(PlaybackToolsPro.previousIndex(0, 3, true), 2);
      expect(PlaybackToolsPro.shuffledIndices(5, 7).length, 5);
      expect(PlaybackToolsPro.queueSummary(1, 4), '2 de 4');
    });

    test('progreso, letra y volumen', () {
      expect(PlaybackToolsPro.progressPercent(30, 100), 30);
      expect(PlaybackToolsPro.volumePercent(0.5), 50);
      expect(PlaybackToolsPro.volumeFromPercent(25), 0.25);
      expect(PlaybackToolsPro.speedLabel(1.25), '1.25×');
      expect(PlaybackToolsPro.repeatLabel('all'), 'Repetir cola');
      expect(
        PlaybackToolsPro.lyricIndexAt(
          [const Duration(seconds: 1), const Duration(seconds: 5)],
          const Duration(seconds: 6),
        ),
        1,
      );
      expect(
        PlaybackToolsPro.karaokeFraction(
          const Duration(seconds: 1),
          const Duration(seconds: 3),
          const Duration(seconds: 2),
        ),
        0.5,
      );
    });
  });

  group('Pro toolkit · descargas', () {
    test('formatos y proveedores', () {
      expect(DownloadToolsPro.extensionForFormat('mpeg'), 'mp3');
      expect(DownloadToolsPro.formatFromUrl('https://x/a.FLAC'), 'flac');
      expect(DownloadToolsPro.isDirectAudioUrl('https://x/a.mp3?q=1'), isTrue);
      expect(DownloadToolsPro.isLegalSource('https://archive.org/x'), isTrue);
      expect(DownloadToolsPro.isLegalSource('https://example.com/x'), isFalse);
      expect(DownloadToolsPro.providerLabel('https://jamendo.com/x'), 'Jamendo');
      expect(DownloadToolsPro.mimeForExtension('m4a'), 'audio/mp4');
      expect(DownloadToolsPro.isLossless('flac'), isTrue);
      expect(DownloadToolsPro.isValidBitrate(320), isTrue);
      expect(DownloadToolsPro.isValidBitrate(999), isFalse);
    });

    test('calidad, tamano y reintentos', () {
      expect(DownloadToolsPro.qualityLabel(320), 'Maxima');
      expect(DownloadToolsPro.bestBitrate([64, 128, 256], 192), 256);
      expect(DownloadToolsPro.retryDelaySeconds(0), 2);
      expect(
        DownloadToolsPro.estimateBytes(128, const Duration(seconds: 10)),
        160000,
      );
      expect(DownloadToolsPro.safeDownloadName('../Mi canción?.mp3'), 'Mi cancion.mp3');
    });
  });

  group('Pro toolkit · playlists y letras', () {
    test('exportacion', () {
      expect(PlaylistToolsPro.m3uHeader(), '#EXTM3U');
      expect(
        PlaylistToolsPro.m3uEntry('/a.mp3', 'A', 1000),
        contains('#EXTINF:1,A'),
      );
      expect(PlaylistToolsPro.csvRow(['a"b', 'c']), '"a""b";"c"');
      expect(PlaylistToolsPro.csvHeader(), contains('titulo'));
      expect(PlaylistToolsPro.mergeUnique(['a'], ['a', 'b']), ['a', 'b']);
      expect(
        PlaylistToolsPro.dedupeTracks([
          track('1', 'A', 'B', durationMs: 1),
          track('2', 'A', 'B', durationMs: 1),
        ]).length,
        1,
      );
      expect(PlaylistToolsPro.playlistName([track('1', 'Sola', 'Artista')]), 'Sola');
    });

    test('lyrics', () {
      final parsed = LyricsToolsPro.parseLrcLine('[00:12.50] Hola mundo');
      expect(parsed, isNotNull);
      expect(parsed!.value, 'Hola mundo');
      expect(parsed.key.inMilliseconds, 12500);
      expect(
        LyricsToolsPro.lineAt({parsed.key: 'Hola'}, const Duration(seconds: 13)),
        'Hola',
      );
      expect(LyricsToolsPro.plainLyrics('[ar:X]\n[00:01.00] Hola'), 'Hola');
      expect(LyricsToolsPro.wordCount('uno dos tres'), 3);
      expect(
        LyricsToolsPro.syncedOffset(const Duration(seconds: 1), 500).inMilliseconds,
        1500,
      );
    });
  });

  group('Pro toolkit · ajustes y mantenimiento', () {
    test('ajustes', () {
      expect(SettingsToolsPro.themeModeLabel('dark'), 'Oscuro');
      expect(SettingsToolsPro.dataSaverLabel(true), contains('Activo'));
      expect(SettingsToolsPro.clampBitrate(200), 192);
      expect(SettingsToolsPro.parseBitratePreference('256 kbps'), 256);
      expect(SettingsToolsPro.sortLabel('album'), 'Album');
      expect(SettingsToolsPro.channelLabel('stable'), 'Estable');
      expect(SettingsToolsPro.validateDisplayName('A'), isNotNull);
      expect(SettingsToolsPro.validateDisplayName('SoundBox'), isNull);
    });

    test('mantenimiento', () {
      expect(MaintenanceToolsPro.cacheSizeLabel(1024), '1.0 KB');
      expect(MaintenanceToolsPro.cleanCachePolicy(false), isTrue);
      expect(MaintenanceToolsPro.storagePressure(150), 'Critico');
      expect(
        MaintenanceToolsPro.diagnosticScore(
          online: true,
          cacheMb: 100,
          missingMetadata: 1,
        ),
        98,
      );
      expect(MaintenanceToolsPro.versionCodeFrom('1.0.3'), 103);
      expect(MaintenanceToolsPro.buildTag('1.0.3', 103), '1.0.3 (103)');
      expect(
        MaintenanceToolsPro.supportSummary('1.0.3', false),
        contains('Solo local'),
      );
    });
  });
}
