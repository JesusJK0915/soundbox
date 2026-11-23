// Utilidades puras anadidas en la version estable 1.2.0.
// Generadas de forma determinista; no dependen de Flutter ni de servicios.
import 'dart:convert';
import 'dart:math' as math;

import 'models.dart';
import 'pro_toolkit.dart';

int _levenshtein(String a, String b) {
  final prev = List<int>.generate(b.length + 1, (i) => i);
  final cur = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    cur[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      cur[j] = math.min(math.min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
    }
    for (var j = 0; j <= b.length; j++) prev[j] = cur[j];
  }
  return prev[b.length];
}

class LibraryToolsV2 {
  static String cleanTitle(String value) => value.trim();

  static String cleanArtist(String value) => value.trim();

  static String cleanAlbum(String? value) => (value ?? '').trim();

  static String titleWithoutFeat(String value) => value.replaceAll(RegExp(r'\s*feat\..*$', caseSensitive: false), '').trim();

  static int artistCount(String value) => LibraryToolsPro.splitArtists(value).length;

  static bool hasCollab(String value) => LibraryToolsPro.splitArtists(value).length > 1;

  static bool isExplicit(String value) => value.toLowerCase().contains('explicit');

  static bool isAcoustic(String value) => value.toLowerCase().contains('acoustic');

  static bool isRemastered(String value) => value.toLowerCase().contains('remaster');

  static bool isDeluxe(String value) => value.toLowerCase().contains('deluxe');

  static int safeYearV2(int? year) => year ?? 0;

  static int safeDurationMsV2(int? ms) => ms ?? 0;

  static String durationBucket(Duration value) => value.inMinutes < 3 ? 'Corta' : value.inMinutes < 6 ? 'Media' : 'Larga';

  static bool isLongTrackV2(Duration value) => value.inMinutes >= 10;

  static bool isShortTrackV2(Duration value) => value.inMinutes <= 2;

  static int secondsTotalV2(List<Track> tracks) => tracks.fold<int>(0, (sum, t) => sum + (t.durationMs ?? 0) ~/ 1000);

  static int missingTitleCount(List<Track> tracks) => tracks.where((t) => t.title.trim().isEmpty).length;

  static int missingArtistCount(List<Track> tracks) => tracks.where((t) => t.artist.trim().isEmpty).length;

  static int tracksWithYear(List<Track> tracks) => tracks.where((t) => t.year != null).length;

  static double libraryCompletenessV2(List<Track> tracks) => tracks.isEmpty ? 0.0 : tracks.where((t) => t.title.isNotEmpty && t.artist.isNotEmpty && t.album != null).length / tracks.length;
}

class PlaybackToolsV2 {
  static double clampVolume(double value) => value < 0 ? 0.0 : value > 1 ? 1.0 : value;

  static double clampSpeed(double value) => value < 0.5 ? 0.5 : value > 2.0 ? 2.0 : value;

  static int repeatModeIndex(String mode) => mode == 'one' ? 2 : mode == 'all' ? 1 : 0;

  static String repeatModeName(int index) => index == 2 ? 'one' : index == 1 ? 'all' : 'off';

  static String nextRepeatMode(String mode) => mode == 'off' ? 'all' : mode == 'all' ? 'one' : 'off';

  static bool isRepeatOne(String mode) => mode == 'one';

  static bool isRepeatAll(String mode) => mode == 'all';

  static bool isRepeatOff(String mode) => mode == 'off';

  static int seekForwardMs(int current, int delta, int max) => current + delta > max ? max : current + delta;

  static int seekBackwardMs(int current, int delta) => current - delta < 0 ? 0 : current - delta;

  static double progressRatio(int current, int max) => max <= 0 ? 0.0 : (current / max).clamp(0.0, 1.0);

  static int playedMs(int current, int max) => current.clamp(0, max < 0 ? 0 : max);

  static int remainingMs(int current, int max) => max <= current ? 0 : max - current;

  static bool isFinishedV2(Duration position, Duration duration) => duration <= Duration.zero || position >= duration;

  static bool isBeginningV2(Duration position) => position <= Duration.zero;

  static int wrapIndexV2(int index, int length) => length <= 0 ? 0 : index % length;

  static double volumeAfterStep(double value, double step) => clampVolume(value + step);

  static double speedAfterStep(double value, double step) => clampSpeed(value + step);

  static double crossfadeFractionV2(Duration position, Duration fade) => fade <= Duration.zero ? 0.0 : (position.inMilliseconds / fade.inMilliseconds).clamp(0.0, 1.0);

