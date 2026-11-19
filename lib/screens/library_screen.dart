import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/library_service.dart';
import '../player/player_service.dart';

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
              leading: const CircleAvatar(child: Icon(Icons.audiotrack)),
              title: Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${track.artist}${track.subtitlePath != null ? ' · SUB' : ''}',
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
                  }
                },
                itemBuilder: (context) => const [
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
