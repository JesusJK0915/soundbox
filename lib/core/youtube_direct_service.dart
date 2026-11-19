import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'library_service.dart';
import 'models.dart';
import 'youtube_service.dart';

/// Descarga el stream de audio de un video de YouTube sin API key.
/// Es el equivalente a yt-dlp dentro de la app: no usa la API oficial y
/// depende de que YouTube no cambie su funcionamiento.
class YouTubeDirectService {
  YouTubeDirectService(this._library);

  final LibraryService _library;

  /// Descarga el audio a un archivo temporal y devuelve una pista lista para
  /// que DownloadService aplique la conversion elegida y la añada a la biblioteca.
  Future<Track> prepare(String url) async {
    final id = YouTubeService.videoId(url);
    if (id == null) throw ArgumentError('No es un link de YouTube valido');

    final yt = YoutubeExplode();
    try {
      final video = await yt.videos.get(id);
      final manifest = await yt.videos.streams.getManifest(id);
      if (manifest.audioOnly.isEmpty) {
        throw StateError('El video no tiene stream de audio disponible');
      }

      final streamInfo = manifest.audioOnly.withHighestBitrate();
      final extension = extensionFor(streamInfo.container.name);
      final path = p.join(
        _library.downloadDir.path,
        'yt_${id}_${DateTime.now().microsecondsSinceEpoch}$extension',
      );
      final file = File(path);
      await file.parent.create(recursive: true);

      final sink = file.openWrite();
      try {
        await yt.videos.streams.get(streamInfo).pipe(sink);
      } finally {
        await sink.close();
      }

      return Track(
        id: 'yt:$id:${file.path}',
        title: video.title,
        artist: video.author,
        sourceUrl: file.path,
        isLocal: true,
        format: extension.replaceFirst('.', ''),
        license: 'Descarga directa de YouTube · uso responsable',
        source: 'YouTube (directo)',
      );
    } finally {
      yt.close();
    }
  }

  /// YouTube entrega el audio en MP4 (AAC) o WebM (Opus). Mapeamos a la
  /// extension real para que FFmpeg detecte el contenido correctamente.
  static String extensionFor(String container) {
    switch (container.toLowerCase()) {
      case 'mp4':
      case 'm4a':
        return '.m4a';
      case 'webm':
        return '.webm';
      case 'ogg':
        return '.ogg';
      case 'mp3':
        return '.mp3';
      default:
        return '.m4a';
    }
  }
}
