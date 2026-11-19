import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/download_service.dart';
import '../core/export_service.dart';
import '../core/library_service.dart';
import '../core/models.dart';
import '../player/player_service.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadService>(
      builder: (context, downloads, _) {
        if (downloads.tasks.isEmpty) {
          return const Center(child: Text('No hay descargas todavia.'));
        }

        return ListView.separated(
          itemCount: downloads.tasks.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final task = downloads.tasks[index];
            return ListTile(
              title: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_statusLabel(task.status)),
                  LinearProgressIndicator(value: task.progress),
                  if (task.errorMessage != null)
                    Text(
                      task.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (task.status == DownloadStatus.downloading)
                    IconButton(
                      icon: const Icon(Icons.pause),
                      onPressed: () => downloads.pause(task),
                    ),
                  if (task.status == DownloadStatus.paused ||
                      task.status == DownloadStatus.failed)
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () => downloads.start(task.track),
                    ),
                  if (task.status == DownloadStatus.done)
                    IconButton(
                      icon: const Icon(Icons.save_alt),
                      tooltip: 'Guardar en otro lugar',
                      onPressed: () => _saveTrack(context, task),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => downloads.cancel(task),
                  ),
                ],
              ),
              onTap: () async {
                if (task.status != DownloadStatus.done) return;
                final library = context.read<LibraryService>();
                final local = library.tracks.cast<Track?>().firstWhere(
                      (track) => track?.sourceUrl == task.savePath,
                      orElse: () => null,
                    );
                if (local == null) return;
                await context
                    .read<PlayerService>()
                    .setQueue(library.playableTracks, index: 0);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _saveTrack(BuildContext context, DownloadTask task) async {
    final library = context.read<LibraryService>();
    Track? local;
    for (final item in library.tracks) {
      if (item.sourceUrl == task.savePath) {
        local = item;
        break;
      }
    }
    if (local == null) return;

    try {
      final saved = await context.read<ExportService>().saveFile(local);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved == null ? 'Guardado cancelado' : 'Cancion guardada'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
    }
  }

  String _statusLabel(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.queued:
        return 'En cola';
      case DownloadStatus.downloading:
        return 'Descargando';
      case DownloadStatus.paused:
        return 'Pausada';
      case DownloadStatus.done:
        return 'Completada';
      case DownloadStatus.failed:
        return 'Fallida';
      case DownloadStatus.canceled:
        return 'Cancelada';
    }
  }
}
