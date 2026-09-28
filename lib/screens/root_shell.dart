import 'package:flutter/material.dart';

import 'settings/settings_screen.dart';
import 'songs/songs_screen.dart';
import '../widgets/mini_player.dart';

/// Bottom-navigation shell: Home / Songs / Albums / Playlists / More.
/// Songs, playback (mini-player), and Settings (More) are wired up.
/// Home/Albums/Playlists remain lightweight placeholders until their
/// phases land.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 1; // Land on Songs, where the working feature is.

  static const _tabs = [
    _PlaceholderTab(title: 'Home', icon: Icons.home_rounded),
    SongsScreen(),
    _PlaceholderTab(title: 'Albums', icon: Icons.album_rounded),
    _PlaceholderTab(title: 'Playlists', icon: Icons.playlist_play_rounded),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
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
