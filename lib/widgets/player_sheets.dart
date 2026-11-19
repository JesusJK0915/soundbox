import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../core/models.dart';
import '../player/player_service.dart';

Future<void?> _showSheet(
  BuildContext context,
  Widget Function(BuildContext context) builder,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

Widget _sheetFrame(BuildContext context, Widget child) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.78,
    ),
    decoration: BoxDecoration(
      color: scheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
    ),
    child: child,
  );
}

Widget _sheetHandle(ColorScheme scheme) => Center(
      child: Container(
        width: 42,
        height: 4,
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: scheme.outlineVariant,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );

/// Velocidad de reproducción.
Future<void?> showSpeedSheet(BuildContext context) {
  return _showSheet(context, (context) {
    final scheme = Theme.of(context).colorScheme;
    return Consumer<PlayerService>(
      builder: (context, player, _) => _sheetFrame(
        context,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(scheme),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Velocidad de reproducción',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: playbackSpeeds.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final value = playbackSpeeds[index];
                  final selected = (player.speed - value).abs() < 0.01;
                  return ChoiceChip(
                    label: Text('${value.toStringAsFixed(2).replaceFirst('.00', '')}×'),
                    selected: selected,
                    onSelected: (_) => player.setSpeed(value),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  });
}

/// Temporizador para detener la música al dormirse.
Future<void?> showSleepSheet(BuildContext context) {
  const options = <int>[5, 10, 15, 20, 30, 45, 60, 90];
  return _showSheet(context, (context) {
    final scheme = Theme.of(context).colorScheme;
    return Consumer<PlayerService>(
      builder: (context, player, _) => _sheetFrame(
        context,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(scheme),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Temporizador de sueño',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            if (player.sleepActive)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(Icons.nightlight_round, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Quedan ${_formatRemaining(player.sleepRemaining)}',
                        style: TextStyle(color: scheme.onSecondaryContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: () => player.addSleepTime(const Duration(minutes: 5)),
                      child: const Text('+5 min'),
                    ),
                    TextButton(
                      onPressed: player.cancelSleepTimer,
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (final minutes in options)
                    ActionChip(
                      avatar: const Icon(Icons.timer_outlined, size: 16),
                      label: Text('$minutes min'),
                      onPressed: () {
                        player.startSleepTimer(Duration(minutes: minutes));
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  });
}

/// Letra incrustada en los metadatos del archivo.
Future<void?> showLyricsSheet(BuildContext context, Track track) {
  final lyrics = track.extraTags?['Letra'];
  return _showSheet(context, (context) {
    final scheme = Theme.of(context).colorScheme;
    return _sheetFrame(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetHandle(scheme),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Letra',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              child: Text(
                lyrics?.trim().isNotEmpty == true
                    ? lyrics!
                    : 'Esta canción no tiene letra incrustada en sus '
                        'metadatos.\n\nPuedes añadir etiquetas de letra a tus '
                        'archivos con cualquier editor de MP3 y volver a '
                        'leer los metadatos desde Ajustes.',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}

String _formatRemaining(Duration? value) {
  final duration = value ?? Duration.zero;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
