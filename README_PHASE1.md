# Musick — Phase 1

**Phase 1 scope (per the build plan):** project setup, theme system, SQLite
setup, Android permissions, music scanning, the Song model, and a working
Songs list. Playback, playlists, statistics, and settings arrive in later
phases — the placeholder tabs (Home / Albums / Playlists / More) say so on
screen so it's clear what's next.

## What's in this drop

```
musick_app/
├── assets/icon/                     ← icon source (SVGs) + render_icon.py + preview PNG
├── android/app/src/main/
│   ├── AndroidManifest.xml           ← permissions, no INTERNET
│   └── res/mipmap-*/                 ← generated launcher icons (legacy + adaptive)
├── lib/
│   ├── core/
│   │   ├── constants/app_constants.dart
│   │   ├── theme/color_themes.dart   ← the 8 accent options
│   │   ├── theme/app_theme.dart      ← Material3 ColorScheme.fromSeed builder
│   │   └── database/database_helper.dart  ← sqflite schema + migration scaffold
│   ├── models/song.dart
│   ├── services/
│   │   ├── database_service.dart     ← all SQL for songs table
│   │   └── music_scanner_service.dart← on_audio_query + permission flow
│   ├── providers/
│   │   ├── theme_provider.dart       ← persisted appearance state
│   │   └── library_provider.dart     ← scan state + song list, used by UI
│   ├── screens/songs/songs_screen.dart
│   ├── widgets/song_tile.dart        ← artwork + fallback art + play count
│   └── main.dart
└── pubspec.yaml
```

## Where each file belongs

Drop this whole `musick_app/` folder in as a new Flutter project root (or
merge `lib/`, `android/app/src/main/`, and `pubspec.yaml` into an existing
`flutter create` scaffold if you already have one — the standard
`android/`, `ios/`, `web/` boilerplate from `flutter create musick` isn't
reproduced here, only the parts Phase 1 touches).

## pubspec.yaml dependencies (already added)

| Package | Why |
|---|---|
| `flutter_riverpod` / `riverpod` | State management (chosen once, used consistently) |
| `sqflite` + `path` | Local SQLite persistence |
| `on_audio_query` | Reads the Android MediaStore (titles/artists/albums/artwork/duration) — no file copying |
| `permission_handler` | Runtime permission requests |
| `shared_preferences` | Persisted theme mode + accent color |
| `path_provider` | Resolves the sqflite database directory |

Run:

```bash
flutter pub get
```

## Android configuration changes (already applied)

- `AndroidManifest.xml` requests `READ_MEDIA_AUDIO` (Android 13+) and
  `READ_EXTERNAL_STORAGE` (maxSdkVersion 32, for older devices) — no
  `INTERNET` permission anywhere.
- `POST_NOTIFICATIONS` / `FOREGROUND_SERVICE*` are pre-added for Phase 2's
  background playback notification; they're inert until that service exists.
- Adaptive launcher icon wired via `mipmap-anydpi-v26/ic_launcher.xml`,
  pointing at generated `ic_launcher_foreground.png` /
  `ic_launcher_background.png` per density, plus a legacy flat
  `ic_launcher.png` for pre-Android-8 devices.
- Minimum SDK: `on_audio_query` and `permission_handler` require
  **minSdkVersion 21+** — set this in `android/app/build.gradle` if your
  scaffold's default is lower.

## How to run and test

1. `flutter create` a fresh project (if you don't have one), then copy this
   `lib/`, `android/`, `assets/`, and `pubspec.yaml` over it. This drop's
   `android/` folder is now complete (settings.gradle, build.gradle files,
   gradle-wrapper.properties, MainActivity.kt, launch theme/background) —
   copy the whole folder rather than merging just `src/main/`, or you'll
   overwrite the pieces that make it build.
2. Keep your own `local.properties` (it has your machine's `flutter.sdk`
   path) — don't overwrite it with anything from this drop; there isn't
   one included, since it's machine-specific and not meant to be shared.
3. `flutter pub get`
3. `flutter run` on a real Android device or emulator with music already on
   it (add a few MP3/FLAC files via the emulator's file manager or `adb push`
   if testing on an emulator with no music).
4. On first launch you'll land on the **Songs** tab (placeholder tabs sit on
   either side). Tap **Allow Music Access** to trigger the permission
   dialog, then the scan runs automatically.
5. Confirm:
   - Songs list populates with title/artist and generated fallback art for
     anything with no embedded artwork.
   - Search filters by title/artist/album instantly.
   - Sort menu re-orders the list.
   - Favorite heart toggles and **persists** across an app restart.
   - "Remove from library" shows the confirmation dialog, hides the song,
     and — restart the app — it stays hidden (soft-delete, not a rescan
     bring-back).
   - Pull-to-refresh re-scans and picks up any newly added device files
     without wiping existing play counts/favorites (there are none yet
     until Phase 2 adds playback).

## Known Phase 1 boundaries (by design, not bugs)

- Tapping a song does nothing yet — playback is Phase 2.
- Home / Albums / Playlists / More tabs are placeholders.
- Play counts stay at 0 — Phase 2 wires `libraryProvider.recordPlay()` into
  the audio player service once real playback exists.
- Settings screen isn't built yet — the accent/theme system underneath it
  (`themeProvider`, `AppColorThemes`) is already fully wired and persisted,
  ready for a Settings screen to control it in a later phase.

Fix any compile errors from your specific Flutter/Gradle version before
moving to Phase 2 (audio playback, mini-player, Now Playing, background
playback) — let me know what you hit and I'll patch it.