  static String playbackStateLabel(bool playing, bool buffering) => buffering ? 'Cargando' : playing ? 'Reproduciendo' : 'Pausado';
}

class SearchToolsV2 {
  static String compactWhitespaceV2(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String removePunctuationV2(String value) => value.replaceAll(RegExp(r'[^\w\s]'), '');

  static List<String> tokenListV2(String value) => compactWhitespaceV2(value).split(' ').where((s) => s.isNotEmpty).toList();

  static List<String> uniqueTokensV2(String value) => tokenListV2(value).toSet().toList();

  static int tokenCountV2(String value) => tokenListV2(value).length;

  static bool isWildcardV2(String value) => value.contains('*') || value.contains('?');

  static String stripWildcardsV2(String value) => value.replaceAll(RegExp(r'[*?]'), '');

  static bool isQuotedV2(String value) => value.length >= 2 && value.startsWith('"') && value.endsWith('"');

  static String unquoteV2(String value) => isQuotedV2(value) ? value.substring(1, value.length - 1) : value;

  static bool exactMatchV2(String query, String candidate) => LibraryToolsPro.normalizeText(query) == LibraryToolsPro.normalizeText(candidate);

  static bool prefixMatchV2(String query, String candidate) => LibraryToolsPro.normalizeText(candidate).startsWith(LibraryToolsPro.normalizeText(query));

  static bool containsMatchV2(String query, String candidate) => LibraryToolsPro.normalizeText(candidate).contains(LibraryToolsPro.normalizeText(query));

  static int tokenOverlapV2(String query, String candidate) => tokenListV2(query).toSet().intersection(tokenListV2(candidate).toSet()).length;

  static double jaccardV2(String query, String candidate) {
    final a = tokenListV2(query).toSet(); final b = tokenListV2(candidate).toSet(); final u = a.union(b); return u.isEmpty ? 0.0 : a.intersection(b).length / u.length;
  }

  static int levenshteinV2(String a, String b) => _levenshtein(a, b);

  static int bestFuzzyIndexV2(String query, List<String> options) {
    if (options.isEmpty) return -1; var best = 0; var score = _levenshtein(query, options.first); for (var i = 1; i < options.length; i++) { final s = _levenshtein(query, options[i]); if (s < score) { score = s; best = i; } } return best;
  }

  static String searchHintV2(String query) => query.trim().isEmpty ? 'Escribe para buscar' : 'Resultados para ' + query;

  static String resultLabelV2(int count) => count == 1 ? '1 resultado' : '${count} resultados';

  static bool isStopWordV2(String token) => const {'de', 'la', 'el', 'los', 'las', 'y', 'o'}.contains(token.toLowerCase());

  static List<String> removeStopWordsV2(String value) => tokenListV2(value).where((t) => !isStopWordV2(t)).toList();
}

class DownloadToolsV2 {
  static String normalizeFormatV2(String format) => format.replaceAll('.', '').toLowerCase();

  static String extensionForFormatV2(String format) => '.' + normalizeFormatV2(format);

  static bool isAudioExtensionV2(String ext) => const {'mp3', 'm4a', 'aac', 'flac', 'ogg', 'wav'}.contains(normalizeFormatV2(ext));

  static bool isVideoExtensionV2(String ext) => const {'mp4', 'mkv', 'webm'}.contains(normalizeFormatV2(ext));

  static String urlHostV2(String url) => Uri.tryParse(url)?.host ?? '';

  static String urlPathV2(String url) => Uri.tryParse(url)?.path ?? '';

  static bool isHttpsV2(String url) => url.toLowerCase().startsWith('https://');

  static bool isHttpV2(String url) => url.toLowerCase().startsWith('http://');

  static String safeFileNameV2(String value) => value.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();

  static String fileNameWithoutExtV2(String name) => name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;

  static String fileExtV2(String name) => name.contains('.') ? name.substring(name.lastIndexOf('.') + 1) : '';

  static String estimateSizeLabelV2(int bytes) => bytes >= 1000000 ? '${(bytes / 1000000).toStringAsFixed(1)} MB' : '${(bytes / 1000).toStringAsFixed(0)} KB';

  static int bitrateToKbpsV2(int bps) => bps ~/ 1000;

  static int kbpsToBpsV2(int kbps) => kbps * 1000;

  static String retryAttemptLabelV2(int attempt) => 'Intento ${attempt}';

  static bool isRetryableV2(int status) => status == 408 || status == 429 || status >= 500;

