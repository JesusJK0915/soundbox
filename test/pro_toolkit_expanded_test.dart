import 'package:flutter_test/flutter_test.dart';
import 'package:soundbox/core/models.dart';
import 'package:soundbox/core/pro_toolkit.dart';

const _a = Track(
  id: 'a',
  title: 'Al Rojo Vivo',
  artist: 'Octavio Mesa, D.R.A.',
  album: 'Muneca de Cuerda',
  sourceUrl: 'file:///a.mp3',
  isLocal: true,
  downloaded: true,
  artworkPath: '/art/a.jpg',
  genre: 'Rock',
  year: 2018,
  tagsRead: true,
  license: 'CC BY 4.0',
  source: 'Jamendo',
  durationMs: 143000,
  bitrateBps: 320000,
  sampleRate: 48000,
);

const _b = Track(
  id: 'b',
  title: 'Bachateo',
  artist: 'Kordy G',
  album: 'Bachatas',
  sourceUrl: 'https://cdn.example.com/b.mp3',
  format: 'mp3',
  genre: 'Pop',
  year: 2022,
  tagsRead: false,
  source: 'SoundCloud',
  durationMs: 180000,
);

const _lyrics = '[ar:Artista]\n[ti:Titulo]\n[00:01.00]Primera linea\n'
    '[00:03.50]Segunda linea\n[00:06.00]Tercera linea\n';

