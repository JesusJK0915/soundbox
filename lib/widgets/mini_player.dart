import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../player/player_service.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (context, player, _) {
        final track = player.currentTrack;
        if (track == null) return const SizedBox.shrink();

        final duration = player.duration;
        final progress = duration == null || duration.inMicroseconds == 0
            ? 0.0
            : (player.position.inMicroseconds / duration.inMicroseconds)
                .clamp(0.0, 1.0)
                .toDouble();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: progress, minHeight: 2),
            ListTile(
              dense: true,
              leading: CircleAvatar(
                child: const Icon(Icons.audiotrack),
              ),
              title: Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () =>
                    player.isPlaying ? player.pause() : player.play(),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlayerScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