  static String mimeForExtV2(String ext) => switch (normalizeFormatV2(ext)) { 'mp3' => 'audio/mpeg', 'm4a' => 'audio/mp4', 'flac' => 'audio/flac', 'ogg' => 'audio/ogg', 'wav' => 'audio/wav', _ => 'application/octet-stream' };

  static String qualityFromBitrateV2(int bps) => bps >= 256000 ? 'Alta' : bps >= 128000 ? 'Media' : 'Baja';

  static double downloadProgressV2(int done, int total) => total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

  static String etaLabelV2(int seconds) => seconds <= 0 ? 'Listo' : '${seconds} s';
}

class PlaylistToolsV2 {
  static String m3uHeaderV2() => '#EXTM3U';

  static bool isM3uHeaderV2(String line) => line.trim() == '#EXTM3U';

  static bool isExtinfV2(String line) => line.trim().startsWith('#EXTINF:');

  static int parseExtinfSecondsV2(String line) {
    final m = RegExp(r'#EXTINF:(\d+)').firstMatch(line); return m == null ? 0 : int.tryParse(m.group(1) ?? '') ?? 0;
  }

  static String parseExtinfTitleV2(String line) {
    final i = line.indexOf(','); return i < 0 ? '' : line.substring(i + 1).trim();
  }

  static String playlistSlugV2(String name) => LibraryToolsPro.normalizeText(name).replaceAll(RegExp(r'\s+'), '-');

  static String playlistFileNameV2(String name) => playlistSlugV2(name) + '.m3u';

  static int playlistSizeV2(List<Track> tracks) => tracks.length;

  static int playlistDurationSecondsV2(List<Track> tracks) => tracks.fold<int>(0, (s, t) => s + (t.durationMs ?? 0) ~/ 1000);

  static String playlistDurationLabelV2(List<Track> tracks) => Duration(seconds: playlistDurationSecondsV2(tracks)).toString();

  static List<Track> mergeTracksV2(List<Track> a, List<Track> b) => [...a, ...b];

  static List<Track> uniqueTracksV2(List<Track> tracks) {
    tracks.fold<List<Track>>(<Track>[], (list, t) { if (!list.any((x) => x.id == t.id)) list.add(t); return list; })
  }

  static List<Track> tracksByGenreV2(List<Track> tracks, String genre) => tracks.where((t) => LibraryToolsPro.normalizeText(t.genre ?? '') == LibraryToolsPro.normalizeText(genre)).toList();

  static List<Track> tracksByYearV2(List<Track> tracks, int year) => tracks.where((t) => t.year == year).toList();

  static List<Track> tracksByArtistV2(List<Track> tracks, String artist) => tracks.where((t) => LibraryToolsPro.artistKey(t.artist) == LibraryToolsPro.artistKey(artist)).toList();

  static List<Track> shuffleTracksV2(List<Track> tracks, int seed) => PlaybackToolsPro.shuffledIndices(tracks.length, seed).map((i) => tracks[i]).toList();

  static String firstTitleV2(List<Track> tracks) => tracks.isEmpty ? '' : tracks.first.title;

  static String lastTitleV2(List<Track> tracks) => tracks.isEmpty ? '' : tracks.last.title;

  static String playlistChecksumV2(List<Track> tracks) => tracks.map((t) => t.id).join('|');

  static double playlistHealthV2(List<Track> tracks) => tracks.isEmpty ? 0.0 : tracks.where((t) => t.title.isNotEmpty && t.artist.isNotEmpty).length / tracks.length;
}

class LyricsToolsV2 {
  static String lrcTimeLabelV2(Duration d) => '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  static bool isLrcTimestampV2(String line) => RegExp(r'^\[\d{1,2}:\d{2}(?:\.\d+)?\]').hasMatch(line.trim());

  static bool isLrcMetadataV2(String line) => RegExp(r'^\[[a-zA-Z]+:').hasMatch(line.trim());

