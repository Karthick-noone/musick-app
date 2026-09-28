import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;

import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../services/audio_player_service.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(playerProvider);
    final scheme = Theme.of(context).colorScheme;
    final song = snapshot.currentSong;

    if (song == null) {
      return const Scaffold(body: Center(child: Text('Nothing playing')));
    }

    // Play count as known before this session's own increment lands in the
    // library list (library_provider updates it once the threshold hits).
    final libSong = ref.watch(libraryProvider).songs.where((s) => s.id == song.id).firstOrNull;
    final playCount = libSong?.playCount ?? song.playCount;

    final duration = snapshot.duration ?? song.duration;
    final position = snapshot.position > duration ? duration : snapshot.position;
    final progress = duration.inMilliseconds == 0 ? 0.0 : position.inMilliseconds / duration.inMilliseconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            onPressed: () {
              // Queue view lands in Phase 3 alongside Playlists.
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Column(
            children: [
              const Spacer(),
              Hero(
                tag: 'now_playing_art_${song.mediaId}',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: scheme.primary.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: oaq.QueryArtworkWidget(
                      id: int.tryParse(song.mediaId) ?? 0,
                      type: oaq.ArtworkType.AUDIO,
                      artworkFit: BoxFit.cover,
                      artworkWidth: 280,
                      artworkHeight: 280,
                      nullArtworkWidget: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [scheme.primary, scheme.tertiary]),
                        ),
                        child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 96),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                song.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 21),
              ),
              const SizedBox(height: 4),
              Text(
                [song.artist, song.album].where((e) => e != null && e.isNotEmpty).join(' • '),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14.5),
              ),
              if (playCount > 0) ...[
                const SizedBox(height: 6),
                Text('Played $playCount times', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
              ],
              const SizedBox(height: 20),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (v) {
                    final target = Duration(milliseconds: (v * duration.inMilliseconds).round());
                    ref.read(playerProvider.notifier).seek(target);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(position), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                    Text(_fmt(duration), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 24,
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: snapshot.shuffleEnabled ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    onPressed: () => ref.read(playerProvider.notifier).toggleShuffle(),
                  ),
                  IconButton(
                    iconSize: 34,
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: () => ref.read(playerProvider.notifier).previous(),
                  ),
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary),
                    child: IconButton(
                      iconSize: 38,
                      color: scheme.onPrimary,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          snapshot.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          key: ValueKey(snapshot.isPlaying),
                        ),
                      ),
                      onPressed: () => ref.read(playerProvider.notifier).togglePlayPause(),
                    ),
                  ),
                  IconButton(
                    iconSize: 34,
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () => ref.read(playerProvider.notifier).next(),
                  ),
                  IconButton(
                    iconSize: 24,
                    icon: Icon(
                      switch (snapshot.repeatOption) {
                        RepeatOption.off => Icons.repeat_rounded,
                        RepeatOption.all => Icons.repeat_rounded,
                        RepeatOption.one => Icons.repeat_one_rounded,
                      },
                      color: snapshot.repeatOption == RepeatOption.off ? scheme.onSurfaceVariant : scheme.primary,
                    ),
                    onPressed: () => ref.read(playerProvider.notifier).cycleRepeat(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      libSong?.isFavorite == true ? Icons.favorite : Icons.favorite_border,
                      color: libSong?.isFavorite == true ? scheme.error : scheme.onSurfaceVariant,
                    ),
                    onPressed: libSong == null ? null : () => ref.read(libraryProvider.notifier).toggleFavorite(libSong),
                  ),
                  IconButton(
                    icon: const Icon(Icons.playlist_add_rounded),
                    onPressed: () {
                      // Wired up in Phase 3 (Playlists).
                    },
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
