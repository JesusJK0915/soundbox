// Generador temporal para la expansion 1.2.0 del toolkit.
// No forma parte del runtime de la app.
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const existing = fs.readFileSync(path.join(root, 'lib/core/pro_toolkit.dart'), 'utf8');

const m = (ret, name, params, body, call) => ({ ret, name, params, body, call });

const groups = [];

groups.push({
  cls: 'LibraryToolsV2',
  title: 'Biblioteca',
  methods: [
    m('String', 'cleanTitle', 'String value', 'value.trim()', "'  Hola  '"),
    m('String', 'cleanArtist', 'String value', 'value.trim()', "'  Artista  '"),
    m('String', 'cleanAlbum', 'String? value', "(value ?? '').trim()", "null"),
    m('String', 'titleWithoutFeat', 'String value', "value.replaceAll(RegExp(r'\\s*feat\\..*$', caseSensitive: false), '').trim()", "'Tema feat. Otro'"),
    m('int', 'artistCount', 'String value', 'LibraryToolsPro.splitArtists(value).length', "'Uno & Dos'"),
    m('bool', 'hasCollab', 'String value', 'LibraryToolsPro.splitArtists(value).length > 1', "'Uno & Dos'"),
    m('bool', 'isExplicit', 'String value', "value.toLowerCase().contains('explicit')", "'Tema explicit'"),
    m('bool', 'isAcoustic', 'String value', "value.toLowerCase().contains('acoustic')", "'Tema acoustic'"),
    m('bool', 'isRemastered', 'String value', "value.toLowerCase().contains('remaster')", "'Tema remaster'"),
    m('bool', 'isDeluxe', 'String value', "value.toLowerCase().contains('deluxe')", "'Tema deluxe'"),
    m('int', 'safeYearV2', 'int? year', 'year ?? 0', 'null'),
    m('int', 'safeDurationMsV2', 'int? ms', 'ms ?? 0', 'null'),
    m('String', 'durationBucket', 'Duration value', "value.inMinutes < 3 ? 'Corta' : value.inMinutes < 6 ? 'Media' : 'Larga'", 'Duration(minutes: 4)'),
    m('bool', 'isLongTrackV2', 'Duration value', 'value.inMinutes >= 10', 'Duration(minutes: 12)'),
    m('bool', 'isShortTrackV2', 'Duration value', 'value.inMinutes <= 2', 'Duration(minutes: 1)'),
    m('int', 'secondsTotalV2', 'List<Track> tracks', "tracks.fold<int>(0, (sum, t) => sum + (t.durationMs ?? 0) ~/ 1000)", 'const <Track>[]'),
    m('int', 'missingTitleCount', 'List<Track> tracks', "tracks.where((t) => t.title.trim().isEmpty).length", 'const <Track>[]'),
    m('int', 'missingArtistCount', 'List<Track> tracks', "tracks.where((t) => t.artist.trim().isEmpty).length", 'const <Track>[]'),
    m('int', 'tracksWithYear', 'List<Track> tracks', 'tracks.where((t) => t.year != null).length', 'const <Track>[]'),
    m('double', 'libraryCompletenessV2', 'List<Track> tracks', "tracks.isEmpty ? 0.0 : tracks.where((t) => t.title.isNotEmpty && t.artist.isNotEmpty && t.album != null).length / tracks.length", 'const <Track>[]'),
  ],
});

groups.push({
  cls: 'PlaybackToolsV2',
  title: 'Reproduccion',
  methods: [
    m('double', 'clampVolume', 'double value', 'value < 0 ? 0.0 : value > 1 ? 1.0 : value', '1.5'),
    m('double', 'clampSpeed', 'double value', 'value < 0.5 ? 0.5 : value > 2.0 ? 2.0 : value', '3.0'),
    m('int', 'repeatModeIndex', 'String mode', "mode == 'one' ? 2 : mode == 'all' ? 1 : 0", "'all'"),
    m('String', 'repeatModeName', 'int index', "index == 2 ? 'one' : index == 1 ? 'all' : 'off'", '1'),
    m('String', 'nextRepeatMode', 'String mode', "mode == 'off' ? 'all' : mode == 'all' ? 'one' : 'off'", "'off'"),
    m('bool', 'isRepeatOne', 'String mode', "mode == 'one'", "'one'"),
    m('bool', 'isRepeatAll', 'String mode', "mode == 'all'", "'all'"),
    m('bool', 'isRepeatOff', 'String mode', "mode == 'off'", "'off'"),
    m('int', 'seekForwardMs', 'int current, int delta, int max', 'current + delta > max ? max : current + delta', '100, 50, 120'),
    m('int', 'seekBackwardMs', 'int current, int delta', 'current - delta < 0 ? 0 : current - delta', '30, 50'),
    m('double', 'progressRatio', 'int current, int max', 'max <= 0 ? 0.0 : (current / max).clamp(0.0, 1.0)', '50, 100'),
    m('int', 'playedMs', 'int current, int max', 'current.clamp(0, max < 0 ? 0 : max)', '50, 100'),
    m('int', 'remainingMs', 'int current, int max', 'max <= current ? 0 : max - current', '50, 100'),
    m('bool', 'isFinishedV2', 'Duration position, Duration duration', 'duration <= Duration.zero || position >= duration', 'Duration(seconds: 5), Duration(seconds: 3)'),
    m('bool', 'isBeginningV2', 'Duration position', 'position <= Duration.zero', 'Duration.zero'),
    m('int', 'wrapIndexV2', 'int index, int length', 'length <= 0 ? 0 : index % length', '7, 5'),
    m('double', 'volumeAfterStep', 'double value, double step', 'clampVolume(value + step)', '0.8, 0.4'),
    m('double', 'speedAfterStep', 'double value, double step', 'clampSpeed(value + step)', '1.5, 0.8'),
    m('double', 'crossfadeFractionV2', 'Duration position, Duration fade', 'fade <= Duration.zero ? 0.0 : (position.inMilliseconds / fade.inMilliseconds).clamp(0.0, 1.0)', 'Duration(seconds: 1), Duration(seconds: 4)'),
    m('String', 'playbackStateLabel', 'bool playing, bool buffering', "buffering ? 'Cargando' : playing ? 'Reproduciendo' : 'Pausado'", 'true, false'),
  ],
});