void main() {
  group('Pro toolkit expandido · biblioteca', () {
    test(' conteos y salud', () {
      final tracks = [_a, _b];
      expect(LibraryInsightsPro.uniqueTitles(tracks), 2);
      expect(LibraryInsightsPro.uniqueArtists(tracks), 2);
      expect(LibraryInsightsPro.uniqueAlbums(tracks), 2);
      expect(LibraryInsightsPro.trackCountByArtist(tracks, 'Octavio Mesa'), 1);
      expect(LibraryInsightsPro.trackCountByAlbum(tracks, 'Bachatas'), 1);
      expect(LibraryInsightsPro.longestTitle(tracks), isA<String>());
      expect(LibraryInsightsPro.shortestTitle(tracks), isA<String>());
      expect(LibraryInsightsPro.averageDuration(tracks), isA<Duration>());
      expect(LibraryInsightsPro.totalDurationLabel(tracks), contains(':'));
      expect(LibraryInsightsPro.localCount(tracks), 1);
      expect(LibraryInsightsPro.onlineCount(tracks), 1);
      expect(LibraryInsightsPro.downloadedCount(tracks), 1);
      expect(LibraryInsightsPro.missingArtworkCount(tracks), 1);
      expect(LibraryInsightsPro.missingGenreCount(tracks), 0);
      expect(LibraryInsightsPro.taggedCount(tracks), 1);
      expect(LibraryInsightsPro.untaggedCount(tracks), 1);
      expect(LibraryInsightsPro.oldestYear(tracks), 2018);
      expect(LibraryInsightsPro.newestYear(tracks), 2022);
      expect(LibraryInsightsPro.yearRangeLabel(tracks), '2018–2022');
      final score = LibraryInsightsPro.libraryScore(tracks);
      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(100));
    });
  });

  group('Pro toolkit expandido · reproduccion', () {
    test(' saltos, indices y limites', () {
      const duration = Duration(minutes: 3);
      const position = Duration(seconds: 30);
      expect(PlaybackInsightsPro.isTrackFinished(duration, duration), isTrue);
      expect(PlaybackInsightsPro.isTrackStarting(Duration.zero), isTrue);
      expect(PlaybackInsightsPro.forwardSeek(position, duration, 10),
          Duration(seconds: 40));
      expect(PlaybackInsightsPro.backwardSeek(position, 10),
          Duration(seconds: 20));
      expect(PlaybackInsightsPro.replaySeconds(duration, 10),
          Duration(minutes: 2, seconds: 50));
      expect(PlaybackInsightsPro.loopIndex(-1, 3), 2);
      expect(PlaybackInsightsPro.bounceIndex(3, 3), 1);
      expect(PlaybackInsightsPro.queuePositionLabel(1, 3), '2 de 3');
      expect(PlaybackInsightsPro.remainingTracks(3, 1), 1);
      final fraction = PlaybackInsightsPro.playedFraction(position, duration);
      expect(fraction, greaterThanOrEqualTo(0.0));
      expect(fraction, lessThanOrEqualTo(1.0));
      expect(PlaybackInsightsPro.volumeStep(0.9, 0.5), 1.0);
      expect(PlaybackInsightsPro.normalizedGain(50), 20.0);
      expect(PlaybackInsightsPro.isSilent(0.0), isTrue);
      expect(PlaybackInsightsPro.shuffleSeed(7, 2), isA<int>());
      expect(PlaybackInsightsPro.repeatCycle('all'), 'one');
      expect(PlaybackInsightsPro.speedStep(2.9, 0.5), 3.0);
      expect(PlaybackInsightsPro.speedLabelShort(1.25), '1.25x');
      expect(PlaybackInsightsPro.sleepMinutesLabel(15), '15 min');
      expect(PlaybackInsightsPro.isLongTrack(duration), isFalse);
      expect(PlaybackInsightsPro.isShortTrack(duration), isFalse);
    });
  });

  group('Pro toolkit expandido · busqueda', () {
    test(' tokens y coincidencias', () {
      final tracks = [_a, _b];
      expect(SearchInsightsPro.queryWords(' Al  Rojo '), ['al', 'rojo']);
      expect(SearchInsightsPro.queryIsEmpty('   '), isTrue);
      expect(SearchInsightsPro.matchesAllTokens('Al Rojo Vivo', 'rojo vivo'),
          isTrue);
      expect(SearchInsightsPro.matchesAnyToken('Al Rojo Vivo', 'bachata'),
          isFalse);
      expect(SearchInsightsPro.highlightRanges('Al Rojo', 'rojo'), isNotEmpty);
      final overlap = SearchInsightsPro.tokenOverlapScore('al rojo', 'rojo vivo');
      expect(overlap, greaterThanOrEqualTo(0.0));
      expect(overlap, lessThanOrEqualTo(1.0));
      expect(SearchInsightsPro.fuzzyContains('Rojo', 'rj'), isTrue);
      expect(SearchInsightsPro.titleStartsWith(_a, 'al'), isTrue);
      expect(SearchInsightsPro.artistStartsWith(_a, 'octavio'), isTrue);
      expect(SearchInsightsPro.albumContains(_b, 'bach'), isTrue);
      expect(SearchInsightsPro.bestMatchIndex(tracks, 'rojo'), 0);
      expect(SearchInsightsPro.sortedByQuery(tracks, 'rojo').length, 2);
      expect(SearchInsightsPro.normalizeQuery('  AL   Rojo '), 'al rojo');
      expect(SearchInsightsPro.stripQuotes('"rojo"'), 'rojo');
      expect(SearchInsightsPro.expandWildcard('rojo*'), 'rojo');
      expect(SearchInsightsPro.isExactPhrase('"rojo"'), isTrue);
      expect(SearchInsightsPro.phraseTokens('"al rojo"'), ['al', 'rojo']);
      expect(SearchInsightsPro.searchHint(''), contains('Escribe'));
      expect(SearchInsightsPro.resultCountLabel(2), '2 resultados');
      expect(SearchInsightsPro.noResultsMessage('x'), contains('x'));
    });
  });

  group('Pro toolkit expandido · descargas', () {
    test(' proveedores y formatos', () {
      final tracks = [_a, _b];
      expect(DownloadInsightsPro.isAudioExtension('mp3'), isTrue);
      expect(DownloadInsightsPro.isVideoExtension('mp4'), isTrue);
      expect(DownloadInsightsPro.isSubtitleExtension('lrc'), isTrue);
      expect(DownloadInsightsPro.safeFormat('mp4'), 'mp3');
      expect(DownloadInsightsPro.providerKey(_b.sourceUrl), 'direct');
      expect(DownloadInsightsPro.providerNeedsAttribution('https://archive.org/x'),
          isTrue);
      expect(DownloadInsightsPro.attributionText(_a), contains('CC BY 4.0'));
      expect(DownloadInsightsPro.isPlainFileUrl(_a.sourceUrl), isTrue);
      expect(DownloadInsightsPro.hostFromUrl(_b.sourceUrl), 'cdn.example.com');
      expect(DownloadInsightsPro.urlWithoutQuery('https://x/a.mp3?t=1'),
          'https://x/a.mp3');
      expect(DownloadInsightsPro.urlScheme('https://x/a.mp3'), 'https');
      expect(DownloadInsightsPro.isSecureUrl('https://x/a.mp3'), isTrue);
      expect(DownloadInsightsPro.qualityRank('320 kbps'), 4);
      expect(DownloadInsightsPro.bestQualityUrl({'128 kbps': 'x', '320 kbps': 'y'}),
          'y');
      expect(DownloadInsightsPro.fileNameFromUrl('https://x/Canci%C3%B3n.mp3'),
          isA<String>());
      expect(DownloadInsightsPro.fileExtensionFromName('a.mp3'), 'mp3');
      expect(DownloadInsightsPro.downloadStateLabel(DownloadStatus.queued),
          'En cola');
      expect(DownloadInsightsPro.isTerminalStatus(DownloadStatus.done), isTrue);
      expect(DownloadInsightsPro.progressPercentDone(50, 100), 50);
      expect(DownloadInsightsPro.etaLabel(90), '1 min 30 s');
      expect(tracks.length, 2);
    });
  });

  group('Pro toolkit expandido · playlists', () {
    test(' operaciones sobre colas', () {
      final tracks = [_a, _b];
      expect(PlaylistInsightsPro.playlistSlug('Mi Lista!'), 'mi-lista');
      expect(PlaylistInsightsPro.playlistColorSeed('Mi Lista'), isA<int>());
      expect(PlaylistInsightsPro.trackIds(tracks), ['a', 'b']);
      expect(PlaylistInsightsPro.uniqueTrackIds([...tracks, _a]).length, 2);
      expect(PlaylistInsightsPro.playlistDuration(tracks),
          const Duration(milliseconds: 323000));
      expect(PlaylistInsightsPro.isPlaylistEmpty(const []), isTrue);
      expect(PlaylistInsightsPro.playlistSizeLabel(tracks), contains('2'));
      expect(PlaylistInsightsPro.insertAtIndex(tracks, 0, _a).length, 3);
      expect(PlaylistInsightsPro.removeFirstWhere(tracks, 'a').length, 1);
      expect(PlaylistInsightsPro.moveTrack(tracks, 0, 1).first.id, 'b');
      expect(PlaylistInsightsPro.swapTracks(tracks, 0, 1).first.id, 'b');
      expect(PlaylistInsightsPro.rotateQueue(tracks, 1).first.id, 'b');
      expect(PlaylistInsightsPro.chunkTracks(tracks, 1).length, 2);
      expect(PlaylistInsightsPro.interleave(tracks, tracks).length, 4);
      expect(PlaylistInsightsPro.repeatTracks(tracks, 2).length, 4);
      expect(PlaylistInsightsPro.takeEveryNth(tracks, 2).length, 1);
      expect(PlaylistInsightsPro.playlistOverlap(tracks, [_b]), 1);
      expect(PlaylistInsightsPro.mergePlaylists(tracks, [_b]).length, 2);
      expect(PlaylistInsightsPro.shuffleWithSeed(tracks, 7).length, 2);
      expect(PlaylistInsightsPro.playlistChecksum(tracks), isA<String>());
    });
  });

  group('Pro toolkit expandido · letras', () {
    test(' parseo LRC', () {
      final lines = ['Primera', 'Segunda', 'Tercera'];
      expect(LyricsInsightsPro.lrcLineCount(_lyrics), 3);
      expect(LyricsInsightsPro.hasTimestamps(_lyrics), isTrue);
      expect(LyricsInsightsPro.firstTimestamp(_lyrics),
          const Duration(milliseconds: 1000));
      expect(LyricsInsightsPro.lastTimestamp(_lyrics),
          const Duration(milliseconds: 6000));
      expect(LyricsInsightsPro.lyricsDurationLabel(_lyrics), '00:05');
      expect(LyricsInsightsPro.lineAtPercent(lines, 50), 'Segunda');
      expect(LyricsInsightsPro.activeLineWindow(lines, 1).length, 3);
      expect(LyricsInsightsPro.lineBefore(lines, 1), 'Primera');
      expect(LyricsInsightsPro.lineAfter(lines, 1), 'Tercera');
      expect(LyricsInsightsPro.isBlankLine('  '), isTrue);
      expect(LyricsInsightsPro.trimLrcLine('[00:01.00]Hola'), 'Hola');
      expect(LyricsInsightsPro.lrcTagValue(_lyrics, 'ar'), 'Artista');
      expect(LyricsInsightsPro.metadataTags(_lyrics)['ti'], 'Titulo');
      expect(LyricsInsightsPro.stripMetadataTags(_lyrics), contains('Primera'));
      expect(LyricsInsightsPro.dedupeLines([...lines, 'Primera']).length, 3);
      expect(LyricsInsightsPro.karaokeWordCount('[00:01.00]Una dos tres'), 3);
      expect(LyricsInsightsPro.estimateSingingSeconds(lines), 1);
      expect(LyricsInsightsPro.syncOffsetFromTap(100, 150),
          const Duration(milliseconds: 50));
      expect(LyricsInsightsPro.lyricSearchQuery(_a), contains('letra'));
      expect(LyricsInsightsPro.tooFastWarning(lines), isFalse);
    });
  });

  group('Pro toolkit expandido · ajustes', () {
    test(' etiquetas legibles', () {
      expect(SettingsInsightsPro.themeLabelShort('dark'), 'Oscuro');
      expect(SettingsInsightsPro.contrastLabel(true), contains('Alto'));
      expect(SettingsInsightsPro.reduceMotionLabel(false), contains('completo'));
      expect(SettingsInsightsPro.hapticsLabel(true), contains('activada'));
      expect(SettingsInsightsPro.gesturesLabel(false), contains('desactivados'));
      expect(SettingsInsightsPro.wifiOnlyLabel(true), 'Solo Wi-Fi');
      expect(SettingsInsightsPro.dataSaverNote(true), contains('menor'));
      expect(SettingsInsightsPro.autoLyricsLabel(true), contains('automaticas'));
      expect(SettingsInsightsPro.wormLabel(true), contains('tiempo'));
      expect(SettingsInsightsPro.miniPlayerLabel(true), contains('visible'));
      expect(SettingsInsightsPro.shuffleByDefaultLabel(true), contains('iniciar'));
      expect(SettingsInsightsPro.sortModeLabel('plays'), 'Más escuchadas');
      expect(SettingsInsightsPro.gridLabel(true), contains('cuadricula'));
      expect(SettingsInsightsPro.notificationLabel(true), contains('visible'));
      expect(SettingsInsightsPro.batterySaverLabel(true), contains('bateria'));
      expect(SettingsInsightsPro.privacyLabel(false), contains('dispositivo'));
      expect(SettingsInsightsPro.languageLabel('en'), 'English');
      expect(SettingsInsightsPro.accentColorName(0), 'Azul');
      expect(SettingsInsightsPro.settingsSearchTerm(' TEMA '),
          contains('Buscar ajuste'));
      expect(SettingsInsightsPro.resetSummary(2), '2 ajustes restaurados');
    });
  });

  group('Pro toolkit expandido · estadisticas', () {
    test(' habitos de escucha', () {
      final counts = {'a': 2, 'b': 5};
      final dates = [
        DateTime(2026, 11, 17),
        DateTime(2026, 11, 18),
        DateTime(2026, 11, 19),
      ];
      expect(StatsInsightsPro.incrementPlayCount(counts, 'a')['a'], 3);
      expect(counts['a'], 2);
      expect(StatsInsightsPro.playCount(counts, 'b'), 5);
      expect(StatsInsightsPro.topTrackId(counts), 'b');
      expect(StatsInsightsPro.totalPlays(counts), 7);
      expect(StatsInsightsPro.averagePlays(counts), 3.5);
      expect(StatsInsightsPro.playRateLabel(7, 7), '1.0 por día');
      expect(StatsInsightsPro.streakDays(dates), 3);
      expect(StatsInsightsPro.lastPlayedLabel(0), contains('1970'));
      expect(StatsInsightsPro.listeningMinutesLabel(const Duration(minutes: 5)),
          contains('5'));
      expect(StatsInsightsPro.favoriteRatio(1, 4), 0.25);
      expect(StatsInsightsPro.completionRate(const Duration(seconds: 30),
          const Duration(minutes: 1)), 0.5);
      expect(StatsInsightsPro.skipRate(1, 4), 0.25);
      expect(StatsInsightsPro.dailyGoalLabel(5, 3), contains('3 de 5'));
      expect(StatsInsightsPro.weeklyGoalLabel(20, 8), contains('8 de 20'));
      expect(StatsInsightsPro.moodFromGenre('Rock'), 'energico');
      expect(StatsInsightsPro.moodLabel('relajado'), contains('relajado'));
      expect(StatsInsightsPro.listeningSlotLabel(9), 'Mañana');
      expect(StatsInsightsPro.peakHour({9: 3, 20: 7}), 20);
      expect(StatsInsightsPro.recommendationReason(_a), contains('Rock'));
      expect(StatsInsightsPro.statsBadge(85), 'Experto');
    });
  });

  group('Pro toolkit expandido · mantenimiento', () {
    test(' rutas y diagnostico', () {
      expect(MaintenanceInsightsPro.bytesToGb(1024 * 1024 * 1024), '1.00 GB');
      expect(MaintenanceInsightsPro.freeSpaceWarning(0), contains('Poco'));
      expect(MaintenanceInsightsPro.isLowStorage(0), isTrue);
      expect(MaintenanceInsightsPro.cacheEntriesLabel(1), contains('1 archivo'));
      expect(MaintenanceInsightsPro.clearCacheNote(2048), contains('KB'));
      expect(MaintenanceInsightsPro.orphanCount(['a.lrc', 'b.mp3']), 1);
      expect(MaintenanceInsightsPro.duplicatePathCount(['a', 'a']), 1);
      expect(MaintenanceInsightsPro.safePathJoin('/tmp/', 'a.mp3'), '/tmp/a.mp3');
      expect(MaintenanceInsightsPro.isValidFileName('a.mp3'), isTrue);
      expect(MaintenanceInsightsPro.truncatedName('abcdef', 4), 'abc…');
      expect(MaintenanceInsightsPro.logLine('info', 'ok'), '[INFO] ok');
      expect(MaintenanceInsightsPro.errorSummary([]), 'Sin errores');
      expect(MaintenanceInsightsPro.healthLabel(85), 'Saludable');
      expect(MaintenanceInsightsPro.repairAction(20), 'Reindexar biblioteca');
      expect(MaintenanceInsightsPro.backupName('1.1.0'), contains('1.1.0'));
      expect(MaintenanceInsightsPro.restoreNote(true), contains('disponible'));
      expect(MaintenanceInsightsPro.diagnosticLine('x', 1), 'x: 1');
      expect(MaintenanceInsightsPro.permissionStatusLabel(true),
          contains('concedido'));
      expect(MaintenanceInsightsPro.crashMarker('a\nb'), 'a');
      expect(MaintenanceInsightsPro.supportTicketId(1), startsWith('SB-'));
    });
  });

  group('Pro toolkit expandido · exportacion', () {
    test(' M3U, compartir y metadatos', () {
      expect(SharingInsightsPro.m3uExtendedLine(_a), contains('#EXTINF:'));
      expect(SharingInsightsPro.m3uComment('x'), '# x');
      expect(SharingInsightsPro.m3uTitle('Mi lista'), contains('#PLAYLIST:'));
      expect(SharingInsightsPro.xspfTrackLine(_a), contains('<track>'));
      expect(SharingInsightsPro.csvEscape('a"b'), '"a""b"');
      expect(SharingInsightsPro.shareText(_a), contains('Al Rojo Vivo'));
      expect(SharingInsightsPro.shareSubject([_a, _b]), contains('2 canciones'));
      expect(SharingInsightsPro.attributionFooter(_a), contains('Jamendo'));
      expect(SharingInsightsPro.licenseBadge('CC BY'), 'Creative Commons');
      expect(SharingInsightsPro.legalProvidersCsv(), contains('Jamendo'));
      expect(SharingInsightsPro.youtubeNotice(), contains('autorizado'));
      expect(SharingInsightsPro.directUrlHint(), contains('URL directa'));
      expect(SharingInsightsPro.fileUri('/tmp/a.mp3'), 'file:///tmp/a.mp3');
      expect(SharingInsightsPro.encodedQuery({'a': '1'}), 'a=1');
      expect(SharingInsightsPro.decodeQuery('a=1')['a'], '1');
      expect(SharingInsightsPro.trackFingerprint(_a), contains('al rojo vivo'));
      expect(SharingInsightsPro.playlistExportName('Mi Lista!'),
          endsWith('.m3u'));
      expect(SharingInsightsPro.metadataSummary(_a), contains('2018'));
      expect(SharingInsightsPro.bitrateQualityLabel(320000), 'Alta');
      expect(SharingInsightsPro.sampleRateLabel(48000), '48.0 kHz');
    });
  });
}
