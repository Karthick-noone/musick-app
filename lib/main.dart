import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/songs/songs_screen.dart';

void main() {
  runApp(const ProviderScope(child: MusickApp()));
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
      home: const RootShell(),
    );
  }
}

/// Bottom-navigation shell: Home / Songs / Albums / Playlists / More.
/// Only Songs is implemented in Phase 1 — the rest are lightweight
/// placeholders so the navigation structure is in place from the start.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 1; // Land on Songs for Phase 1, where the working feature is.

  static const _tabs = [
    _PlaceholderTab(title: 'Home', icon: Icons.home_rounded),
    SongsScreen(),
    _PlaceholderTab(title: 'Albums', icon: Icons.album_rounded),
    _PlaceholderTab(title: 'Playlists', icon: Icons.playlist_play_rounded),
    _PlaceholderTab(title: 'More', icon: Icons.more_horiz_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.music_note_outlined), selectedIcon: Icon(Icons.music_note_rounded), label: 'Songs'),
          NavigationDestination(icon: Icon(Icons.album_outlined), selectedIcon: Icon(Icons.album_rounded), label: 'Albums'),
          NavigationDestination(icon: Icon(Icons.playlist_play_outlined), selectedIcon: Icon(Icons.playlist_play_rounded), label: 'Playlists'),
          NavigationDestination(icon: Icon(Icons.more_horiz_outlined), selectedIcon: Icon(Icons.more_horiz_rounded), label: 'More'),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text('$title arrives in a later phase', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
