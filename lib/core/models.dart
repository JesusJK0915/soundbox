import 'package:dio/dio.dart';

enum DownloadStatus {
  queued,
  downloading,
  converting,
  paused,
  done,
  failed,
  canceled,
}

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

  /// Carátula extraída de las etiquetas del archivo (ruta local).
  final String? artworkPath;
  final String? albumArtist;
  final int? year;
  final String? genre;
  final int? trackNumber;
  final int? trackTotal;
  final int? discNumber;
  /// Bitrate leido de las etiquetas, en bits por segundo.
  final int? bitrateBps;
  final int? sampleRate;
  final Map<String, String>? extraTags;
  final bool tagsRead;

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
    this.artworkPath,
    this.albumArtist,
    this.year,
    this.genre,
    this.trackNumber,
    this.trackTotal,
    this.discNumber,
    this.bitrateBps,
    this.sampleRate,
    this.extraTags,
    this.tagsRead = false,
  });

  bool get isSubtitle {
    final f = (format ?? '').toLowerCase();
    return ['srt', 'vtt'].contains(f);
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? artworkUrl,
    String? artworkPath,
    String? sourceUrl,
    bool? isLocal,
    String? format,
    int? durationMs,
    String? license,
    String? subtitlePath,
    bool? downloaded,
    String? source,
    String? albumArtist,
    int? year,
    String? genre,
    int? trackNumber,
    int? trackTotal,
    int? discNumber,
    int? bitrateBps,
    int? sampleRate,
    Map<String, String>? extraTags,
    bool? tagsRead,
  }) =>
      Track(
        id: id ?? this.id,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        album: album ?? this.album,
        artworkUrl: artworkUrl ?? this.artworkUrl,
        artworkPath: artworkPath ?? this.artworkPath,
        sourceUrl: sourceUrl ?? this.sourceUrl,
        isLocal: isLocal ?? this.isLocal,
        format: format ?? this.format,
        durationMs: durationMs ?? this.durationMs,
        license: license ?? this.license,
        subtitlePath: subtitlePath ?? this.subtitlePath,
        downloaded: downloaded ?? this.downloaded,
        source: source ?? this.source,
        albumArtist: albumArtist ?? this.albumArtist,
        year: year ?? this.year,
        genre: genre ?? this.genre,
        trackNumber: trackNumber ?? this.trackNumber,
        trackTotal: trackTotal ?? this.trackTotal,
        discNumber: discNumber ?? this.discNumber,
        bitrateBps: bitrateBps ?? this.bitrateBps,
        sampleRate: sampleRate ?? this.sampleRate,
        extraTags: extraTags ?? this.extraTags,
        tagsRead: tagsRead ?? this.tagsRead,
      );

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
        'artworkPath': artworkPath,
        'albumArtist': albumArtist,
        'year': year,
        'genre': genre,
        'trackNumber': trackNumber,
        'trackTotal': trackTotal,
        'discNumber': discNumber,
        'bitrateBps': bitrateBps,
        'sampleRate': sampleRate,
        'extraTags': extraTags,
        'tagsRead': tagsRead,
      };

  static Map<String, String>? _readExtraTags(Object? value) {
    if (value is! Map) return null;
    return value.map(
      (key, dynamicValue) => MapEntry<String, String>(
        key.toString(),
        dynamicValue.toString(),
      ),
    );
  }

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
        artworkPath: json['artworkPath'] as String?,
        albumArtist: json['albumArtist'] as String?,
        year: json['year'] as int?,
        genre: json['genre'] as String?,
        trackNumber: json['trackNumber'] as int?,
        trackTotal: json['trackTotal'] as int?,
        discNumber: json['discNumber'] as int?,
        bitrateBps: json['bitrateBps'] as int?,
        sampleRate: json['sampleRate'] as int?,
        extraTags: _readExtraTags(json['extraTags']),
        tagsRead: json['tagsRead'] as bool? ?? false,
      );
}

class DownloadTask {
  final String id;
  final String title;
  final String url;
  String savePath;
  final Track track;
  final CancelToken cancelToken;
  DownloadStatus status;
  double progress;
  String? errorMessage;
  String? note;

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
    this.note,
  });
}