  static int lrcTimestampMillisV2(String line) {
    final m = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d+))?\]').firstMatch(line); if (m == null) return 0; final min = int.tryParse(m.group(1) ?? '') ?? 0; final sec = int.tryParse(m.group(2) ?? '') ?? 0; final frac = m.group(3) ?? ''; final ms = (frac + '000').substring(0, 3); return min * 60000 + sec * 1000 + (int.tryParse(ms) ?? 0);
  }

  static String lrcTextV2(String line) => line.replaceAll(RegExp(r'^\[[^\]]+\]'), '').trim();

  static String stripLrcTagsV2(String lyrics) => lyrics.replaceAll(RegExp(r'\[[^\]]+\]'), '').trim();

  static int lyricsLineCountV2(String lyrics) => stripLrcTagsV2(lyrics).split('\n').where((l) => l.trim().isNotEmpty).length;

  static bool isLyricsEmptyV2(String lyrics) => stripLrcTagsV2(lyrics).isEmpty;

  static bool isInstrumentalV2(String lyrics) => stripLrcTagsV2(lyrics).toLowerCase().contains('instrumental');

  static int lyricsWordCountV2(String lyrics) => stripLrcTagsV2(lyrics).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  static int activeLineIndexV2(List<Duration> times, Duration position) {
    for (var i = times.length - 1; i >= 0; i--) { if (position >= times[i]) return i; } return -1;
  }

  static int nextLineIndexV2(List<Duration> times, Duration position) {
    for (var i = 0; i < times.length; i++) { if (times[i] > position) return i; } return -1;
  }

  static String lyricAtV2(List<String> lines, int index) => index < 0 || index >= lines.length ? '' : lines[index];

  static int safeLyricIndexV2(List<String> lines, int index) => index < 0 ? 0 : index >= lines.length ? lines.length - 1 : index;

  static double karaokePercentV2(Duration start, Duration end, Duration position) => end <= start ? 0.0 : (position - start).inMilliseconds / (end - start).inMilliseconds;

  static String syncOffsetLabelV2(int ms) => ms > 0 ? '+' + ms.toString() + ' ms' : ms.toString() + ' ms';

  static Duration applyOffsetV2(Duration time, int ms) => Duration(milliseconds: time.inMilliseconds + ms);

  static bool hasTranslationV2(String lyrics) => lyrics.toLowerCase().contains('translation');

  static String firstLyricV2(String lyrics) {
    final lines = stripLrcTagsV2(lyrics).split('\n').where((l) => l.trim().isNotEmpty).toList(); return lines.isEmpty ? '' : lines.first;
  }

  static String lastLyricV2(String lyrics) {
    final lines = stripLrcTagsV2(lyrics).split('\n').where((l) => l.trim().isNotEmpty).toList(); return lines.isEmpty ? '' : lines.last;
  }
}

class SettingsToolsV2 {
  static String gestureLabelV2(bool enabled) => enabled ? 'Gestos activos' : 'Gestos desactivados';

  static String hapticLabelV2(bool enabled) => enabled ? 'Háptico activo' : 'Háptico desactivado';

  static String wormLabelV2(bool enabled) => enabled ? 'Onda visible' : 'Onda oculta';

  static String themeLabelV2(String theme) => theme == 'dark' ? 'Oscuro' : 'Claro';

  static bool isDarkThemeV2(String theme) => theme == 'dark';

  static String toggleThemeV2(String theme) => theme == 'dark' ? 'light' : 'dark';

  static String qualityLabelV2(int kbps) => kbps >= 256 ? 'Alta' : kbps >= 128 ? 'Media' : 'Baja';

  static String crossfadeLabelV2(double seconds) => seconds.toStringAsFixed(1) + ' s';

  static String sleepLabelV2(int minutes) => minutes <= 0 ? 'Desactivado' : minutes.toString() + ' min';

  static String volumeLabelV2(int percent) => percent.toString() + ' %';

  static int clampBrightnessV2(int value) => value < 0 ? 0 : value > 100 ? 100 : value;

  static String safeLocaleV2(String locale) => locale.isEmpty ? 'es' : locale;

  static String languageLabelV2(String code) => code.startsWith('es') ? 'Español' : code.startsWith('en') ? 'English' : code;

  static String accessibilitySummaryV2(bool gestures, bool haptics) => gestures && haptics ? 'Completa' : gestures || haptics ? 'Parcial' : 'Mínima';

  static String preferenceKeyV2(String name) => 'sb_' + LibraryToolsPro.normalizeText(name).replaceAll(RegExp(r'\s+'), '_');

  static String preferenceValueLabelV2(String name, bool value) => name + (value ? ': sí' : ': no');

  static String storageLabelV2(int bytes) => bytes >= 1000000 ? (bytes / 1000000).toStringAsFixed(1) + ' MB' : (bytes / 1000).toStringAsFixed(0) + ' KB';

  static String cacheLabelV2(int files) => files.toString() + ' archivos';

  static String networkLabelV2(bool online) => online ? 'En línea' : 'Sin conexión';

  static String updateChannelLabelV2(String channel) => channel == 'stable' ? 'Estable' : channel == 'beta' ? 'Beta' : 'Alpha';
}

class StatsToolsV2 {
  static int listeningMinutesV2(int ms) => ms ~/ 60000;

