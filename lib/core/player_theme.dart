import 'package:flutter/material.dart';

import 'models.dart';

/// Color semilla determinista por pista. Cada cancion obtiene una paleta
/// Material You distinta sin depender de permisos ni de una API externa.
Color playerSeedColor(Track track) {
  final index = (track.id.hashCode & 0x7fffffff) % Colors.primaries.length;
  return Colors.primaries[index];
}

ColorScheme playerColorScheme(Track track, Brightness brightness) =>
    ColorScheme.fromSeed(
      seedColor: playerSeedColor(track),
      brightness: brightness,
    );

/// Tag compartido entre el mini reproductor y la pantalla completa.
String playerArtHeroTag(Track track) => 'soundbox-art-${track.id}';
