import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song.dart';
import '../services/database_service.dart';
import '../services/music_scanner_service.dart';

enum LibraryStatus { initial, needsPermission, scanning, ready, error }

class LibraryState {
  final LibraryStatus status;
  final List<Song> songs;
  final String? errorMessage;

  const LibraryState({
    this.status = LibraryStatus.initial,
    this.songs = const [],
    this.errorMessage,
  });

  LibraryState copyWith({
    LibraryStatus? status,
    List<Song>? songs,
    String? errorMessage,
  }) {
    return LibraryState(
      status: status ?? this.status,
      songs: songs ?? this.songs,
      errorMessage: errorMessage,
    );
  }
}

/// Single source of truth for "what songs does the user have". Screens
/// (Home, Songs, Albums, Artists) all read from this instead of querying
/// SQLite or on_audio_query themselves.
class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier() : super(const LibraryState()) {
    _bootstrap();
  }

  final _scanner = MusicScannerService.instance;
  final _db = DatabaseService.instance;

  final Completer<void> _readyCompleter = Completer<void>();

  /// Resolves once the splash screen has enough to show (permission
  /// checked, cached songs loaded) — NOT once a full rescan completes, so
  /// startup never waits on scanning 700+ files.
  Future<void> get ready => _readyCompleter.future;

  Future<void> _bootstrap() async {
    final hasPerm = await _scanner.hasPermission();
    if (!hasPerm) {
      state = state.copyWith(status: LibraryStatus.needsPermission);
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
      return;
    }
    await _loadFromDbThenScan();
  }

  /// Called from the first-launch flow after the user taps
  /// "Allow Music Access".
  Future<bool> requestPermissionAndScan() async {
    final result = await _scanner.requestPermission();
    if (result != ScanPermissionResult.granted) {
      state = state.copyWith(status: LibraryStatus.needsPermission);
      return false;
    }
    await _loadFromDbThenScan();
    return true;
  }

  Future<void> _loadFromDbThenScan() async {
    // Show whatever's already cached immediately (fast startup for 700+
    // songs), then refresh in the background via a scan.
    final cached = await _db.getAllSongs();
    state = state.copyWith(status: LibraryStatus.ready, songs: cached);
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    await rescan();
  }

  Future<void> rescan() async {
    try {
      state = state.copyWith(status: LibraryStatus.scanning);
      await _scanner.scanLibrary();
      final songs = await _db.getAllSongs();
      state = state.copyWith(status: LibraryStatus.ready, songs: songs);
    } catch (e) {
      state = state.copyWith(status: LibraryStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> toggleFavorite(Song song) async {
    if (song.id == null) return;
    final newValue = !song.isFavorite;
    await _db.setFavorite(song.id!, newValue);
    state = state.copyWith(
      songs: [
        for (final s in state.songs)
          if (s.id == song.id) s.copyWith(isFavorite: newValue) else s,
      ],
    );
  }

  Future<void> removeFromLibrary(Song song) async {
    if (song.id == null) return;
    await _db.removeFromLibrary(song.id!);
    state = state.copyWith(
      songs: state.songs.where((s) => s.id != song.id).toList(),
    );
  }

  /// Called once real playback has crossed the "counts as a play" threshold
  /// (see AppConstants.minPlaySecondsToCount) — wired up in Phase 2 once the
  /// audio player service exists.
  Future<void> recordPlay(Song song, {required int durationPlayedMs}) async {
    if (song.id == null) return;
    await _db.recordPlay(song.id!, durationPlayedMs: durationPlayedMs);
    state = state.copyWith(
      songs: [
        for (final s in state.songs)
          if (s.id == song.id)
            s.copyWith(playCount: s.playCount + 1, lastPlayed: DateTime.now())
          else
            s,
      ],
    );
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier();
});
