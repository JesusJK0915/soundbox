import 'dart:convert';
import 'dart:math' as math;

import 'models.dart';

/// Utilidades puras añadidas en la version estable 1.0.3.
///
/// Estan agrupadas por area para que puedan usarse desde la biblioteca, el
/// reproductor, las descargas, las letras, los ajustes y el mantenimiento sin
/// depender de Flutter ni de servicios externos.
class LibraryToolsPro {
  static String normalizeText(String value) {
    final withoutDiacritics = value
        .replaceAll(RegExp(r'[áàäâãÁÀÄÂÃ]'), 'a')
        .replaceAll(RegExp(r'[éèëêÉÈËÊ]'), 'e')
        .replaceAll(RegExp(r'[íìïîÍÌÏÎ]'), 'i')
        .replaceAll(RegExp(r'[óòöôõÓÒÖÔÕ]'), 'o')
        .replaceAll(RegExp(r'[úùüûÚÙÜÛ]'), 'u');
    return withoutDiacritics.toLowerCase().trim();
  }

  static String titleKey(String title) => normalizeText(title)
      .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String artistKey(String artist) => normalizeText(artist)
      .replaceAll(RegExp(r'feat\.?|ft\.?|&'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static List<String> splitArtists(String artist) => artist
      .split(RegExp(r',|;| feat\.? | ft\.? | & '))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  static bool isLive(String title) =>
      normalizeText(title).contains(RegExp(r'\blive\b|en vivo'));

  static bool isRemix(String title) =>
      normalizeText(title).contains(RegExp(r'\bremix\b|\bmix\b|\bedit\b'));

  static bool isInstrumental(String title) =>
      normalizeText(title).contains(RegExp(r'instrumental|karaoke|backing'));

  static bool isCover(String title) =>
      normalizeText(title).contains(RegExp(r'\bcover\b|version acustica'));

  static String durationLabel(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  static String fileSizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  static String bitrateLabel(int? bps) => bps == null || bps <= 0
      ? 'bitrate desconocido'
      : '${(bps / 1000).round()} kbps';

  static String sanitizeFileName(String value) {
    final withoutDiacritics = value
        .replaceAll(RegExp(r'[áàäâã]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöôõ]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ÁÀÄÂÃ]'), 'A')
        .replaceAll(RegExp(r'[ÉÈËÊ]'), 'E')
        .replaceAll(RegExp(r'[ÍÌÏÎ]'), 'I')
        .replaceAll(RegExp(r'[ÓÒÖÔÕ]'), 'O')
        .replaceAll(RegExp(r'[ÚÙÜÛ]'), 'U');
    return withoutDiacritics
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'_+\.'), '.')
        .replaceAll(RegExp(r'^[\s._-]+|[\s._-]+$'), '')
        .trim();
  }

  static List<String> searchTokens(String value) => normalizeText(value)
      .split(RegExp(r'\W+'))
      .where((token) => token.length > 1)
      .toList();

  static int searchScore(String query, String candidate) {
    final q = normalizeText(query);
    final c = normalizeText(candidate);
    if (q.isEmpty) return 0;
    if (c == q) return 100;
    if (c.startsWith(q)) return 80;
    if (c.contains(q)) return 60;
    var score = 0;
    for (final token in searchTokens(q)) {
      if (c.contains(token)) score += 10;
    }
    return score;
  }

  static Map<String, List<Track>> groupByAlbum(List<Track> tracks) {
    final result = <String, List<Track>>{};
    for (final track in tracks) {
      result.putIfAbsent(track.album ?? 'Sin album', () => []).add(track);
    }
    return result;
  }

  static Map<String, List<Track>> groupByArtist(List<Track> tracks) {
    final result = <String, List<Track>>{};
    for (final track in tracks) {
      result.putIfAbsent(track.artist, () => []).add(track);
    }
    return result;
  }

  static List<String> missingFields(Track track) {
    final missing = <String>[];
    if (track.title.trim().isEmpty) missing.add('titulo');
    if (track.artist.trim().isEmpty) missing.add('artista');
    if (track.year == null) missing.add('ano');
    if (track.genre == null || track.genre!.isEmpty) missing.add('genero');
    if (track.bitrateBps == null) missing.add('bitrate');
    return missing;
  }

  static Map<String, List<Track>> duplicateGroups(List<Track> tracks) {
    final groups = <String, List<Track>>{};
    for (final track in tracks) {
      final key = '${titleKey(track.title)}|'
          '${artistKey(track.artist)}|${track.durationMs ?? 0}';
      groups.putIfAbsent(key, () => []).add(track);
    }
    return groups..removeWhere((_, value) => value.length < 2);
  }

  static List<String> topGenres(List<Track> tracks, [int limit = 5]) {
    final counts = <String, int>{};
    for (final track in tracks) {
      final genre = track.genre?.trim();
      if (genre == null || genre.isEmpty) continue;
      counts[genre] = (counts[genre] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((entry) => entry.key).toList();
  }

  static double libraryHealth(List<Track> tracks) {
    if (tracks.isEmpty) return 0;
    var complete = 0;
    for (final track in tracks) {
      if (missingFields(track).length <= 2) complete++;
    }
    return (complete * 100 / tracks.length).roundToDouble();
  }
}

class PlaybackToolsPro {
  static Duration clampDuration(Duration value, Duration min, Duration max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static int nextIndex(int index, int length, bool repeat) {
    if (length <= 0) return 0;
    final next = index + 1;
    return next >= length ? (repeat ? 0 : length - 1) : next;
  }

  static int previousIndex(int index, int length, bool repeat) {
    if (length <= 0) return 0;
    final previous = index - 1;
    return previous < 0 ? (repeat ? length - 1 : 0) : previous;
  }

  static List<int> shuffledIndices(int length, int seed) {
    final random = math.Random(seed);
    final indices = List<int>.generate(length, (index) => index);
    for (var i = indices.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = indices[i];
      indices[i] = indices[j];
      indices[j] = temp;
    }
    return indices;
  }

  static String repeatLabel(String mode) {
    switch (mode) {
      case 'one':
        return 'Repetir cancion';
      case 'all':
        return 'Repetir cola';
      default:
        return 'Sin repeticion';
    }
  }

  static String speedLabel(double speed) => '${speed.toStringAsFixed(2)}×';

  static int volumePercent(double volume) =>
      (volume.clamp(0.0, 1.0) * 100).round();

  static double volumeFromPercent(int percent) =>
      (percent.clamp(0, 100) / 100).toDouble();

  static double gainDb(double volume) => volume <= 0
      ? -60.0
      : (20 * math.log(volume) / math.ln10).roundToDouble();

  static int crossfadeMs(double seconds) =>
      (seconds.clamp(0.0, 12.0) * 1000).round();

  static DateTime sleepFinish(DateTime now, Duration duration) =>
      now.add(duration);

  static String remainingLabel(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static int progressPercent(int currentMs, int maxMs) {
    if (maxMs <= 0) return 0;
    return (currentMs * 100 / maxMs).clamp(0, 100).round();
  }

  static bool isNearEnd(Duration position, Duration duration) =>
      duration > Duration.zero && duration - position <= const Duration(seconds: 5);

  static Duration seekClamp(Duration target, Duration duration) =>
      PlaybackToolsPro.clampDuration(target, Duration.zero, duration);

  static int lyricIndexAt(List<Duration> times, Duration position) {
    for (var i = times.length - 1; i >= 0; i--) {
      if (position >= times[i]) return i;
    }
    return -1;
  }

  static double karaokeFraction(Duration start, Duration end, Duration position) {
    final total = end.inMilliseconds - start.inMilliseconds;
    if (total <= 0) return 0;
    final done = position.inMilliseconds - start.inMilliseconds;
    return (done / total).clamp(0.0, 1.0);
  }

  static String queueSummary(int index, int length) =>
      length <= 0 ? 'Cola vacia' : '${index + 1} de $length';

  static String skipSilenceLabel(bool enabled) =>
      enabled ? 'Saltar silencio: Activo' : 'Saltar silencio: Inactivo';

  static double recommendedVolume(bool batterySaver) => batterySaver ? 0.7 : 0.85;
}

class DownloadToolsPro {
  static String extensionForFormat(String format) {
    final value = format.toLowerCase().replaceAll('.', '');
    if (value == 'mpeg' || value == 'mp3') return 'mp3';
    if (value == 'm4a' || value == 'mp4') return 'm4a';
    if (value == 'ogg' || value == 'opus') return 'ogg';
    if (['flac', 'wav', 'aac'].contains(value)) return value;
    return 'mp3';
  }

  static String formatFromUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    for (final ext in ['mp3', 'm4a', 'ogg', 'flac', 'wav', 'opus']) {
      if (path.endsWith('.$ext')) return ext;
    }
    return 'mp3';
  }

  static bool isDirectAudioUrl(String url) =>
      RegExp(r'\.(mp3|m4a|ogg|oga|opus|flac|wav)(\?|$)', caseSensitive: false)
          .hasMatch(url);

  static bool isLegalSource(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.contains('archive.org') ||
        host.contains('wikimedia.org') ||
        host.contains('jamendo.com') ||
        host.contains('soundcloud.com') ||
        host.contains('pixabay.com') ||
        host.isEmpty;
  }

  static String safeDownloadName(String value) =>
      LibraryToolsPro.sanitizeFileName(value).replaceAll(RegExp(r'^\.+'), '');

  static int estimateBytes(int kbps, Duration duration) =>
      (kbps * 1000 * duration.inSeconds / 8).round();

  static String qualityLabel(int kbps) {
    if (kbps >= 320) return 'Maxima';
    if (kbps >= 256) return 'Muy alta';
    if (kbps >= 192) return 'Alta';
    if (kbps >= 128) return 'Buena';
    return 'Estandar';
  }

  static int bestBitrate(List<int> options, int preferred) {
    if (options.isEmpty) return preferred;
    final sorted = options.toList()..sort();
    for (final option in sorted) {
      if (option >= preferred) return option;
    }
    return sorted.last;
  }

  static String mimeForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'm4a':
        return 'audio/mp4';
      case 'ogg':
      case 'opus':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      case 'wav':
        return 'audio/wav';
      default:
        return 'audio/mpeg';
    }
  }

  static bool isLossless(String extension) =>
      ['flac', 'wav'].contains(extension.toLowerCase());

  static String cleanUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.replace(queryParameters: <String, dynamic>{}).toString();
  }

  static String providerLabel(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.contains('archive')) return 'Internet Archive';
    if (host.contains('wikimedia')) return 'Wikimedia Commons';
    if (host.contains('jamendo')) return 'Jamendo';
    if (host.contains('soundcloud')) return 'SoundCloud';
    if (host.contains('pixabay')) return 'Pixabay';
    if (host.contains('youtube')) return 'YouTube (audio autorizado)';
    return 'URL directa';
  }