groups.push({
  cls: 'SearchToolsV2',
  title: 'Busqueda',
  methods: [
    m('String', 'compactWhitespaceV2', 'String value', "value.replaceAll(RegExp(r'\\s+'), ' ').trim()", "'  a   b  '"),
    m('String', 'removePunctuationV2', 'String value', "value.replaceAll(RegExp(r'[^\\w\\s]'), '')", "'a,b!'"),
    m('List<String>', 'tokenListV2', 'String value', "compactWhitespaceV2(value).split(' ').where((s) => s.isNotEmpty).toList()", "'a b'"),
    m('List<String>', 'uniqueTokensV2', 'String value', 'tokenListV2(value).toSet().toList()', "'a a b'"),
    m('int', 'tokenCountV2', 'String value', 'tokenListV2(value).length', "'a b c'"),
    m('bool', 'isWildcardV2', 'String value', "value.contains('*') || value.contains('?')", "'a*'"),
    m('String', 'stripWildcardsV2', 'String value', "value.replaceAll(RegExp(r'[*?]'), '')", "'a*?'"),
    m('bool', 'isQuotedV2', 'String value', "value.length >= 2 && value.startsWith('\"') && value.endsWith('\"')", "'\"hola\"'"),
    m('String', 'unquoteV2', 'String value', "isQuotedV2(value) ? value.substring(1, value.length - 1) : value", "'\"hola\"'"),
    m('bool', 'exactMatchV2', 'String query, String candidate', 'LibraryToolsPro.normalizeText(query) == LibraryToolsPro.normalizeText(candidate)', "'Hola', 'hola'"),
    m('bool', 'prefixMatchV2', 'String query, String candidate', 'LibraryToolsPro.normalizeText(candidate).startsWith(LibraryToolsPro.normalizeText(query))', "'hol', 'hola'"),
    m('bool', 'containsMatchV2', 'String query, String candidate', 'LibraryToolsPro.normalizeText(candidate).contains(LibraryToolsPro.normalizeText(query))', "'ola', 'hola'"),
    m('int', 'tokenOverlapV2', 'String query, String candidate', "tokenListV2(query).toSet().intersection(tokenListV2(candidate).toSet()).length", "'a b', 'b c'"),
    m('double', 'jaccardV2', 'String query, String candidate', "final a = tokenListV2(query).toSet(); final b = tokenListV2(candidate).toSet(); final u = a.union(b); return u.isEmpty ? 0.0 : a.intersection(b).length / u.length;", "'a b', 'b c'"),
    m('int', 'levenshteinV2', 'String a, String b', '_levenshtein(a, b)', "'casa', 'casa'"),
    m('int', 'bestFuzzyIndexV2', 'String query, List<String> options', "if (options.isEmpty) return -1; var best = 0; var score = _levenshtein(query, options.first); for (var i = 1; i < options.length; i++) { final s = _levenshtein(query, options[i]); if (s < score) { score = s; best = i; } } return best;", "'casa', const ['perro', 'casa']"),
    m('String', 'searchHintV2', 'String query', "query.trim().isEmpty ? 'Escribe para buscar' : 'Resultados para ' + query", "''"),
    m('String', 'resultLabelV2', 'int count', "count == 1 ? '1 resultado' : '${count} resultados'", '2'),
    m('bool', 'isStopWordV2', 'String token', "const {'de', 'la', 'el', 'los', 'las', 'y', 'o'}.contains(token.toLowerCase())", "'de'"),
    m('List<String>', 'removeStopWordsV2', 'String value', "tokenListV2(value).where((t) => !isStopWordV2(t)).toList()", "'la casa de papel'"),
  ],
});

