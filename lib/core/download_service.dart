import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

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

  final List<DownloadTask> _tasks = <DownloadTask>[];

  DownloadService(this._library);

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  bool isDownloading(String id) => _tasks.any(
        (t) =>
            t.id == id &&
            (t.status == DownloadStatus.downloading ||
                t.status == DownloadStatus.queued),
      );

  Future<void> start(Track track) async {
    if (isDownloading(track.id)) return;

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

    await _run(task, track);
  }

  void pause(DownloadTask task) {
    if (task.status != DownloadStatus.downloading) return;
    task.cancelToken.cancel('paused');
    task.status = DownloadStatus.paused;
    notifyListeners();
  }

  void cancel(DownloadTask task) {
    task.cancelToken.cancel('cancelled');
    task.status = DownloadStatus.canceled;
    notifyListeners();
    final file = File(task.savePath);
    if (file.existsSync()) file.deleteSync();
  }

  Future<void> _run(DownloadTask task, Track track) async {
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
      final lengthHeader = response.headers.value(HttpHeaders.contentLengthHeader);
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
      task.status = DownloadStatus.done;
      notifyListeners();

      await _library.addDownloadedFile(
        sourcePath: task.savePath,
        title: track.title,
        artist: track.artist,
        license: track.license,
        artworkUrl: track.artworkUrl,
      );
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

  String _safeName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\w\- ]+'), '').trim();
    return cleaned.isEmpty ? 'pista' : cleaned;
  }

  String _extensionFor(Track track) {
    final format = (track.format ?? '').replaceFirst('.', '').toLowerCase();
    if (format.isEmpty) return '.mp3';
    if (['mp3', 'ogg', 'm4a', 'flac', 'wav', 'mp4', 'webm', 'mkv']
        .contains(format)) {
      return '.$format';
    }
    return '.mp3';
  }
}