  static int retryDelaySeconds(int attempt) =>
      math.min(30, 2 * math.pow(2, attempt.clamp(0, 4)).toInt());

  static bool isValidBitrate(int kbps) => const {64, 96, 128, 192, 256, 320}
      .contains(kbps);

  static String formatLabel(String extension) => extension.toUpperCase();
}

class PlaylistToolsPro {
  static String m3uHeader() => '#EXTM3U';

  static String m3uEntry(String path, String title, int? durationMs) {
    final seconds = durationMs == null ? -1 : (durationMs / 1000).round();
    return '#EXTINF:$seconds,$title\n$path';
  }

  static String csvHeader() => 'titulo;artista;album;duracion_ms;formato';

  static String csvRow(List<String> cells) =>
      cells.map((cell) => '"${cell.replaceAll('"', '""')}"').join(';');

  static String jsonEscape(String value) => jsonEncode(value);

  static List<String> mergeUnique(List<String> first, List<String> second) {
    final result = <String>[...first];
    for (final value in second) {
      if (!result.contains(value)) result.add(value);
    }
    return result;
  }

  static List<Track> dedupeTracks(List<Track> tracks) {
    final seen = <String>{};
    return tracks.where((track) {
      final key = '${track.title.toLowerCase()}|'
          '${track.artist.toLowerCase()}|${track.durationMs ?? 0}';
      return seen.add(key);
    }).toList();
  }

  static List<Track> sortTracks(List<Track> tracks, String criterion) {
    final sorted = [...tracks];
    switch (criterion) {
      case 'artist':
        sorted.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case 'album':
        sorted.sort((a, b) =>
            (a.album ?? '').compareTo(b.album ?? ''));
        break;
      case 'duration':
        sorted.sort((a, b) => (a.durationMs ?? 0).compareTo(b.durationMs ?? 0));
        break;
      default:
        sorted.sort((a, b) => a.title.compareTo(b.title));
    }
    return sorted;
  }

  static List<Track> filterTracks(List<Track> tracks, String query) {
    if (query.trim().isEmpty) return tracks;
    return tracks
        .where((track) =>
            LibraryToolsPro.searchScore(query, '${track.title} ${track.artist}') >
            0)
        .toList();
  }

  static String playlistName(List<Track> tracks) {
    if (tracks.isEmpty) return 'Nueva playlist';
    if (tracks.length == 1) return tracks.first.title;
    final artist = LibraryToolsPro.splitArtists(tracks.first.artist).first;
    return '$artist · ${tracks.length} canciones';
  }
}

class LyricsToolsPro {
  static Duration? parseTimestamp(String value) {
    final match = RegExp(r'(\d+):(\d+(?:\.\d+)?)').firstMatch(value);
    if (match == null) return null;
    final minutes = int.parse(match.group(1)!);
    final seconds = double.parse(match.group(2)!);
    return Duration(milliseconds: ((minutes * 60 + seconds) * 1000).round());
  }

