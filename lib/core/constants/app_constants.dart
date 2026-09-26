/// App-wide constants. Keep magic strings/numbers out of widgets and
/// services so they can be changed from a single place.
class AppConstants {
  AppConstants._();

  static const String appName = 'Musick';
  static const String appTagline = 'Your music. Your device. No cloud.';

  // How long a song must play before it counts toward play_count /
  // play_history, per the "no accidental taps" requirement.
  static const int minPlaySecondsToCount = 12;

  // SQLite
  static const String dbName = 'musick.db';
  static const int dbVersion = 1;

  static const String tableSongs = 'songs';
  static const String tablePlaylists = 'playlists';
  static const String tablePlaylistSongs = 'playlist_songs';
  static const String tablePlayHistory = 'play_history';

  // SharedPreferences keys
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefAccentColor = 'pref_accent_color';
  static const String prefSortOption = 'pref_sort_option';
  static const String prefFirstLaunchDone = 'pref_first_launch_done';
}
