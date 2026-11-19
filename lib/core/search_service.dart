import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'config.dart';
import 'models.dart';

class SearchService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  Future<List<Track>> search(String query, {int limit = 20}) async {
    final term = query.trim();
    if (term.isEmpty) return const <Track>[];

    final results = <Track>[];
    try {
      results.addAll(await _searchInternetArchive(term, limit));
    } catch (_) {}

    if (jamendoClientId.isNotEmpty) {
      try {
        results.addAll(await _searchJamendo(term, limit));
      } catch (_) {}
    }

    return results;
  }

  Future<List<Track>> _searchInternetArchive(String query, int limit) async {
    final encodedQuery = Uri.encodeQueryComponent('mediatype:audio AND ($query)');
    final fields = ['identifier', 'title', 'creator']
        .map((f) => 'fl[]=${Uri.encodeQueryComponent(f)}')
        .join('&');
    final url =
        'https://archive.org/advancedsearch.php?q=$encodedQuery&$fields'
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
    const audioExtensions = ['.mp3', '.ogg', '.m4a', '.flac', '.wav'];
    for (final file in files) {
      if (file is! Map) continue;
      final name = file['name']?.toString() ?? '';
      final extension = p.extension(name).toLowerCase();
      if (audioExtensions.contains(extension)) {
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
        ? creators.map((c) => c.toString()).join(', ')
        : (creators?.toString() ?? 'Desconocido');

    return Track(
      id: 'ia:$identifier:$fileName',
      title: doc['title']?.toString() ?? p.basenameWithoutExtension(fileName),
      artist: artist,
      sourceUrl:
          'https://archive.org/download/$encodedId/$encodedFile',
      isLocal: false,
      format: p.extension(fileName).replaceFirst('.', '').toLowerCase(),
      artworkUrl: 'https://archive.org/services/img/$encodedId',
      license: metadata is Map ? metadata['licenseurl']?.toString() : null,
    );
  }

  Future<List<Track>> _searchJamendo(String query, int limit) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url =
        'https://api.jamendo.com/v3.0/tracks/?client_id=$jamendoClientId'
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
      );
    }).where((track) => track.sourceUrl.isNotEmpty).toList();
  }
}
