import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';

/// Owns the single sqflite [Database] instance and its schema.
///
/// IMPORTANT: never destroy/recreate the DB on upgrade. Every future schema
/// change must be an additive migration inside [_onUpgrade] so existing
/// users never lose play counts, favorites, or playlists.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Enforce FK constraints (e.g. playlist_songs -> playlists/songs).
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE ${AppConstants.tableSongs} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        media_id TEXT UNIQUE NOT NULL,
        file_path TEXT NOT NULL,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        album_art TEXT,
        duration INTEGER NOT NULL DEFAULT 0,
        file_extension TEXT,
        date_added INTEGER,
        play_count INTEGER NOT NULL DEFAULT 0,
        last_played INTEGER,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        hidden_from_library INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE ${AppConstants.tablePlaylists} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        cover_image TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE ${AppConstants.tablePlaylistSongs} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        song_id INTEGER NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        added_at INTEGER NOT NULL,
        FOREIGN KEY (playlist_id) REFERENCES ${AppConstants.tablePlaylists} (id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES ${AppConstants.tableSongs} (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE ${AppConstants.tablePlayHistory} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id INTEGER NOT NULL,
        played_at INTEGER NOT NULL,
        duration_played INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (song_id) REFERENCES ${AppConstants.tableSongs} (id) ON DELETE CASCADE
      )
    ''');

    batch.execute(
        'CREATE INDEX idx_songs_media_id ON ${AppConstants.tableSongs} (media_id)');
    batch.execute(
        'CREATE INDEX idx_playlist_songs_playlist ON ${AppConstants.tablePlaylistSongs} (playlist_id)');
    batch.execute(
        'CREATE INDEX idx_play_history_song ON ${AppConstants.tablePlayHistory} (song_id)');

    await batch.commit(noResult: true);
  }

  /// Additive migrations only. Example for a future version bump:
  ///
  /// if (oldVersion < 2) {
  ///   await db.execute('ALTER TABLE songs ADD COLUMN lyrics TEXT');
  /// }
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // No migrations yet — schema version 1 is the initial release.
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
