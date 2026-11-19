import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'models.dart';
import 'providers.dart';

class SearchService {
  SearchService(this._settings);

  final ProviderSettingsService _settings;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  static const List<String> _audioExtensions = [
    '.mp3',
    '.ogg',
    '.m4a',
    '.flac',
    '.wav',
    '.aac',
    '.opus',
  ];
  /// Busca audio en todos los proveedores activos. Si el texto es una URL
  /// directa a un archivo de audio, la añade sin consultar ningun servicio.
  Future<List<Track>> search(String query, {int limit = 20}) async {
    final term = query.trim();
    if (term.isEmpty) return const <Track>[];

    if (term.startsWith('http://') || term.startsWith('https://')) {
      final direct = trackFromDirectUrl(term);
      return direct == null ? const <Track>[] : <Track>[direct];
    }

    final providers = _settings.activeSearchProviders;
    if (providers.isEmpty) return const <Track>[];

    final lists = await Future.wait(
      providers.map((kind) => _searchProvider(kind, term, limit)),
    );

    final seen = <String>{};
    final results = <Track>[];
    for (final list in lists) {
      for (final track in list) {
        final key = track.sourceUrl.toLowerCase();
        if (key.isEmpty || !seen.add(key)) continue;
        results.add(track);
        if (results.length >= limit) return results;
      }
    }
    return results;
  }

  Future<List<Track>> _searchProvider(
    ProviderKind kind,
    String query,
    int limit,
  ) async {
    try {
      switch (kind) {
        case ProviderKind.internetArchive:
          return await _searchInternetArchive(query, limit);
        case ProviderKind.wikimedia:
          return await _searchWikimedia(query, limit);
        case ProviderKind.jamendo:
          return await _searchJamendo(query, limit);
        case ProviderKind.soundCloud:
          return await _searchSoundCloud(query, limit);
        case ProviderKind.pixabay:
          return await _searchPixabay(query, limit);
        case ProviderKind.directUrl:
          return const <Track>[];
      }
    } catch (_) {
      return const <Track>[];
    }
  }

