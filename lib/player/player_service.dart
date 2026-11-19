import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/connectivity_service.dart';
import '../core/library_service.dart';
import '../core/listening_stats.dart';
import '../core/lyrics_service.dart';
import '../core/models.dart';
import '../core/user_preferences.dart';

/// Velocidades ofrecidas en el reproductor.
const playbackSpeeds = <double>[0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

class PlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final ConnectivityService _connectivity;
  final UserPreferencesService? _prefs;
  final LibraryService? _library;
  final LyricsService? _lyrics;
  final ListeningStatsService? _stats;

  List<Track> _queue = <Track>[];
  int _index = 0;
  bool _shuffle = false;
  LoopMode _loopMode = LoopMode.off;
  double _speed = 1;
  final Set<String> _lyricsRequested = <String>{};

  Timer? _sleepTimer;
  Timer? _sleepTicker;
  Duration? _sleepRemaining;
  int _lastSavedMs = 0;
  int _listeningSeconds = 0;
  DateTime? _lastListeningTick;

  PlayerService(
    this._connectivity, [
    this._prefs,
    this._library,
    this._lyrics,
    this._stats,
  ]) {
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.positionStream.listen((position) {
      // Guarda la posición cada 5 s para reanudar después de reiniciar.
      if (position.inMilliseconds - _lastSavedMs >= 5000) {
        _lastSavedMs = position.inMilliseconds;
        final track = currentTrack;
        if (track != null) {
          unawaited(_prefs?.savePosition(track.id, position));
        }
      }
      if (_player.playing) {
        final now = DateTime.now();
        final last = _lastListeningTick;
        if (last != null) {
          _listeningSeconds += now.difference(last).inSeconds;
        }
        _lastListeningTick = now;
        if (_listeningSeconds >= 60) {
          final seconds = _listeningSeconds;
          _listeningSeconds = 0;
          unawaited(_stats?.addListeningTime(Duration(seconds: seconds)));
        }
      } else {
        _lastListeningTick = null;
      }
      notifyListeners();
    });
    _player.durationStream.listen((_) => notifyListeners());
    _player.currentIndexStream.listen((index) {
      if (index != null && index < _queue.length) {
        _index = index;
        _lastSavedMs = 0;
        _maybeFetchLyrics();
        notifyListeners();
      }
    });

    final prefs = _prefs;
    if (prefs != null) {
      if (prefs.rememberShuffle) {
        _shuffle = prefs.getBool('player.shuffle_saved');
      }
      if (prefs.rememberSpeed) {
        final saved = prefs.getDouble('player.speed_saved');
        if (saved != null) _speed = saved;
      }
      unawaited(_player.setVolume(prefs.volume));
    }

    _connectivity.addListener(() {
      if (_connectivity.isOnline) return;
      final current = currentTrack;
      if (current == null || current.isLocal) return;
      final localIndex = _queue.indexWhere((track) => track.isLocal);
      if (localIndex >= 0) {
        playIndex(localIndex);
      } else {
        stop();
      }
    });
  }

  void _rememberPlaybackSettings() {
    final prefs = _prefs;
    if (prefs == null) return;
    if (prefs.rememberShuffle) prefs.setBool('player.shuffle_saved', _shuffle);
    if (prefs.rememberSpeed) prefs.setDouble('player.speed_saved', _speed);
  }

  /// Atenúa el volumen antes de cambiar de pista cuando el crossfade está activo.
  Future<void> _crossfadeIfNeeded() async {
    final prefs = _prefs;
    if (!crossfade || prefs == null) return;
    final target = prefs.volume;
    for (var step = 1; step <= 4; step++) {
      await _player.setVolume(target * (1 - step / 4));
      await Future<void>.delayed(const Duration(milliseconds: 70));
    }
  }

  Future<void> _restoreVolume() async {
    final prefs = _prefs;
    if (prefs != null) await _player.setVolume(prefs.volume);
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Busca letras en LRCLIB una vez por pista cuando no hay subtítulo local.
  void _maybeFetchLyrics() {
    final prefs = _prefs;
    final library = _library;
    final lyrics = _lyrics;
    final track = currentTrack;
    if (prefs == null || library == null || lyrics == null || track == null) {
      return;
    }
    if (!prefs.autoLyrics || track.subtitlePath != null) return;
    if (!_connectivity.isOnline) return;
    if (prefs.lowData && !track.isLocal) return;
    if (!_lyricsRequested.add(track.id)) return;
    unawaited(_downloadLyrics(track));
  }

  Future<void> _downloadLyrics(Track track) async {
    final result = await lyricsServiceFor(track);
    if (result == null) return;
    final content = result.lrcContent;
    if (content == null) return;
    await _library?.attachLyrics(track.id, content);
  }

  Future<LyricsResult?> lyricsServiceFor(Track track) async {
    final lyrics = _lyrics;
    if (lyrics == null) return null;
    return lyrics.fetch(track);
  }

  /// Fuerza una búsqueda de letra para la pista actual.
  Future<LyricsResult?> refreshLyrics() async {
    final track = currentTrack;
    final lyrics = _lyrics;
    if (track == null || lyrics == null) return null;
    return lyrics.fetch(track);
  }

  Track? get currentTrack => _queue.isEmpty
      ? null
      : _queue[_index.clamp(0, _queue.length - 1).toInt()];
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  List<Track> get queue => List.unmodifiable(_queue);
  bool get shuffle => _shuffle;
  LoopMode get loopMode => _loopMode;
  double get speed => _speed;

  bool get sleepActive => _sleepTimer != null;
  Duration? get sleepRemaining => _sleepRemaining;

  Future<void> setQueue(List<Track> tracks, {int index = 0}) async {
    if (tracks.isEmpty) return;
    _queue = List<Track>.from(tracks);
    _index = index.clamp(0, _queue.length - 1).toInt();
    final selected = _queue[_index];
    final saved = _prefs?.positionFor(selected.id) ?? Duration.zero;
    _lastSavedMs = saved.inMilliseconds;

    final sources = _queue
        .map((track) => AudioSource.uri(_uriFor(track), tag: track))
        .toList();

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: _index,
      initialPosition: saved,
    );
    await _applyAudioSettings();
    unawaited(_prefs?.registerPlay(selected.id));
    unawaited(_prefs?.recordPlayback(selected.id));
    _maybeFetchLyrics();
    await _player.play();
    notifyListeners();
  }

  Future<void> _applyAudioSettings() async {
    await _player.setLoopMode(_loopMode);
    await _player.setShuffleModeEnabled(_shuffle);
    await _player.setSpeed(_speed);
    if (_prefs != null) {
      await _player.setVolume(_prefs!.volume);
    }
  }

  /// Reproduce toda la lista desde el principio (o en aleatorio).
  Future<void> playAll(List<Track> tracks, {bool shuffled = false}) async {
    if (tracks.isEmpty) return;
    late final List<Track> ordered;
    if (shuffled) {
      ordered = List<Track>.from(tracks)..shuffle();
    } else {
      ordered = tracks;
    }
    if (shuffle != shuffled) await toggleShuffle();
    await setQueue(ordered);
  }

  Future<void> playIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _index = index;
    final selected = _queue[index];
    final saved = _prefs?.positionFor(selected.id) ?? Duration.zero;
    _lastSavedMs = saved.inMilliseconds;
    await _player.seek(saved, index: index);
    unawaited(_prefs?.registerPlay(selected.id));
    unawaited(_prefs?.recordPlayback(selected.id));
    _maybeFetchLyrics();
    await _player.play();
    notifyListeners();
  }

  Future<void> enqueue(Track track) async {
    _queue.add(track);
    final source = _player.audioSource;
    if (source is ConcatenatingAudioSource) {
      await source.add(AudioSource.uri(_uriFor(track), tag: track));
    }
    notifyListeners();
  }

  /// Inserta una canción justo después de la que suena ahora.
  Future<void> playNext(Track track) async {
    final insertAt = (_player.currentIndex ?? _index) + 1;
    final position = insertAt.clamp(0, _queue.length).toInt();
    _queue.insert(position, track);
    final source = _player.audioSource;
    if (source is ConcatenatingAudioSource) {
      await source.insert(position, AudioSource.uri(_uriFor(track), tag: track));
    }
    notifyListeners();
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    final source = _player.audioSource;
    if (source is ConcatenatingAudioSource) {
      await source.removeAt(index);
    }
    if (_index >= _queue.length) _index = _queue.isEmpty ? 0 : _queue.length - 1;
    notifyListeners();
  }

  /// Mueve una canción dentro de la cola (usado por los botones de la cola).
  Future<void> moveQueueItem(int from, int to) async {
    if (from < 0 || to < 0 || from >= _queue.length || to >= _queue.length) {
      return;
    }
    final track = _queue.removeAt(from);
    _queue.insert(to, track);
    _index = _queue.indexWhere((item) => item.id == track.id);
    if (_index < 0) _index = 0;

    try {
      final source = _player.audioSource;
      if (source is ConcatenatingAudioSource) await source.move(from, to);
    } catch (_) {
      // Algunas versiones de just_audio no permiten mover durante la
      // reproducción: se reconstruye la cola conservando posición y tiempo.
      final saved = _player.position;
      final sources = _queue
          .map((item) => AudioSource.uri(_uriFor(item), tag: item))
          .toList();
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: _index,
        initialPosition: saved,
      );
      await _player.setLoopMode(_loopMode);
      await _player.setShuffleModeEnabled(_shuffle);
      await _player.setSpeed(_speed);
    }
    notifyListeners();
  }

  Future<void> clearQueue() async {
    _queue = <Track>[];
    _index = 0;
    await _player.stop();
    await _player.setAudioSource(ConcatenatingAudioSource(children: const []));
    notifyListeners();
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
    await _prefs?.setVolume(volume);
  }

  /// Guarda la cola actual para restaurarla al reiniciar.
  Future<void> persistQueue() async {
    final ids = _queue.map((track) => track.id).toList();
    await _prefs?.setCustomQueue(ids);
    await _prefs?.recordQueue(ids);
  }

  /// Reordena la cola de forma aleatoria (o sesgada a favoritas).
  Future<void> shuffleQueue() async {
    final prefs = _prefs;
    if (prefs == null || _queue.isEmpty) return;
    final current = currentTrack;
    final rest = List<Track>.from(_queue)..removeWhere((track) => track == current);
    if (prefs.shuffleBiased) {
      rest.sort((a, b) {
        final scoreA = (prefs.isFavorite(a.id) ? 1 : 0) + prefs.playCount(a.id);
        final scoreB = (prefs.isFavorite(b.id) ? 1 : 0) + prefs.playCount(b.id);
        return scoreB.compareTo(scoreA);
      });
    }
    rest.shuffle();
    final ordered = <Track>[if (current != null) current, ...rest];
    await setQueue(ordered, index: 0);
    await persistQueue();
  }

  /// Opciones de audio avanzadas (crossfade/gapless) para la interfaz.
  bool get crossfade => _prefs?.crossfade ?? false;
  bool get gapless => _prefs?.gapless ?? true;

  Future<void> setCrossfade(bool value) async {
    await _prefs?.setCrossfade(value);
    notifyListeners();
  }

  Future<void> setGaplessWithRestart(bool value) async {
    await setGapless(value);
    final current = currentTrack;
    if (current == null || _queue.isEmpty) return;
    final saved = _player.position;
    final sources = _queue
        .map((track) => AudioSource.uri(_uriFor(track), tag: track))
        .toList();
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: _index,
      initialPosition: saved,
    );
    await _applyAudioSettings();
  }

  Future<void> setGapless(bool value) async {
    await _prefs?.setGapless(value);
    notifyListeners();
  }

  Future<void> skipNext() async {
    await _crossfadeIfNeeded();
    await _player.seekToNext();
    await _restoreVolume();
    await _player.play();
  }

  Future<void> skipPrevious() async {
    await _crossfadeIfNeeded();
    await _player.seekToPrevious();
    await _restoreVolume();
    await _player.play();
  }

  Future<void> toggleShuffle() async {
    _shuffle = !_shuffle;
    await _player.setShuffleModeEnabled(_shuffle);
    _rememberPlaybackSettings();
    notifyListeners();
  }

  /// Ciclo: sin repetir → toda la cola → una canción → sin repetir.
  Future<void> toggleLoop() async {
    _loopMode = switch (_loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      _ => LoopMode.off,
    };
    await _player.setLoopMode(_loopMode);
    notifyListeners();
  }

  // ——— Velocidad ———

  double get nextSpeed {
    final index = playbackSpeeds.indexOf(_speed);
    return playbackSpeeds[(index + 1) % playbackSpeeds.length];
  }

  Future<void> setSpeed(double value) async {
    _speed = value;
    await _player.setSpeed(value);
    _rememberPlaybackSettings();
    notifyListeners();
  }

  Future<void> cycleSpeed() => setSpeed(nextSpeed);

  // ——— Temporizador de sueño ———

  void startSleepTimer(Duration duration) {
    cancelSleepTimer(notify: false);
    _sleepRemaining = duration;
    _sleepTimer = Timer(duration, () async {
      if (_prefs?.sleepFade ?? false) await _crossfadeIfNeeded();
      await _player.pause();
      await _restoreVolume();
      cancelSleepTimer();
    });
    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _sleepRemaining;
      if (remaining == null) return;
      _sleepRemaining =
          remaining > const Duration(seconds: 1)
              ? remaining - const Duration(seconds: 1)
              : Duration.zero;
      notifyListeners();
    });
    notifyListeners();
  }

  void addSleepTime(Duration extra) {
    if (!sleepActive) return;
    _sleepTimer?.cancel();
    _sleepRemaining = (_sleepRemaining ?? Duration.zero) + extra;
    _sleepTimer = Timer(_sleepRemaining!, () async {
      if (_prefs?.sleepFade ?? false) await _crossfadeIfNeeded();
      await _player.pause();
      await _restoreVolume();
      cancelSleepTimer();
    });
    notifyListeners();
  }

  void cancelSleepTimer({bool notify = true}) {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();
    _sleepTimer = null;
    _sleepTicker = null;
    _sleepRemaining = null;
    if (notify) notifyListeners();
  }

  Uri _uriFor(Track track) =>
      track.isLocal ? Uri.file(track.sourceUrl) : Uri.parse(track.sourceUrl);

  @override
  void dispose() {
    cancelSleepTimer(notify: false);
    _player.dispose();
    super.dispose();
  }
}
