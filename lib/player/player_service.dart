import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/connectivity_service.dart';
import '../core/models.dart';

class PlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final ConnectivityService _connectivity;

  List<Track> _queue = <Track>[];
  int _index = 0;
  bool _shuffle = false;
  LoopMode _loopMode = LoopMode.off;

  PlayerService(this._connectivity) {
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.positionStream.listen((_) => notifyListeners());
    _player.durationStream.listen((_) => notifyListeners());
    _player.currentIndexStream.listen((index) {
      if (index != null && index < _queue.length) {
        _index = index;
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

  Future<void> setQueue(List<Track> tracks, {int index = 0}) async {
    if (tracks.isEmpty) return;
    _queue = List<Track>.from(tracks);
    _index = index.clamp(0, _queue.length - 1).toInt();

    final sources = _queue
        .map((track) => AudioSource.uri(_uriFor(track), tag: track))
        .toList();

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: _index,
      initialPosition: Duration.zero,
    );
    await _player.setLoopMode(_loopMode);
    await _player.setShuffleModeEnabled(_shuffle);
    await _player.play();
    notifyListeners();
  }

  Future<void> playIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _index = index;
    await _player.seek(Duration.zero, index: index);
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

  Future<void> toggleLoop() async {
    _loopMode = _loopMode == LoopMode.off ? LoopMode.all : LoopMode.off;
    await _player.setLoopMode(_loopMode);
    notifyListeners();
  }

  Uri _uriFor(Track track) =>
      track.isLocal ? Uri.file(track.sourceUrl) : Uri.parse(track.sourceUrl);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
