import 'package:flutter/material.dart';

import '../core/models.dart';

/// Muestra todos los campos conocidos de una pista, incluidas las etiquetas
/// adicionales leidas del archivo.
Future<void> showTrackDetails(BuildContext context, Track track) async {
  final rows = _detailRows(track);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.35,
        maxChildSize: 0.94,
        builder: (context, controller) => Container(
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
                        'Detalles de la canción',
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
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(row.key),
                      subtitle: Text(row.value),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

List<MapEntry<String, String>> _detailRows(Track track) {
  final rows = <MapEntry<String, String>>[];

  void add(String label, Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) rows.add(MapEntry(label, text));
  }

  add('Título', track.title);
  add('Artista', track.artist);
  add('Álbum', track.album);
  add('Artista del álbum', track.albumArtist);
  add('Año', track.year);
  add('Género', track.genre);
  if (track.trackNumber != null) {
    final total = track.trackTotal;
    add(
      'Pista',
      total == null ? '${track.trackNumber}' : '${track.trackNumber} / $total',
    );
  }
  if (track.discNumber != null) add('Disco', track.discNumber);
  if (track.durationMs != null && track.durationMs! > 0) {
    add('Duración', _formatDuration(Duration(milliseconds: track.durationMs!)));
  }
  if (track.bitrateBps != null && track.bitrateBps! > 0) {
    add('Bitrate', '${(track.bitrateBps! / 1000).round()} kbps');
  }
  if (track.sampleRate != null && track.sampleRate! > 0) {
    add(
      'Frecuencia',
      '${(track.sampleRate! / 1000).toStringAsFixed(1)} kHz',
    );
  }
  add('Formato', track.format?.toUpperCase());
  add('Origen', track.source);
  add('Licencia', track.license);
  if (track.subtitlePath != null) add('Subtítulos', 'Adjuntos');
  if (track.artworkPath != null) add('Carátula', 'Extraída del archivo');

  final extra = track.extraTags;
  if (extra != null) {
    extra.forEach((key, value) => add(key, value));
  }
  return rows;
}

String _formatDuration(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:$minutes:$seconds'
      : '$minutes:$seconds';
}