  static String listeningHoursV2(int ms) => (ms / 3600000).toStringAsFixed(1);

  static int dailyAverageV2(int totalMs, int days) => days <= 0 ? 0 : totalMs ~/ days;

  static String streakLabelV2(int days) => days == 1 ? '1 día' : days.toString() + ' días';

  static String topArtistV2(List<Track> tracks) {
    final counts = <String, int>{}; for (final t in tracks) { final k = LibraryToolsPro.artistKey(t.artist); counts[k] = (counts[k] ?? 0) + 1; } if (counts.isEmpty) return ''; return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static String topGenreV2(List<Track> tracks) {
    final counts = <String, int>{}; for (final t in tracks) { final k = LibraryToolsPro.normalizeText(t.genre ?? ''); if (k.isEmpty) continue; counts[k] = (counts[k] ?? 0) + 1; } if (counts.isEmpty) return ''; return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static int uniqueArtistsV2(List<Track> tracks) => tracks.map((t) => LibraryToolsPro.artistKey(t.artist)).toSet().length;

  static int uniqueGenresV2(List<Track> tracks) => tracks.map((t) => LibraryToolsPro.normalizeText(t.genre ?? '')).toSet().where((g) => g.isNotEmpty).length;

  static double completionRateV2(int played, int total) => total <= 0 ? 0.0 : (played / total).clamp(0.0, 1.0);

  static double skipRateV2(int skips, int plays) => plays <= 0 ? 0.0 : (skips / plays).clamp(0.0, 1.0);

  static double favoriteRatioV2(int favorites, int total) => total <= 0 ? 0.0 : (favorites / total).clamp(0.0, 1.0);

  static String hourBucketV2(DateTime time) => time.hour < 12 ? 'Mañana' : time.hour < 19 ? 'Tarde' : 'Noche';

  static String weekdayLabelV2(int weekday) => const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][(weekday - 1).clamp(0, 6)];

  static String monthLabelV2(int month) => const ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'][(month - 1).clamp(0, 11)];

  static String yearLabelV2(int year) => year <= 0 ? 'Sin año' : year.toString();

  static int mostPlayedHourV2(List<int> hours) {
    final counts = <int, int>{}; for (final h in hours) { counts[h] = (counts[h] ?? 0) + 1; } if (counts.isEmpty) return 0; return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static double averageSessionMinutesV2(List<int> minutes) => minutes.isEmpty ? 0.0 : minutes.reduce((a, b) => a + b) / minutes.length;

  static int longestSessionV2(List<int> minutes) => minutes.isEmpty ? 0 : minutes.reduce(math.max);

  static String statsSummaryV2(int plays, int minutes) => plays.toString() + ' reproducciones · ' + minutes.toString() + ' min';

  static String activityLabelV2(int plays) => plays == 0 ? 'Sin actividad' : plays < 10 ? 'Baja' : plays < 50 ? 'Media' : 'Alta';
}

class MaintenanceToolsV2 {
  static int versionCodeFromV2(String version) => MaintenanceToolsPro.versionCodeFrom(version);

  static bool isValidVersionV2(String version) => RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version);

  static int segmentLimitV2(int segment) => segment > 9 ? 9 : segment < 0 ? 0 : segment;

  static int clampVersionPartV2(int part) => segmentLimitV2(part);

  static int buildNumberFromTagV2(String tag) => MaintenanceToolsPro.versionCodeFrom(tag.replaceAll('v', ''));

  static bool isStableTagV2(String tag) => RegExp(r'^v\d+\.\d+\.\d+$').hasMatch(tag);

  static bool isPrereleaseTagV2(String tag) => tag.contains('-alpha') || tag.contains('-beta') || tag.contains('-rc');

  static String normalizeTagV2(String tag) => tag.startsWith('v') ? tag : 'v' + tag;

  static String cacheKeyV2(String path) => path.hashCode.toString();

  static String safeJsonKeyV2(String key) => key.replaceAll(RegExp(r'\s+'), '_');

  static String truncateV2(String value, int max) => value.length <= max ? value : value.substring(0, max.clamp(0, value.length));

  static String ellipsizeV2(String value, int max) => value.length <= max ? value : value.substring(0, max.clamp(0, value.length)) + '…';

  static int countLinesV2(String value) => value.isEmpty ? 0 : value.split('\n').length;

  static int countWordsV2(String value) => value.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  static bool isBlankV2(String? value) => value == null || value.trim().isEmpty;

  static String coalesceV2(String? value, String fallback) => isBlankV2(value) ? fallback : value!;

  static String padNumberV2(int value, int length) => value.toString().padLeft(length, '0');

  static String bytesLabelV2(int bytes) => bytes >= 1048576 ? (bytes / 1048576).toStringAsFixed(1) + ' MiB' : (bytes / 1024).toStringAsFixed(0) + ' KiB';

  static String percentLabelV2(double value) => (value.clamp(0.0, 1.0) * 100).round().toString() + ' %';

  static String diagnosticSummaryV2(String version, int code) => version + ' (' + code.toString() + ')';
}

class ExportToolsV2 {
  static String csvEscapeV2(String value) => '"' + value.replaceAll('"', '""') + '"';

