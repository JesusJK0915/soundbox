import 'package:dio/dio.dart';

enum DownloadStatus { queued, downloading, paused, done, failed, canceled }

class Track {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? artworkUrl;
  final String sourceUrl;
  final bool isLocal;
  final String? format;
  final int? durationMs;
  final String? license;
  final String? subtitlePath;
  final bool downloaded;

  /// Nombre del proveedor de origen (Internet Archive, Wikimedia, etc.).
  final String? source;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.sourceUrl,
    this.album,
    this.artworkUrl,
    this.isLocal = false,
    this.format,
    this.durationMs,
    this.license,
    this.subtitlePath,
    this.downloaded = false,
    this.source,
  });

  bool get isSubtitle {
    final f = (format ?? '').toLowerCase();
    return ['srt', 'vtt'].contains(f);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'artworkUrl': artworkUrl,
        'sourceUrl': sourceUrl,
        'isLocal': isLocal,
        'format': format,
        'durationMs': durationMs,
        'license': license,
        'subtitlePath': subtitlePath,
        'downloaded': downloaded,
        'source': source,
      };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        sourceUrl: json['sourceUrl'] as String,
        album: json['album'] as String?,
        artworkUrl: json['artworkUrl'] as String?,
        isLocal: json['isLocal'] as bool? ?? false,
        format: json['format'] as String?,
        durationMs: json['durationMs'] as int?,
        license: json['license'] as String?,
        subtitlePath: json['subtitlePath'] as String?,
        downloaded: json['downloaded'] as bool? ?? false,
        source: json['source'] as String?,
      );
}

class DownloadTask {
  final String id;
  final String title;
  final String url;
  final String savePath;
  final Track track;
  final CancelToken cancelToken;
  DownloadStatus status;
  double progress;
  String? errorMessage;

  DownloadTask({
    required this.id,
    required this.title,
    required this.url,
    required this.savePath,
    required this.track,
    required this.cancelToken,
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.errorMessage,
  });
}
