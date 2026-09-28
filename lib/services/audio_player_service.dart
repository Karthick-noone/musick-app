import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../core/constants/app_constants.dart';
import '../models/song.dart';

enum RepeatOption { off, all, one }

/// The single AudioHandler instance registered with audio_service. It owns
/// the actual just_audio player, the current queue, shuffle/repeat state,
/// and reports play/pause/seek/skip back to Android's lock-screen and
/// notification controls (section 16 of the spec). Everything the UI needs
/// is exposed as streams so PlayerProvider (Riverpod) can expose them to
/// widgets without the UI ever touching just_audio directly.
class MusickAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _shuffle = false;
  RepeatOption _repeat = RepeatOption.off;
  List<int> _shuffleOrder = [];

  /// Fired once per song, the first time it crosses
  /// AppConstants.minPlaySecondsToCount of real playback — this is what
  /// library_provider hooks into to increment play_count / play_history.
  final void Function(Song song, int durationPlayedMs) onValidPlay;

  bool _countedThisSong = false;
  Timer? _countTimer;

  Song? get currentSong => (_currentIndex >= 0 && _currentIndex < _queue.length) ? _queue[_currentIndex] : null;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;

  MusickAudioHandler({required this.onValidPlay}) {
    _player.playbackEventStream.listen(_broadcastState, onError: (Object e, StackTrace st) {
      // A single corrupted/unsupported file must not crash playback —
      // skip to the next track instead (section 30: error handling).
      skipToNext();
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });

    // Re-arm the "counts as a play" timer whenever a new track actually
    // starts loading, and cancel it on pause/skip so a quick skip never
    // counts.
    _player.playingStream.listen((playing) {
      if (playing) {
        _armCountTimer();
      } else {
        _countTimer?.cancel();
      }
    });
  }

  void _armCountTimer() {
    _countTimer?.cancel();
    if (_countedThisSong) return;
    _countTimer = Timer(const Duration(seconds: AppConstants.minPlaySecondsToCount), () {
      final song = currentSong;
      if (song != null && !_countedThisSong) {
        _countedThisSong = true;
        onValidPlay(song, _player.position.inMilliseconds);
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      queueIndex: _currentIndex,
    ));
  }

  /// Loads a fresh queue (e.g. "all songs" from the Songs screen, or a
  /// single album/playlist) and starts playback at [startIndex].
  Future<void> loadQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue = songs;
    _currentIndex = startIndex;
    _rebuildShuffleOrder();

    queue.add([
      for (final s in songs)
        MediaItem(
          id: s.mediaId,
          title: s.title,
          artist: s.artist ?? 'Unknown artist',
          album: s.album,
          duration: s.duration,
        ),
    ]);

    await _playIndex(_currentIndex);
  }

  Future<void> _playIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    _countedThisSong = false;
    _countTimer?.cancel();

    final song = _queue[index];
    mediaItem.add(MediaItem(
      id: song.mediaId,
      title: song.title,
      artist: song.artist ?? 'Unknown artist',
      album: song.album,
      duration: song.duration,
    ));

    try {
      await _player.setFilePath(song.filePath);
      await _player.play();
    } catch (_) {
      // Corrupted/missing/unsupported file — skip rather than crash
      // (section 30 & 17: graceful handling of bad audio files).
      await skipToNext();
    }
  }

  void _rebuildShuffleOrder() {
    _shuffleOrder = List.generate(_queue.length, (i) => i)..shuffle();
  }

  void _onTrackCompleted() {
    if (_repeat == RepeatOption.one) {
      _playIndex(_currentIndex);
      return;
    }
    skipToNext();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    int next;
    if (_shuffle) {
      final pos = _shuffleOrder.indexOf(_currentIndex);
      next = _shuffleOrder[(pos + 1) % _shuffleOrder.length];
    } else {
      next = _currentIndex + 1;
    }
    if (next >= _queue.length) {
      if (_repeat == RepeatOption.all) {
        next = 0;
      } else {
        await _player.stop();
        return;
      }
    }
    await _playIndex(next);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    // Restart the current song instead of going back if we're more than
    // 3 seconds in — matches common music-player UX.
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    int prev;
    if (_shuffle) {
      final pos = _shuffleOrder.indexOf(_currentIndex);
      prev = _shuffleOrder[(pos - 1 + _shuffleOrder.length) % _shuffleOrder.length];
    } else {
      prev = _currentIndex - 1;
    }
    if (prev < 0) prev = _repeat == RepeatOption.all ? _queue.length - 1 : 0;
    await _playIndex(prev);
  }

  Future<void> toggleShuffle() async {
    _shuffle = !_shuffle;
    if (_shuffle) _rebuildShuffleOrder();
  }

  bool get shuffleEnabled => _shuffle;

  void cycleRepeat() {
    _repeat = switch (_repeat) {
      RepeatOption.off => RepeatOption.all,
      RepeatOption.all => RepeatOption.one,
      RepeatOption.one => RepeatOption.off,
    };
  }

  RepeatOption get repeatOption => _repeat;

  @override
  Future<void> onTaskRemoved() async {
    await _player.stop();
    await super.onTaskRemoved();
  }

  Future<void> disposePlayer() async {
    _countTimer?.cancel();
    await _player.dispose();
  }
}