  /// Convierte una URL a un archivo de audio en una pista descargable.
  Track? trackFromDirectUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    final fileName = p.basename(uri.path);
    final extension = p.extension(fileName).toLowerCase();
    if (!_audioExtensions.contains(extension)) return null;
    return Track(
      id: 'url:$url',
      title: p.basenameWithoutExtension(fileName),
      artist: 'URL directa',
      sourceUrl: url,
      format: extension.replaceFirst('.', ''),
      license: 'Proporcionado por el usuario',
      source: 'URL directa',
    );
  }

  Future<List<Track>> _searchInternetArchive(String query, int limit) async {
    final encodedQuery =
        Uri.encodeQueryComponent('mediatype:audio AND ($query)');
    final fields = ['identifier', 'title', 'creator']
        .map((field) => 'fl[]=${Uri.encodeQueryComponent(field)}')
        .join('&');
    final url = 'https://archive.org/advancedsearch.php?q=$encodedQuery&$fields'
        '&rows=$limit&page=1&output=json';

    final response = await _dio.get<Map<String, dynamic>>(url);
    final data = response.data;
    if (data == null) return const <Track>[];

    final responseBlock = data['response'];
    if (responseBlock is! Map) return const <Track>[];
    final docs = responseBlock['docs'];
    if (docs is! List) return const <Track>[];

    final futures = docs.whereType<Map>().map(
          (doc) => _trackFromArchiveDoc(doc),
        );
    final tracks = await Future.wait(futures);
    return tracks.whereType<Track>().toList();
  }

  Future<Track?> _trackFromArchiveDoc(Map<dynamic, dynamic> doc) async {
    final identifier = doc['identifier']?.toString();
    if (identifier == null || identifier.isEmpty) return null;

    final metadataResponse = await _dio.get<Map<String, dynamic>>(
      'https://archive.org/metadata/${Uri.encodeComponent(identifier)}',
    );
    final metadataBody = metadataResponse.data;
    if (metadataBody == null) return null;
    final metadata = metadataBody['metadata'];
    final files = metadataBody['files'];
    if (files is! List) return null;

    Map<dynamic, dynamic>? audioFile;
    for (final file in files) {
      if (file is! Map) continue;
      final name = file['name']?.toString() ?? '';
      final extension = p.extension(name).toLowerCase();
      if (_audioExtensions.contains(extension)) {
        audioFile = file;
        if (extension == '.mp3') break;
      }
    }

    if (audioFile == null) return null;
    final fileName = audioFile['name'].toString();
    final encodedId = Uri.encodeComponent(identifier);
    final encodedFile = Uri.encodeComponent(fileName);

    final creators = doc['creator'];
    final artist = creators is List
        ? creators.map((creator) => creator.toString()).join(', ')
        : (creators?.toString() ?? 'Desconocido');

    return Track(
      id: 'ia:$identifier:$fileName',
      title: doc['title']?.toString() ?? p.basenameWithoutExtension(fileName),
      artist: artist,
      sourceUrl: 'https://archive.org/download/$encodedId/$encodedFile',
      isLocal: false,
      format: p.extension(fileName).replaceFirst('.', '').toLowerCase(),
      artworkUrl: 'https://archive.org/services/img/$encodedId',
      license: metadata is Map ? metadata['licenseurl']?.toString() : null,
      source: 'Internet Archive',
    );
  }

  Future<List<Track>> _searchWikimedia(String query, int limit) async {
    final searchTerm = Uri.encodeQueryComponent('$query filetype:audio');
    final url = 'https://commons.wikimedia.org/w/api.php?'
        'action=query&format=json&generator=search'
        '&gsrsearch=$searchTerm&gsrnamespace=6&gsrlimit=$limit'
        '&prop=imageinfo&iiprop=url|mime|extmetadata&iiurlwidth=320';

    final response = await _dio.get<Map<String, dynamic>>(url);
    final data = response.data;
    if (data == null) return const <Track>[];

    final queryBlock = data['query'];
    if (queryBlock is! Map) return const <Track>[];
    final pages = queryBlock['pages'];
    if (pages is! Map) return const <Track>[];

    final tracks = <Track>[];
    for (final value in pages.values) {
      if (value is! Map) continue;
      final infoList = value['imageinfo'];
      if (infoList is! List || infoList.isEmpty) continue;
      final info = infoList.first;
      if (info is! Map) continue;

      final sourceUrl = info['url']?.toString() ?? '';
      if (sourceUrl.isEmpty) continue;
      final format = _formatFromMime(info['mime']?.toString() ?? '', sourceUrl);
      if (format == null) continue;

      final title = (value['title']?.toString() ?? '')
          .replaceFirst(RegExp(r'^File:'), '');
      var artist = 'Desconocido';
      String? license;
      final metadata = info['extmetadata'];
      if (metadata is Map) {
        final artistData = metadata['Artist'];
        if (artistData is Map) {
          final extracted = _stripHtml(artistData['value']?.toString());
          if (extracted.isNotEmpty) artist = extracted;
        }
        final licenseData = metadata['LicenseShortName'];
        if (licenseData is Map) {
          license = licenseData['value']?.toString();
        }
      }

      tracks.add(
        Track(
          id: 'wm:${value['pageid'] ?? title}',
          title: title,
          artist: artist,
          sourceUrl: sourceUrl,
          format: format,
          license: license,
          artworkUrl: info['thumburl']?.toString(),
          source: 'Wikimedia',
        ),
      );
    }
    return tracks;
  }

  Future<List<Track>> _searchJamendo(String query, int limit) async {
    final key = _settings.key(ProviderKind.jamendo);
    final encodedQuery = Uri.encodeComponent(query);
    final url = 'https://api.jamendo.com/v3.0/tracks/?client_id=$key'
        '&format=json&limit=$limit&search=$encodedQuery';

    final response = await _dio.get<Map<String, dynamic>>(url);
    final data = response.data;
    if (data == null) return const <Track>[];
    final results = data['results'];
    if (results is! List) return const <Track>[];

    return results.whereType<Map>().map((item) {
      return Track(
        id: 'jamendo:${item['id']}',
        title: item['name']?.toString() ?? 'Sin titulo',
        artist: item['artist_name']?.toString() ?? 'Desconocido',
        sourceUrl: item['audio']?.toString() ?? '',
        artworkUrl: item['album_image']?.toString(),
        isLocal: false,
        format: 'mp3',
        license: item['license']?.toString(),
        source: 'Jamendo',
      );
    }).where((track) => track.sourceUrl.isNotEmpty).toList();
  }

  Future<List<Track>> _searchSoundCloud(String query, int limit) async {
    final key = _settings.key(ProviderKind.soundCloud);
    final encodedQuery = Uri.encodeQueryComponent(query);
    final url = 'https://api-v2.soundcloud.com/search/tracks?'
        'q=$encodedQuery&limit=$limit'
        '&client_id=${Uri.encodeQueryComponent(key)}';

    final response = await _dio.get<Map<String, dynamic>>(url);
    final data = response.data;
    if (data == null) return const <Track>[];
    final collection = data['collection'];
    if (collection is! List) return const <Track>[];

    final tracks = <Track>[];
    for (final item in collection) {
      if (item is! Map) continue;
      if (item['downloadable'] != true) continue;
      final sourceUrl = item['download_url']?.toString() ?? '';
      if (sourceUrl.isEmpty) continue;
      final mime = item['content_type']?.toString() ?? '';
      if (mime.startsWith('video/')) continue;

      tracks.add(
        Track(
          id: 'sc:${item['id']}',
          title: item['title']?.toString() ?? 'Sin titulo',
          artist: item['user'] is Map
              ? (item['user'] as Map)['username']?.toString() ?? 'Desconocido'
              : 'Desconocido',
          sourceUrl: sourceUrl,
          artworkUrl: item['artwork_url']?.toString(),
          format: _formatFromMime(
                item['content_type']?.toString() ?? '',
                sourceUrl,
              ) ??
              'mp3',
          license: 'Descarga autorizada por el autor',
          source: 'SoundCloud',
        ),
      );
    }
    return tracks;
  }

  Future<List<Track>> _searchPixabay(String query, int limit) async {
    final key = _settings.key(ProviderKind.pixabay);
    final encodedQuery = Uri.encodeQueryComponent(query);
    final url = 'https://pixabay.com/api/?'
        'key=${Uri.encodeQueryComponent(key)}'
        '&q=$encodedQuery&audio_type=music&per_page=$limit';

    final response = await _dio.get<Map<String, dynamic>>(url);
    final data = response.data;
    if (data == null) return const <Track>[];
    final hits = data['hits'];
    if (hits is! List) return const <Track>[];

    final tracks = <Track>[];
    for (final item in hits) {
      if (item is! Map) continue;
      final rawUrl = item['download_url'] ??
          item['url'] ??
          item['audio'] ??
          item['previewURL'];
      final sourceUrl = rawUrl?.toString() ?? '';
      if (sourceUrl.isEmpty) continue;
      final extension = p.extension(Uri.tryParse(sourceUrl)?.path ?? '')
          .toLowerCase();
      if (!_audioExtensions.contains(extension)) continue;

      tracks.add(
        Track(
          id: 'px:${item['id']}',
          title: item['title']?.toString() ??
              item['name']?.toString() ??
              'Sin titulo',
          artist: item['user']?.toString() ?? 'Pixabay',
          sourceUrl: sourceUrl,
          format: extension.replaceFirst('.', ''),
          artworkUrl: item['thumbnail']?.toString(),
          license: item['license']?.toString() ??
              'Pixabay Content License',
          source: 'Pixabay',
        ),
      );
    }
    return tracks;
  }

  String? _formatFromMime(String mime, String url) {
    final extension = p.extension(Uri.tryParse(url)?.path ?? '').toLowerCase();
    if (_audioExtensions.contains(extension)) {
      return extension.replaceFirst('.', '');
    }
    if (mime.startsWith('audio/')) {
      return mime.split('/').last.split(';').first.trim();
    }
    return null;
  }

  String _stripHtml(String? text) {
    if (text == null || text.isEmpty) return '';
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .trim();
  }
}
