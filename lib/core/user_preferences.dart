import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Orden disponible para la biblioteca.
enum LibrarySort { title, artist, year, recent, plays }

/// Modo de tema de la interfaz.
enum AppThemeMode { system, light, dark }

/// Preferencias del usuario, favoritos y estadísticas de escucha.
///
/// Todo se guarda en `SharedPreferences` y se publica con `notifyListeners`
/// para que la interfaz reaccione al instante.
class UserPreferencesService extends ChangeNotifier {
  static const favoritesKey = 'user.favorites';
  static const playCountsKey = 'user.play_counts';
  static const lastPlayedKey = 'user.last_played';
  static const positionsKey = 'user.positions';
  static const sortKey = 'user.library_sort';
  static const gridKey = 'user.library_grid';
  static const themeModeKey = 'user.theme_mode';
  static const hapticsKey = 'user.haptics';
  static const gesturesKey = 'user.gestures';
  static const dockVisibleKey = 'user.dock_visible';
  static const dockXKey = 'user.dock_x';
  static const dockYKey = 'user.dock_y';

  UserPreferencesService([SharedPreferences? prefs]) : _prefs = prefs {
    _favorites = _readList(favoritesKey).toSet();
    _playCounts = _readMap(playCountsKey)
        .map((key, value) => MapEntry(key, (value as num).toInt()));
    _lastPlayed = _readMap(lastPlayedKey)
        .map((key, value) => MapEntry(key, (value as num).toInt()));
    _positions = _readMap(positionsKey)
        .map((key, value) => MapEntry(key, (value as num).toInt()));
    final sortIndex = _prefs?.getInt(sortKey) ?? 0;
    final themeIndex = _prefs?.getInt(themeModeKey) ?? 0;
    _sort = LibrarySort.values[
        sortIndex.clamp(0, LibrarySort.values.length - 1).toInt()];
    _gridView = _prefs?.getBool(gridKey) ?? false;
    _themeMode = AppThemeMode.values[
        themeIndex.clamp(0, AppThemeMode.values.length - 1).toInt()];
    _haptics = _prefs?.getBool(hapticsKey) ?? true;
    _gestures = _prefs?.getBool(gesturesKey) ?? true;
    _dockVisible = _prefs?.getBool(dockVisibleKey) ?? true;
    _dockX = _prefs?.getDouble(dockXKey) ?? 0.5;
    _dockY = _prefs?.getDouble(dockYKey) ?? 0.88;
  }

  final SharedPreferences? _prefs;

  late Set<String> _favorites;
  late Map<String, int> _playCounts;
  late Map<String, int> _lastPlayed;
  late Map<String, int> _positions;
  late LibrarySort _sort;
  late bool _gridView;
  late AppThemeMode _themeMode;
  late bool _haptics;
  late bool _gestures;
  late bool _dockVisible;
  late double _dockX;
  late double _dockY;

  static Future<UserPreferencesService> load() async =>
      UserPreferencesService(await SharedPreferences.getInstance());

  List<String> _readList(String key) {
    final stored = _prefs?.get(key);
    if (stored is List) {
      return stored.map((value) => value.toString()).toList();
    }
    if (stored is String) {
      try {
        final decoded = jsonDecode(stored);
        if (decoded is List) {
          return decoded.map((value) => value.toString()).toList();
        }
      } catch (_) {}
    }
    return const <String>[];
  }

