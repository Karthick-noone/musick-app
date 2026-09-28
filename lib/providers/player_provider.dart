import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../models/song.dart';
import '../services/audio_player_service.dart';

/// Combines position/duration/playing into one snapshot so widgets only
/// need to watch a single provider instead of three separate streams.
class PlaybackSnapshot {
  final Song? currentSong;
  final Duration position;
  final Duration? duration;
  final bool isPlaying;
  final bool shuffleEnabled;
  final RepeatOption repeatOption;

  const PlaybackSnapshot({
    this.currentSong,
    this.position = Duration.zero,
    this.duration,
    this.isPlaying = false,
    this.shuffleEnabled = false,
    this.repeatOption = RepeatOption.off,
  });
}

/// Holds the single MusickAudioHandler for the app's lifetime and exposes
/// it (plus a merged playback stream) to every screen that needs playback
/// state: the mini-player, Now Playing, and song tiles' "currently
/// playing" highlight.
class PlayerNotifier extends StateNotifier<PlaybackSnapshot> {
  final MusickAudioHandler handler;
  final Ref ref;

  PlayerNotifier(this.handler, this.ref) : super(const PlaybackSnapshot()) {
    Rx.combineLatest3<Duration, Duration?, bool, PlaybackSnapshot>(
      handler.positionStream,
      handler.durationStream,
      handler.playingStream,
      (pos, dur, playing) => PlaybackSnapshot(
        currentSong: handler.currentSong,
        position: pos,
        duration: dur,
        isPlaying: playing,
        shuffleEnabled: handler.shuffleEnabled,
        repeatOption: handler.repeatOption,
      ),
    ).listen((snapshot) => state = snapshot);
  }

  Future<void> playQueue(List<Song> songs, {required int startIndex}) =>
      handler.loadQueue(songs, startIndex: startIndex);

  Future<void> togglePlayPause() {
    return state.isPlaying ? handler.pause() : handler.play();
  }

  Future<void> next() => handler.skipToNext();
  Future<void> previous() => handler.skipToPrevious();
  Future<void> seek(Duration position) => handler.seek(position);

  Future<void> toggleShuffle() async {
    await handler.toggleShuffle();
    state = PlaybackSnapshot(
      currentSong: state.currentSong,
      position: state.position,
      duration: state.duration,
      isPlaying: state.isPlaying,
      shuffleEnabled: handler.shuffleEnabled,
      repeatOption: state.repeatOption,
    );
  }

  void cycleRepeat() {
    handler.cycleRepeat();
    state = PlaybackSnapshot(
      currentSong: state.currentSong,
      position: state.position,
      duration: state.duration,
      isPlaying: state.isPlaying,
      shuffleEnabled: state.shuffleEnabled,
      repeatOption: handler.repeatOption,
    );
  }
}

/// Created once in main() after AudioService.init() and overridden into
/// the ProviderScope, so the same handler instance is shared by
/// audio_service (for the notification/lock screen) and the UI.
final audioHandlerProvider = Provider<MusickAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main()');
});

final playerProvider = StateNotifierProvider<PlayerNotifier, PlaybackSnapshot>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return PlayerNotifier(handler, ref);
});
