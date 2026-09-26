import 'package:on_audio_query/on_audio_query.dart' as oaq;

/// App-level Song entity, backed by the `songs` SQLite table.
///
/// `mediaId` is the Android MediaStore id (as a string) — the stable
/// identifier used to detect duplicates across rescans. `filePath` is kept
/// only to resolve the file on disk for playback; the audio bytes
/// themselves are never copied into the app.
class Song {
  final int? id; // local DB row id (null until inserted)
  final String mediaId;
  final String filePath;
  final String title;
  final String? artist;
  final String? album;
  final String? albumArt; // cached artwork path/uri, if any
  final int durationMs;
  final String? fileExtension;
  final DateTime? dateAdded;
  final int playCount;
  final DateTime? lastPlayed;
  final bool isFavorite;
  final bool hiddenFromLibrary;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Song({
    this.id,
    required this.mediaId,
    required this.filePath,
    required this.title,
    this.artist,
    this.album,
    this.albumArt,
    required this.durationMs,
    this.fileExtension,
    this.dateAdded,
    this.playCount = 0,
    this.lastPlayed,
    this.isFavorite = false,
    this.hiddenFromLibrary = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration get duration => Duration(milliseconds: durationMs);

  Song copyWith({
    int? id,
    int? playCount,
    DateTime? lastPlayed,
    bool? isFavorite,
    bool? hiddenFromLibrary,
    DateTime? updatedAt,
  }) {
    return Song(
      id: id ?? this.id,
      mediaId: mediaId,
      filePath: filePath,
      title: title,
      artist: artist,
      album: album,
      albumArt: albumArt,
      durationMs: durationMs,
      fileExtension: fileExtension,
      dateAdded: dateAdded,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      isFavorite: isFavorite ?? this.isFavorite,
      hiddenFromLibrary: hiddenFromLibrary ?? this.hiddenFromLibrary,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Builds an (unsaved) Song from an on_audio_query scan result.
  /// `id` is left null — the database service decides insert vs. update
  /// based on `mediaId` so play counts/favorites survive rescans.
  factory Song.fromAudioModel(oaq.SongModel model) {
    final now = DateTime.now();
    return Song(
      mediaId: model.id.toString(),
      filePath: model.data,
      title: model.title.isNotEmpty ? model.title : 'Unknown title',
      artist: (model.artist == null || model.artist == '<unknown>') ? null : model.artist,
      album: (model.album == null || model.album == '<unknown>') ? null : model.album,
      albumArt: null, // resolved on demand via QueryArtworkWidget / artwork cache
      durationMs: model.duration ?? 0,
      fileExtension: model.fileExtension,
      dateAdded: model.dateAdded != null
          ? DateTime.fromMillisecondsSinceEpoch(model.dateAdded! * 1000)
          : null,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Song.fromMap(Map<String, Object?> map) {
    return Song(
      id: map['id'] as int?,
      mediaId: map['media_id'] as String,
      filePath: map['file_path'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      albumArt: map['album_art'] as String?,
      durationMs: (map['duration'] as int?) ?? 0,
      fileExtension: map['file_extension'] as String?,
      dateAdded: map['date_added'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date_added'] as int)
          : null,
      playCount: (map['play_count'] as int?) ?? 0,
      lastPlayed: map['last_played'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_played'] as int)
          : null,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      hiddenFromLibrary: (map['hidden_from_library'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    final map = <String, Object?>{
      'media_id': mediaId,
      'file_path': filePath,
      'title': title,
      'artist': artist,
      'album': album,
      'album_art': albumArt,
      'duration': durationMs,
      'file_extension': fileExtension,
      'date_added': dateAdded?.millisecondsSinceEpoch,
      'play_count': playCount,
      'last_played': lastPlayed?.millisecondsSinceEpoch,
      'is_favorite': isFavorite ? 1 : 0,
      'hidden_from_library': hiddenFromLibrary ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
    if (includeId && id != null) map['id'] = id;
    return map;
  }
}
