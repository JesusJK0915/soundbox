import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../player/player_service.dart';
import '../widgets/subtitle_overlay.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (context, player, _) {
        final track = player.currentTrack;
        if (track == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Reproductor')),
            body: const Center(child: Text('No hay pista activa')),
          );
        }

        final duration = player.duration ?? Duration.zero;
        final maxMs = duration.inMilliseconds < 1 ? 1 : duration.inMilliseconds;
        final currentMs = player.position.inMilliseconds.clamp(0, maxMs);

        return Scaffold(
          appBar: AppBar(title: const Text('Reproductor')),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 72,
                      backgroundImage: track.artworkUrl == null
                          ? null
                          : NetworkImage(track.artworkUrl!),
                      child: track.artworkUrl == null
                          ? Icon(
                              track.isVideo ? Icons.movie : Icons.music_note,
                              size: 64,
                            )
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      track.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(track.artist,
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 24),
                    Slider(
                      value: currentMs.toDouble(),
                      max: maxMs.toDouble(),
                      onChanged: (value) =>
                          player.seek(Duration(milliseconds: value.toInt())),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_format(player.position)),
                          Text(_format(duration)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.shuffle,
                            color: player.shuffle ? Colors.deepPurple : null,
                          ),
                          onPressed: player.toggleShuffle,
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 36),
                          onPressed: player.skipPrevious,
                        ),
                        CircleAvatar(
                          radius: 32,
                          child: IconButton(
                            icon: Icon(
                              player.isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 32,
                            ),
                            onPressed: () => player.isPlaying
                                ? player.pause()
                                : player.play(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 36),
                          onPressed: player.skipNext,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.repeat,
                            color: player.loopMode != LoopMode.off
                                ? Colors.deepPurple
                                : null,
                          ),
                          onPressed: player.toggleLoop,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _VolumeControl(),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: player.queue.length,
                        itemBuilder: (context, index) {
                          final item = player.queue[index];
                          return SizedBox(
                            width: 140,
                            child: ListTile(
                              dense: true,
                              title: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => player.playIndex(index),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SubtitleOverlay(
                subtitlePath: track.subtitlePath,
                position: player.position,
              ),
            ],
          ),
        );
      },
    );
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _VolumeControl extends StatefulWidget {
  const _VolumeControl();

  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl> {
  double _volume = 1;

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerService>();
    return Row(
      children: [
        const Icon(Icons.volume_down),
        Expanded(
          child: Slider(
            value: _volume,
            onChanged: (value) {
              setState(() => _volume = value);
              player.setVolume(value);
            },
          ),
        ),
      ],
    );
  }
}
