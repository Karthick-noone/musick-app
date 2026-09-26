import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/song.dart';
import '../../providers/library_provider.dart';
import '../../widgets/song_tile.dart';

enum SongSort { recentlyAdded, recentlyPlayed, titleAz, titleZa, artist, album, mostPlayed, leastPlayed }

class SongsScreen extends ConsumerStatefulWidget {
  const SongsScreen({super.key});

  @override
  ConsumerState<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends ConsumerState<SongsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  SongSort _sort = SongSort.recentlyAdded;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Song> _applyFilterAndSort(List<Song> songs) {
    var result = songs;

    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      result = result.where((s) {
        return s.title.toLowerCase().contains(q) ||
            (s.artist ?? '').toLowerCase().contains(q) ||
            (s.album ?? '').toLowerCase().contains(q);
      }).toList();
    }

    final sorted = [...result];
    switch (_sort) {
      case SongSort.recentlyAdded:
        sorted.sort((a, b) => (b.dateAdded ?? b.createdAt).compareTo(a.dateAdded ?? a.createdAt));
        break;
      case SongSort.recentlyPlayed:
        sorted.sort((a, b) {
          final ap = a.lastPlayed ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bp = b.lastPlayed ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bp.compareTo(ap);
        });
        break;
      case SongSort.titleAz:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SongSort.titleZa:
        sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SongSort.artist:
        sorted.sort((a, b) => (a.artist ?? '').toLowerCase().compareTo((b.artist ?? '').toLowerCase()));
        break;
      case SongSort.album:
        sorted.sort((a, b) => (a.album ?? '').toLowerCase().compareTo((b.album ?? '').toLowerCase()));
        break;
      case SongSort.mostPlayed:
        sorted.sort((a, b) => b.playCount.compareTo(a.playCount));
        break;
      case SongSort.leastPlayed:
        sorted.sort((a, b) => a.playCount.compareTo(b.playCount));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Songs'),
        actions: [
          PopupMenuButton<SongSort>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: SongSort.recentlyAdded, child: Text('Recently added')),
              PopupMenuItem(value: SongSort.recentlyPlayed, child: Text('Recently played')),
              PopupMenuItem(value: SongSort.titleAz, child: Text('Title A-Z')),
              PopupMenuItem(value: SongSort.titleZa, child: Text('Title Z-A')),
              PopupMenuItem(value: SongSort.artist, child: Text('Artist')),
              PopupMenuItem(value: SongSort.album, child: Text('Album')),
              PopupMenuItem(value: SongSort.mostPlayed, child: Text('Most played')),
              PopupMenuItem(value: SongSort.leastPlayed, child: Text('Least played')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search songs, artists, albums',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: scheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(library)),
        ],
      ),
    );
  }

  Widget _buildBody(LibraryState library) {
    switch (library.status) {
      case LibraryStatus.initial:
      case LibraryStatus.scanning:
        if (library.songs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        break; // fall through to show cached songs while a rescan runs
      case LibraryStatus.needsPermission:
        return _PermissionNeeded(onGrant: () => ref.read(libraryProvider.notifier).requestPermissionAndScan());
      case LibraryStatus.error:
        return _ErrorState(
          message: library.errorMessage ?? 'Something went wrong.',
          onRetry: () => ref.read(libraryProvider.notifier).rescan(),
        );
      case LibraryStatus.ready:
        break;
    }

    final songs = _applyFilterAndSort(library.songs);

    if (songs.isEmpty) {
      return _EmptyState(
        hasQuery: _query.isNotEmpty,
        onScanAgain: () => ref.read(libraryProvider.notifier).rescan(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(libraryProvider.notifier).rescan(),
      child: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return SongTile(
            song: song,
            onTap: () {
              // Phase 2 wires this into AudioPlayerService.play(song).
            },
            onToggleFavorite: () => ref.read(libraryProvider.notifier).toggleFavorite(song),
            onRemove: () => _confirmRemove(context, song),
            onAddToPlaylist: () {
              // Implemented in Phase 3 (Playlists).
            },
          );
        },
      ),
    );
  }

  void _confirmRemove(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Library?'),
        content: const Text(
          'This song will disappear from your music library, but the original file will remain on your device.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(libraryProvider.notifier).removeFromLibrary(song);
              Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _PermissionNeeded extends StatelessWidget {
  final VoidCallback onGrant;
  const _PermissionNeeded({required this.onGrant});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_music_rounded, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Musick needs access to your music',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'This lets Musick find the audio files already on your device. Nothing leaves your phone.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onGrant, child: const Text('Allow Music Access')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  final VoidCallback onScanAgain;
  const _EmptyState({required this.hasQuery, required this.onScanAgain});

  @override
  Widget build(BuildContext context) {
    if (hasQuery) {
      return const Center(child: Text('No matching songs'));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_off_rounded, size: 56),
            const SizedBox(height: 16),
            const Text('No music found', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              "We couldn't find any audio files on your device.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onScanAgain, child: const Text('Scan Again')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
