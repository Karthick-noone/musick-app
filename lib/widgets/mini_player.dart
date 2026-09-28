import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;

import '../providers/player_provider.dart';
import '../screens/now_playing/now_playing_screen.dart';

/// Compact bar above the bottom nav, per section 15 of the spec. Hidden
/// entirely (via AnimatedSize/AnimatedOpacity) when nothing is loaded, and
/// slides/fades in the moment a song starts — one of the few animations
/// the spec explicitly asks for.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(playerProvider);
    final song = snapshot.currentSong;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: song == null
          ? const SizedBox(width: double.infinity, height: 0)
          : SafeArea(
              top: false,
              bottom: false,
              child: Material(
                color: scheme.surfaceContainerHigh,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: oaq.QueryArtworkWidget(
                              id: int.tryParse(song.mediaId) ?? 0,
                              type: oaq.ArtworkType.AUDIO,
                              artworkFit: BoxFit.cover,
                              nullArtworkWidget: Container(
                                color: scheme.primaryContainer,
                                child: Icon(Icons.music_note_rounded, color: scheme.onPrimaryContainer, size: 20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                              ),
                              Text(
                                song.artist ?? 'Unknown artist',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              snapshot.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              key: ValueKey(snapshot.isPlaying),
                            ),
                          ),
                          onPressed: () => ref.read(playerProvider.notifier).togglePlayPause(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          onPressed: () => ref.read(playerProvider.notifier).next(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