  static MapEntry<Duration, String>? parseLrcLine(String line) {
    final time = parseTimestamp(line);
    if (time == null) return null;
    final text = line.replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '').trim();
    return MapEntry(time, text);
  }

  static Map<Duration, String> sortLyrics(Map<Duration, String> lyrics) {
    final entries = lyrics.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Map.fromEntries(entries);
  }

  static String? lineAt(Map<Duration, String> lyrics, Duration position) {
    String? result;
    for (final entry in lyrics.entries) {
      if (entry.key > position) break;
      result = entry.value;
    }
    return result;
  }

  static int nextLineIndex(List<Duration> times, Duration position) {
    for (var i = 0; i < times.length; i++) {
      if (times[i] > position) return i;
    }
    return -1;
  }

  static String stripLrcMeta(String source) => source
      .split('\n')
      .where((line) => !RegExp(r'^\[(ar|ti|al|by|offset|length):').hasMatch(line))
      .join('\n');

  static String plainLyrics(String source) => stripLrcMeta(source)
      .replaceAll(RegExp(r'\[\d+:\d+(?:\.\d+)?\]'), '')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  static int wordCount(String text) =>
      text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;

  static double readingSpeed(String text, Duration duration) {
    if (duration.inSeconds <= 0) return 0;
    return (wordCount(text) * 60 / duration.inSeconds).roundToDouble();
  }

  static Duration syncedOffset(Duration base, int milliseconds) =>
      base + Duration(milliseconds: milliseconds);
}

class SettingsToolsPro {
  static String themeModeLabel(String mode) {
    switch (mode) {
      case 'light':
        return 'Claro';
      case 'dark':
        return 'Oscuro';
      default:
        return 'Sistema';
    }
  }

  static String dataSaverLabel(bool enabled) =>
      enabled ? 'Ahorro de datos: Activo' : 'Ahorro de datos: Inactivo';

  static String boolLabel(bool value) => value ? 'Activo' : 'Inactivo';

  static int clampBitrate(int kbps) =>
      const [64, 96, 128, 192, 256, 320]
          .reduce((a, b) => (b - kbps).abs() < (a - kbps).abs() ? b : a);

  static int parseBitratePreference(String value) =>
      int.tryParse(value.replaceAll(RegExp(r'\D'), '')) ?? 128;

  static String sortLabel(String criterion) {
    switch (criterion) {
      case 'artist':
        return 'Artista';
      case 'album':
        return 'Album';
      case 'duration':
        return 'Duracion';
      case 'recent':
        return 'Recientes';
      default:
        return 'Titulo';
    }
  }

  static int accentSeed(String value) =>
      value.codeUnits.fold(0, (seed, code) => seed * 31 + code) & 0x7fffffff;

  static String backupKey(String version) => 'soundbox.backup.$version';

  static String? validateDisplayName(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 2) return 'Minimo 2 caracteres';
    if (trimmed.length > 24) return 'Maximo 24 caracteres';
    return null;
  }

  static String channelLabel(String channel) {
    switch (channel.toLowerCase()) {
      case 'alpha':
        return 'Alpha';
      case 'stable':
        return 'Estable';
      default:
        return 'Beta';
    }
  }
}

class MaintenanceToolsPro {
  static String cacheSizeLabel(int bytes) =>
      LibraryToolsPro.fileSizeLabel(bytes);

  static bool cleanCachePolicy(bool keepLyrics) => !keepLyrics;

  static bool orphanSubtitleName(String audio, String subtitle) {
    final base = audio.replaceAll(RegExp(r'\.[^.]+$'), '');
    return subtitle.startsWith(base) && subtitle.contains('.');
  }

  static int oldDownloadDays(DateTime now, DateTime downloaded) =>
      now.difference(downloaded).inDays;

  static String storagePressure(int freeMb) {
    if (freeMb < 200) return 'Critico';
    if (freeMb < 1000) return 'Bajo';
    return 'Saludable';
  }

  static String permissionLabel(bool granted) => granted ? 'Concedido' : 'Falta';

  static String logFingerprint(String message) =>
      message.trim().toLowerCase().replaceAll(RegExp(r'\d+'), '#');

  static int diagnosticScore({
    required bool online,
    required int cacheMb,
    required int missingMetadata,
  }) {
    var score = 100;
    if (!online) score -= 15;
    if (cacheMb > 500) score -= 20;
    score -= math.min(40, missingMetadata * 2);
    return score.clamp(0, 100);
  }

  static String recommendationFor(int score) {
    if (score >= 85) return 'Todo en orden';
    if (score >= 60) return 'Revisa los metadatos de la biblioteca';
    return 'Limpia la cache y actualiza la biblioteca';
  }

  static String batteryLabel(int level) {
    if (level >= 70) return 'Alta';
    if (level >= 25) return 'Media';
    return 'Baja';
  }

  static String networkLabel(bool online, bool metered) {
    if (!online) return 'Sin conexion';
    return metered ? 'Datos medidos' : 'Wi-Fi';
  }

  static int versionCodeFrom(String version) {
    final parts = version.split('.');
    if (parts.length != 3) return 0;
    final major = int.tryParse(parts[0]) ?? 0;
    final minor = int.tryParse(parts[1]) ?? 0;
    final patch = int.tryParse(parts[2]) ?? 0;
    return major * 100 + minor * 10 + patch;
  }

  static String featureTag(String id, bool enabled) =>
      '$id:${enabled ? "on" : "off"}';

  static String buildTag(String version, int code) => '$version ($code)';

  static String supportSummary(String version, bool online) =>
      'SoundBox $version · ${online ? "Con conexion" : "Solo local"}';
}

// ---------------------------------------------------------------------------
// 200 utilidades nuevas para la version estable 1.1.0.
// Mantienen el mismo contrato que las 100 anteriores: puras, sin Flutter y
// con resultados deterministas para poder probarlas en GitHub Actions.
// ---------------------------------------------------------------------------

/// Biblioteca avanzada: conteos, integridad y puntuacion de salud.
class LibraryInsightsPro {
  static int uniqueTitles(List<Track> tracks) =>
      tracks.map((t) => LibraryToolsPro.titleKey(t.title)).toSet().length;

  static int uniqueArtists(List<Track> tracks) =>
      tracks.map((t) => LibraryToolsPro.artistKey(t.artist)).toSet().length;

