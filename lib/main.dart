import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/library_provider.dart';
import 'providers/player_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'services/audio_player_service.dart';

// Assigned once, right after AudioService.init below, before runApp — the
// closure passed into MusickAudioHandler captures this variable rather
// than a value, so it's safe even though the container doesn't exist yet
// at the moment the handler itself is constructed.
late final ProviderContainer _container;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioHandler = await AudioService.init(
    builder: () => MusickAudioHandler(
      onValidPlay: (song, durationPlayedMs) {
        _container.read(libraryProvider.notifier).recordPlay(song, durationPlayedMs: durationPlayedMs);
      },
    ),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.musick.app.channel.audio',
      androidNotificationChannelName: 'Musick playback',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  _container = ProviderContainer(
    overrides: [audioHandlerProvider.overrideWithValue(audioHandler)],
  );

  runApp(UncontrolledProviderScope(container: _container, child: const MusickApp()));
}

class MusickApp extends ConsumerWidget {
  const MusickApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeState.mode,
      theme: AppTheme.light(themeState.accent),
      darkTheme: AppTheme.dark(themeState.accent),
      home: const SplashScreen(),
    );
  }
}
