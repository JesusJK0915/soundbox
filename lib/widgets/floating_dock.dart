import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/player_theme.dart';
import '../core/user_preferences.dart';
import '../player/player_service.dart';
import '../screens/player_screen.dart';
import 'track_artwork.dart';

/// Mini reproductor flotante: se puede arrastrar, se acopla arriba o abajo y
/// recuerda su posición entre reinicios.
class FloatingDock extends StatefulWidget {
  const FloatingDock({super.key});

  @override
  State<FloatingDock> createState() => _FloatingDockState();
}

class _FloatingDockState extends State<FloatingDock> {
  Offset _drag = Offset.zero;

  double _clamp(double value, double min, double max) =>
      value < min ? min : value > max ? max : value;

  double _max(double a, double b) => a > b ? a : b;

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserPreferencesService, PlayerService>(
      builder: (context, prefs, player, _) {
        final track = player.currentTrack;
        if (!prefs.dockVisible || track == null) {
          return const SizedBox.shrink();
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            const dockHeight = 78.0;
            final dockWidth =
                constraints.maxWidth < 430 ? constraints.maxWidth - 24 : 360.0;

            final centerX = prefs.dockX * constraints.maxWidth + _drag.dx;
            final centerY = prefs.dockY * constraints.maxHeight + _drag.dy;
            final maxLeft = _max(8.0, constraints.maxWidth - dockWidth - 8);
            final maxTop = _max(8.0, constraints.maxHeight - dockHeight - 8);
            final left = _clamp(centerX - dockWidth / 2, 8.0, maxLeft);
            final top = _clamp(centerY - dockHeight / 2, 8.0, maxTop);

            final scheme = playerSchemeFor(context, track);
            final isFavorite = prefs.isFavorite(track.id);

            Future<void> snap() async {
              final snapTop = top > constraints.maxHeight / 2 ? maxTop : 8.0;
              await prefs.setDockOffset(
                (left + dockWidth / 2) / constraints.maxWidth,
                (snapTop + dockHeight / 2) / constraints.maxHeight,
              );
              if (mounted) setState(() => _drag = Offset.zero);
            }

            return AnimatedTheme(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              data: Theme.of(context).copyWith(colorScheme: scheme),
              child: Stack(
              children: [
                AnimatedPositioned(
                  duration: _drag == Offset.zero
                      ? const Duration(milliseconds: 420)
                      : Duration.zero,
                  curve: Curves.easeOutBack,
                  left: left,
                  top: top,
                  width: dockWidth,
                  height: dockHeight,
                  child: Material(
                    color: scheme.secondaryContainer.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(26),
                    elevation: 8,
                    shadowColor: scheme.shadow.withOpacity(0.35),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: () {
                        if (prefs.haptics) {
                          HapticFeedback.lightImpact();
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PlayerScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          GestureDetector(
                            onPanUpdate: (details) {
                              setState(() => _drag += details.delta);
                            },
                            onPanEnd: (_) => snap(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Icon(
                                Icons.drag_indicator,
                                color: scheme.onSecondaryContainer
                                    .withOpacity(0.6),
                              ),
                            ),
                          ),
                          Hero(
                            tag: playerArtHeroTag(track),
                            child: ClipOval(
                              child: SizedBox(
                                width: 46,
                                height: 46,
                                child: TrackArtwork(track: track, iconSize: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                    color: scheme.onSecondaryContainer
                                        .withOpacity(0.72),
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
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                            ),
                            color: isFavorite
                                ? scheme.primary
                                : scheme.onSecondaryContainer,
                            onPressed: () async {
                              await prefs.toggleFavorite(track.id);
                              if (prefs.haptics) {
                                HapticFeedback.selectionClick();
                              }
                            },
                          ),
                          IconButton(
                            tooltip: player.isPlaying ? 'Pausar' : 'Reproducir',
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                              minimumSize: const Size(42, 42),
                              shape: const StadiumBorder(),
                            ),
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
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
                  ),
                ),
              ],
              ),
            );
          },
        );
      },
    );
  }
}