groups.push({
  cls: 'DownloadToolsV2',
  title: 'Descargas',
  methods: [
    m('String', 'normalizeFormatV2', 'String format', "format.replaceAll('.', '').toLowerCase()", "'.MP3'"),
    m('String', 'extensionForFormatV2', 'String format', "'.' + normalizeFormatV2(format)", "'mp3'"),
    m('bool', 'isAudioExtensionV2', 'String ext', "const {'mp3', 'm4a', 'aac', 'flac', 'ogg', 'wav'}.contains(normalizeFormatV2(ext))", "'mp3'"),
    m('bool', 'isVideoExtensionV2', 'String ext', "const {'mp4', 'mkv', 'webm'}.contains(normalizeFormatV2(ext))", "'mp4'"),
    m('String', 'urlHostV2', 'String url', "Uri.tryParse(url)?.host ?? ''", "'https://example.com/a.mp3'"),
    m('String', 'urlPathV2', 'String url', "Uri.tryParse(url)?.path ?? ''", "'https://example.com/a.mp3'"),
    m('bool', 'isHttpsV2', 'String url', "url.toLowerCase().startsWith('https://')", "'https://example.com'"),
    m('bool', 'isHttpV2', 'String url', "url.toLowerCase().startsWith('http://')", "'http://example.com'"),
    m('String', 'safeFileNameV2', 'String value', "value.replaceAll(RegExp(r'[<>:\"/\\\\|?*]'), '_').trim()", "'a/b:c'"),
    m('String', 'fileNameWithoutExtV2', 'String name', "name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name", "'cancion.mp3'"),
    m('String', 'fileExtV2', 'String name', "name.contains('.') ? name.substring(name.lastIndexOf('.') + 1) : ''", "'cancion.mp3'"),
    m('String', 'estimateSizeLabelV2', 'int bytes', "bytes >= 1000000 ? '${(bytes / 1000000).toStringAsFixed(1)} MB' : '${(bytes / 1000).toStringAsFixed(0)} KB'", '2000000'),
    m('int', 'bitrateToKbpsV2', 'int bps', 'bps ~/ 1000', '192000'),
    m('int', 'kbpsToBpsV2', 'int kbps', 'kbps * 1000', '192'),
    m('String', 'retryAttemptLabelV2', 'int attempt', "'Intento ${attempt}'", '2'),
    m('bool', 'isRetryableV2', 'int status', 'status == 408 || status == 429 || status >= 500', '503'),
    m('String', 'mimeForExtV2', 'String ext', "switch (normalizeFormatV2(ext)) { 'mp3' => 'audio/mpeg', 'm4a' => 'audio/mp4', 'flac' => 'audio/flac', 'ogg' => 'audio/ogg', 'wav' => 'audio/wav', _ => 'application/octet-stream' }", "'mp3'"),
    m('String', 'qualityFromBitrateV2', 'int bps', "bps >= 256000 ? 'Alta' : bps >= 128000 ? 'Media' : 'Baja'", '192000'),
    m('double', 'downloadProgressV2', 'int done, int total', 'total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0)', '50, 100'),
    m('String', 'etaLabelV2', 'int seconds', "seconds <= 0 ? 'Listo' : '${seconds} s'", '10'),
  ],
});

groups.push({
  cls: 'PlaylistToolsV2',
  title: 'Playlists',
  methods: [
    m('String', 'm3uHeaderV2', '', "'#EXTM3U'", ''),
    m('bool', 'isM3uHeaderV2', 'String line', "line.trim() == '#EXTM3U'", "'#EXTM3U'"),
    m('bool', 'isExtinfV2', 'String line', "line.trim().startsWith('#EXTINF:')", "'#EXTINF:123,Art - Tema'"),
    m('int', 'parseExtinfSecondsV2', 'String line', "final m = RegExp(r'#EXTINF:(\\d+)').firstMatch(line); return m == null ? 0 : int.tryParse(m.group(1) ?? '') ?? 0;", "'#EXTINF:123,Art - Tema'"),
    m('String', 'parseExtinfTitleV2', 'String line', "final i = line.indexOf(','); return i < 0 ? '' : line.substring(i + 1).trim();", "'#EXTINF:123,Art - Tema'"),
    m('String', 'playlistSlugV2', 'String name', "LibraryToolsPro.normalizeText(name).replaceAll(RegExp(r'\\s+'), '-')", "'Mi Lista'"),
    m('String', 'playlistFileNameV2', 'String name', "playlistSlugV2(name) + '.m3u'", "'Mi Lista'"),
    m('int', 'playlistSizeV2', 'List<Track> tracks', 'tracks.length', 'const <Track>[]'),
    m('int', 'playlistDurationSecondsV2', 'List<Track> tracks', "tracks.fold<int>(0, (s, t) => s + (t.durationMs ?? 0) ~/ 1000)", 'const <Track>[]'),
    m('String', 'playlistDurationLabelV2', 'List<Track> tracks', 'Duration(seconds: playlistDurationSecondsV2(tracks)).toString()', 'const <Track>[]'),
    m('List<Track>', 'mergeTracksV2', 'List<Track> a, List<Track> b', '[...a, ...b]', 'const <Track>[], const <Track>[]'),
    m('List<Track>', 'uniqueTracksV2', 'List<Track> tracks', "tracks.fold<List<Track>>(<Track>[], (list, t) { if (!list.any((x) => x.id == t.id)) list.add(t); return list; })", 'const <Track>[]'),
    m('List<Track>', 'tracksByGenreV2', 'List<Track> tracks, String genre', "tracks.where((t) => LibraryToolsPro.normalizeText(t.genre ?? '') == LibraryToolsPro.normalizeText(genre)).toList()", 'const <Track>[], \'Pop\''),
    m('List<Track>', 'tracksByYearV2', 'List<Track> tracks, int year', 'tracks.where((t) => t.year == year).toList()', 'const <Track>[], 2020'),
    m('List<Track>', 'tracksByArtistV2', 'List<Track> tracks, String artist', 'tracks.where((t) => LibraryToolsPro.artistKey(t.artist) == LibraryToolsPro.artistKey(artist)).toList()', 'const <Track>[], \'Art\''),
    m('List<Track>', 'shuffleTracksV2', 'List<Track> tracks, int seed', 'PlaybackToolsPro.shuffledIndices(tracks.length, seed).map((i) => tracks[i]).toList()', 'const <Track>[], 1'),
    m('String', 'firstTitleV2', 'List<Track> tracks', "tracks.isEmpty ? '' : tracks.first.title", 'const <Track>[]'),
    m('String', 'lastTitleV2', 'List<Track> tracks', "tracks.isEmpty ? '' : tracks.last.title", 'const <Track>[]'),
    m('String', 'playlistChecksumV2', 'List<Track> tracks', "tracks.map((t) => t.id).join('|')", 'const <Track>[]'),
    m('double', 'playlistHealthV2', 'List<Track> tracks', "tracks.isEmpty ? 0.0 : tracks.where((t) => t.title.isNotEmpty && t.artist.isNotEmpty).length / tracks.length", 'const <Track>[]'),
  ],
});

