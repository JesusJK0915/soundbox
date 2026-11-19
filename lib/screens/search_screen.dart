import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connectivity_service.dart';
import '../core/download_service.dart';
import '../core/download_settings.dart';
import '../core/models.dart';
import '../core/providers.dart';
import '../core/search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  SearchService? _search;
  final TextEditingController _controller = TextEditingController();

  bool _loading = false;
  String? _error;
  List<Track> _results = const <Track>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(bool online) async {
    if (!online) return;
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final search = _search ??=
          SearchService(context.read<ProviderSettingsService>());
      final results = await search.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        final online = connectivity.isOnline;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                enabled: online,
                decoration: InputDecoration(
                  hintText: online
                      ? 'Buscar en las fuentes activas o pegar una URL'
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
