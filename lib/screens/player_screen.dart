import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../core/models.dart';
import '../core/player_theme.dart';
import '../core/user_preferences.dart';
import '../player/player_service.dart';
import '../widgets/player_sheets.dart';
import '../widgets/subtitle_overlay.dart';
import '../widgets/track_artwork.dart';
import '../widgets/track_details_sheet.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (context, player, _) {
        final track = player.currentTrack;
        if (track == null) return const _EmptyPlayer();
        final prefs = context.watch<UserPreferencesService>();
        final isFavorite = prefs.isFavorite(track.id);

        final scheme = playerSchemeFor(context, track);
        final duration = player.duration ?? Duration.zero;
        final maxMs = duration.inMilliseconds < 1 ? 1 : duration.inMilliseconds;
        final currentMs = player.position.inMilliseconds.clamp(0, maxMs);

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: scheme,
            scaffoldBackgroundColor: scheme.surface,
          ),
          child: Focus(
            autofocus: true,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.space): () {
                  player.isPlaying ? player.pause() : player.play();
                },
                const SingleActivator(LogicalKeyboardKey.arrowRight): () {
                  player.skipNext();
                },
                const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                  player.skipPrevious();
                },
                const SingleActivator(LogicalKeyboardKey.keyF): () {
                  prefs.toggleFavorite(track.id);
                },
                const SingleActivator(LogicalKeyboardKey.keyL): () {
                  showLyricsSheet(context, track);
                },
              },
              child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  tooltip: 'Volver',
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.secondaryContainer,
                    foregroundColor: scheme.onSecondaryContainer,
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              title: const Text('Suena ahora'),
              actions: [
                IconButton(
                  tooltip: isFavorite
                      ? 'Quitar de favoritos'
                      : 'Añadir a favoritos',
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                  onPressed: () async {
                    await prefs.toggleFavorite(track.id);
                    if (prefs.haptics) HapticFeedback.selectionClick();
                  },
                ),
                IconButton(
                  tooltip: 'Letra',
                  icon: const Icon(Icons.short_text_rounded),
                  onPressed: () => showLyricsSheet(context, track),
                ),
                IconButton(
                  tooltip: 'Detalles de la canción',
                  icon: const Icon(Icons.info_outline_rounded),
                  onPressed: () => showTrackDetails(context, track),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'speed') showSpeedSheet(context);
                    if (value == 'sleep') showSleepSheet(context);
                    if (value == 'lyrics') showLyricsSheet(context, track);
                    if (value == 'next') player.playNext(track);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'speed',
                      child: Text('Velocidad · ${player.speed.toStringAsFixed(2)}×'),
                    ),
                    PopupMenuItem(
                      value: 'sleep',
                      child: Text(
                        player.sleepActive
                            ? 'Temporizador: ${_formatRemaining(player.sleepRemaining)}'
                            : 'Temporizador de sueño',
                      ),
                    ),
                    const PopupMenuItem(value: 'lyrics', child: Text('Letra')),
                    const PopupMenuItem(
                      value: 'next',
                      child: Text('Reproducir de nuevo a continuación'),
                    ),
                  ],
                ),
              ],
            ),
            body: Stack(
              children: [
                _AmbientBackground(
                  scheme: scheme,
                  isPlaying: player.isPlaying,
                ),
                SafeArea(
                  child: _PlayerBody(
                    player: player,
                    prefs: prefs,
                    track: track,
                    currentMs: currentMs,
                    maxMs: maxMs,
                    duration: duration,
                  ),
                ),
                SubtitleOverlay(
                  subtitlePath: track.subtitlePath,
                  position: player.position,
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

/// Cuerpo del reproductor que se adapta al alto real del telefono.
///
/// Los controles quedan siempre centrados y no hace falta deslizar: si la
/// pantalla es baja se ocultan los extras y [FittedBox] escala el contenido.
class _PlayerBody extends StatelessWidget {
  const _PlayerBody({
    required this.player,
    required this.prefs,
    required this.track,
    required this.currentMs,
    required this.maxMs,
    required this.duration,
  });

  final PlayerService player;
  final UserPreferencesService prefs;
  final Track track;
  final int currentMs;
  final int maxMs;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;
        final compact = height < 720;
        final tiny = height < 560;

        final artByWidth =
            (compact ? width * 0.44 : width * 0.54).clamp(120.0, 264.0);
        final artByHeight = height * (tiny ? 0.24 : 0.30);
        final artSize = math.min(artByWidth, artByHeight).toDouble();

        final showChips = !compact;
        final showVolume = height >= 660;
        final showQueue = height >= 840;
        final contentWidth = (width - 32).clamp(260.0, 520.0).toDouble();

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: contentWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DragHandle(prefs: prefs),
                  const SizedBox(height: 6),
                  Center(
                    child: GestureDetector(
                      onDoubleTap: prefs.gestures
                          ? () async {
                              await prefs.toggleFavorite(track.id);
                              if (prefs.haptics) {
                                HapticFeedback.mediumImpact();
                              }
                            }
                          : null,
                      onHorizontalDragEnd: prefs.swipeToSkip
                          ? (details) {
                              final velocity = details.primaryVelocity ?? 0;
                              if (velocity > 400) {
                                player.skipPrevious();
                              } else if (velocity < -400) {
                                player.skipNext();
                              }
                            }
                          : null,
                      child: _HeroArtwork(track: track, size: artSize),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _TrackInfo(track: track),
                  if (showChips) ...[
                    const SizedBox(height: 8),
                    _MetaChips(track: track),
                  ],
                  if (player.speed - 1.0 != 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Chip(
                          avatar: const Icon(Icons.speed, size: 15),
                          label: Text(
                            '${player.speed.toStringAsFixed(2)}×',
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  if (player.sleepActive) _SleepBanner(player: player),
                  const SizedBox(height: 12),
                  _Progress(
                    currentMs: currentMs,
                    maxMs: maxMs,
                    position: player.position,
                    duration: duration,
                    onSeek: player.seek,
                    showWorm: player.isPlaying && prefs.expressiveWorm,
                  ),
                  const SizedBox(height: 12),
                  _Controls(player: player),
                  if (showVolume) ...[
                    const SizedBox(height: 10),
                    _VolumeControl(player: player),
                  ],
                  if (showQueue) ...[
                    const SizedBox(height: 10),
                    _QueuePreview(player: player),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Onda ondulada estilo Material 3 Expressive que aparece al reproducir.
class _ExpressiveWorm extends StatefulWidget {
  const _ExpressiveWorm({required this.color});

  final Color color;

  @override
  State<_ExpressiveWorm> createState() => _ExpressiveWormState();
}

class _ExpressiveWormState extends State<_ExpressiveWorm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _controller.addListener(_onTick);
  }

  void _onTick() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: CustomPaint(
        painter: _WormPainter(phase: _controller.value, color: widget.color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WormPainter extends CustomPainter {
  const _WormPainter({required this.phase, required this.color});

  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = color.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const cycles = 2.6;
    const steps = 72;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = t * size.width;
      final y = size.height / 2 +
          math.sin(t * cycles * math.pi * 2 + phase * math.pi * 2) *
              size.height *
              0.30;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);

    // La cabeza va en el centro del widget, que coincide con el pulgar
    // del Slider. Antes se dibujaba en el extremo derecho y parecia
    // desplazada hacia adelante.
    final headT = 0.5;
    final headY = size.height / 2 +
        math.sin(headT * cycles * math.pi * 2 + phase * math.pi * 2) *
            size.height *
            0.30;
    canvas.drawCircle(
      Offset(size.width * headT, headY),
      4.5,
      Paint()..color = color.withOpacity(0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _WormPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.color != color;
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.prefs});

  final UserPreferencesService prefs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if (!prefs.gestures) return;
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 420 && context.mounted) {
            Navigator.of(context).maybePop();
          }
        },
        child: Container(
          width: 64,
          height: 22,
          alignment: Alignment.center,
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withOpacity(0.45),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _SleepBanner extends StatelessWidget {
  const _SleepBanner({required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.nightlight_round, size: 17, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            'Sueño · ${_formatRemaining(player.sleepRemaining)}',
            style: TextStyle(color: scheme.onTertiaryContainer, fontSize: 12),
          ),
          TextButton(
            onPressed: () => showSleepSheet(context),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }
}

String _formatRemaining(Duration? value) {
  final duration = value ?? Duration.zero;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _EmptyPlayer extends StatelessWidget {
  const _EmptyPlayer();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_note_rounded, size: 84, color: scheme.primary),
              const SizedBox(height: 20),
              Text(
                'No hay pista activa',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Elige una cancion de tu biblioteca para empezar.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.library_music),
                label: const Text('Ir a la biblioteca'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({required this.scheme, required this.isPlaying});

  final ColorScheme scheme;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer,
              scheme.surface,
              scheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -56,
              left: -12,
              child: _Orb(color: scheme.primary.withOpacity(0.18)),
            ),
            Positioned(
              bottom: -80,
              right: -32,
              child: _Orb(color: scheme.tertiary.withOpacity(0.16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork({required this.track, this.size = 224});

  final Track track;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconSize = (size * 0.46).clamp(48.0, 112.0);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(size * 0.15),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.28),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: context.watch<UserPreferencesService>().artworkBlur
          ? ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: TrackArtwork(track: track, iconSize: iconSize),
            )
          : TrackArtwork(track: track, iconSize: iconSize),
    );
  }
}

class _TrackInfo extends StatelessWidget {
  const _TrackInfo({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          track.title,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          track.artist,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
        ),
        if (track.album != null && track.album!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            track.album!,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _MetaChips extends StatelessWidget {
  const _MetaChips({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (track.year != null) _chip(Icons.calendar_today, '${track.year}'),
      if (track.genre != null && track.genre!.isNotEmpty)
        _chip(Icons.music_note, track.genre!),
      if (track.trackNumber != null)
        _chip(Icons.format_list_numbered, '#${track.trackNumber}'),
      if (track.bitrateBps != null && track.bitrateBps! > 0)
        _chip(
          Icons.speed,
          '${(track.bitrateBps! / 1000).round()} kbps',
        ),
      if (track.format != null && track.format!.isNotEmpty)
        _chip(Icons.audio_file, track.format!.toUpperCase()),
      if (track.source != null && track.source!.isNotEmpty)
        _chip(Icons.source_rounded, track.source!),
      if (track.subtitlePath != null)
        _chip(Icons.closed_caption, 'Subtítulos'),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: chips,
    );
  }

  Widget _chip(IconData icon, String label) {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Chip(
          avatar: Icon(icon, size: 15),
          label: Text(label),
          labelStyle: TextStyle(
            color: scheme.onSecondaryContainer,
            fontSize: 11,
          ),
          backgroundColor: scheme.secondaryContainer,
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      },
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.currentMs,
    required this.maxMs,
    required this.position,
    required this.duration,
    required this.onSeek,
    required this.showWorm,
  });

  final int currentMs;
  final int maxMs;
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final bool showWorm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final fraction = maxMs <= 0
                ? 0.0
                : (currentMs / maxMs).clamp(0.0, 1.0);
            // Radio por defecto del Slider de Material 3. Se fija abajo
            // con SliderTheme para que esta formula y el pulgar coincidan.
            const thumbRadius = 10.0;
            const wormWidth = 32.0;
            final thumbX = thumbRadius + (width - 2 * thumbRadius) * fraction;
            final wormLeft = (thumbX - wormWidth / 2).clamp(
              0.0,
              (width - wormWidth).clamp(0.0, width),
            );
            return SizedBox(
              height: 48,
              child: Stack(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: thumbRadius,
                      ),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: currentMs.toDouble(),
                      max: maxMs.toDouble(),
                      activeColor: scheme.primary,
                      inactiveColor: scheme.secondaryContainer,
                      thumbColor:
                          showWorm ? Colors.transparent : scheme.primary,
                      onChanged: (value) =>
                          onSeek(Duration(milliseconds: value.toInt())),
                    ),
                  ),
                  if (showWorm)
                    Positioned(
                      left: wormLeft,
                      top: 14,
                      width: wormWidth,
                      height: 20,
                      child: IgnorePointer(
                        child: _ExpressiveWorm(color: scheme.primary),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Retroceder 10 segundos',
                icon: const Icon(Icons.replay_10, size: 20),
                onPressed: () => _seekBy(-const Duration(seconds: 10)),
              ),
              Text(_format(position),
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              const Spacer(),
              Text(_format(duration),
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              IconButton(
                tooltip: 'Avanzar 10 segundos',
                icon: const Icon(Icons.forward_10, size: 20),
                onPressed: () => _seekBy(const Duration(seconds: 10)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _seekBy(Duration delta) {
    final target = position + delta;
    if (target < Duration.zero) {
      onSeek(Duration.zero);
    } else if (target > duration) {
      onSeek(duration);
    } else {
      onSeek(target);
    }
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _smallControl(
          icon: Icons.shuffle_rounded,
          selected: player.shuffle,
          onPressed: player.toggleShuffle,
        ),
        _smallControl(
          icon: Icons.skip_previous_rounded,
          size: 30,
          onPressed: player.skipPrevious,
        ),
        IconButton(
          tooltip: player.isPlaying ? 'Pausar' : 'Reproducir',
          style: IconButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            minimumSize: const Size(76, 76),
            shape: const StadiumBorder(),
            elevation: 4,
          ),
          icon: _PlayPauseIcon(isPlaying: player.isPlaying),
          onPressed: () => player.isPlaying ? player.pause() : player.play(),
        ),
        _smallControl(
          icon: Icons.skip_next_rounded,
          size: 30,
          onPressed: player.skipNext,
        ),
        _smallControl(
          icon: Icons.repeat_rounded,
          selected: player.loopMode != LoopMode.off,
          onPressed: player.toggleLoop,
        ),
      ],
    );
  }

  Widget _smallControl({
    required IconData icon,
    required VoidCallback onPressed,
    bool selected = false,
    double size = 24,
  }) {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return IconButton(
          icon: Icon(icon, size: size),
          tooltip: icon == Icons.shuffle_rounded
              ? 'Aleatorio'
              : icon == Icons.repeat_rounded
                  ? 'Repetir'
                  : null,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            minimumSize: const Size(50, 50),
            backgroundColor: selected
                ? scheme.secondaryContainer
                : Colors.transparent,
            foregroundColor: selected
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
            shape: const StadiumBorder(),
          ),
        );
      },
    );
  }
}

class _PlayPauseIcon extends StatelessWidget {
  const _PlayPauseIcon({required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Icon(
      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
      size: 38,
    );
  }
}

class _VolumeControl extends StatefulWidget {
  const _VolumeControl({required this.player});

  final PlayerService player;

  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl> {
  double _volume = 1;
  double _lastVolume = 1;

  void _change(double value) {
    setState(() {
      _volume = value;
      if (value > 0) _lastVolume = value;
    });
    widget.player.setVolume(value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: _volume == 0 ? 'Activar sonido' : 'Silenciar',
            icon: Icon(
              _volume == 0 ? Icons.volume_off : Icons.volume_down_rounded,
            ),
            color: scheme.onSurfaceVariant,
            onPressed: () => _change(_volume == 0 ? _lastVolume : 0),
          ),
          Expanded(
            child: Slider(
              value: _volume,
              activeColor: scheme.primary,
              inactiveColor: scheme.secondaryContainer,
              thumbColor: scheme.primary,
              onChanged: _change,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueuePreview extends StatelessWidget {
  const _QueuePreview({required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = player.currentTrack;
    final index = current == null
        ? -1
        : player.queue.indexWhere((item) => item.id == current.id);
    final next = player.queue.skip(index + 1).take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.queue_music_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'A continuación',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: () => _openQueue(context),
                icon: const Icon(Icons.unfold_more, size: 18),
                label: Text('${player.queue.length}'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (next.isEmpty)
            Text(
              'No hay más canciones en la cola.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            )
          else
            ...next.map(
              (item) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.music_note, size: 18),
                title: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  final target = player.queue.indexWhere(
                    (candidate) => candidate.id == item.id,
                  );
                  if (target >= 0) player.playIndex(target);
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openQueue(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QueueSheet(player: player),
    );
  }
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet({required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.32,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cola de reproducción',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: player.clearQueue,
                      child: const Text('Limpiar'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: player.queue.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = player.queue[index];
                    final isCurrent = item.id == player.currentTrack?.id;
                    return Card(
                      color: isCurrent
                          ? scheme.secondaryContainer
                          : scheme.surfaceContainerHighest,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrent
                              ? scheme.primary
                              : scheme.secondaryContainer,
                          child: Icon(
                            isCurrent
                                ? Icons.equalizer_rounded
                                : Icons.music_note,
                            size: 18,
                            color: isCurrent
                                ? scheme.onPrimary
                                : scheme.onSecondaryContainer,
                          ),
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          item.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: isCurrent,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Subir en la cola',
                              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                              onPressed: index == 0
                                  ? null
                                  : () => player.moveQueueItem(index, index - 1),
                            ),
                            IconButton(
                              tooltip: 'Bajar en la cola',
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                              ),
                              onPressed: index == player.queue.length - 1
                                  ? null
                                  : () => player.moveQueueItem(index, index + 1),
                            ),
                            IconButton(
                              tooltip: 'Quitar de la cola',
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => player.removeFromQueue(index),
                            ),
                          ],
                        ),
                        onTap: () {
                          player.playIndex(index);
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