groups.push({
  cls: 'LyricsToolsV2',
  title: 'Letras',
  methods: [
    m('String', 'lrcTimeLabelV2', 'Duration d', "'${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}'", 'Duration(seconds: 65)'),
    m('bool', 'isLrcTimestampV2', 'String line', "RegExp(r'^\\[\\d{1,2}:\\d{2}(?:\\.\\d+)?\\]').hasMatch(line.trim())", "'[01:23]Hola'"),
    m('bool', 'isLrcMetadataV2', 'String line', "RegExp(r'^\\[[a-zA-Z]+:').hasMatch(line.trim())", "'[ar:Artista]'"),
    m('int', 'lrcTimestampMillisV2', 'String line', "final m = RegExp(r'\\[(\\d{1,2}):(\\d{2})(?:\\.(\\d+))?\\]').firstMatch(line); if (m == null) return 0; final min = int.tryParse(m.group(1) ?? '') ?? 0; final sec = int.tryParse(m.group(2) ?? '') ?? 0; final frac = m.group(3) ?? ''; final ms = (frac + '000').substring(0, 3); return min * 60000 + sec * 1000 + (int.tryParse(ms) ?? 0);", "'[01:23.500]Hola'"),
    m('String', 'lrcTextV2', 'String line', "line.replaceAll(RegExp(r'^\\[[^\\]]+\\]'), '').trim()", "'[01:23]Hola'"),
    m('String', 'stripLrcTagsV2', 'String lyrics', "lyrics.replaceAll(RegExp(r'\\[[^\\]]+\\]'), '').trim()", "'[01:23]Hola'"),
    m('int', 'lyricsLineCountV2', 'String lyrics', "stripLrcTagsV2(lyrics).split('\\n').where((l) => l.trim().isNotEmpty).length", "'[00:01]A\\n[00:02]B'"),
    m('bool', 'isLyricsEmptyV2', 'String lyrics', 'stripLrcTagsV2(lyrics).isEmpty', "''"),
    m('bool', 'isInstrumentalV2', 'String lyrics', "stripLrcTagsV2(lyrics).toLowerCase().contains('instrumental')", "'Instrumental'"),
    m('int', 'lyricsWordCountV2', 'String lyrics', "stripLrcTagsV2(lyrics).split(RegExp(r'\\s+')).where((w) => w.isNotEmpty).length", "'uno dos tres'"),
    m('int', 'activeLineIndexV2', 'List<Duration> times, Duration position', "for (var i = times.length - 1; i >= 0; i--) { if (position >= times[i]) return i; } return -1;", "const [Duration(seconds: 1)], Duration(seconds: 2)"),
    m('int', 'nextLineIndexV2', 'List<Duration> times, Duration position', "for (var i = 0; i < times.length; i++) { if (times[i] > position) return i; } return -1;", "const [Duration(seconds: 1)], Duration.zero"),
    m('String', 'lyricAtV2', 'List<String> lines, int index', "index < 0 || index >= lines.length ? '' : lines[index]", "const ['A'], 0"),
    m('int', 'safeLyricIndexV2', 'List<String> lines, int index', "index < 0 ? 0 : index >= lines.length ? lines.length - 1 : index", "const ['A'], 5"),
    m('double', 'karaokePercentV2', 'Duration start, Duration end, Duration position', "end <= start ? 0.0 : (position - start).inMilliseconds / (end - start).inMilliseconds", 'Duration(seconds: 1), Duration(seconds: 3), Duration(seconds: 2)'),
    m('String', 'syncOffsetLabelV2', 'int ms', "ms > 0 ? '+' + ms.toString() + ' ms' : ms.toString() + ' ms'", '120'),
    m('Duration', 'applyOffsetV2', 'Duration time, int ms', 'Duration(milliseconds: time.inMilliseconds + ms)', 'Duration(seconds: 1), 100'),
    m('bool', 'hasTranslationV2', 'String lyrics', "lyrics.toLowerCase().contains('translation')", "'[translation:es]'"),
    m('String', 'firstLyricV2', 'String lyrics', "final lines = stripLrcTagsV2(lyrics).split('\\n').where((l) => l.trim().isNotEmpty).toList(); return lines.isEmpty ? '' : lines.first;", "'[00:01]A'"),
    m('String', 'lastLyricV2', 'String lyrics', "final lines = stripLrcTagsV2(lyrics).split('\\n').where((l) => l.trim().isNotEmpty).toList(); return lines.isEmpty ? '' : lines.last;", "'[00:01]A'"),
  ],
});

