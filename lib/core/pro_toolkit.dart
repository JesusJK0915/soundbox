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
