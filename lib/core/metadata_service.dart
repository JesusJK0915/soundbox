import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Datos leidos de las etiquetas del archivo. Solo contiene tipos que
/// `compute` puede enviar entre isolates.
class TrackMetadata {
  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? year;
  final String? genre;
  final int? trackNumber;
  final int? trackTotal;
  final int? discNumber;
  final int? durationMs;
  final int? bitrateBps;
  final int? sampleRate;
  final String? artworkPath;
  final Map<String, String> extraTags;

  const TrackMetadata({
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.year,
    this.genre,
    this.trackNumber,
    this.trackTotal,
    this.discNumber,
    this.durationMs,
    this.bitrateBps,
    this.sampleRate,
    this.artworkPath,
    this.extraTags = const <String, String>{},
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'artist': artist,
        'album': album,
        'albumArtist': albumArtist,
        'year': year,
        'genre': genre,
        'trackNumber': trackNumber,
        'trackTotal': trackTotal,
        'discNumber': discNumber,
        'durationMs': durationMs,
        'bitrateBps': bitrateBps,
        'sampleRate': sampleRate,
        'artworkPath': artworkPath,
        'extraTags': extraTags,
      };

  factory TrackMetadata.fromJson(Map<dynamic, dynamic> json) {
    final rawTags = json['extraTags'];
    final tags = <String, String>{};
    if (rawTags is Map) {
      rawTags.forEach((key, value) {
        tags[key.toString()] = value.toString();
      });
    }
    return TrackMetadata(
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      albumArtist: json['albumArtist'] as String?,
      year: json['year'] as int?,
      genre: json['genre'] as String?,
      trackNumber: json['trackNumber'] as int?,
      trackTotal: json['trackTotal'] as int?,
      discNumber: json['discNumber'] as int?,
      durationMs: json['durationMs'] as int?,
      bitrateBps: json['bitrateBps'] as int?,
      sampleRate: json['sampleRate'] as int?,
      artworkPath: json['artworkPath'] as String?,
      extraTags: tags,
    );
  }
}

/// Lee las etiquetas en un isolate para no bloquear la interfaz. La carátula
/// se guarda como archivo en [artworkDir] y solo se devuelve su ruta.
Future<TrackMetadata?> readTrackMetadata({
  required String filePath,
  required String artworkDir,
}) async {
  try {
    final map = await compute<Map<String, dynamic>, Map<dynamic, dynamic>>(
      _readMetadataInIsolate,
      <String, dynamic>{
        'filePath': filePath,
        'artworkDir': artworkDir,
      },
    );
    if (map['ok'] != true) return null;
    return TrackMetadata.fromJson(map);
  } catch (_) {
    return null;
  }
}

Map<String, dynamic> _readMetadataInIsolate(Map<String, dynamic> args) {
  final filePath = args['filePath'] as String;
  final artworkDirPath = args['artworkDir'] as String;
  final file = File(filePath);
  if (!file.existsSync()) return <String, dynamic>{'ok': false};

  final AudioMetadata meta;
  try {
    meta = readMetadata(file, getImage: true);
  } catch (_) {
    return <String, dynamic>{'ok': false};
  }

  final now = DateTime.now().year;
  final rawYear = meta.year?.year;
  final year = rawYear != null && rawYear >= 1900 && rawYear <= now + 1
      ? rawYear
      : null;

  final extra = <String, String>{};
  if (meta.performers.isNotEmpty) {
    extra['Intérpretes'] = meta.performers.join(', ');
  }
  if (meta.language != null && meta.language!.trim().isNotEmpty) {
    extra['Idioma'] = meta.language!.trim();
  }
  if (meta.lyrics != null && meta.lyrics!.trim().isNotEmpty) {
    final lyrics = meta.lyrics!.trim();
    extra['Letra'] = lyrics.length > 500 ? '${lyrics.substring(0, 500)}…' : lyrics;
  }
  if (meta.chapters.isNotEmpty) {
    extra['Capítulos'] = '${meta.chapters.length}';
  }

  final result = <String, dynamic>{
    'ok': true,
    'title': _clean(meta.title),
    'artist': _clean(meta.artist),
    'album': _clean(meta.album),
    'albumArtist': _clean(meta.albumArtist),
    'year': year,
    'genre': _clean(meta.genres.where((g) => g.trim().isNotEmpty).join(', ')),
    'trackNumber': meta.trackNumber,
    'trackTotal': meta.trackTotal,
    'discNumber': meta.discNumber,
    'durationMs': meta.duration?.inMilliseconds,
    'bitrateBps': meta.bitrate,
    'sampleRate': meta.sampleRate,
    'artworkPath': _saveArtwork(meta, file, artworkDirPath),
    'extraTags': extra,
  };
  return result;
}

String? _clean(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String? _saveArtwork(
  AudioMetadata meta,
  File audioFile,
  String artworkDirPath,
) {
  if (meta.pictures.isEmpty) return null;
  Picture? cover;
  for (final picture in meta.pictures) {
    if (picture.pictureType == PictureType.coverFront) {
      cover = picture;
      break;
    }
  }
  cover ??= meta.pictures.first;
  if (cover.bytes.isEmpty) return null;

  final mime = cover.mimetype.toLowerCase();
  final extension = mime.contains('png')
      ? '.png'
      : mime.contains('webp')
          ? '.webp'
          : '.jpg';
  final key = audioFile.path.hashCode.toUnsigned(32).toRadixString(16);
  final dir = Directory(artworkDirPath);
  try {
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final target = File(p.join(dir.path, 'cover_$key$extension'));
    target.writeAsBytesSync(cover.bytes);
    return target.path;
  } catch (_) {
    return null;
  }
}
