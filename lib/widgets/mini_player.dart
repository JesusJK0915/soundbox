import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/player_theme.dart';
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
        final scheme = playerSchemeFor(context, track);

        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
          child: Material(
            color: scheme.secondaryContainer.withOpacity(0.72),
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlayerScreen(),
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    color: scheme.primary,
                    backgroundColor: scheme.secondaryContainer,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Row(
                      children: [
                        Hero(
                          tag: playerArtHeroTag(track),
                          child: CircleAvatar(
                            radius: 23,
                            backgroundColor: scheme.primary,
                            child: Icon(
                              Icons.music_note_rounded,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: scheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: scheme.onSecondaryContainer
                                      .withOpacity(0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip:
                              player.isPlaying ? 'Pausar' : 'Reproducir',
                          style: IconButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            minimumSize: const Size(44, 44),
                            shape: const StadiumBorder(),
                          ),
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOutBack,
                            child: Icon(
                              player.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              key: ValueKey<bool>(player.isPlaying),
                            ),
                          ),
                          onPressed: () => player.isPlaying
                              ? player.pause()
                              : player.play(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
