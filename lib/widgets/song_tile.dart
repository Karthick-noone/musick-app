import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;

import '../models/song.dart';

/// A single row in any song list (Songs, Favorites, Album detail, ...).
/// Handles its own artwork (via on_audio_query's artwork cache, falling
/// back to a generated tile per section 31 of the spec) so callers just
/// pass a [Song].
class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onRemove;
  final VoidCallback onAddToPlaylist;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onRemove,
    required this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 52,
          height: 52,
          child: oaq.QueryArtworkWidget(
            id: int.tryParse(song.mediaId) ?? 0,
            type: oaq.ArtworkType.AUDIO,
            artworkFit: BoxFit.cover,
            artworkBorder: BorderRadius.circular(10),
            nullArtworkWidget: _FallbackArt(song: song),
            errorBuilder: (context, error, stack) => _FallbackArt(song: song),
          ),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              song.artist ?? 'Unknown artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
          if (song.playCount > 0) ...[
            const SizedBox(width: 8),
            Text(
              '${song.playCount} plays',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              song.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: song.isFavorite ? scheme.error : scheme.onSurfaceVariant,
              size: 20,
            ),
            onPressed: onToggleFavorite,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
            onSelected: (value) {
              if (value == 'playlist') onAddToPlaylist();
              if (value == 'remove') onRemove();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'playlist', child: Text('Add to playlist')),
              PopupMenuItem(value: 'remove', child: Text('Remove from library')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Premium generated fallback artwork for songs with no embedded artwork:
/// accent-tinted tile + music note + the first letter of the title.
class _FallbackArt extends StatelessWidget {
  final Song song;
  const _FallbackArt({required this.song});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final letter = song.title.trim().isNotEmpty ? song.title.trim()[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.35,
            child: Icon(Icons.music_note_rounded, color: scheme.onPrimary, size: 30),
          ),
          Text(
            letter,
            style: TextStyle(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
