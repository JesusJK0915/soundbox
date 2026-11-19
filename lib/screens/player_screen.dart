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
                AnimatedScale(
                  scale: isFavorite ? 1.12 : 1,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  child: IconButton(
                    tooltip: isFavorite
                        ? 'Quitar de favoritos'
                        : 'Añadir a favoritos',
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey<bool>(isFavorite),
                      ),
                    ),
                    onPressed: () async {
                      await prefs.toggleFavorite(track.id);
                      if (prefs.haptics) HapticFeedback.selectionClick();
                    },
                  ),
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 76, 20, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _DragHandle(prefs: prefs),
                                const SizedBox(height: 4),
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
                                    child: _HeroArtwork(
                                      track: track,
                                      isPlaying: player.isPlaying,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 350),
                                  switchInCurve: Curves.easeOutCubic,
                                  child: _TrackInfo(
                                    key: ValueKey<String>(track.id),
                                    track: track,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _MetaChips(track: track),
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
                                if (player.sleepActive)
                                  _SleepBanner(player: player),
                                const SizedBox(height: 28),
                                _Progress(
                                  currentMs: currentMs,
                                  maxMs: maxMs,
                                  position: player.position,
                                  duration: duration,
                                  onSeek: player.seek,
                                ),
                                const SizedBox(height: 20),
                                _Controls(player: player),
                                const SizedBox(height: 22),
                                _VolumeControl(player: player),
                                const SizedBox(height: 22),
                                _QueuePreview(player: player),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SubtitleOverlay(
                  subtitlePath: track.subtitlePath,
                  position: player.position,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
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
            AnimatedPositioned(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              top: isPlaying ? -96 : -56,
              left: isPlaying ? -48 : -12,
              child: _Orb(color: scheme.primary.withOpacity(0.18)),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              bottom: isPlaying ? -120 : -80,
              right: isPlaying ? -72 : -32,
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
  const _HeroArtwork({required this.track, required this.isPlaying});

  final Track track;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(track.id),
      tween: Tween<double>(begin: 0.92, end: isPlaying ? 1 : 0.97),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, scale, _) {
        return Transform.scale(
          scale: scale,
          child: Hero(
            tag: playerArtHeroTag(track),
            child: Container(
              width: 224,
              height: 224,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withOpacity(0.28),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: TrackArtwork(track: track, iconSize: 104),
            ),
          ),
        );
      },
    );
  }
}

class _TrackInfo extends StatelessWidget {
  const _TrackInfo({super.key, required this.track});

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
  });

  final int currentMs;
  final int maxMs;
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Slider(
          value: currentMs.toDouble(),
          max: maxMs.toDouble(),
          activeColor: scheme.primary,
          inactiveColor: scheme.secondaryContainer,
          thumbColor: scheme.primary,
          onChanged: (value) => onSeek(Duration(milliseconds: value.toInt())),
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
    final end = duration;
    onSeek(
      end == null
          ? target < Duration.zero ? Duration.zero : target
          : target < Duration.zero
              ? Duration.zero
              : target > end
                  ? end
                  : target,
    );
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
        AnimatedScale(
          scale: player.isPlaying ? 1.06 : 1,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          child: IconButton(
            tooltip: player.isPlaying ? 'Pausar' : 'Reproducir',
            style: IconButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              minimumSize: const Size(76, 76),
              shape: const StadiumBorder(),
              elevation: 4,
            ),
            icon: _PlayPauseIcon(isPlaying: player.isPlaying),
            onPressed: () =>
                player.isPlaying ? player.pause() : player.play(),
          ),
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutBack,
      child: Icon(
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        key: ValueKey<bool>(isPlaying),
        size: 38,
      ),
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

class _PlayingBars extends StatefulWidget {
  const _PlayingBars({required this.isPlaying});

  final bool isPlaying;

  @override
  State<_PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<_PlayingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      opacity: widget.isPlaying ? 1 : 0.35,
      duration: const Duration(milliseconds: 250),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SizedBox(
            width: 22,
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _bar(scheme, 0.0, 0.55, 5, 18),
                _bar(scheme, 0.2, 0.8, 8, 20),
                _bar(scheme, 0.4, 1.0, 4, 15),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _bar(ColorScheme scheme, double begin, double end, double min, double max) {
    final height = Tween<double>(begin: min, end: max).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: Curves.easeInOut),
      ),
    );
    return AnimatedBuilder(
      animation: height,
      builder: (context, _) {
        return Container(
          width: 4,
          height: height.value,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}
