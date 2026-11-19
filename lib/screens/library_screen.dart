import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/export_service.dart';
import '../core/library_service.dart';
import '../core/models.dart';
import '../player/player_service.dart';
import '../widgets/track_artwork.dart';
import '../widgets/track_details_sheet.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryService>(
      builder: (context, library, _) {
        final tracks = library.playableTracks;
        if (tracks.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Importa tu musica para empezar.\n'
                'Todo se guarda en este dispositivo.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: tracks.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final track = tracks[index];
            return ListTile(
              leading: ClipOval(
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: TrackArtwork(track: track, iconSize: 20),
                ),
              ),
              title: Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                [
                  track.artist,
                  if (track.album != null && track.album!.isNotEmpty)
                    track.album!,
                  if (track.subtitlePath != null) 'SUB',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () =>
                  context.read<PlayerService>().setQueue(tracks, index: index),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'remove') {
                    await library.remove(track.id);
                    return;
                  }
                  if (value == 'subtitle') {
                    final path = await library.pickSubtitlePath();
                    if (path != null) {
                      await library.attachSubtitle(track.id, path);
                    }
                    return;
                  }
                  if (value == 'details') {
                    await showTrackDetails(context, track);
                    return;
                  }
                  if (value == 'export') {
                    await _saveTrack(context, track);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'details', child: Text('Ver metadatos')),
                  PopupMenuItem(
                    value: 'export',
                    child: Text('Guardar en otro lugar'),
                  ),
                  PopupMenuItem(value: 'subtitle', child: Text('Adjuntar SUB')),
                  PopupMenuItem(value: 'remove', child: Text('Eliminar')),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> _saveTrack(BuildContext context, Track track) async {
  try {
    final saved = await context.read<ExportService>().saveFile(track);
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
