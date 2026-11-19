import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/connectivity_service.dart';
import '../core/models.dart';
import '../core/user_preferences.dart';

/// Velocidades ofrecidas en el reproductor.
const playbackSpeeds = <double>[0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

class PlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final ConnectivityService _connectivity;
  final UserPreferencesService? _prefs;

  List<Track> _queue = <Track>[];
  int _index = 0;
  bool _shuffle = false;
  LoopMode _loopMode = LoopMode.off;
  double _speed = 1;

  Timer? _sleepTimer;
  Timer? _sleepTicker;
  Duration? _sleepRemaining;
  int _lastSavedMs = 0;

  PlayerService(this._connectivity, [this._prefs]) {
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
      notifyListeners();
    });
    _player.durationStream.listen((_) => notifyListeners());
    _player.currentIndexStream.listen((index) {
      if (index != null && index < _queue.length) {
        _index = index;
        _lastSavedMs = 0;
        notifyListeners();
      }
    });

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
    await _player.setLoopMode(_loopMode);
    await _player.setShuffleModeEnabled(_shuffle);
    await _player.setSpeed(_speed);
    unawaited(_prefs?.registerPlay(selected.id));
    await _player.play();
    notifyListeners();
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
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  Future<void> skipNext() async {
    await _player.seekToNext();
    await _player.play();
  }

  Future<void> skipPrevious() async {
    await _player.seekToPrevious();
    await _player.play();
  }

  Future<void> toggleShuffle() async {
    _shuffle = !_shuffle;
    await _player.setShuffleModeEnabled(_shuffle);
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
    notifyListeners();
  }

  Future<void> cycleSpeed() => setSpeed(nextSpeed);

  // ——— Temporizador de sueño ———

  void startSleepTimer(Duration duration) {
    cancelSleepTimer(notify: false);
    _sleepRemaining = duration;
    _sleepTimer = Timer(duration, () async {
      await _player.pause();
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
      await _player.pause();
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