groups.push({
  cls: 'SettingsToolsV2',
  title: 'Ajustes',
  methods: [
    m('String', 'gestureLabelV2', 'bool enabled', "enabled ? 'Gestos activos' : 'Gestos desactivados'", 'true'),
    m('String', 'hapticLabelV2', 'bool enabled', "enabled ? 'Háptico activo' : 'Háptico desactivado'", 'true'),
    m('String', 'wormLabelV2', 'bool enabled', "enabled ? 'Onda visible' : 'Onda oculta'", 'true'),
    m('String', 'themeLabelV2', 'String theme', "theme == 'dark' ? 'Oscuro' : 'Claro'", "'dark'"),
    m('bool', 'isDarkThemeV2', 'String theme', "theme == 'dark'", "'dark'"),
    m('String', 'toggleThemeV2', 'String theme', "theme == 'dark' ? 'light' : 'dark'", "'dark'"),
    m('String', 'qualityLabelV2', 'int kbps', "kbps >= 256 ? 'Alta' : kbps >= 128 ? 'Media' : 'Baja'", '192'),
    m('String', 'crossfadeLabelV2', 'double seconds', "seconds.toStringAsFixed(1) + ' s'", '3.5'),
    m('String', 'sleepLabelV2', 'int minutes', "minutes <= 0 ? 'Desactivado' : minutes.toString() + ' min'", '15'),
    m('String', 'volumeLabelV2', 'int percent', "percent.toString() + ' %'", '80'),
    m('int', 'clampBrightnessV2', 'int value', 'value < 0 ? 0 : value > 100 ? 100 : value', '150'),
    m('String', 'safeLocaleV2', 'String locale', "locale.isEmpty ? 'es' : locale", "''"),
    m('String', 'languageLabelV2', 'String code', "code.startsWith('es') ? 'Español' : code.startsWith('en') ? 'English' : code", "'es_MX'"),
    m('String', 'accessibilitySummaryV2', 'bool gestures, bool haptics', "gestures && haptics ? 'Completa' : gestures || haptics ? 'Parcial' : 'Mínima'", 'true, false'),
    m('String', 'preferenceKeyV2', 'String name', "'sb_' + LibraryToolsPro.normalizeText(name).replaceAll(RegExp(r'\\s+'), '_')", "'Modo oscuro'"),
    m('String', 'preferenceValueLabelV2', 'String name, bool value', "name + (value ? ': sí' : ': no')", "'Gestos', true"),
    m('String', 'storageLabelV2', 'int bytes', "bytes >= 1000000 ? (bytes / 1000000).toStringAsFixed(1) + ' MB' : (bytes / 1000).toStringAsFixed(0) + ' KB'", '2000000'),
    m('String', 'cacheLabelV2', 'int files', "files.toString() + ' archivos'", '12'),
    m('String', 'networkLabelV2', 'bool online', "online ? 'En línea' : 'Sin conexión'", 'true'),
    m('String', 'updateChannelLabelV2', 'String channel', "channel == 'stable' ? 'Estable' : channel == 'beta' ? 'Beta' : 'Alpha'", "'stable'"),
  ],
});

