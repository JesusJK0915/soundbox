import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/connectivity_service.dart';
import '../core/download_service.dart';
import '../core/download_settings.dart';
import '../core/library_service.dart';
import '../core/models.dart';
import '../core/providers.dart';
import '../core/search_service.dart';
import '../core/youtube_direct_service.dart';
import '../core/youtube_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  SearchService? _search;
  YouTubeDirectService? _youtubeDirect;
  final TextEditingController _controller = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _directNotice;
  List<Track> _results = const <Track>[];
  YouTubeVideo? _youtube;
  String? _youtubeUrl;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startDirectDownload(String url) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _directNotice = null;
      _youtube = null;
      _youtubeUrl = null;
      _results = const <Track>[];
    });

    try {
      final direct = _youtubeDirect ??= YouTubeDirectService(
        context.read<LibraryService>(),
      );
      final downloads = context.read<DownloadService>();
      final track = await direct.prepare(url);
      if (!mounted) return;
      await downloads.startFromFile(track, track.sourceUrl);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _directNotice = 'Descargando "${track.title}" · revisa Descargas';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('StateError: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _runSearch(bool online) async {
    if (!online) return;
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _directNotice = null;
      _youtube = null;
      _youtubeUrl = null;
      _results = const <Track>[];
    });

    try {
      final settings = context.read<ProviderSettingsService>();
      final search = _search ??= SearchService(settings);

      if (YouTubeService.isYouTubeUrl(query)) {
        if (settings.youtubeDirect) {
          await _startDirectDownload(query);
          return;
        }

        final key = settings.key(ProviderKind.youtube).trim();
        if (key.isEmpty || !settings.isEnabled(ProviderKind.youtube)) {
          setState(() {
            _error = 'Activa "YouTube (solo búsqueda)" y pega una API key en '
                'Ajustes para usar links de YouTube.';
            _loading = false;
          });
          return;
        }

        final video = await YouTubeService(key).resolve(query);
        if (!mounted) return;
        final term = video.searchQuery;
        if (term.isEmpty) {
          setState(() {
            _error = 'El video no tiene un titulo utilizable para buscar';
            _loading = false;
          });
          return;
        }
        setState(() {
          _youtube = video;
          _youtubeUrl = query;
        });

        final results = await search.search(term);
        if (!mounted) return;
        setState(() {
          _results = results;
          _loading = false;
        });
        return;
      }

      final results = await search.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('StateError: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _copyYouTubeUrl() async {
    final url = _youtubeUrl;
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link de YouTube copiado')),
    );
  }

  Widget _buildYouTubeCard(YouTubeVideo video, ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: video.thumbnailUrl == null
                ? const SizedBox(
                    width: 56,
                    height: 44,
                    child: Icon(Icons.music_note),
                  )
                : Image.network(
                    video.thumbnailUrl!,
                    width: 56,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 56,
                      height: 44,
                      child: Icon(Icons.music_note),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Link de YouTube · solo metadata',
                  style: TextStyle(
                    color: colors.onSecondaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onSecondaryContainer),
                ),
                const SizedBox(height: 2),
                Text(
                  '${video.channel} · buscando: ${video.searchQuery}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSecondaryContainer,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Elige una fuente legal de abajo; nunca se extrae audio '
                  'del video.',
                  style: TextStyle(
                    color: colors.onSecondaryContainer,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copiar link de YouTube',
            color: colors.onSecondaryContainer,
            onPressed: _copyYouTubeUrl,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        final online = connectivity.isOnline;
        final colors = Theme.of(context).colorScheme;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                enabled: online,
                decoration: InputDecoration(
                  hintText: online
                      ? 'Buscar, pegar URL o link de YouTube'
                      : 'Sin conexion',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: online ? () => _runSearch(true) : null,
                  ),
                ),
                onSubmitted: (_) => _runSearch(online),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Consumer<DownloadSettingsService>(
                  builder: (context, quality, _) => Text(
                    'Descargas: ${quality.label}'
                    '${quality.isLossy ? ' · ${quality.bitrate} kbps' : ''}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
            if (_directNotice != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Text(
                  _directNotice!,
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
            if (_youtube != null) _buildYouTubeCard(_youtube!, colors),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('Sin resultados'))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final track = _results[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: track.artworkUrl == null
                                ? null
                                : NetworkImage(track.artworkUrl!),
                            child: track.artworkUrl == null
                                ? const Icon(Icons.music_note)
                                : null,
                          ),
                          title: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              track.artist,
                              if (track.source != null) track.source!,
                              if (track.license != null) 'con licencia',
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Consumer<DownloadService>(
                            builder: (context, downloads, _) {
                              final busy = downloads.isDownloading(track.id);
                              return IconButton(
                                icon: Icon(
                                  busy ? Icons.hourglass_top : Icons.download,
                                ),
                                onPressed: busy
                                    ? null
                                    : () => downloads.start(track),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