  Map<String, dynamic> _readMap(String key) {
    final stored = _prefs?.get(key);
    if (stored is String) {
      try {
        final decoded = jsonDecode(stored);
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {}
    }
    if (stored is Map) {
      return stored.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  Future<void> _write(String key, Object value) async {
    await _prefs?.setString(key, jsonEncode(value));
  }

  // ——— Favoritos ———

  Set<String> get favoriteIds => Set<String>.unmodifiable(_favorites);
  bool isFavorite(String id) => _favorites.contains(id);

  Future<void> toggleFavorite(String id) async {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    await _write(favoritesKey, _favorites.toList());
    notifyListeners();
  }

  Future<void> setFavorite(String id, bool value) async {
    if (value == _favorites.contains(id)) return;
    await toggleFavorite(id);
  }

  List<Track> favorites(Iterable<Track> tracks) =>
      tracks.where((track) => isFavorite(track.id)).toList();

  // ——— Estadísticas ———

  int playCount(String id) => _playCounts[id] ?? 0;
  int get totalPlays =>
      _playCounts.values.fold<int>(0, (sum, value) => sum + value);

  DateTime? lastPlayed(String id) {
    final millis = _lastPlayed[id];
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> registerPlay(String id) async {
    _playCounts[id] = playCount(id) + 1;
    _lastPlayed[id] = DateTime.now().millisecondsSinceEpoch;
    await _write(playCountsKey, _playCounts);
    await _write(lastPlayedKey, _lastPlayed);
    notifyListeners();
  }

  List<Track> mostPlayed(Iterable<Track> tracks) {
    final result = tracks.toList()
      ..sort((a, b) => playCount(b.id).compareTo(playCount(a.id)));
    return result;
  }

  List<Track> recentlyPlayed(Iterable<Track> tracks) {
    final result = tracks.where((track) => _lastPlayed.containsKey(track.id)).toList()
      ..sort((a, b) => _lastPlayed[b.id]!.compareTo(_lastPlayed[a.id]!));
    return result;
  }

  // ——— Posición de reproducción ———

  Duration positionFor(String id) =>
      Duration(milliseconds: _positions[id] ?? 0);

  /// No notifica: se llama varias veces por minuto desde el reproductor.
  Future<void> savePosition(String id, Duration position) async {
    if (position.inMilliseconds < 1000) return;
    if (_positions[id] == position.inMilliseconds) return;
    _positions[id] = position.inMilliseconds;
    await _write(positionsKey, _positions);
  }

  // ——— Biblioteca ———

  LibrarySort get sort => _sort;

  Future<void> setSort(LibrarySort value) async {
    if (_sort == value) return;
    _sort = value;
    await _prefs?.setInt(sortKey, value.index);
    notifyListeners();
  }

  bool get gridView => _gridView;

  Future<void> setGridView(bool value) async {
    if (_gridView == value) return;
    _gridView = value;
    await _prefs?.setBool(gridKey, value);
    notifyListeners();
  }

  /// Aplica el orden elegido por el usuario a una lista de canciones.
  List<Track> sorted(Iterable<Track> tracks) {
    final result = tracks.toList();
    switch (_sort) {
      case LibrarySort.title:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case LibrarySort.artist:
        result.sort((a, b) {
          final byArtist = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          return byArtist != 0
              ? byArtist
              : a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
      case LibrarySort.year:
        result.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
      case LibrarySort.recent:
        result.sort((a, b) => (b.id.compareTo(a.id)));
      case LibrarySort.plays:
        result.sort((a, b) => playCount(b.id).compareTo(playCount(a.id)));
    }
    return result;
  }

  // ——— Interfaz ———

  AppThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(AppThemeMode value) async {
    if (_themeMode == value) return;
    _themeMode = value;
    await _prefs?.setInt(themeModeKey, value.index);
    notifyListeners();
  }

  bool get haptics => _haptics;

  Future<void> setHaptics(bool value) async {
    if (_haptics == value) return;
    _haptics = value;
    await _prefs?.setBool(hapticsKey, value);
    notifyListeners();
  }

  bool get gestures => _gestures;

  Future<void> setGestures(bool value) async {
    if (_gestures == value) return;
    _gestures = value;
    await _prefs?.setBool(gesturesKey, value);
    notifyListeners();
  }

  bool get dockVisible => _dockVisible;

  Future<void> setDockVisible(bool value) async {
    if (_dockVisible == value) return;
    _dockVisible = value;
    await _prefs?.setBool(dockVisibleKey, value);
    notifyListeners();
  }

  double get dockX => _dockX;
  double get dockY => _dockY;

  /// Guarda la posición normalizada (0..1) del dock flotante.
  Future<void> setDockOffset(double x, double y) async {
    _dockX = x.clamp(0.0, 1.0);
    _dockY = y.clamp(0.0, 1.0);
    await _prefs?.setDouble(dockXKey, _dockX);
    await _prefs?.setDouble(dockYKey, _dockY);
    notifyListeners();
  }

  Future<void> resetStats() async {
    _favorites.clear();
    _playCounts.clear();
    _lastPlayed.clear();
    _positions.clear();
    await _write(favoritesKey, <String>[]);
    await _write(playCountsKey, <String, int>{});
    await _write(lastPlayedKey, <String, int>{});
    await _write(positionsKey, <String, int>{});
    notifyListeners();
  }
}