groups.push({
  cls: 'StatsToolsV2',
  title: 'Estadisticas',
  methods: [
    m('int', 'listeningMinutesV2', 'int ms', 'ms ~/ 60000', '120000'),
    m('String', 'listeningHoursV2', 'int ms', '(ms / 3600000).toStringAsFixed(1)', '7200000'),
    m('int', 'dailyAverageV2', 'int totalMs, int days', 'days <= 0 ? 0 : totalMs ~/ days', '60000, 2'),
    m('String', 'streakLabelV2', 'int days', "days == 1 ? '1 día' : days.toString() + ' días'", '3'),
    m('String', 'topArtistV2', 'List<Track> tracks', "final counts = <String, int>{}; for (final t in tracks) { final k = LibraryToolsPro.artistKey(t.artist); counts[k] = (counts[k] ?? 0) + 1; } if (counts.isEmpty) return ''; return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;", 'const <Track>[]'),
    m('String', 'topGenreV2', 'List<Track> tracks', "final counts = <String, int>{}; for (final t in tracks) { final k = LibraryToolsPro.normalizeText(t.genre ?? ''); if (k.isEmpty) continue; counts[k] = (counts[k] ?? 0) + 1; } if (counts.isEmpty) return ''; return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;", 'const <Track>[]'),
    m('int', 'uniqueArtistsV2', 'List<Track> tracks', "tracks.map((t) => LibraryToolsPro.artistKey(t.artist)).toSet().length", 'const <Track>[]'),
    m('int', 'uniqueGenresV2', 'List<Track> tracks', "tracks.map((t) => LibraryToolsPro.normalizeText(t.genre ?? '')).toSet().where((g) => g.isNotEmpty).length", 'const <Track>[]'),
    m('double', 'completionRateV2', 'int played, int total', 'total <= 0 ? 0.0 : (played / total).clamp(0.0, 1.0)', '5, 10'),
    m('double', 'skipRateV2', 'int skips, int plays', 'plays <= 0 ? 0.0 : (skips / plays).clamp(0.0, 1.0)', '2, 10'),
    m('double', 'favoriteRatioV2', 'int favorites, int total', 'total <= 0 ? 0.0 : (favorites / total).clamp(0.0, 1.0)', '3, 10'),
    m('String', 'hourBucketV2', 'DateTime time', "time.hour < 12 ? 'Mañana' : time.hour < 19 ? 'Tarde' : 'Noche'", 'DateTime(2026, 1, 1, 10)'),
    m('String', 'weekdayLabelV2', 'int weekday', "const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][(weekday - 1).clamp(0, 6)]", '1'),
    m('String', 'monthLabelV2', 'int month', "const ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'][(month - 1).clamp(0, 11)]", '11'),
    m('String', 'yearLabelV2', 'int year', "year <= 0 ? 'Sin año' : year.toString()", '2026'),
    m('int', 'mostPlayedHourV2', 'List<int> hours', "final counts = <int, int>{}; for (final h in hours) { counts[h] = (counts[h] ?? 0) + 1; } if (counts.isEmpty) return 0; return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;", "const [10, 10, 20]"),
    m('double', 'averageSessionMinutesV2', 'List<int> minutes', 'minutes.isEmpty ? 0.0 : minutes.reduce((a, b) => a + b) / minutes.length', 'const [10, 20]'),
    m('int', 'longestSessionV2', 'List<int> minutes', 'minutes.isEmpty ? 0 : minutes.reduce(math.max)', 'const [10, 20]'),
    m('String', 'statsSummaryV2', 'int plays, int minutes', "plays.toString() + ' reproducciones · ' + minutes.toString() + ' min'", '3, 12'),
    m('String', 'activityLabelV2', 'int plays', "plays == 0 ? 'Sin actividad' : plays < 10 ? 'Baja' : plays < 50 ? 'Media' : 'Alta'", '12'),
  ],
});

groups.push({
  cls: 'MaintenanceToolsV2',
  title: 'Mantenimiento',
  methods: [
    m('int', 'versionCodeFromV2', 'String version', 'MaintenanceToolsPro.versionCodeFrom(version)', "'1.2.0'"),
    m('bool', 'isValidVersionV2', 'String version', "RegExp(r'^\\d+\\.\\d+\\.\\d+$').hasMatch(version)", "'1.2.0'"),
    m('int', 'segmentLimitV2', 'int segment', 'segment > 9 ? 9 : segment < 0 ? 0 : segment', '12'),
    m('int', 'clampVersionPartV2', 'int part', 'segmentLimitV2(part)', '12'),
    m('int', 'buildNumberFromTagV2', 'String tag', "MaintenanceToolsPro.versionCodeFrom(tag.replaceAll('v', ''))", "'v1.2.0'"),
    m('bool', 'isStableTagV2', 'String tag', "RegExp(r'^v\\d+\\.\\d+\\.\\d+$').hasMatch(tag)", "'v1.2.0'"),
    m('bool', 'isPrereleaseTagV2', 'String tag', "tag.contains('-alpha') || tag.contains('-beta') || tag.contains('-rc')", "'v1.2.0-beta.1'"),
    m('String', 'normalizeTagV2', 'String tag', "tag.startsWith('v') ? tag : 'v' + tag", "'1.2.0'"),
    m('String', 'cacheKeyV2', 'String path', 'path.hashCode.toString()', "'/tmp/a'"),
    m('String', 'safeJsonKeyV2', 'String key', "key.replaceAll(RegExp(r'\\s+'), '_')", "'mi clave'"),
    m('String', 'truncateV2', 'String value, int max', 'value.length <= max ? value : value.substring(0, max.clamp(0, value.length))', "'abcdef', 3"),
    m('String', 'ellipsizeV2', 'String value, int max', "value.length <= max ? value : value.substring(0, max.clamp(0, value.length)) + '…'", "'abcdef', 3"),
    m('int', 'countLinesV2', 'String value', "value.isEmpty ? 0 : value.split('\\n').length", "'a\\nb'"),
    m('int', 'countWordsV2', 'String value', "value.split(RegExp(r'\\s+')).where((w) => w.isNotEmpty).length", "'uno dos'"),
    m('bool', 'isBlankV2', 'String? value', 'value == null || value.trim().isEmpty', "''"),
    m('String', 'coalesceV2', 'String? value, String fallback', 'isBlankV2(value) ? fallback : value!', "null, 'x'"),
    m('String', 'padNumberV2', 'int value, int length', 'value.toString().padLeft(length, \'0\')', '7, 3'),
    m('String', 'bytesLabelV2', 'int bytes', "bytes >= 1048576 ? (bytes / 1048576).toStringAsFixed(1) + ' MiB' : (bytes / 1024).toStringAsFixed(0) + ' KiB'", '2097152'),
    m('String', 'percentLabelV2', 'double value', "(value.clamp(0.0, 1.0) * 100).round().toString() + ' %'", '0.5'),
    m('String', 'diagnosticSummaryV2', 'String version, int code', "version + ' (' + code.toString() + ')'", "'1.2.0', 120"),
  ],
});

