import 'package:dio/dio.dart';

/// Video de YouTube del que solo se lee metadata publica.
/// Nunca se descarga ni se extrae audio del video.
class YouTubeVideo {
  const YouTubeVideo({
    required this.id,
    required this.title,
    required this.channel,
    this.thumbnailUrl,
    this.description = '',
  });

  final String id;
  final String title;
  final String channel;
  final String? thumbnailUrl;
  final String description;

  /// Termino limpio para buscar la misma cancion en fuentes legales.
  String get searchQuery {
    final cleanTitle = _cleanText(title);
    final parts = cleanTitle
        .split(RegExp(r'\s+[-–—|]\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    String artist = _cleanChannel(channel);
    String song = cleanTitle;
    if (parts.length >= 2) {
      artist = parts.first;
      song = parts.skip(1).join(' ');
    }

    return <String>[song, artist]
        .where((part) => part.isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _cleanText(String value) {
    final noTags = value.replaceAll(
      RegExp(
        r'[\[(][^\])]*(official|audio|video|lyrics?|letra|hd|4k|'
        r'remastered|live|visualizer|teaser|clip|mv)[^\])]*[\])]',
        caseSensitive: false,
      ),
      ' ',
    );
    final noWords = noTags.replaceAll(
      RegExp(
        r'\b(official|audio|video|lyrics|lyric|hd|4k|visualizer)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    return noWords.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _cleanChannel(String value) => value
      .replaceAll(
        RegExp(r'\s*[-–—|]\s*(topic|vevo)\s*$', caseSensitive: false),
        '',
      )
      .replaceAll(
        RegExp(r'\s+(topic|vevo)\s*$', caseSensitive: false),
        '',
      )
      .trim();
}

/// Cliente de la YouTube Data API v3. Solo consulta `videos.list?part=snippet`.
class YouTubeService {
  YouTubeService(this._apiKey);

  final String _apiKey;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  static const Set<String> _hosts = <String>{
    'youtube.com',
    'music.youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'youtu.be',
  };

  static bool isYouTubeUrl(String text) => videoId(text) != null;

  /// Extrae el ID de watch, youtu.be, shorts, embed y live.
  static String? videoId(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;

    final host = uri.host.toLowerCase();
    if (!_hosts.contains(host)) return null;

    if (host == 'youtu.be') {
      return _cleanId(
        uri.pathSegments.isEmpty ? null : uri.pathSegments.first,
      );
    }

    final segments = uri.pathSegments;
    if (segments.isNotEmpty &&
        const <String>{'embed', 'shorts', 'live'}.contains(segments.first) &&
        segments.length > 1) {
      return _cleanId(segments[1]);
    }
    return _cleanId(uri.queryParameters['v']);
  }

  static String? _cleanId(String? value) {
    if (value == null || value.isEmpty) return null;
    final id = value.split(RegExp(r'[?&#/]')).first;
    return RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id) ? id : null;
  }

  Future<YouTubeVideo> resolve(String url) async {
    final key = _apiKey.trim();
    if (key.isEmpty) {
      throw StateError('Falta la API key de YouTube en Ajustes');
    }
    final id = videoId(url);
    if (id == null) throw ArgumentError('No es un link de YouTube valido');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://www.googleapis.com/youtube/v3/videos',
        queryParameters: <String, dynamic>{
          'part': 'snippet',
          'id': id,
          'key': key,
        },
      );
      final body = response.data;
      final apiError = body?['error'];
      if (apiError is Map) {
        throw StateError(
          apiError['message']?.toString() ?? 'La API key de YouTube no es valida',
        );
      }

      final items = body?['items'];
      if (items is! List || items.isEmpty) {
        throw StateError('No se encontro el video de YouTube');
      }
      final first = items.first;
      if (first is! Map) throw StateError('Respuesta inesperada de YouTube');
      final snippet = first['snippet'];
      if (snippet is! Map) throw StateError('Respuesta inesperada de YouTube');

      return YouTubeVideo(
        id: id,
        title: snippet['title']?.toString() ?? 'Sin titulo',
        channel: snippet['channelTitle']?.toString() ?? 'Desconocido',
        description: snippet['description']?.toString() ?? '',
        thumbnailUrl: _thumbnail(snippet['thumbnails']),
      );
    } on DioException catch (error) {
      final message = error.response?.data?['error']?['message']?.toString();
      throw StateError(
        message ?? 'No se pudo consultar YouTube: ${error.message}',
      );
    }
  }

  String? _thumbnail(Object? thumbnails) {
    if (thumbnails is! Map) return null;
    for (final name in <String>['medium', 'high', 'default']) {
      final item = thumbnails[name];
      final url = item is Map ? item['url']?.toString() : null;
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }
}
