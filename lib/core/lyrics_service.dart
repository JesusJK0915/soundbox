import 'dart:async';

import 'package:dio/dio.dart';

import 'models.dart';

/// Resultado de una busqueda de letras en LRCLIB.
class LyricsResult {
  final int id;
  final String trackName;
  final String artistName;
  final String? albumName;
  final int? duration;
  final bool instrumental;
  final String? syncedLyrics;
  final String? plainLyrics;
  final bool hasWordSync;

  const LyricsResult({
    required this.id,
    required this.trackName,
    required this.artistName,
    this.albumName,
    this.duration,
    this.instrumental = false,
    this.syncedLyrics,
    this.plainLyrics,
    this.hasWordSync = false,
  });

  /// Contenido LRC listo para guardar y mostrar en el overlay.
  String? get lrcContent {
    final synced = syncedLyrics?.trim();
    if (synced != null && synced.isNotEmpty) return synced;
    final plain = plainLyrics?.trim();
    if (plain == null || plain.isEmpty) return null;
    return plain
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => '[00:00.00]$line')
        .join('\n');
  }

  factory LyricsResult.fromJson(Map<String, dynamic> json) => LyricsResult(
        id: (json['id'] as num?)?.toInt() ?? 0,
        trackName: (json['trackName'] as String?) ?? '',
        artistName: (json['artistName'] as String?) ?? '',
        albumName: json['albumName'] as String?,
        duration: (json['duration'] as num?)?.toInt(),
        instrumental: (json['instrumental'] as bool?) ?? false,
        syncedLyrics: json['syncedLyrics'] as String?,
        plainLyrics: json['plainLyrics'] as String?,
        hasWordSync: (json['hasWordSync'] as bool?) ?? false,
      );
}

class LyricsService {
  static const baseUrl = 'https://lrclib.net';
  static const userAgent =
      'SoundBox 0.11.0 (https://github.com/JesusJK0915/soundbox)';

  final Dio _dio;
  final Map<String, LyricsResult?> _cache = <String, LyricsResult?>{};
  DateTime? _lastRequest;
  Future<void> _queue = Future.value();
  bool _closed = false;

  LyricsService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
              headers: {
                'User-Agent': userAgent,
                'Accept': 'application/json',
              },
            ));

  void dispose() => _closed = true;

  String _key(Track track) => [
        track.title.trim().toLowerCase(),
        track.artist.trim().toLowerCase(),
        track.album?.trim().toLowerCase() ?? '',
        (track.durationMs ?? 0).toString(),
      ].join('|');

  /// Busca letras para [track]. Devuelve null si no hay coincidencia o hay error.
  /// Las peticiones se hacen en cola con retardo para no abusar del servicio.
  Future<LyricsResult?> fetch(Track track) {
    final key = _key(track);
    if (_cache.containsKey(key)) return Future.value(_cache[key]);
    final next = _queue.then((_) => _fetchQueued(track, key));
    _queue = next.catchError((_) {});
    return next;
  }

  Future<LyricsResult?> _fetchQueued(Track track, String key) async {
    if (_closed) return null;
    final wait = _lastRequest == null
        ? Duration.zero
        : Duration(
            milliseconds:
                350 - DateTime.now().difference(_lastRequest!).inMilliseconds,
          );
    if (wait > Duration.zero) await Future<void>.delayed(wait);
    if (_closed) return null;
    _lastRequest = DateTime.now();

    final duration = track.durationMs == null
        ? null
        : (track.durationMs! ~/ 1000).clamp(1, 3600);
    final query = <String, dynamic>{
      'track_name': track.title.trim(),
      'artist_name': track.artist.trim(),
    };
    final album = track.album?.trim();
    if (album != null && album.isNotEmpty) query['album_name'] = album;
    if (duration != null) query['duration'] = duration;

    try {
      var response = await _dio.get<dynamic>('/api/get', queryParameters: query);
      if (_isMissing(response.data)) {
        final search = <String, dynamic>{
          'track_name': track.title.trim(),
          'artist_name': track.artist.trim(),
        };
        if (album != null && album.isNotEmpty) search['album_name'] = album;
        response = await _dio.get<dynamic>('/api/search', queryParameters: search);
      }
      final result = pickBestMatch(response.data, track, duration);
      if (!_closed) _cache[key] = result;
      return result;
    } on DioException catch (e) {
      final retryAfter = e.response?.headers.value('retry-after');
      final seconds = int.tryParse(retryAfter ?? '') ?? 0;
      if (seconds > 0 && seconds <= 60 && !_closed) {
        await Future<void>.delayed(Duration(seconds: seconds));
        return _fetchQueued(track, key);
      }
      if (!_closed) _cache[key] = null;
      return null;
    } catch (_) {
      if (!_closed) _cache[key] = null;
      return null;
    }
  }

  static bool _isMissing(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['id'] != null) return false;
      return data['message'] != null || data['error'] != null;
    }
    return true;
  }

  static LyricsResult? pickBestMatch(
    dynamic data,
    Track track,
    int? duration,
  ) {
    final items = <Map<String, dynamic>>[];
    if (data is Map<String, dynamic>) {
      items.add(data);
    } else if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) items.add(item);
      }
    }
    if (items.isEmpty) return null;

    final title = track.title.trim().toLowerCase();
    final artist = track.artist.trim().toLowerCase();
    LyricsResult? fallback;
    for (final item in items) {
      final result = LyricsResult.fromJson(item);
      if (result.syncedLyrics == null &&
          result.plainLyrics == null &&
          !result.instrumental) {
        continue;
      }
      fallback ??= result;
      final sameTitle = result.trackName.trim().toLowerCase() == title ||
          result.trackName.trim().toLowerCase().contains(title);
      final sameArtist = result.artistName.trim().toLowerCase() == artist ||
          result.artistName.trim().toLowerCase().contains(artist);
      final closeDuration = duration == null ||
          result.duration == null ||
          (result.duration! - duration).abs() <= 3;
      if (sameTitle && sameArtist && closeDuration) return result;
    }
    return fallback;
  }
}
