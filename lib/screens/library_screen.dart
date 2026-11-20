import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/connectivity_service.dart';
import '../core/export_service.dart';
import '../core/library_service.dart';
import '../core/library_tools.dart';
import '../core/lyrics_service.dart';
import '../core/models.dart';
import '../core/pro_toolkit.dart';
import '../core/user_preferences.dart';
import '../player/player_service.dart';
import '../widgets/track_artwork.dart';
import '../widgets/track_details_sheet.dart';

enum LibraryFilter { all, favorites, recent, plays }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _search = TextEditingController();
  final Set<String> _selected = <String>{};
  LibraryFilter _filter = LibraryFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _haptic(UserPreferencesService prefs) {
    if (prefs.haptics) HapticFeedback.selectionClick();
  }

  List<Track> _visibleTracks(
    LibraryService library,
    UserPreferencesService prefs,
  ) {
    var tracks = library.playableTracks;
    final query = _search.text.trim();
    if (query.isNotEmpty) {
      tracks = PlaylistToolsPro.filterTracks(
        tracks,
        query,
      );
    }

    switch (_filter) {
      case LibraryFilter.all:
        return prefs.sorted(tracks);
      case LibraryFilter.favorites:
        return prefs.sorted(prefs.favorites(tracks));
      case LibraryFilter.recent:
        return prefs.recentlyPlayed(tracks);
      case LibraryFilter.plays:
        return prefs.mostPlayed(tracks);
    }
  }

  void _toggleSelection(String id, UserPreferencesService prefs) {
    _haptic(prefs);
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _bulkDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar canciones'),
        content: Text(
          'Se borrarán ${_selected.length} canción(es) de la biblioteca '
          'y de este dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final count = _selected.length;
    final library = context.read<LibraryService>();
    for (final id in List<String>.from(_selected)) {
      await library.remove(id);
    }
    if (!context.mounted) return;
    setState(() => _selected.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count cancion(es) eliminada(s)')),
    );
  }

  Future<void> _bulkExport(BuildContext context) async {
    final export = context.read<ExportService>();
    final tracks = context
        .read<LibraryService>()
        .playableTracks
        .where((track) => _selected.contains(track.id))
        .toList();
    var saved = 0;
    for (final track in tracks) {
      try {
        if (await export.saveFile(track) != null) saved++;
      } catch (_) {}
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$saved cancion(es) guardadas')),
    );
  }

  Future<void> _refreshMetadata(BuildContext context) async {
    final count = await context
        .read<LibraryService>()
        .refreshMetadata(force: true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 0
              ? 'Los metadatos ya estaban actualizados'
              : '$count cancion(es) actualizada(s)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LibraryService, UserPreferencesService>(
      builder: (context, library, prefs, _) {
        final tracks = _visibleTracks(library, prefs);
        final hasSelection = _selected.isNotEmpty;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar en tu biblioteca...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final filter in LibraryFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_filterLabel(filter)),
                        avatar: Icon(_filterIcon(filter), size: 16),
                        selected: _filter == filter,
                        showCheckmark: false,
                        onSelected: (_) {
                          _haptic(prefs);
                          setState(() => _filter = filter);
                        },
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    '${tracks.length} canción(es)',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Reproducir todo',
                    icon: const Icon(Icons.play_arrow_rounded),
                    onPressed: tracks.isEmpty
                        ? null
                        : () => context.read<PlayerService>().playAll(tracks),
                  ),
                  IconButton(
                    tooltip: 'Reproducir en aleatorio',
                    icon: const Icon(Icons.shuffle_rounded),
                    onPressed: tracks.isEmpty
                        ? null
                        : () => context
                            .read<PlayerService>()
                            .playAll(tracks, shuffled: true),
                  ),
                  PopupMenuButton<LibrarySort>(
                    tooltip: 'Ordenar',
                    icon: const Icon(Icons.sort_rounded),
                    onSelected: prefs.setSort,
                    itemBuilder: (context) => [
                      for (final sort in LibrarySort.values)
                        PopupMenuItem(
                          value: sort,
                          child: Row(
                            children: [
                              if (sort == prefs.sort)
                                const Icon(Icons.check, size: 18)
                              else
                                const SizedBox(width: 18),
                              const SizedBox(width: 8),
                              Text(_sortLabel(sort)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    tooltip: prefs.gridView
                        ? 'Vista de lista'
                        : 'Vista de cuadrícula',
                    icon: Icon(
                      prefs.gridView ? Icons.view_list : Icons.grid_view_rounded,
                    ),
                    onPressed: () => prefs.setGridView(!prefs.gridView),
                  ),
                ],
              ),
            ),
            if (hasSelection)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 2, 12, 6),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Salir de selección',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _selected.clear()),
                    ),
                    Text('${_selected.length} seleccionada(s)'),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Seleccionar todo',
                      icon: const Icon(Icons.select_all),
                      onPressed: () => setState(() {
                        _selected.addAll(tracks.map((t) => t.id));
                      }),
                    ),
                    IconButton(
                      tooltip: 'Añadir a la cola',
                      icon: const Icon(Icons.queue_music),
                      onPressed: () {
                        final player = context.read<PlayerService>();
                        for (final track in tracks.where(
                          (t) => _selected.contains(t.id),
                        )) {
                          player.enqueue(track);
                        }
                        setState(() => _selected.clear());
                      },
                    ),
                    IconButton(
                      tooltip: 'Guardar selección',
                      icon: const Icon(Icons.save_as_outlined),
                      onPressed: () => _bulkExport(context),
                    ),
                    IconButton(
                      tooltip: 'Eliminar selección',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _bulkDelete(context),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: tracks.isEmpty
                  ? _EmptyLibrary(filter: _filter, query: _search.text)
                  : RefreshIndicator(
                      onRefresh: () => _refreshMetadata(context),
                      child: prefs.gridView
                          ? _buildGrid(tracks, library, prefs)
                          : _buildList(tracks, library, prefs),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList(
    List<Track> tracks,
    LibraryService library,
    UserPreferencesService prefs,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 110),
      itemCount: tracks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final track = tracks[index];
        final selected = _selected.contains(track.id);
        return ListTile(
          key: ValueKey<String>(track.id),
          selected: selected,
              selectedTileColor:
                  Theme.of(context).colorScheme.secondaryContainer,
              leading: ClipOval(
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: TrackArtwork(track: track, iconSize: 20),
                ),
              ),
              title: Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                [
                  track.artist,
                  if (track.album != null && track.album!.isNotEmpty)
                    track.album!,
                  if (prefs.showYear && track.year != null)
                    track.year.toString(),
                  if (prefs.showBitrate && track.bitrateBps != null)
                    '${(track.bitrateBps! / 1000).round()} kbps',
                  if (track.subtitlePath != null) 'SUB',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                if (_selected.isNotEmpty) {
                  _toggleSelection(track.id, prefs);
                  return;
                }
                context.read<PlayerService>().setQueue(tracks, index: index);
              },
              onLongPress: () => _toggleSelection(track.id, prefs),
              trailing: selected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : PopupMenuButton<String>(
                      onSelected: (value) => _onTrackAction(
                        context,
                        value,
                        track,
                        library,
                      ),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'details',
                          child: Text('Ver metadatos'),
                        ),
                        PopupMenuItem(
                          value: 'next',
                          child: Text('Reproducir a continuación'),
                        ),
                        PopupMenuItem(value: 'queue', child: Text('Añadir a la cola')),
                        PopupMenuItem(
                          value: 'export',
                          child: Text('Guardar en otro lugar'),
                        ),
                        PopupMenuItem(
                          value: 'subtitle',
                          child: Text('Adjuntar SUB'),
                        ),
                        PopupMenuItem(
                          value: 'playlist',
                          child: Text('Añadir a lista'),
                        ),
                        PopupMenuItem(
                          value: 'lyrics',
                          child: Text('Buscar letras (LRCLIB)'),
                        ),
                        PopupMenuItem(value: 'remove', child: Text('Eliminar')),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildGrid(
    List<Track> tracks,
    LibraryService library,
    UserPreferencesService prefs,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final selected = _selected.contains(track.id);
        final scheme = Theme.of(context).colorScheme;
        return Card(
          color: selected
              ? scheme.secondaryContainer
              : scheme.surfaceContainerHighest,
          surfaceTintColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: InkWell(
            onTap: () {
              if (_selected.isNotEmpty) {
                _toggleSelection(track.id, prefs);
              } else {
                context.read<PlayerService>().setQueue(tracks, index: index);
              }
            },
            onLongPress: () => _toggleSelection(track.id, prefs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TrackArtwork(track: track, iconSize: 44),
                      if (selected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: CircleAvatar(
                            backgroundColor: scheme.primary,
                            child: Icon(
                              Icons.check,
                              color: scheme.onPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onTrackAction(
    BuildContext context,
    String value,
    Track track,
    LibraryService library,
  ) async {
    final player = context.read<PlayerService>();
    switch (value) {
      case 'details':
        await showTrackDetails(context, track);
        break;
      case 'next':
        await player.playNext(track);
        break;
      case 'queue':
        await player.enqueue(track);
        break;
      case 'export':
        await _saveTrack(context, track);
        break;
      case 'subtitle':
        final path = await library.pickSubtitlePath();
        if (path != null) await library.attachSubtitle(track.id, path);
        break;
      case 'playlist':
        await _addToPlaylist(context, track);
        break;
      case 'lyrics':
        await _fetchLyrics(context, track, library);
        break;
      case 'remove':
        await library.remove(track.id);
        break;
    }
  }

  Future<void> _fetchLyrics(
    BuildContext context,
    Track track,
    LibraryService library,
  ) async {
    final online = context.read<ConnectivityService>().isOnline;
    if (!online) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin conexión a LRCLIB')),
      );
      return;
    }
    final result = await context.read<LyricsService>().fetch(track);
    final content = result?.lrcContent;
    if (content != null) {
      await library.attachLyrics(track.id, content);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          content != null
              ? 'Letra guardada para ${track.title}'
              : 'No se encontró letra para ${track.title}',
        ),
      ),
    );
  }

  Future<void> _addToPlaylist(BuildContext context, Track track) async {
    final tools = context.read<LibraryToolsService>();
    if (tools.playlists.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crea una lista primero en Herramientas → Listas'),
        ),
      );
      return;
    }
    final playlistId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Añadir a lista'),
        children: tools.playlists
            .map(
              (playlist) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, playlist.id),
                child: Text(playlist.name),
              ),
            )
            .toList(),
      ),
    );
    if (playlistId != null) {
      await tools.addToPlaylist(playlistId, track.id);
    }
  }

  Future<void> _saveTrack(BuildContext context, Track track) async {
    try {
      final saved = await context.read<ExportService>().saveFile(track);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved == null ? 'Guardado cancelado' : 'Cancion guardada'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
    }
  }

  String _filterLabel(LibraryFilter filter) => switch (filter) {
        LibraryFilter.all => 'Todas',
        LibraryFilter.favorites => 'Favoritas',
        LibraryFilter.recent => 'Recientes',
        LibraryFilter.plays => 'Más escuchadas',
      };

  IconData _filterIcon(LibraryFilter filter) => switch (filter) {
        LibraryFilter.all => Icons.library_music_outlined,
        LibraryFilter.favorites => Icons.favorite_outline,
        LibraryFilter.recent => Icons.history,
        LibraryFilter.plays => Icons.bar_chart,
      };

  String _sortLabel(LibrarySort sort) => switch (sort) {
        LibrarySort.title => 'Título',
        LibrarySort.artist => 'Artista',
        LibrarySort.year => 'Año',
        LibrarySort.recent => 'Añadidas recientemente',
        LibrarySort.plays => 'Más reproducidas',
      };
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.filter, required this.query});

  final LibraryFilter filter;
  final String query;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = query.isNotEmpty
        ? 'No hay canciones que coincidan con "$query".'
        : switch (filter) {
            LibraryFilter.favorites =>
              'Aún no tienes favoritas. Toca el corazón de una canción.',
            LibraryFilter.recent => 'Todavía no has escuchado ninguna canción.',
            LibraryFilter.plays =>
              'Escucha algunas canciones para ver estadísticas aquí.',
            LibraryFilter.all =>
              'Importa tu música para empezar.\nTodo se guarda en este dispositivo.',
          };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_off_rounded, size: 72, color: scheme.primary),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
