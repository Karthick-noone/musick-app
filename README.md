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

---

## Phase 2 — Playback + splash/profile/appearance (this drop)

**Playback (spec sections 14–17):**
- `services/audio_player_service.dart` — a `BaseAudioHandler` wrapping
  `just_audio`. Owns the queue, shuffle order, repeat mode, and the
  "counts as a play" timer (fires `onValidPlay` once a song crosses
  `AppConstants.minPlaySecondsToCount`, wired straight into
  `libraryProvider.recordPlay`). Skips to the next track instead of
  crashing on a corrupted/unsupported file.
- `providers/player_provider.dart` — merges position/duration/playing
  into one `PlaybackSnapshot` for the UI.
- `widgets/mini_player.dart` — persistent bar above the bottom nav,
  animates in/out with the queue state.
- `screens/now_playing/now_playing_screen.dart` — full player: artwork,
  scrubbable progress, prev/play/pause/next, shuffle, repeat (off → all →
  one), favorite, "Played N times", queue button (stubbed for Phase 3).
- Background playback: `audio_service` + the Android manifest's
  `AudioService`/`MediaButtonReceiver` entries give you the lock-screen
  and notification controls; `MainActivity` now extends
  `AudioServiceActivity`.

**Splash screen ("reduce loading" ask):**
- `screens/splash/splash_screen.dart` plays
  `assets/animations/splash.json` — **drop your Lottie file in at that
  exact path** and it picks it up with no code changes. Until then it
  falls back to a simple fading app-icon mark, so the app still runs.
- The splash's minimum-display timer and the library bootstrap
  (permission check + cached-song load) run in parallel via
  `Future.wait`, not back-to-back — the splash never adds its own delay
  on top of real load time, and a full rescan of 700+ songs happens
  *after* navigating in, never blocking the first screen.

**Profile (new):**
- `providers/profile_provider.dart` — local display name + photo
  (copied into app documents so it survives cache clears/URI expiry),
  persisted via `SharedPreferences`.
- `screens/profile/profile_screen.dart` — avatar with an edit-photo
  picker (`image_picker`, gallery source), edit-name dialog, remove
  photo, and delete-profile (resets name/photo only — never touches the
  music library/favorites/playlists).

**Appearance settings (new):**
- `screens/settings/appearance_screen.dart` — System/Light/Dark radio
  group + the 8-swatch accent grid, both already backed by
  `themeProvider` from Phase 1.
- `screens/settings/settings_screen.dart` is now the real "More" tab:
  profile row, Appearance, and placeholders for Library/Statistics
  (later phases).

### New dependencies this phase
`just_audio`, `audio_service`, `audio_session`, `rxdart`, `lottie`,
`image_picker` — all added to `pubspec.yaml`.

### New Android permissions/config
Manifest already had `POST_NOTIFICATIONS` and the foreground-service
permissions from Phase 1 (pre-added for this). This drop adds the
`AudioService` `<service>` and `MediaButtonReceiver` `<receiver>`
entries, and `xmlns:tools` on the manifest root.

### To test
1. Drop your Lottie JSON at `assets/animations/splash.json`, then
   `flutter pub get` and rebuild.
2. Cold-start the app — splash should play briefly then land on Songs.
3. Tap a song — mini-player should appear above the nav bar and start
   playing; tap it to open Now Playing.
4. Lock the phone or switch apps — playback should continue, and the
   lock screen / notification should show play/pause/skip controls.
5. Let a song play past ~12 seconds — its play count should increment
   (visible on the Songs list and in Now Playing's "Played N times").
6. Go to **More → your name** to edit name/photo/delete profile, and
   **More → Appearance** to change theme mode and accent color — the
   whole app should re-theme instantly.

