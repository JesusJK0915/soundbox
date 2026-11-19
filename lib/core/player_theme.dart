import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'artwork_palette_service.dart';
import 'models.dart';
import 'theme_settings.dart';

/// Deterministic fallback color, used when there is no usable cover art.
Color playerSeedColor(Track track) {
  final index = (track.id.hashCode & 0x7fffffff) % Colors.primaries.length;
  return Colors.primaries[index];
}

ColorScheme playerColorScheme(
  Track track,
  Brightness brightness, {
  Color? seedColor,
}) =>
    ColorScheme.fromSeed(
      seedColor: seedColor ?? playerSeedColor(track),
      brightness: brightness,
    );

/// Effective player palette, with three layers:
///
/// 1. Material You generated from the current cover art (when enabled and
///    available), so the player colors change with the song image.
/// 2. Wallpaper Material You from the system.
/// 3. A deterministic fallback color per track.
ColorScheme playerSchemeFor(BuildContext context, Track track) {
  final settings = context.watch<ThemeSettingsService>();
  final brightness = Theme.of(context).brightness;

  if (settings.artworkColors) {
    final palette = context.watch<ArtworkPaletteService>();
    final seed = palette.seedFor(track);
    if (seed != null) {
      return playerColorScheme(track, brightness, seedColor: seed);
    }
    // Start extraction after this build. This also makes the player recolor
    // once the image finishes loading the first time.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (palette.seedFor(track) == null) palette.ensureSeed(track);
    });
  }

  if (settings.wallpaperColors && !settings.artworkColors) {
    final wallpaper = WallpaperColors.maybeOf(context)?.schemeFor(brightness);
    if (wallpaper != null) return wallpaper;
  }
  return playerColorScheme(track, brightness);
}

/// Tag compartido entre el mini reproductor y la pantalla completa.
String playerArtHeroTag(Track track) => 'soundbox-art-${track.id}';
