import 'dart:io';

import 'package:flutter/material.dart';

import '../core/models.dart';

/// Muestra la carátula incrustada en el archivo, la imagen remota de la fuente
/// o un icono de respaldo.
class TrackArtwork extends StatelessWidget {
  const TrackArtwork({
    super.key,
    required this.track,
    this.iconSize = 40,
    this.fit = BoxFit.cover,
  });

  final Track track;
  final double iconSize;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = track.artworkPath;

    Widget content;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      content = Image.file(File(path), fit: fit);
    } else if (track.artworkUrl != null && track.artworkUrl!.isNotEmpty) {
      content = Image.network(
        track.artworkUrl!,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(scheme),
      );
    } else {
      content = _placeholder(scheme);
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: scheme.secondaryContainer,
      child: content,
    );
  }

  Widget _placeholder(ColorScheme scheme) => Center(
        child: Icon(
          Icons.music_note_rounded,
          color: scheme.onSecondaryContainer,
          size: iconSize,
        ),
      );
}