  static String csvHeaderV2() => 'id,title,artist,album,duration';

  static String csvRowV2(Track track) => [track.id, track.title, track.artist, track.album ?? '', (track.durationMs ?? 0).toString()].map(csvEscapeV2).join(',');

  static String jsonSafeV2(String value) => jsonEncode(value);

  static String playlistHeaderV2(String name) => '#EXTM3U\n#PLAYLIST:' + name;

  static String extinfLineV2(Track track) => '#EXTINF:' + ((track.durationMs ?? 0) ~/ 1000).toString() + ',' + track.artist + ' - ' + track.title;

  static String trackUriV2(Track track) => track.sourceUrl;

  static String exportNameV2(String name, String ext) => LibraryToolsPro.sanitizeFileName(name) + '.' + normalizeFormatV2(ext);

  static int exportSizeEstimateV2(List<Track> tracks) => 64 + tracks.length * 96;

  static String m3uBodyV2(List<Track> tracks) => tracks.map(extinfLineV2).join('\n');

  static String tagsToJsonV2(Map<String, String> tags) => jsonEncode(tags);

  static String decodeJsonV2(String raw) => jsonDecode(raw).toString();

  static String fileNameForTrackV2(Track track) => LibraryToolsPro.sanitizeFileName(track.title) + extensionForFormatV2(track.format ?? 'mp3');

  static String licenseLabelV2(String? license) => license == null || license.isEmpty ? 'Sin licencia' : license;

  static String providerLabelV2(Track track) => track.source ?? 'Desconocido';

  static String exportSummaryV2(List<Track> tracks) => tracks.length.toString() + ' pistas';

  static bool isExportableV2(Track track) => track.title.isNotEmpty && track.sourceUrl.isNotEmpty;

  static String exportChecksumV2(List<Track> tracks) => tracks.map((t) => t.id).join(',').hashCode.toString();

  static String mimeForExportV2(String ext) => ext == 'm3u' ? 'audio/x-mpegurl' : 'application/json';

  static String exportVersionTagV2(String version) => 'SoundBox-' + version;
}

/// Mejoras seguras sobre 100 utilidades anteriores.
/// Cada metodo acepta entradas nulas o con espacios y delega en la
/// funcion original ya publicada, sin cambiar su contrato.
class ToolkitRefinementsV2 {
  static String safeNormalizeText(Object? value) => LibraryToolsPro.normalizeText(value?.toString().trim() ?? '');