  static int uniqueAlbums(List<Track> tracks) =>
      tracks.map((t) => LibraryToolsPro.normalizeText(t.album ?? '')).toSet().length;

  static int trackCountByArtist(List<Track> tracks, String artist) => tracks
      .where((t) => LibraryToolsPro.artistKey(t.artist) ==
          LibraryToolsPro.artistKey(artist))
      .length;

  static int trackCountByAlbum(List<Track> tracks, String album) => tracks
      .where((t) =>
          LibraryToolsPro.normalizeText(t.album ?? '') ==
          LibraryToolsPro.normalizeText(album))
      .length;

  static String longestTitle(List<Track> tracks) {
    if (tracks.isEmpty) return '';
    return tracks.reduce((a, b) => a.title.length >= b.title.length ? a : b).title;
  }

  static String shortestTitle(List<Track> tracks) {
    if (tracks.isEmpty) return '';
    return tracks.reduce((a, b) => a.title.length <= b.title.length ? a : b).title;
  }

  static Duration averageDuration(List<Track> tracks) {
    if (tracks.isEmpty) return Duration.zero;
    final total = tracks.fold<int>(0, (sum, t) => sum + (t.durationMs ?? 0));
    return Duration(milliseconds: total ~/ tracks.length);
  }

  static String totalDurationLabel(List<Track> tracks) {
    final total = tracks.fold<int>(0, (sum, t) => sum + (t.durationMs ?? 0));
    return LibraryToolsPro.durationLabel(Duration(milliseconds: total));
  }

  static int localCount(List<Track> tracks) =>
      tracks.where((t) => t.isLocal).length;

  static int onlineCount(List<Track> tracks) =>
      tracks.where((t) => !t.isLocal).length;

  static int downloadedCount(List<Track> tracks) =>
      tracks.where((t) => t.downloaded).length;

  static int missingArtworkCount(List<Track> tracks) =>
      tracks.where((t) => t.artworkUrl == null && t.artworkPath == null).length;

  static int missingGenreCount(List<Track> tracks) =>
      tracks.where((t) => t.genre == null || t.genre!.trim().isEmpty).length;

  static int taggedCount(List<Track> tracks) =>
      tracks.where((t) => t.tagsRead).length;

  static int untaggedCount(List<Track> tracks) =>
      tracks.where((t) => !t.tagsRead).length;

  static int? oldestYear(List<Track> tracks) {
    final years = tracks.map((t) => t.year).whereType<int>().toList()..sort();
    return years.isEmpty ? null : years.first;
  }

  static int? newestYear(List<Track> tracks) {
    final years = tracks.map((t) => t.year).whereType<int>().toList()..sort();
    return years.isEmpty ? null : years.last;
  }

  static String yearRangeLabel(List<Track> tracks) {
    final first = oldestYear(tracks);
    final last = newestYear(tracks);
    if (first == null || last == null) return 'Sin años';
    return first == last ? '$first' : '$first–$last';
  }

  static int libraryScore(List<Track> tracks) {
    if (tracks.isEmpty) return 0;
    var score = 100;
    score -= (missingArtworkCount(tracks) * 20 ~/ tracks.length)
        .clamp(0, 25)
        .toInt();
    score -= (missingGenreCount(tracks) * 20 ~/ tracks.length)
        .clamp(0, 25)
        .toInt();
    score -= (untaggedCount(tracks) * 15 ~/ tracks.length)
        .clamp(0, 20)
        .toInt();
    final duplicates = LibraryToolsPro.duplicateGroups(tracks).length;
    score -= (duplicates * 5).clamp(0, 30).toInt();
    return score.clamp(0, 100).toInt();
  }
}

/// Reproduccion avanzada: saltos, limites, cola y estados de reproduccion.
class PlaybackInsightsPro {
  static bool isTrackFinished(Duration position, Duration duration) =>
      duration > Duration.zero && position >= duration - const Duration(seconds: 2);

  static bool isTrackStarting(Duration position) =>
      position <= const Duration(seconds: 3);

  static Duration forwardSeek(Duration position, Duration duration, int seconds) =>
      LibraryToolsPro.clampDuration(
        position + Duration(seconds: seconds),
        Duration.zero,
        duration,
      );

  static Duration backwardSeek(Duration position, int seconds) =>
      LibraryToolsPro.clampDuration(
        position - Duration(seconds: seconds),
        Duration.zero,
        position,
      );

  static Duration replaySeconds(Duration duration, int seconds) =>
      duration > Duration(seconds: seconds)
          ? duration - Duration(seconds: seconds)
          : Duration.zero;

  static int loopIndex(int index, int length) {
    if (length <= 0) return 0;
    return ((index % length) + length) % length;
  }

  static int bounceIndex(int index, int length) {
    if (length <= 1) return 0;
    final cycle = length * 2 - 2;
    final position = ((index % cycle) + cycle) % cycle;
    return position < length ? position : cycle - position;
  }

  static String queuePositionLabel(int index, int length) =>
      length <= 0 ? '0 de 0' : '${index + 1} de $length';

  static int remainingTracks(int length, int index) =>
      (length - index - 1).clamp(0, length).toInt();

  static double playedFraction(Duration position, Duration duration) {
    if (duration <= Duration.zero) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  static double volumeStep(double volume, double delta) =>
      (volume + delta).clamp(0.0, 1.0);

  static double normalizedGain(double db) => db.clamp(-20.0, 20.0);

  static bool isSilent(double volume) => volume <= 0.001;

  static int shuffleSeed(int base, int length) =>
      (base * 31 + length * 17).abs();

  static String repeatCycle(String mode) {
    switch (mode) {
      case 'off':
        return 'all';
      case 'all':
        return 'one';
      case 'one':
        return 'off';
      default:
        return 'off';
    }
  }

  static double speedStep(double speed, double delta) =>
      (speed + delta).clamp(0.5, 3.0);

  static String speedLabelShort(double speed) =>
      '${speed.toStringAsFixed(2)}x';

  static String sleepMinutesLabel(int minutes) =>
      minutes <= 0 ? 'Sin temporizador' : '$minutes min';

  static bool isLongTrack(Duration duration) =>
      duration >= const Duration(minutes: 8);

  static bool isShortTrack(Duration duration) =>
      duration > Duration.zero && duration <= const Duration(seconds: 90);
}

/// Busqueda avanzada: tokens, coincidencias y orden de resultados.
class SearchInsightsPro {
  static List<String> queryWords(String query) => LibraryToolsPro.normalizeText(query)
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  static bool queryIsEmpty(String query) => queryWords(query).isEmpty;

