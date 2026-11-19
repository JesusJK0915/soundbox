import 'dart:io';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import 'models.dart';

/// Generates and caches one Material You seed color per track from its cover
/// art. The seed is derived from the cover's dominant/vibrant color instead of
/// an arbitrary ID, so the player palette really follows the image.
class ArtworkPaletteService extends ChangeNotifier {
  final Map<String, Future<Color?>> _pending = <String, Future<Color?>>{};
  final Map<String, Color?> _cache = <String, Color?>{};

  Color? seedFor(Track track) => _cache[track.id];

  Future<Color?> ensureSeed(Track track) {
    final cached = _cache[track.id];
    if (cached != null) return Future.value(cached);
    return _pending.putIfAbsent(track.id, () async {
      final color = await _extract(track);
      _cache[track.id] = color;
      _pending.remove(track.id);
      notifyListeners();
      return color;
    });
  }

  Future<Color?> _extract(Track track) async {
    try {
      final imageProvider = _imageProviderFor(track);
      if (imageProvider == null) return null;

      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(256, 256),
        maximumColorCount: 16,
        timeout: const Duration(seconds: 8),
      );
      final source = palette.vibrantColor ??
          palette.mutedColor ??
          palette.lightVibrantColor ??
          palette.dominantColor ??
          palette.darkVibrantColor;
      return source?.color;
    } catch (_) {
      return null;
    }
  }

  ImageProvider? _imageProviderFor(Track track) {
    final path = track.artworkPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) return FileImage(file);
    }

    final url = track.artworkUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return NetworkImage(url);
      }
      final file = File(url);
      if (file.existsSync()) return FileImage(file);
    }
    return null;
  }
}