  static String compactNormalizeText(Object? value) => LibraryToolsPro.normalizeText((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeTitleKey(Object? value) => LibraryToolsPro.titleKey(value?.toString().trim() ?? '');

  static String compactTitleKey(Object? value) => LibraryToolsPro.titleKey((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeArtistKey(Object? value) => LibraryToolsPro.artistKey(value?.toString().trim() ?? '');

  static String compactArtistKey(Object? value) => LibraryToolsPro.artistKey((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeSanitizeFileName(Object? value) => LibraryToolsPro.sanitizeFileName(value?.toString().trim() ?? '');

  static String compactSanitizeFileName(Object? value) => LibraryToolsPro.sanitizeFileName((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeRepeatLabel(Object? value) => PlaybackToolsPro.repeatLabel(value?.toString().trim() ?? '');

  static String compactRepeatLabel(Object? value) => PlaybackToolsPro.repeatLabel((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeExtensionForFormat(Object? value) => DownloadToolsPro.extensionForFormat(value?.toString().trim() ?? '');

  static String compactExtensionForFormat(Object? value) => DownloadToolsPro.extensionForFormat((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeFormatFromUrl(Object? value) => DownloadToolsPro.formatFromUrl(value?.toString().trim() ?? '');

  static String compactFormatFromUrl(Object? value) => DownloadToolsPro.formatFromUrl((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeSafeDownloadName(Object? value) => DownloadToolsPro.safeDownloadName(value?.toString().trim() ?? '');

  static String compactSafeDownloadName(Object? value) => DownloadToolsPro.safeDownloadName((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeMimeForExtension(Object? value) => DownloadToolsPro.mimeForExtension(value?.toString().trim() ?? '');

  static String compactMimeForExtension(Object? value) => DownloadToolsPro.mimeForExtension((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeCleanUrl(Object? value) => DownloadToolsPro.cleanUrl(value?.toString().trim() ?? '');

  static String compactCleanUrl(Object? value) => DownloadToolsPro.cleanUrl((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeProviderLabel(Object? value) => DownloadToolsPro.providerLabel(value?.toString().trim() ?? '');

  static String compactProviderLabel(Object? value) => DownloadToolsPro.providerLabel((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeFormatLabel(Object? value) => DownloadToolsPro.formatLabel(value?.toString().trim() ?? '');

  static String compactFormatLabel(Object? value) => DownloadToolsPro.formatLabel((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeJsonEscape(Object? value) => PlaylistToolsPro.jsonEscape(value?.toString().trim() ?? '');

  static String compactJsonEscape(Object? value) => PlaylistToolsPro.jsonEscape((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeStripLrcMeta(Object? value) => LyricsToolsPro.stripLrcMeta(value?.toString().trim() ?? '');

  static String compactStripLrcMeta(Object? value) => LyricsToolsPro.stripLrcMeta((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safePlainLyrics(Object? value) => LyricsToolsPro.plainLyrics(value?.toString().trim() ?? '');

  static String compactPlainLyrics(Object? value) => LyricsToolsPro.plainLyrics((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeThemeModeLabel(Object? value) => SettingsToolsPro.themeModeLabel(value?.toString().trim() ?? '');

  static String compactThemeModeLabel(Object? value) => SettingsToolsPro.themeModeLabel((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeSortLabel(Object? value) => SettingsToolsPro.sortLabel(value?.toString().trim() ?? '');

  static String compactSortLabel(Object? value) => SettingsToolsPro.sortLabel((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeBackupKey(Object? value) => SettingsToolsPro.backupKey(value?.toString().trim() ?? '');

  static String compactBackupKey(Object? value) => SettingsToolsPro.backupKey((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeChannelLabel(Object? value) => SettingsToolsPro.channelLabel(value?.toString().trim() ?? '');

  static String compactChannelLabel(Object? value) => SettingsToolsPro.channelLabel((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeLogFingerprint(Object? value) => MaintenanceToolsPro.logFingerprint(value?.toString().trim() ?? '');

  static String compactLogFingerprint(Object? value) => MaintenanceToolsPro.logFingerprint((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeRepeatCycle(Object? value) => PlaybackInsightsPro.repeatCycle(value?.toString().trim() ?? '');

  static String compactRepeatCycle(Object? value) => PlaybackInsightsPro.repeatCycle((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeNormalizeQuery(Object? value) => SearchInsightsPro.normalizeQuery(value?.toString().trim() ?? '');

  static String compactNormalizeQuery(Object? value) => SearchInsightsPro.normalizeQuery((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeStripQuotes(Object? value) => SearchInsightsPro.stripQuotes(value?.toString().trim() ?? '');

  static String compactStripQuotes(Object? value) => SearchInsightsPro.stripQuotes((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeExpandWildcard(Object? value) => SearchInsightsPro.expandWildcard(value?.toString().trim() ?? '');

  static String compactExpandWildcard(Object? value) => SearchInsightsPro.expandWildcard((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeSearchHint(Object? value) => SearchInsightsPro.searchHint(value?.toString().trim() ?? '');

  static String compactSearchHint(Object? value) => SearchInsightsPro.searchHint((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeNoResultsMessage(Object? value) => SearchInsightsPro.noResultsMessage(value?.toString().trim() ?? '');

  static String compactNoResultsMessage(Object? value) => SearchInsightsPro.noResultsMessage((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeSafeFormat(Object? value) => DownloadInsightsPro.safeFormat(value?.toString().trim() ?? '');

  static String compactSafeFormat(Object? value) => DownloadInsightsPro.safeFormat((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeProviderKey(Object? value) => DownloadInsightsPro.providerKey(value?.toString().trim() ?? '');

  static String compactProviderKey(Object? value) => DownloadInsightsPro.providerKey((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeHostFromUrl(Object? value) => DownloadInsightsPro.hostFromUrl(value?.toString().trim() ?? '');

  static String compactHostFromUrl(Object? value) => DownloadInsightsPro.hostFromUrl((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeUrlWithoutQuery(Object? value) => DownloadInsightsPro.urlWithoutQuery(value?.toString().trim() ?? '');

  static String compactUrlWithoutQuery(Object? value) => DownloadInsightsPro.urlWithoutQuery((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeUrlScheme(Object? value) => DownloadInsightsPro.urlScheme(value?.toString().trim() ?? '');

  static String compactUrlScheme(Object? value) => DownloadInsightsPro.urlScheme((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeFileNameFromUrl(Object? value) => DownloadInsightsPro.fileNameFromUrl(value?.toString().trim() ?? '');

  static String compactFileNameFromUrl(Object? value) => DownloadInsightsPro.fileNameFromUrl((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeFileExtensionFromName(Object? value) => DownloadInsightsPro.fileExtensionFromName(value?.toString().trim() ?? '');

  static String compactFileExtensionFromName(Object? value) => DownloadInsightsPro.fileExtensionFromName((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safePlaylistSlug(Object? value) => PlaylistInsightsPro.playlistSlug(value?.toString().trim() ?? '');

  static String compactPlaylistSlug(Object? value) => PlaylistInsightsPro.playlistSlug((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeLyricsDurationLabel(Object? value) => LyricsInsightsPro.lyricsDurationLabel(value?.toString().trim() ?? '');

  static String compactLyricsDurationLabel(Object? value) => LyricsInsightsPro.lyricsDurationLabel((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeTrimLrcLine(Object? value) => LyricsInsightsPro.trimLrcLine(value?.toString().trim() ?? '');

  static String compactTrimLrcLine(Object? value) => LyricsInsightsPro.trimLrcLine((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeStripMetadataTags(Object? value) => LyricsInsightsPro.stripMetadataTags(value?.toString().trim() ?? '');

  static String compactStripMetadataTags(Object? value) => LyricsInsightsPro.stripMetadataTags((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeThemeLabelShort(Object? value) => SettingsInsightsPro.themeLabelShort(value?.toString().trim() ?? '');

  static String compactThemeLabelShort(Object? value) => SettingsInsightsPro.themeLabelShort((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeSortModeLabel(Object? value) => SettingsInsightsPro.sortModeLabel(value?.toString().trim() ?? '');

  static String compactSortModeLabel(Object? value) => SettingsInsightsPro.sortModeLabel((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeLanguageLabel(Object? value) => SettingsInsightsPro.languageLabel(value?.toString().trim() ?? '');

  static String compactLanguageLabel(Object? value) => SettingsInsightsPro.languageLabel((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeSettingsSearchTerm(Object? value) => SettingsInsightsPro.settingsSearchTerm(value?.toString().trim() ?? '');

  static String compactSettingsSearchTerm(Object? value) => SettingsInsightsPro.settingsSearchTerm((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeMoodFromGenre(Object? value) => StatsInsightsPro.moodFromGenre(value?.toString().trim() ?? '');

  static String compactMoodFromGenre(Object? value) => StatsInsightsPro.moodFromGenre((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeMoodLabel(Object? value) => StatsInsightsPro.moodLabel(value?.toString().trim() ?? '');

  static String compactMoodLabel(Object? value) => StatsInsightsPro.moodLabel((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeBackupName(Object? value) => MaintenanceInsightsPro.backupName(value?.toString().trim() ?? '');

  static String compactBackupName(Object? value) => MaintenanceInsightsPro.backupName((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeCrashMarker(Object? value) => MaintenanceInsightsPro.crashMarker(value?.toString().trim() ?? '');

  static String compactCrashMarker(Object? value) => MaintenanceInsightsPro.crashMarker((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeM3uComment(Object? value) => SharingInsightsPro.m3uComment(value?.toString().trim() ?? '');

  static String compactM3uComment(Object? value) => SharingInsightsPro.m3uComment((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeM3uTitle(Object? value) => SharingInsightsPro.m3uTitle(value?.toString().trim() ?? '');

  static String compactM3uTitle(Object? value) => SharingInsightsPro.m3uTitle((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeCsvEscape(Object? value) => SharingInsightsPro.csvEscape(value?.toString().trim() ?? '');

  static String compactCsvEscape(Object? value) => SharingInsightsPro.csvEscape((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safeFileUri(Object? value) => SharingInsightsPro.fileUri(value?.toString().trim() ?? '');

  static String compactFileUri(Object? value) => SharingInsightsPro.fileUri((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());

  static String safePlaylistExportName(Object? value) => SharingInsightsPro.playlistExportName(value?.toString().trim() ?? '');

  static String compactPlaylistExportName(Object? value) => SharingInsightsPro.playlistExportName((value?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim());
}
