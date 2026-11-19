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

  static const autoLyricsKey = 'user.auto_lyrics';
  static const lyricsKaraokeKey = 'user.lyrics_karaoke';
  static const queueRepeatKey = 'user.queue_repeat';
  static const crossfadeKey = 'user.crossfade';
  static const gaplessKey = 'user.gapless';
  static const shuffleBiasedKey = 'user.shuffle_biased';
  static const rememberShuffleKey = 'user.remember_shuffle';
  static const rememberSpeedKey = 'user.remember_speed';
  static const volumeKey = 'user.volume';
  static const scanOnStartKey = 'user.scan_on_start';
  static const autoMetadataKey = 'user.auto_metadata';
  static const groupArtistsKey = 'user.group_artists';
  static const showYearKey = 'user.show_year';
  static const showBitrateKey = 'user.show_bitrate';
  static const compactDockKey = 'user.compact_dock';
  static const swipeToSkipKey = 'user.swipe_to_skip';
  static const doubleTapFavoriteKey = 'user.double_tap_favorite';
  static const sleepFadeKey = 'user.sleep_fade';
  static const shuffleQueueKey = 'user.shuffle_queue';
  static const queueHistoryKey = 'user.queue_history';
  static const customQueueKey = 'user.custom_queue';
  static const playbackHistoryKey = 'user.playback_history';
  static const lyricFontKey = 'user.lyric_font';
  static const artworkBlurKey = 'user.artwork_blur';
  static const lowDataKey = 'user.low_data';

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

    _autoLyrics = flag(autoLyricsKey, true);
    _lyricsKaraoke = flag(lyricsKaraokeKey, true);
    _queueRepeat = flag(queueRepeatKey, false);
    _crossfade = flag(crossfadeKey, false);
    _gapless = flag(gaplessKey, true);
    _shuffleBiased = flag(shuffleBiasedKey, false);
    _rememberShuffle = flag(rememberShuffleKey, false);
    _rememberSpeed = flag(rememberSpeedKey, true);
    _volume = (_prefs?.getDouble(volumeKey) ?? 1).clamp(0.0, 1.0);
    _scanOnStart = flag(scanOnStartKey, false);
    _autoMetadata = flag(autoMetadataKey, true);
    _groupArtists = flag(groupArtistsKey, false);
    _showYear = flag(showYearKey, true);
    _showBitrate = flag(showBitrateKey, false);
    _compactDock = flag(compactDockKey, false);
    _swipeToSkip = flag(swipeToSkipKey, true);
    _doubleTapFavorite = flag(doubleTapFavoriteKey, true);
    _sleepFade = flag(sleepFadeKey, true);
    _shuffleQueue = _readList(shuffleQueueKey).toSet();
    _queueHistory = _readList(queueHistoryKey);
    _customQueue = _readList(customQueueKey);
    _playbackHistory = _readList(playbackHistoryKey);
    _lyricFont = _prefs?.getDouble(lyricFontKey) ?? 22;
    _artworkBlur = flag(artworkBlurKey, false);
    _lowData = flag(lowDataKey, false);
  }

  bool flag(String key, bool fallback) => _prefs?.getBool(key) ?? fallback;
  bool getBool(String key) => _prefs?.getBool(key) ?? false;
  double? getDouble(String key) => _prefs?.getDouble(key);

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

  late bool _autoLyrics;
  late bool _lyricsKaraoke;
  late bool _queueRepeat;
  late bool _crossfade;
  late bool _gapless;
  late bool _shuffleBiased;
  late bool _rememberShuffle;
  late bool _rememberSpeed;
  late double _volume;
  late bool _scanOnStart;
  late bool _autoMetadata;
  late bool _groupArtists;
  late bool _showYear;
  late bool _showBitrate;
  late bool _compactDock;
  late bool _swipeToSkip;
  late bool _doubleTapFavorite;
  late bool _sleepFade;
  late Set<String> _shuffleQueue;
  late List<String> _queueHistory;
  late List<String> _customQueue;
  late List<String> _playbackHistory;
  late double _lyricFont;
  late bool _artworkBlur;
  late bool _lowData;

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

  // ——— Nuevas preferencias ———

  bool get autoLyrics => _autoLyrics;
  Future<void> setAutoLyrics(bool value) => _setFlag(autoLyricsKey, value, (v) => _autoLyrics = v);

  bool get lyricsKaraoke => _lyricsKaraoke;
  Future<void> setLyricsKaraoke(bool value) =>
      _setFlag(lyricsKaraokeKey, value, (v) => _lyricsKaraoke = v);

  bool get queueRepeat => _queueRepeat;
  Future<void> setQueueRepeat(bool value) =>
      _setFlag(queueRepeatKey, value, (v) => _queueRepeat = v);

  bool get crossfade => _crossfade;
  Future<void> setCrossfade(bool value) =>
      _setFlag(crossfadeKey, value, (v) => _crossfade = v);

  bool get gapless => _gapless;
  Future<void> setGapless(bool value) =>
      _setFlag(gaplessKey, value, (v) => _gapless = v);

  bool get shuffleBiased => _shuffleBiased;
  Future<void> setShuffleBiased(bool value) =>
      _setFlag(shuffleBiasedKey, value, (v) => _shuffleBiased = v);

  bool get rememberShuffle => _rememberShuffle;
  Future<void> setRememberShuffle(bool value) =>
      _setFlag(rememberShuffleKey, value, (v) => _rememberShuffle = v);

  bool get rememberSpeed => _rememberSpeed;
  Future<void> setRememberSpeed(bool value) =>
      _setFlag(rememberSpeedKey, value, (v) => _rememberSpeed = v);

  double get volume => _volume;
  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    await _prefs?.setDouble(volumeKey, _volume);
    notifyListeners();
  }

  bool get scanOnStart => _scanOnStart;
  Future<void> setScanOnStart(bool value) =>
      _setFlag(scanOnStartKey, value, (v) => _scanOnStart = v);

  bool get autoMetadata => _autoMetadata;
  Future<void> setAutoMetadata(bool value) =>
      _setFlag(autoMetadataKey, value, (v) => _autoMetadata = v);

  bool get groupArtists => _groupArtists;
  Future<void> setGroupArtists(bool value) =>
      _setFlag(groupArtistsKey, value, (v) => _groupArtists = v);

  bool get showYear => _showYear;
  Future<void> setShowYear(bool value) =>
      _setFlag(showYearKey, value, (v) => _showYear = v);

  bool get showBitrate => _showBitrate;
  Future<void> setShowBitrate(bool value) =>
      _setFlag(showBitrateKey, value, (v) => _showBitrate = v);

  bool get compactDock => _compactDock;
  Future<void> setCompactDock(bool value) =>
      _setFlag(compactDockKey, value, (v) => _compactDock = v);

  bool get swipeToSkip => _swipeToSkip;
  Future<void> setSwipeToSkip(bool value) =>
      _setFlag(swipeToSkipKey, value, (v) => _swipeToSkip = v);

  bool get doubleTapFavorite => _doubleTapFavorite;
  Future<void> setDoubleTapFavorite(bool value) =>
      _setFlag(doubleTapFavoriteKey, value, (v) => _doubleTapFavorite = v);

  bool get sleepFade => _sleepFade;
  Future<void> setSleepFade(bool value) =>
      _setFlag(sleepFadeKey, value, (v) => _sleepFade = v);

  bool get artworkBlur => _artworkBlur;
  Future<void> setArtworkBlur(bool value) =>
      _setFlag(artworkBlurKey, value, (v) => _artworkBlur = v);

  bool get lowData => _lowData;
  Future<void> setLowData(bool value) =>
      _setFlag(lowDataKey, value, (v) => _lowData = v);

  double get lyricFont => _lyricFont;
  Future<void> setLyricFont(double value) async {
    _lyricFont = value.clamp(16.0, 34.0);
    await _prefs?.setDouble(lyricFontKey, _lyricFont);
    notifyListeners();
  }

  Future<void> _setFlag(String key, bool value, void Function(bool) apply) async {
    apply(value);
    await _prefs?.setBool(key, value);
    notifyListeners();
  }

  // ——— Cola personalizada, historial y aleatoriedad ———

  Set<String> get shuffleQueue => Set<String>.unmodifiable(_shuffleQueue);
  bool isInShuffleQueue(String id) => _shuffleQueue.contains(id);

  Future<void> toggleShuffleQueue(String id) async {
    if (!_shuffleQueue.add(id)) _shuffleQueue.remove(id);
    await _write(shuffleQueueKey, _shuffleQueue.toList());
    notifyListeners();
  }

  Future<void> setShuffleQueue(Iterable<String> ids) async {
    _shuffleQueue = ids.toSet();
    await _write(shuffleQueueKey, _shuffleQueue.toList());
    notifyListeners();
  }

  List<String> get customQueue => List<String>.unmodifiable(_customQueue);

  Future<void> setCustomQueue(Iterable<String> ids) async {
    _customQueue = ids.toList();
    await _write(customQueueKey, _customQueue);
    notifyListeners();
  }

  List<String> get queueHistory => List<String>.unmodifiable(_queueHistory);

  Future<void> recordQueue(List<String> ids) async {
    _queueHistory = [ids.join(','), ..._queueHistory.where((v) => v != ids.join(','))]
        .take(20)
        .toList();
    await _write(queueHistoryKey, _queueHistory);
    notifyListeners();
  }

  List<String> get playbackHistory => List<String>.unmodifiable(_playbackHistory);

  Future<void> recordPlayback(String id) async {
    _playbackHistory = [id, ..._playbackHistory.where((v) => v != id)].take(200).toList();
    await _write(playbackHistoryKey, _playbackHistory);
    notifyListeners();
  }

  Future<void> clearPlaybackHistory() async {
    _playbackHistory = <String>[];
    await _write(playbackHistoryKey, _playbackHistory);
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
    _playbackHistory = <String>[];
    _queueHistory = <String>[];
    await _write(playbackHistoryKey, _playbackHistory);
    await _write(queueHistoryKey, _queueHistory);
    notifyListeners();
  }
}
