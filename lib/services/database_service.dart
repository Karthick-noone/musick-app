import 'package:sqflite/sqflite.dart';

import '../core/constants/app_constants.dart';
import '../core/database/database_helper.dart';
import '../models/song.dart';

/// All SQLite reads/writes for songs go through this service — screens and
/// providers never touch `sqflite` directly.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Future<Database> get _db => DatabaseHelper.instance.database;

  // ---- Songs -------------------------------------------------------------

  /// Inserts newly-discovered songs and updates metadata for already-known
  /// ones (matched by `media_id`), WITHOUT touching play_count,
  /// last_played, is_favorite, or hidden_from_library — a rescan must never
  /// erase user history or preferences.
  ///
  /// Returns the count of newly inserted songs.
  Future<int> upsertScannedSongs(List<Song> scanned) async {
    final db = await _db;
    int inserted = 0;

    await db.transaction((txn) async {
      for (final song in scanned) {
        final existing = await txn.query(
          AppConstants.tableSongs,
          columns: ['id'],
          where: 'media_id = ?',
          whereArgs: [song.mediaId],
          limit: 1,
        );

        if (existing.isEmpty) {
          await txn.insert(AppConstants.tableSongs, song.toMap());
          inserted++;
        } else {
          final id = existing.first['id'] as int;
          await txn.update(
            AppConstants.tableSongs,
            {
              'file_path': song.filePath,
              'title': song.title,
              'artist': song.artist,
              'album': song.album,
              'duration': song.durationMs,
              'file_extension': song.fileExtension,
              'date_added': song.dateAdded?.millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
    });

    return inserted;
  }

  /// All visible songs (excludes anything soft-removed via
  /// `hidden_from_library`), most-recently-added first by default.
  Future<List<Song>> getAllSongs({String orderBy = 'date_added DESC'}) async {
    final db = await _db;
    final rows = await db.query(
      AppConstants.tableSongs,
      where: 'hidden_from_library = 0',
      orderBy: orderBy,
    );
    return rows.map(Song.fromMap).toList();
  }

  Future<int> getSongCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${AppConstants.tableSongs} WHERE hidden_from_library = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> setFavorite(int songId, bool isFavorite) async {
    final db = await _db;
    await db.update(
      AppConstants.tableSongs,
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  /// "Remove from Library": soft-delete only. The physical file on the
  /// device is never touched. A rescan will not automatically bring it
  /// back — the user restores it explicitly (Settings > Library).
  Future<void> removeFromLibrary(int songId) async {
    final db = await _db;
    await db.update(
      AppConstants.tableSongs,
      {
        'hidden_from_library': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  Future<void> restoreToLibrary(int songId) async {
    final db = await _db;
    await db.update(
      AppConstants.tableSongs,
      {
        'hidden_from_library': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  /// Called after [AppConstants.minPlaySecondsToCount] of real playback.
  /// Increments play_count, stamps last_played, and logs a play_history row.
  Future<void> recordPlay(int songId, {required int durationPlayedMs}) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE ${AppConstants.tableSongs} '
        'SET play_count = play_count + 1, last_played = ?, updated_at = ? '
        'WHERE id = ?',
        [now, now, songId],
      );
      await txn.insert(AppConstants.tablePlayHistory, {
        'song_id': songId,
        'played_at': now,
        'duration_played': durationPlayedMs,
      });
    });
  }

  Future<void> resetPlayCounts() async {
    final db = await _db;
    await db.update(AppConstants.tableSongs, {'play_count': 0, 'last_played': null});
  }

  Future<void> clearPlayHistory() async {
    final db = await _db;
    await db.delete(AppConstants.tablePlayHistory);
  }
}