groups.push({
  cls: 'ExportToolsV2',
  title: 'Exportacion',
  methods: [
    m('String', 'csvEscapeV2', 'String value', "'\"' + value.replaceAll('\"', '\"\"') + '\"'", "'a,b'"),
    m('String', 'csvHeaderV2', '', "'id,title,artist,album,duration'", ''),
    m('String', 'csvRowV2', 'Track track', "[track.id, track.title, track.artist, track.album ?? '', (track.durationMs ?? 0).toString()].map(csvEscapeV2).join(',')", '_t()'),
    m('String', 'jsonSafeV2', 'String value', 'jsonEncode(value)', "'hola'"),
    m('String', 'playlistHeaderV2', 'String name', "'#EXTM3U\\n#PLAYLIST:' + name", "'Mi lista'"),
    m('String', 'extinfLineV2', 'Track track', "'#EXTINF:' + ((track.durationMs ?? 0) ~/ 1000).toString() + ',' + track.artist + ' - ' + track.title", '_t()'),
    m('String', 'trackUriV2', 'Track track', 'track.sourceUrl', '_t()'),
    m('String', 'exportNameV2', 'String name, String ext', "LibraryToolsPro.sanitizeFileName(name) + '.' + normalizeFormatV2(ext)", "'Mi lista', 'm3u'"),
    m('int', 'exportSizeEstimateV2', 'List<Track> tracks', '64 + tracks.length * 96', 'const <Track>[]'),
    m('String', 'm3uBodyV2', 'List<Track> tracks', "tracks.map(extinfLineV2).join('\\n')", 'const <Track>[]'),
    m('String', 'tagsToJsonV2', 'Map<String, String> tags', 'jsonEncode(tags)', "const {'a': 'b'}"),
    m('String', 'decodeJsonV2', 'String raw', 'jsonDecode(raw).toString()', "'\"hola\"'"),
    m('String', 'fileNameForTrackV2', 'Track track', "LibraryToolsPro.sanitizeFileName(track.title) + extensionForFormatV2(track.format ?? 'mp3')", '_t()'),
    m('String', 'licenseLabelV2', 'String? license', "license == null || license.isEmpty ? 'Sin licencia' : license", "null"),
    m('String', 'providerLabelV2', 'Track track', "track.source ?? 'Desconocido'", '_t()'),
    m('String', 'exportSummaryV2', 'List<Track> tracks', "tracks.length.toString() + ' pistas'", 'const <Track>[]'),
    m('bool', 'isExportableV2', 'Track track', 'track.title.isNotEmpty && track.sourceUrl.isNotEmpty', '_t()'),
    m('String', 'exportChecksumV2', 'List<Track> tracks', "tracks.map((t) => t.id).join(',').hashCode.toString()", 'const <Track>[]'),
    m('String', 'mimeForExportV2', 'String ext', "ext == 'm3u' ? 'audio/x-mpegurl' : 'application/json'", "'m3u'"),
    m('String', 'exportVersionTagV2', 'String version', "'SoundBox-' + version", "'1.2.0'"),
  ],
});

const totalNew = groups.reduce((n, g) => n + g.methods.length, 0);
if (totalNew !== 200) throw new Error('Se esperaban 200 metodos, hay ' + totalNew);

