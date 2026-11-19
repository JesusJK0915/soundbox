import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'theme_settings.dart';

/// Color semilla determinista por pista. Se usa cuando el usuario desactiva
/// los colores del fondo de pantalla o el dispositivo no los ofrece.
Color playerSeedColor(Track track) {
  final index = (track.id.hashCode & 0x7fffffff) % Colors.primaries.length;
  return Colors.primaries[index];
}

ColorScheme playerColorScheme(Track track, Brightness brightness) =>
    ColorScheme.fromSeed(
      seedColor: playerSeedColor(track),
      brightness: brightness,
    );

/// Esquema efectivo del reproductor: Material You del fondo de pantalla cuando
/// esta activado y disponible; en caso contrario, la paleta de la cancion.
ColorScheme playerSchemeFor(BuildContext context, Track track) {
  final settings = context.watch<ThemeSettingsService>();
  final brightness = Theme.of(context).brightness;
  if (settings.wallpaperColors) {
    final wallpaper = WallpaperColors.maybeOf(context)?.schemeFor(brightness);
    if (wallpaper != null) return wallpaper;
  }
  return playerColorScheme(track, brightness);
}

/// Tag compartido entre el mini reproductor y la pantalla completa.
String playerArtHeroTag(Track track) => 'soundbox-art-${track.id}';
