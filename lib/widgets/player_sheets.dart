import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connectivity_service.dart';
import '../core/library_service.dart';
import '../core/lyrics_service.dart';
import '../core/models.dart';
import '../core/subtitle_parser.dart';
import '../core/user_preferences.dart';
import '../player/player_service.dart';

Future<void> _showSheet(
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
Future<void> showSpeedSheet(BuildContext context) {
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
Future<void> showSleepSheet(BuildContext context) {
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

/// Letra sincronizada, incrustada o descargada de LRCLIB.
Future<void> showLyricsSheet(BuildContext context, Track track) {
  return _showSheet(
    context,
    (context) => _LyricsSheet(track: track),
  );
}

class _LyricsSheet extends StatefulWidget {
  const _LyricsSheet({required this.track});

  final Track track;

  @override
  State<_LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<_LyricsSheet> {
  String? _content;
  String? _source;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    final path = widget.track.subtitlePath;
    if (path != null && await File(path).exists()) {
      _content = await File(path).readAsString();
      _source = 'Archivo local';
    } else {
      final embedded = widget.track.extraTags?['Letra'];
      if (embedded != null && embedded.trim().isNotEmpty) {
        _content = embedded;
        _source = 'Metadatos del archivo';
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _search() async {
    final online = context.read<ConnectivityService>().isOnline;
    if (!online) {
      setState(() => _error = 'Sin conexión: no se puede consultar LRCLIB.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await context.read<LyricsService>().fetch(widget.track);
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _loading = false;
        _error = 'No se encontró letra para esta canción.';
      });
      return;
    }
    final content = result.lrcContent;
    if (content == null) {
      setState(() {
        _loading = false;
        _error = result.instrumental
            ? 'LRCLIB marca esta canción como instrumental.'
            : 'LRCLIB no devolvió letra para esta canción.';
      });
      return;
    }
    await context.read<LibraryService>().attachLyrics(widget.track.id, content);
    if (!mounted) return;
    setState(() {
      _content = content;
      _source = 'LRCLIB · ${result.artistName}';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prefs = context.watch<UserPreferencesService>();
    final fontSize = prefs.lyricFont;
    final karaokeEnabled = prefs.lyricsKaraoke;
    final cues = _content == null ? const <SubtitleCue>[] : parseSubtitles(_content!);
    final text = cues.isEmpty
        ? _content!.trim()
        : cues.map((cue) => cue.text).join('\n');
    final karaoke = context.watch<PlayerService>().positionStream;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Letra', style: Theme.of(context).textTheme.titleLarge),
                      if (_source != null)
                        Text(
                          _source!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Buscar en LRCLIB',
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download_outlined),
                  onPressed: _loading ? null : _search,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                style: TextStyle(color: scheme.error),
              ),
            ),
          Flexible(
            child: StreamBuilder<Duration>(
              stream: karaoke,
              initialData: Duration.zero,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final active = cueAt(cues, position);
                final displayed = karaokeEnabled && active != null
                    ? cues.map((cue) => cue.text == active ? '♪ $active' : cue.text).join('\n')
                    : text;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                  child: Text(
                    displayed.isNotEmpty
                        ? displayed
                        : 'Toca el icono de nube para buscar la letra '
                            'automáticamente en LRCLIB.\n\nTambién puedes '
                            'adjuntar un archivo .lrc, .srt o .vtt desde la '
                            'ficha de la canción.',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: fontSize,
                      height: 1.5,
                    ),
                  ),
                );
              },
            ),
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