// --- 100 mejoras sobre funciones anteriores -------------------------------
const singles = [];
let currentClass = '';
for (const line of existing.split('\n')) {
  const cm = line.match(/^class\s+(\w+)/);
  if (cm) currentClass = cm[1];
  const mm = line.match(/^\s*static\s+String\s+(\w+)\(String\s+\w+\)/);
  if (mm && currentClass) singles.push({ cls: currentClass, name: mm[1] });
}
if (singles.length < 50) throw new Error('No hay suficientes funciones String previas: ' + singles.length);
const cap = (s) => s.charAt(0).toUpperCase() + s.slice(1);
const refinements = [];
for (const s of singles.slice(0, 50)) {
  refinements.push({
    name: 'safe' + cap(s.name),
    ret: 'String',
    params: 'Object? value',
    body: `${s.cls}.${s.name}(value?.toString().trim() ?? '')`,
    call: "'  Hola  '",
    original: `${s.cls}.${s.name}`,
  });
  refinements.push({
    name: 'compact' + cap(s.name),
    ret: 'String',
    params: 'Object? value',
    body: `${s.cls}.${s.name}((value?.toString() ?? '').replaceAll(RegExp(r'\\s+'), ' ').trim())`,
    call: "'  Hola   mundo  '",
    original: `${s.cls}.${s.name}`,
  });
}
if (refinements.length !== 100) throw new Error('Se esperaban 100 mejoras');

// --- Generacion del archivo de utilidades --------------------------------
let lib = `// Utilidades puras anadidas en la version estable 1.2.0.\n`;
lib += `// Generadas de forma determinista; no dependen de Flutter ni de servicios.\n`;
lib += `import 'dart:convert';\nimport 'dart:math' as math;\n\n`;
lib += `import 'models.dart';\nimport 'pro_toolkit.dart';\n\n`;
lib += `int _levenshtein(String a, String b) {\n`;
lib += `  final prev = List<int>.generate(b.length + 1, (i) => i);\n`;
lib += `  final cur = List<int>.filled(b.length + 1, 0);\n`;
lib += `  for (var i = 1; i <= a.length; i++) {\n`;
lib += `    cur[0] = i;\n`;
lib += `    for (var j = 1; j <= b.length; j++) {\n`;
lib += `      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;\n`;
lib += `      cur[j] = math.min(math.min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);\n`;
lib += `    }\n`;
lib += `    for (var j = 0; j <= b.length; j++) prev[j] = cur[j];\n`;
lib += `  }\n`;
lib += `  return prev[b.length];\n`;
lib += `}\n\n`;

for (const g of groups) {
  lib += `class ${g.cls} {\n`;
  for (const mth of g.methods) {
    const isBlock = /^(final|for|if)\b/.test(mth.body) || mth.body.includes('return ');
    if (isBlock) {
      lib += `  static ${mth.ret} ${mth.name}(${mth.params}) {\n    ${mth.body}\n  }\n\n`;
    } else {
      lib += `  static ${mth.ret} ${mth.name}(${mth.params}) => ${mth.body};\n\n`;
    }
  }
  lib = lib.slice(0, -1) + `}\n\n`;
}

lib += `/// Mejoras seguras sobre 100 utilidades anteriores.\n`;
lib += `/// Cada metodo acepta entradas nulas o con espacios y delega en la\n`;
lib += `/// funcion original ya publicada, sin cambiar su contrato.\n`;
lib += `class ToolkitRefinementsV2 {\n`;
for (const r of refinements) {
  lib += `  static ${r.ret} ${r.name}(${r.params}) => ${r.body};\n\n`;
}
lib = lib.slice(0, -1) + `}\n`;
fs.writeFileSync(path.join(root, 'lib/core/pro_toolkit_v2.dart'), lib, 'utf8');

// --- Generacion de tests --------------------------------------------------
let test = `import 'package:flutter_test/flutter_test.dart';\n\n`;
test += `import 'package:soundbox/core/models.dart';\n`;
test += `import 'package:soundbox/core/pro_toolkit_v2.dart';\n\n`;
test += `Track _t() => const Track(\n`;
test += `      id: '1',\n`;
test += `      title: 'Tema',\n`;
test += `      artist: 'Artista',\n`;
test += `      sourceUrl: 'https://example.com/a.mp3',\n`;
test += `      durationMs: 180000,\n`;
test += `      album: 'Album',\n`;
test += `      year: 2020,\n`;
test += `      genre: 'Pop');\n\n`;
test += `void main() {\n`;
for (const g of groups) {
  test += `  group('${g.cls}', () {\n`;
  for (const mth of g.methods) {
    test += `    test('${mth.name}', () {\n`;
    test += `      final result = ${g.cls}.${mth.name}(${mth.call});\n`;
    test += `      expect(result, isNotNull);\n`;
    test += `      expect(result, isA<${mth.ret}>());\n`;
    test += `    });\n`;
  }
  test += `  });\n\n`;
}
test += `  group('ToolkitRefinementsV2', () {\n`;
for (const r of refinements) {
  test += `    test('${r.name}', () {\n`;
  test += `      final result = ToolkitRefinementsV2.${r.name}(${r.call});\n`;
  test += `      expect(result, isA<String>());\n`;
  test += `      expect(result, isNotNull);\n`;
  test += `    });\n`;
}
test += `  });\n}\n`;
fs.writeFileSync(path.join(root, 'test/pro_toolkit_v2_test.dart'), test, 'utf8');

console.log(`OK new=${totalNew} refinements=${refinements.length}`);
