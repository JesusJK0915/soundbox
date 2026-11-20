import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/library_service.dart';
import '../core/library_tools.dart';
import '../core/playlist_export.dart';
import '../core/models.dart';
import '../core/user_preferences.dart';
import '../player/player_service.dart';
import '../widgets/track_artwork.dart';

/// Herramientas avanzadas: historial, duplicados, playlists, ecualizador
/// y listas inteligentes.
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Historial'),
            Tab(text: 'Duplicados'),
            Tab(text: 'Listas'),
            Tab(text: 'Ecualizador'),
            Tab(text: 'Inteligentes'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _HistoryTab(),
              _DuplicatesTab(),
              _PlaylistsTab(),
              _EqualizerTab(),
              _SmartTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<UserPreferencesService>();
    final library = context.watch<LibraryService>();
    final byId = <String, Track>{for (final track in library.tracks) track.id: track};
    final history = prefs.playbackHistory
        .map((id) => byId[id])
        .where((track) => track != null)
        .cast<Track>()
        .toList();
    final available = library.playableTracks;
    Future<void> restoreQueue(Iterable<String> ids) async {
      final count = await context
          .read<PlayerService>()
          .restoreQueueByIds(ids, available);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Cola restaurada con $count pista(s)'
                : 'No se encontraron pistas de esa cola',
          ),
        ),
      );
    }

    return Column(
      children: [
        if (prefs.customQueue.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restaurar última cola'),
            subtitle: Text('${prefs.customQueue.length} pista(s) guardada(s)'),
            onTap: () => restoreQueue(prefs.customQueue),
          ),
        if (prefs.queueHistory.isNotEmpty)
          ExpansionTile(
            leading: const Icon(Icons.history_toggle_off),
            title: const Text('Colas recientes'),
            children: prefs.queueHistory.take(10).map((entry) {
              final ids = entry.split(',').where((id) => id.isNotEmpty).toList();
              return ListTile(
                title: Text('Cola de ${ids.length} pista(s)'),
                subtitle: Text(
                  ids
                      .take(3)
                      .map((id) => byId[id]?.title ?? id)
                      .join(' · '),
                ),
                onTap: () => restoreQueue(ids),
              );
            }).toList(),
          ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Borrar historial'),
          onTap: prefs.clearPlaybackHistory,
        ),
        if (history.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Aún no hay historial de reproducción.'),
          ),
        Expanded(
          child: ListView.separated(
            itemCount: history.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _FilledHistoryButton(
                track: history[index],
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Boton relleno estilo Material Expressive con respuesta animada al toque.
class _FilledHistoryButton extends StatefulWidget {
  const _FilledHistoryButton({required this.track, required this.index});

  final Track track;
  final int index;

  @override
  State<_FilledHistoryButton> createState() => _FilledHistoryButtonState();
}

class _FilledHistoryButtonState extends State<_FilledHistoryButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final player = context.read<PlayerService>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: () {
              _setPressed(false);
              player.playNext(widget.track);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  TrackArtwork(track: widget.track, iconSize: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.track.artist} · ${widget.index + 1}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onPrimaryContainer.withOpacity(0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.play_arrow_rounded,
                    color: scheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DuplicatesTab extends StatelessWidget {
  const _DuplicatesTab();

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();
    final groups = context
        .watch<LibraryToolsService>()
        .findDuplicates(library.playableTracks);
    if (groups.isEmpty) {
      return const Center(child: Text('No se encontraron canciones duplicadas.'));
    }
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return ExpansionTile(
          title: Text(group.tracks.first.title),
          subtitle: Text('${group.tracks.length} copias'),
          children: group.tracks.map((track) {
            return ListTile(
              leading: TrackArtwork(track: track, iconSize: 40),
              title: Text(track.artist),
              subtitle: Text(
                track.isLocal ? 'Local' : (track.source ?? 'Remoto'),
              ),
              trailing: IconButton(
                tooltip: 'Quitar de la biblioteca',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => library.remove(track.id),
              ),
              onTap: () => context.read<PlayerService>().playNext(track),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PlaylistsTab extends StatefulWidget {
  const _PlaylistsTab();

  @override
  State<_PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<_PlaylistsTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createDialog(BuildContext context) async {
    _controller.clear();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva lista de reproducción'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty && context.mounted) {
      await context.read<LibraryToolsService>().createPlaylist(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tools = context.watch<LibraryToolsService>();
    final library = context.watch<LibraryService>();
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.playlist_add),
          title: const Text('Crear lista de reproducción'),
          onTap: () => _createDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: const Text('Exportar biblioteca (M3U)'),
          subtitle: const Text(
            'Guarda el resultado en los ajustes para compartirlo.',
          ),
          onTap: () async {
            final content = context
                .read<PlaylistExportService>()
                .toM3u(library.playableTracks);
            await context.read<PlaylistExportService>().rememberExport(content);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'M3U generado con ${library.playableTracks.length} pista(s)',
                ),
              ),
            );
          },
        ),
        Expanded(
          child: tools.playlists.isEmpty
              ? const Center(child: Text('Todavía no tienes listas.'))
              : ListView.builder(
                  itemCount: tools.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = tools.playlists[index];
                    final tracks = tools.tracksOf(playlist, library.tracks);
                    return ExpansionTile(
                      title: Text(playlist.name),
                      subtitle: Text('${tracks.length} canción(es)'),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {
                          if (tracks.isNotEmpty) {
                            context.read<PlayerService>().playAll(tracks);
                          }
                        },
                      ),
                      children: [
                        ...tracks.map(
                          (track) => ListTile(
                            title: Text(track.title),
                            subtitle: Text(track.artist),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => tools.removeFromPlaylist(
                                playlist.id,
                                track.id,
                              ),
                            ),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('Añadir toda la biblioteca'),
                          onTap: () async {
                            for (final track in library.playableTracks) {
                              await tools.addToPlaylist(playlist.id, track.id);
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_outline),
                          title: const Text('Eliminar lista'),
                          onTap: () => tools.deletePlaylist(playlist.id),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EqualizerTab extends StatelessWidget {
  const _EqualizerTab();

  @override
  Widget build(BuildContext context) {
    final tools = context.watch<LibraryToolsService>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Ecualizador',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: LibraryToolsService.eqPresets.keys.map((name) {
            return ActionChip(
              label: Text(name),
              onPressed: () => tools.applyPreset(name),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        ...List.generate(tools.bands.length, (index) {
          final band = tools.bands[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${band.frequency.round()} Hz · ${band.gain.toStringAsFixed(1)} dB'),
              Slider(
                min: -12,
                max: 12,
                divisions: 48,
                value: band.gain,
                onChanged: (value) => tools.setBandGain(index, value),
              ),
            ],
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.restore),
          label: const Text('Restablecer ecualizador'),
          onPressed: tools.resetEqualizer,
        ),
        const Divider(),
        SwitchListTile(
          secondary: const Icon(Icons.graphic_eq),
          title: const Text('Normalización de volumen'),
          subtitle: const Text('Equilibra el volumen Percibido de las pistas.'),
          value: tools.normalize,
          onChanged: tools.setNormalize,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.volume_up),
          title: const Text('ReplayGain'),
          subtitle: const Text('Usa la etiqueta ReplayGain si está disponible.'),
          value: tools.replayGain,
          onChanged: tools.setReplayGain,
        ),
      ],
    );
  }
}

class _SmartTab extends StatefulWidget {
  const _SmartTab();

  @override
  State<_SmartTab> createState() => _SmartTabState();
}

class _SmartTabState extends State<_SmartTab> {
  final _controller = TextEditingController(text: 'year>2010');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tools = context.watch<LibraryToolsService>();
    final library = context.watch<LibraryService>();
    final prefs = context.watch<UserPreferencesService>();
    final rule = _controller.text;
    final matches = tools.smartPlaylist(
      rule,
      library.playableTracks,
      playCount: prefs.playCount,
      favorites: prefs.favoriteIds,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Regla',
              hintText: 'year>2010, plays>5, genre=Rock, favorite',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          children: ['favorite', 'year>2010', 'plays>5', 'genre=Rock'].map(
            (example) => ActionChip(
              label: Text(example),
              onPressed: () {
                _controller.text = example;
                setState(() {});
              },
            ),
          ).toList(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: matches.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final track = matches[index];
              return ListTile(
                leading: TrackArtwork(track: track, iconSize: 40),
                title: Text(track.title),
                subtitle: Text(track.artist),
                onTap: () => context.read<PlayerService>().playNext(track),
              );
            },
          ),
        ),
      ],
    );
  }
}