  static bool matchesAllTokens(String text, String query) {
    final normalized = LibraryToolsPro.normalizeText(text);
    return queryWords(query).every(normalized.contains);
  }

  static bool matchesAnyToken(String text, String query) {
    final normalized = LibraryToolsPro.normalizeText(text);
    return queryWords(query).any(normalized.contains);
  }

  static List<int> highlightRanges(String text, String query) {
    final normalized = LibraryToolsPro.normalizeText(text);
    final ranges = <int>[];
    for (final word in queryWords(query)) {
      final start = normalized.indexOf(word);
      if (start >= 0) ranges.add(start);
    }
    return ranges;
  }

  static double tokenOverlapScore(String left, String right) {
    final a = queryWords(left).toSet();
    final b = queryWords(right).toSet();
    if (a.isEmpty || b.isEmpty) return 0;
    return a.intersection(b).length / a.union(b).length;
  }

  static bool fuzzyContains(String text, String query) {
    final normalized = LibraryToolsPro.normalizeText(text);
    final needle = LibraryToolsPro.normalizeText(query);
    if (needle.isEmpty) return true;
    var cursor = 0;
    for (final char in needle.split('')) {
      final found = normalized.indexOf(char, cursor);
      if (found < 0) return false;
      cursor = found + 1;
    }
    return true;
  }

  static bool titleStartsWith(Track track, String query) =>
      LibraryToolsPro.normalizeText(track.title)
          .startsWith(LibraryToolsPro.normalizeText(query));

  static bool artistStartsWith(Track track, String query) =>
      LibraryToolsPro.artistKey(track.artist)
          .startsWith(LibraryToolsPro.normalizeText(query));

  static bool albumContains(Track track, String query) =>
      LibraryToolsPro.normalizeText(track.album ?? '')
          .contains(LibraryToolsPro.normalizeText(query));

