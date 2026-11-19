import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ajustes de apariencia. El interruptor se puede cambiar en cualquier momento
/// desde Ajustes y la app se redibuja al instante.
class ThemeSettingsService extends ChangeNotifier {
  static const wallpaperColorsKey = 'theme.wallpaper_colors';
  static const defaultWallpaperColors = true;

  ThemeSettingsService([SharedPreferences? prefs]) : _prefs = prefs {
    _wallpaperColors =
        _prefs?.getBool(wallpaperColorsKey) ?? defaultWallpaperColors;
  }

  final SharedPreferences? _prefs;
  bool _wallpaperColors;

  static Future<ThemeSettingsService> load() async =>
      ThemeSettingsService(await SharedPreferences.getInstance());

  bool get wallpaperColors => _wallpaperColors;

  void setWallpaperColors(bool value) {
    if (_wallpaperColors == value) return;
    _wallpaperColors = value;
    _prefs?.setBool(wallpaperColorsKey, value);
    notifyListeners();
  }
}

/// Esquemas Material You leidos del fondo de pantalla por `dynamic_color`.
/// Son null en dispositivos sin color dinamico (Android < 12) o mientras el
/// sistema todavia no responde.
class WallpaperColors extends InheritedWidget {
  const WallpaperColors({
    super.key,
    required this.light,
    required this.dark,
    required super.child,
  });

  final ColorScheme? light;
  final ColorScheme? dark;

  static WallpaperColors? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WallpaperColors>();

  ColorScheme? schemeFor(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  @override
  bool updateShouldNotify(WallpaperColors oldWidget) =>
      light != oldWidget.light || dark != oldWidget.dark;
}
