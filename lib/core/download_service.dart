import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_audio/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'download_settings.dart';
import 'library_service.dart';
import 'models.dart';

class DownloadService extends ChangeNotifier {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  final LibraryService _library;
  final DownloadSettingsService _settings;

  final List<DownloadTask> _tasks = <DownloadTask>[];

  DownloadService(this._library, this._settings);

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  bool isDownloading(String id) => _tasks.any(
        (t) =>
            t.id == id &&
            (t.status == DownloadStatus.downloading ||
                t.status == DownloadStatus.queued ||
                t.status == DownloadStatus.converting),
      );

  Future<void> start(Track track) async {
    if (isDownloading(track.id)) return;
    if (_isVideoFormat(track.format)) return;

    final extension = _extensionFor(track);
    final safeName = _safeName(track.title);
    final savePath = p.join(_library.downloadDir.path, '$safeName$extension');

    final task = DownloadTask(
      id: track.id,
      title: track.title,
      url: track.sourceUrl,
      savePath: savePath,
      track: track,
      cancelToken: CancelToken(),
    );
    _tasks.insert(0, task);
    notifyListeners();

    await _run(task, track, safeName);
  }

  void pause(DownloadTask task) {
    if (task.status != DownloadStatus.downloading) return;
    task.cancelToken.cancel('paused');
    task.status = DownloadStatus.paused;
    notifyListeners();
  }

  void cancel(DownloadTask task) {
    task.cancelToken.cancel('cancelled');
    if (task.status == DownloadStatus.converting) {
      unawaited(FFmpegKit.cancel());
    }
    task.status = DownloadStatus.canceled;
    notifyListeners();
    _deleteIfExists(task.savePath);
  }

  Future<void> _run(DownloadTask task, Track track, String safeName) async {
    task.status = DownloadStatus.downloading;
    notifyListeners();

    try {
      final file = File(task.savePath);
      await file.parent.create(recursive: true);

      final existing = file.existsSync() ? file.lengthSync() : 0;
      final headers = <String, dynamic>{};
      if (existing > 0) headers['Range'] = 'bytes=$existing-';

      final response = await _dio.get<ResponseBody>(
        task.url,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
        ),
        cancelToken: task.cancelToken,
      );

      final isPartial = response.statusCode == 206;
      final lengthHeader =
          response.headers.value(HttpHeaders.contentLengthHeader);
      final remaining = lengthHeader == null ? 0 : int.tryParse(lengthHeader) ?? 0;
      final total = isPartial ? existing + remaining : remaining;

      final sink = file.openWrite(
        mode: isPartial && existing > 0 ? FileMode.append : FileMode.write,
      );
      var received = isPartial ? existing : 0;

      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        task.progress =
            total > 0 ? (received / total).clamp(0.0, 1.0).toDouble() : 0;
        notifyListeners();
      }
      await sink.close();

      task.progress = 1;
      notifyListeners();

      await _finish(task, track, safeName);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        // El estado ya fue actualizado por pause()/cancel().
        return;
      }
      task.status = DownloadStatus.failed;
      task.errorMessage = error.message;
      notifyListeners();
    } catch (error) {
      task.status = DownloadStatus.failed;
      task.errorMessage = error.toString();
      notifyListeners();
    }
  }

  /// Convierte el archivo descargado al formato/bitrate elegido en Ajustes.
  Future<void> _finish(DownloadTask task, Track track, String safeName) async {
    final sourcePath = task.savePath;
    final sourceExt = p.extension(sourcePath).toLowerCase();
    final targetExt = _settings.extension;
    final targetFormat = _settings.format;

    final needsConversion = targetFormat != AudioFormat.original &&
        (sourceExt != targetExt || _settings.isLossy);

    var finalPath = sourcePath;
    var converted = false;

    if (needsConversion) {
      task.status = DownloadStatus.converting;
      notifyListeners();

      final outputPath = sourceExt == targetExt
          ? p.join(
              _library.downloadDir.path,
              '${safeName}_${_settings.bitrate}$targetExt',
            )
          : p.join(_library.downloadDir.path, '$safeName$targetExt');

      final arguments = DownloadSettingsService.argumentsFor(
        input: sourcePath,
        output: outputPath,
        format: targetFormat,
        bitrate: _settings.bitrate,
      );

      try {
        final session = await FFmpegKit.executeWithArguments(arguments);
        final code = await session.getReturnCode();
        if (!ReturnCode.isSuccess(code)) {
          throw StateError('FFmpeg devolvio ${code?.getValue()}');
        }
        if (!await File(outputPath).exists()) {
          throw StateError('No se genero el archivo convertido');
        }
        finalPath = outputPath;
        converted = true;
        _deleteIfExists(sourcePath);
      } catch (error) {
        task.errorMessage =
            'No se pudo convertir ($error). Se guardo el archivo original.';
        _deleteIfExists(outputPath);
      }
    }

    task.savePath = finalPath;
    await _library.addDownloadedFile(
      sourcePath: finalPath,
      title: track.title,
      artist: track.artist,
      license: track.license,
      artworkUrl: track.artworkUrl,
    );

    if (converted) {
      final quality = _settings.isLossy ? ' ${_settings.bitrate} kbps' : '';
      task.note = 'Convertido a ${_settings.label}$quality';
    }
    task.status = DownloadStatus.done;
    notifyListeners();
  }

  void _deleteIfExists(String path) {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }

  String _safeName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\w\- ]+'), '').trim();
    return cleaned.isEmpty ? 'pista' : cleaned;
  }

  bool _isVideoFormat(String? format) {
    final value = (format ?? '').replaceFirst('.', '').toLowerCase();
    return ['mp4', 'mkv', 'webm', 'mov', 'avi', 'm4v', 'video']
        .contains(value);
  }

  String _extensionFor(Track track) {
    final format = (track.format ?? '').replaceFirst('.', '').toLowerCase();
    if (format.isEmpty) return '.mp3';
    if (['mp3', 'ogg', 'm4a', 'flac', 'wav', 'aac', 'opus']
        .contains(format)) {
      return '.$format';
    }
    return '.mp3';
  }
}