  static int bestMatchIndex(List<Track> tracks, String query) {
    var best = -1;
    var bestScore = -1;
    for (var i = 0; i < tracks.length; i++) {
      final score = LibraryToolsPro.searchScore(tracks[i], query);
      if (score > bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best;
  }

  static List<Track> sortedByQuery(List<Track> tracks, String query) {
    final copy = List<Track>.from(tracks);
    copy.sort((a, b) => LibraryToolsPro.searchScore(b, query)
        .compareTo(LibraryToolsPro.searchScore(a, query)));
    return copy;
  }

  static String normalizeQuery(String query) =>
      LibraryToolsPro.normalizeText(query).replaceAll(RegExp(r'\s+'), ' ').trim();

  static String stripQuotes(String query) =>
      query.replaceAll(RegExp(r'^["\']+|["\']+$'), '').trim();

  static String expandWildcard(String query) =>
      query.replaceAll('*', '').replaceAll('%', '').trim();

  static bool isExactPhrase(String query) =>
      query.trim().startsWith('"') && query.trim().endsWith('"');

  static List<String> phraseTokens(String query) =>
      queryWords(stripQuotes(query));

  static String searchHint(String query) => queryIsEmpty(query)
      ? 'Escribe un artista, cancion o album'
      : 'Buscando "$query"';

  static String resultCountLabel(int count) =>
      count == 1 ? '1 resultado' : '$count resultados';

  static String noResultsMessage(String query) =>
      'Sin resultados para "$query"';
}

/// Descargas y proveedores: URLs, formatos, atribucion y progreso.
class DownloadInsightsPro {
  static bool isAudioExtension(String extension) =>
      ['mp3', 'm4a', 'aac', 'flac', 'ogg', 'opus', 'wav'].contains(
    LibraryToolsPro.normalizeText(extension.replaceAll('.', '')),
  );

  static bool isVideoExtension(String extension) =>
      ['mp4', 'mkv', 'avi', 'mov', 'webm', 'flv'].contains(
    LibraryToolsPro.normalizeText(extension.replaceAll('.', '')),
  );

  static bool isSubtitleExtension(String extension) =>
      ['srt', 'vtt', 'lrc'].contains(
    LibraryToolsPro.normalizeText(extension.replaceAll('.', '')),
  );

  static String safeFormat(String format) =>
      isAudioExtension(format) ? format.toLowerCase() : 'mp3';

  static String providerKey(String url) {
    final host = hostFromUrl(url);
    if (host.contains('archive.org')) return 'archive';
    if (host.contains('wikimedia.org')) return 'wikimedia';
    if (host.contains('jamendo')) return 'jamendo';
    if (host.contains('soundcloud')) return 'soundcloud';
    if (host.contains('pixabay')) return 'pixabay';
    if (host.contains('youtube') || host.contains('youtu.be')) return 'youtube';
    return 'direct';
  }

  static bool providerNeedsAttribution(String url) =>
      ['archive', 'wikimedia', 'jamendo'].contains(providerKey(url));

  static String attributionText(Track track) {
    final license = track.license?.trim();
    if (license == null || license.isEmpty) return 'Fuente: ${track.source ?? 'desconocida'}';
    return '${track.source ?? 'Fuente'} · $license';
  }

  static bool isPlainFileUrl(String url) {
    final path = urlWithoutQuery(url).toLowerCase();
    return isAudioExtension(path.split('.').last);
  }

  static String hostFromUrl(String url) =>
      Uri.tryParse(url)?.host.toLowerCase() ?? '';

  static String urlWithoutQuery(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.replace(query: null, fragment: null).toString();
  }

  static String urlScheme(String url) =>
      Uri.tryParse(url)?.scheme.toLowerCase() ?? '';

  static bool isSecureUrl(String url) => urlScheme(url) == 'https';

  static int qualityRank(String label) {
    switch (LibraryToolsPro.normalizeText(label)) {
      case '320 kbps':
      case 'lossless':
        return 4;
      case '256 kbps':
        return 3;
      case '192 kbps':
        return 2;
      case '128 kbps':
        return 1;
      default:
        return 0;
    }
  }

  static String bestQualityUrl(Map<String, String> urls) {
    if (urls.isEmpty) return '';
    final entry = urls.entries.reduce((a, b) =>
        qualityRank(a.key) >= qualityRank(b.key) ? a : b);
    return entry.value;
  }

  static String fileNameFromUrl(String url) {
    final path = urlWithoutQuery(url);
    final name = path.split('/').where((part) => part.isNotEmpty).lastOrNull ?? 'audio';
    return LibraryToolsPro.sanitizeFileName(name);
  }

  static String fileExtensionFromName(String name) {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  static String downloadStateLabel(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.queued:
        return 'En cola';
      case DownloadStatus.downloading:
        return 'Descargando';
      case DownloadStatus.converting:
        return 'Convirtiendo';
      case DownloadStatus.paused:
        return 'Pausada';
      case DownloadStatus.done:
        return 'Completada';
      case DownloadStatus.failed:
        return 'Fallida';
      case DownloadStatus.canceled:
        return 'Cancelada';
    }
  }

  static bool isTerminalStatus(DownloadStatus status) =>
      status == DownloadStatus.done ||
      status == DownloadStatus.failed ||
      status == DownloadStatus.canceled;

  static int progressPercentDone(int received, int total) {
    if (total <= 0) return 0;
    return (received * 100 / total).clamp(0, 100).round();
  }

  static String etaLabel(int seconds) {
    if (seconds <= 0) return 'Calculando…';
    if (seconds < 60) return '$seconds s';
    return '${seconds ~/ 60} min ${seconds % 60} s';
  }
}

/// Playlists y colas: operaciones puras sobre listas de pistas.
class PlaylistInsightsPro {
  static String playlistSlug(String name) => LibraryToolsPro.normalizeText(name)
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  static int playlistColorSeed(String name) =>
      LibraryToolsPro.normalizeText(name).codeUnits.fold(0, (sum, c) => sum + c);

  static List<String> trackIds(List<Track> tracks) =>
      tracks.map((t) => t.id).toList();

  static List<String> uniqueTrackIds(List<Track> tracks) =>
      trackIds(tracks).toSet().toList();

  static Duration playlistDuration(List<Track> tracks) => Duration(
      milliseconds: tracks.fold<int>(0, (sum, t) => sum + (t.durationMs ?? 0)));

  static bool isPlaylistEmpty(List<Track> tracks) => tracks.isEmpty;

  static String playlistSizeLabel(List<Track> tracks) =>
      '${tracks.length} canción${tracks.length == 1 ? '' : 'es'}';

  static List<Track> insertAtIndex(List<Track> tracks, int index, Track track) {
    final copy = List<Track>.from(tracks);
    final safe = index.clamp(0, copy.length).toInt();
    copy.insert(safe, track);
    return copy;
  }

  static List<Track> removeFirstWhere(List<Track> tracks, String id) {
    final copy = List<Track>.from(tracks);
    final index = copy.indexWhere((t) => t.id == id);
    if (index >= 0) copy.removeAt(index);
    return copy;
  }

  static List<Track> moveTrack(List<Track> tracks, int from, int to) {
    final copy = List<Track>.from(tracks);
    if (from < 0 || from >= copy.length || copy.isEmpty) return copy;
    final safeTo = to.clamp(0, copy.length - 1).toInt();
    final track = copy.removeAt(from);
    copy.insert(safeTo, track);
    return copy;
  }

  static List<Track> swapTracks(List<Track> tracks, int a, int b) {
    final copy = List<Track>.from(tracks);
    if (a < 0 || b < 0 || a >= copy.length || b >= copy.length) return copy;
    final temp = copy[a];
    copy[a] = copy[b];
    copy[b] = temp;
    return copy;
  }

  static List<Track> rotateQueue(List<Track> tracks, int by) {
    if (tracks.isEmpty) return <Track>[];
    final shift = ((by % tracks.length) + tracks.length) % tracks.length;
    return [...tracks.sublist(shift), ...tracks.sublist(0, shift)];
  }

  static List<List<Track>> chunkTracks(List<Track> tracks, int size) {
    if (size <= 0) return <List<Track>>[];
    final chunks = <List<Track>>[];
    for (var i = 0; i < tracks.length; i += size) {
      chunks.add(tracks.sublist(i, math.min(i + size, tracks.length)));
    }
    return chunks;
  }

  static List<Track> interleave(List<Track> left, List<Track> right) {
    final result = <Track>[];
    final max = math.max(left.length, right.length);
    for (var i = 0; i < max; i++) {
      if (i < left.length) result.add(left[i]);
      if (i < right.length) result.add(right[i]);
    }
    return result;
  }

  static List<Track> repeatTracks(List<Track> tracks, int times) {
    if (times <= 0) return <Track>[];
    return List<Track>.generate(tracks.length * times, (i) => tracks[i % tracks.length]);
  }

  static List<Track> takeEveryNth(List<Track> tracks, int n) {
    if (n <= 0) return <Track>[];
    return [
      for (var i = 0; i < tracks.length; i += n) tracks[i],
    ];
  }

  static int playlistOverlap(List<Track> a, List<Track> b) => uniqueTrackIds(a)
      .toSet()
      .intersection(uniqueTrackIds(b).toSet())
      .length;

  static List<Track> mergePlaylists(List<Track> a, List<Track> b) =>
      LibraryToolsPro.mergeUnique([...a, ...b]);

  static List<Track> shuffleWithSeed(List<Track> tracks, int seed) {
    final indices = LibraryToolsPro.shuffledIndices(tracks.length, seed);
    return indices.map((i) => tracks[i]).toList();
  }

  static String playlistChecksum(List<Track> tracks) =>
      uniqueTrackIds(tracks).join('|').hashCode.abs().toRadixString(16);
}

Duration? _durationFromMatch(RegExpMatch match) {
  final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
  final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
  final fraction = match.group(3) ?? '0';
  final millis = fraction.length == 1
      ? (int.tryParse(fraction) ?? 0) * 100
      : int.tryParse(fraction.padRight(3, '0')) ?? 0;
  return Duration(minutes: minutes, seconds: seconds, milliseconds: millis);
}

/// Letras y sincronizacion: parseo, ventanas y correccion de offsets.
class LyricsInsightsPro {
  static int lrcLineCount(String text) => LibraryToolsPro.stripLrcMeta(text)
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .length;

  static bool hasTimestamps(String text) =>
      RegExp(r'\[\d{1,3}:\d{2}(?:[.:]\d{1,3})?\]').hasMatch(text);

  static Duration? firstTimestamp(String text) {
    final match = RegExp(r'\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]')
        .firstMatch(text);
    return match == null ? null : _durationFromMatch(match);
  }

  static Duration? lastTimestamp(String text) {
    final matches = RegExp(r'\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]')
        .allMatches(text)
        .toList();
    return matches.isEmpty ? null : _durationFromMatch(matches.last);
  }

  static String lyricsDurationLabel(String text) {
    final first = firstTimestamp(text);
    final last = lastTimestamp(text);
    if (first == null || last == null) return 'Sin tiempo';
    return LibraryToolsPro.durationLabel(last - first);
  }

  static String lineAtPercent(List<String> lines, int percent) {
    if (lines.isEmpty) return '';
    final index = ((percent.clamp(0, 100) / 100) * (lines.length - 1)).round();
    return lines[index];
  }

  static List<String> activeLineWindow(List<String> lines, int index) {
    if (lines.isEmpty) return <String>[];
    final start = (index - 1).clamp(0, lines.length - 1).toInt();
    final end = (index + 2).clamp(0, lines.length).toInt();
    return lines.sublist(start, end);
  }

  static String lineBefore(List<String> lines, int index) =>
      index <= 0 || lines.isEmpty ? '' : lines[index - 1];

  static String lineAfter(List<String> lines, int index) =>
      index < 0 || index >= lines.length - 1 ? '' : lines[index + 1];

  static bool isBlankLine(String line) => line.trim().isEmpty;

  static String trimLrcLine(String line) =>
      line.replaceAll(RegExp(r'^\[[^\]]+\]\s*'), '').trim();

  static String lrcTagValue(String text, String tag) {
    final match = RegExp('@$tag=([^\\r\\n]+)', caseSensitive: false)
        .firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }

  static Map<String, String> metadataTags(String text) {
    final result = <String, String>{};
    for (final tag in ['ar', 'ti', 'al', 'by', 'offset']) {
      final value = lrcTagValue(text, tag);
      if (value.isNotEmpty) result[tag] = value;
    }
    return result;
  }

  static String stripMetadataTags(String text) => text
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('[') ||
          RegExp(r'\[\d{1,3}:').hasMatch(line))
      .join('\n');

  static List<String> dedupeLines(List<String> lines) =>
      lines.where((line) => line.trim().isNotEmpty).toSet().toList();

  static int karaokeWordCount(String line) =>
      trimLrcLine(line).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  static int estimateSingingSeconds(List<String> lines) =>
      lines.fold<int>(0, (sum, line) => sum + karaokeWordCount(line)) ~/ 3;

  static Duration syncOffsetFromTap(int expectedMs, int actualMs) =>
      Duration(milliseconds: actualMs - expectedMs);

  static String lyricSearchQuery(Track track) =>
      '${track.title} ${track.artist} letra';

  static bool tooFastWarning(List<String> lines) =>
      lines.length > 80 && estimateSingingSeconds(lines) < lines.length;
}

/// Ajustes y accesibilidad: etiquetas y resumenes legibles.
class SettingsInsightsPro {
  static String themeLabelShort(String mode) {
    switch (mode) {
      case 'light':
        return 'Claro';
      case 'dark':
        return 'Oscuro';
      default:
        return 'Sistema';
    }
  }

