import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/player_theme.dart';
import '../core/user_preferences.dart';
import '../player/player_service.dart';
import '../screens/player_screen.dart';
import 'track_artwork.dart';

/// Mini reproductor fijo encima de la barra de navegación.
/// Sin animaciones ni posiciones flotantes: siempre ocupa su propio espacio.
class FloatingDock extends StatelessWidget {
  const FloatingDock({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserPreferencesService, PlayerService>(
      builder: (context, prefs, player, _) {
        final track = player.currentTrack;
        if (!prefs.dockVisible || track == null) {
          return const SizedBox.shrink();
        }

        final scheme = playerSchemeFor(context, track);
        final isFavorite = prefs.isFavorite(track.id);

        return Container(
          color: scheme.surface,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Material(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                if (prefs.haptics) HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlayerScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: TrackArtwork(track: track, iconSize: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSecondaryContainer,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: isFavorite
                          ? 'Quitar de favoritos'
                          : 'Añadir a favoritos',
                      visualDensity: VisualDensity.compact,
                      color: isFavorite
                          ? scheme.primary
                          : scheme.onSecondaryContainer,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                      ),
                      onPressed: () => prefs.toggleFavorite(track.id),
                    ),
                    IconButton(
                      tooltip: player.isPlaying ? 'Pausar' : 'Reproducir',
                      visualDensity: VisualDensity.compact,
                      color: scheme.onSecondaryContainer,
                      icon: Icon(
                        player.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      onPressed: () => player.isPlaying
                          ? player.pause()
                          : player.play(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
