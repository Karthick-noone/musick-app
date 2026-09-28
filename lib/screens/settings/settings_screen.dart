import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/profile_provider.dart';
import '../profile/profile_screen.dart';
import 'appearance_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              radius: 22,
              backgroundImage: profile.photoPath != null ? FileImage(File(profile.photoPath!)) : null,
              child: profile.photoPath == null
                  ? Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?')
                  : null,
            ),
            title: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('View profile'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Appearance'),
            subtitle: const Text('Theme mode & accent color'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearanceScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.library_music_outlined),
            title: const Text('Library'),
            subtitle: const Text('Rescan, sort preference'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              // Wired up alongside Statistics/Playback settings in a later phase.
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_rounded),
            title: const Text('Statistics'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              // Phase 4.
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Musick',
                applicationVersion: '1.0.0',
                applicationLegalese: 'Your music. Your device. No cloud.',
              );
            },
          ),
        ],
      ),
    );
  }
}