  static String contrastLabel(bool enabled) =>
      enabled ? 'Alto contraste' : 'Contraste normal';

  static String reduceMotionLabel(bool enabled) =>
      enabled ? 'Movimiento reducido' : 'Movimiento completo';

  static String hapticsLabel(bool enabled) =>
      enabled ? 'Vibracion activada' : 'Vibracion desactivada';

  static String gesturesLabel(bool enabled) =>
      enabled ? 'Gestos activados' : 'Gestos desactivados';

  static String wifiOnlyLabel(bool enabled) =>
      enabled ? 'Solo Wi-Fi' : 'Wi-Fi y datos';

  static String dataSaverNote(bool enabled) =>
      enabled ? 'Se descarga la menor calidad' : 'Se elige la mejor calidad';

  static String autoLyricsLabel(bool enabled) =>
      enabled ? 'Letras automaticas' : 'Letras manuales';

  static String wormLabel(bool enabled) =>
      enabled ? 'Onda en el tiempo' : 'Onda desactivada';

  static String miniPlayerLabel(bool enabled) =>
      enabled ? 'Mini reproductor visible' : 'Mini reproductor oculto';

  static String shuffleByDefaultLabel(bool enabled) =>
      enabled ? 'Aleatorio al iniciar' : 'Orden al iniciar';

  static String sortModeLabel(String mode) {
    switch (mode) {
      case 'artist':
        return 'Artista';
      case 'year':
        return 'Año';
      case 'recent':
        return 'Recientes';
      case 'plays':
        return 'Más escuchadas';
      default:
        return 'Título';
    }
  }

  static String gridLabel(bool enabled) =>
      enabled ? 'Vista de cuadricula' : 'Vista de lista';

  static String notificationLabel(bool enabled) =>
      enabled ? 'Notificacion visible' : 'Notificacion oculta';

  static String batterySaverLabel(bool enabled) =>
      enabled ? 'Ahorro de bateria' : 'Rendimiento normal';

  static String privacyLabel(bool online) =>
      online ? 'Datos sincronizados' : 'Solo en este dispositivo';

  static String languageLabel(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'pt':
        return 'Português';
      default:
        return 'Español';
    }
  }

  static String accentColorName(int seed) {
    final names = ['Azul', 'Verde', 'Morado', 'Naranja', 'Rosa', 'Cian'];
    return names[seed.abs() % names.length];
  }

  static String settingsSearchTerm(String term) =>
      'Buscar ajuste: ${LibraryToolsPro.normalizeText(term)}';

  static String resetSummary(int count) =>
      count == 1 ? '1 ajuste restaurado' : '$count ajustes restaurados';
}

/// Estadisticas de escucha y habitos.
class StatsInsightsPro {
  static Map<String, int> incrementPlayCount(Map<String, int> counts, String id) {
    final copy = Map<String, int>.from(counts);
    copy[id] = (copy[id] ?? 0) + 1;
    return copy;
  }

  static int playCount(Map<String, int> counts, String id) => counts[id] ?? 0;

  static String? topTrackId(Map<String, int> counts) {
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static int totalPlays(Map<String, int> counts) =>
      counts.values.fold<int>(0, (sum, value) => sum + value);

  static double averagePlays(Map<String, int> counts) =>
      counts.isEmpty ? 0 : totalPlays(counts) / counts.length;

  static String playRateLabel(int count, int days) {
    if (days <= 0) return 'Sin datos';
    return '${(count / days).toStringAsFixed(1)} por día';
  }

  static int streakDays(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final unique = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
      ..sort();
    var streak = 1;
    for (var i = 1; i < unique.length; i++) {
      final diff = unique[i].difference(unique[i - 1]).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        streak = 1;
      }
    }
    return streak;
  }

  static String lastPlayedLabel(int? epochMs) {
    if (epochMs == null) return 'Nunca';
    return DateTime.fromMillisecondsSinceEpoch(epochMs).toIso8601String().split('T').first;
  }

  static String listeningMinutesLabel(Duration duration) =>
      '${duration.inMinutes} min escuchados';

  static double favoriteRatio(int favorites, int total) =>
      total <= 0 ? 0 : (favorites / total).clamp(0.0, 1.0);

  static double completionRate(Duration played, Duration duration) =>
      duration <= Duration.zero
          ? 0
          : (played.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

  static double skipRate(int skips, int plays) =>
      plays <= 0 ? 0 : (skips / plays).clamp(0.0, 1.0);

  static String dailyGoalLabel(int goal, int current) =>
      '$current de $goal canciones hoy';

  static String weeklyGoalLabel(int goal, int current) =>
      '$current de $goal canciones esta semana';

  static String moodFromGenre(String genre) {
    switch (LibraryToolsPro.normalizeText(genre)) {
      case 'rock':
        return 'energico';
      case 'jazz':
        return 'relajado';
      case 'electronica':
        return 'bailar';
      case 'classical':
        return 'concentrado';
      default:
        return 'variado';
    }
  }

  static String moodLabel(String mood) => 'Estado: $mood';

  static String listeningSlotLabel(int hour) {
    if (hour < 6) return 'Madrugada';
    if (hour < 12) return 'Mañana';
    if (hour < 19) return 'Tarde';
    return 'Noche';
  }

  static int peakHour(Map<int, int> byHour) {
    if (byHour.isEmpty) return 0;
    return byHour.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static String recommendationReason(Track track) {
    final genre = track.genre ?? 'varios';
    return 'Por tu genero $genre y artista ${track.artist}';
  }

  static String statsBadge(int score) =>
      score >= 80 ? 'Experto' : score >= 50 ? 'Activo' : 'Nuevo';
}

/// Mantenimiento, archivos y diagnosticos.
class MaintenanceInsightsPro {
  static String bytesToGb(int bytes) =>
      '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';

  static String freeSpaceWarning(int freeBytes) => freeBytes < 1024 * 1024 * 1024
      ? 'Poco espacio libre'
      : 'Espacio suficiente';

  static bool isLowStorage(int freeBytes) => freeBytes < 512 * 1024 * 1024;

  static String cacheEntriesLabel(int count) =>
      count == 1 ? '1 archivo en cache' : '$count archivos en cache';

  static String clearCacheNote(int bytes) =>
      'Liberar ${LibraryToolsPro.fileSizeLabel(bytes)}';

  static int orphanCount(List<String> paths) =>
      paths.where((path) => path.endsWith('.lrc') || path.endsWith('.srt')).length;

  static int duplicatePathCount(List<String> paths) =>
      paths.length - paths.toSet().length;

  static String safePathJoin(String directory, String name) =>
      '${directory.replaceAll(RegExp(r'/+$'), '')}/${LibraryToolsPro.sanitizeFileName(name)}';

  static bool isValidFileName(String name) =>
      name.trim().isNotEmpty &&
      !RegExp(r'[<>:"/\\|?*]').hasMatch(name) &&
      name != '.' &&
      name != '..';

  static String truncatedName(String name, int max) =>
      name.length <= max ? name : '${name.substring(0, max - 1)}…';

  static String logLine(String level, String message) =>
      '[${level.toUpperCase()}] $message';

  static String errorSummary(List<String> errors) =>
      errors.isEmpty ? 'Sin errores' : '${errors.length} incidencias';

  static String healthLabel(int score) =>
      score >= 80 ? 'Saludable' : score >= 50 ? 'Aceptable' : 'Revisar';

  static String repairAction(int score) =>
      score >= 80 ? 'No hacer nada' : score >= 50 ? 'Limpiar cache' : 'Reindexar biblioteca';

  static String backupName(String version) =>
      'soundbox-backup-${version.replaceAll(RegExp(r'[^0-9a-zA-Z.]'), '-')}';

  static String restoreNote(bool hasBackup) =>
      hasBackup ? 'Copia disponible' : 'Sin copia disponible';

  static String diagnosticLine(String key, Object value) => '$key: $value';

  static String permissionStatusLabel(bool granted) =>
      granted ? 'Permiso concedido' : 'Permiso denegado';

  static String crashMarker(String stack) =>
      stack.isEmpty ? 'Sin crash' : stack.split('\n').first;

  static String supportTicketId(int seed) =>
      'SB-${seed.abs().toRadixString(16).toUpperCase().padLeft(8, '0')}';
}

/// Exportacion, compartir y metadatos legales.
class SharingInsightsPro {
  static String m3uExtendedLine(Track track) =>
      '#EXTINF:${(track.durationMs ?? 0) ~/ 1000},${track.artist} - ${track.title}';

  static String m3uComment(String text) => '# $text';

  static String m3uTitle(String name) => '#PLAYLIST:${name.trim()}';

  static String xspfTrackLine(Track track) =>
      '    <track><location>${track.sourceUrl}</location><title>${track.title}</title></track>';

  static String csvEscape(String value) =>
      '"${value.replaceAll('"', '""')}"';

  static String shareText(Track track) =>
      'Escuchando ${track.title} de ${track.artist} en SoundBox';

  static String shareSubject(List<Track> tracks) => tracks.length == 1
      ? 'Una cancion de SoundBox'
      : '${tracks.length} canciones de SoundBox';

  static String attributionFooter(Track track) {
    final source = track.source ?? 'Fuente desconocida';
    final license = track.license ?? 'Ver términos del proveedor';
    return '$source · $license';
  }

  static String licenseBadge(String? license) {
    if (license == null || license.trim().isEmpty) return 'Licencia no indicada';
    final value = license.toUpperCase();
    if (value.contains('CC')) return 'Creative Commons';
    if (value.contains('GPL')) return 'GPL';
    if (value.contains('MIT')) return 'MIT';
    return license;
  }

  static String legalProvidersCsv() =>
      'Internet Archive, Wikimedia Commons, Jamendo, SoundCloud, Pixabay, URL directa';

  static String youtubeNotice() =>
      'YouTube solo para audio propio o autorizado.';

  static String directUrlHint() =>
      'Pega una URL directa a MP3, M4A, FLAC, OGG o WAV.';

  static String fileUri(String path) =>
      path.startsWith('file://') ? path : 'file://$path';

  static String encodedQuery(Map<String, String> params) =>
      Uri(queryParameters: params).query;

  static Map<String, String> decodeQuery(String query) =>
      Uri.splitQueryString(query);

  static String trackFingerprint(Track track) =>
      '${LibraryToolsPro.titleKey(track.title)}|${LibraryToolsPro.artistKey(track.artist)}|'
      '${track.durationMs ?? 0}';

  static String playlistExportName(String name) =>
      '${PlaylistInsightsPro.playlistSlug(name)}.m3u';

  static String metadataSummary(Track track) =>
      '${track.title} · ${track.artist} · ${track.album ?? 'Sin álbum'} · '
      '${track.year ?? 'sin año'}';

  static String bitrateQualityLabel(int bps) {
    if (bps >= 320000) return 'Alta';
    if (bps >= 192000) return 'Media';
    if (bps > 0) return 'Baja';
    return 'Desconocida';
  }

  static String sampleRateLabel(int hz) =>
      hz >= 1000 ? '${(hz / 1000).toStringAsFixed(1)} kHz' : '$hz Hz';
}
