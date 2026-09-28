import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _picker = ImagePicker();

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    await ref.read(profileProvider.notifier).setPhoto(File(picked.path));
  }

  Future<void> _editName(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(hintText: 'Your name'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await ref.read(profileProvider.notifier).setName(result);
    }
  }

  Future<void> _confirmDeleteProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete profile?'),
        content: const Text(
          'This resets your name and removes your photo. Your music library, favorites, and playlists are not affected.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(profileProvider.notifier).deleteProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final scheme = Theme.of(context).colorScheme;
    final initial = profile.name.trim().isNotEmpty ? profile.name.trim()[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage: profile.photoPath != null ? FileImage(File(profile.photoPath!)) : null,
                  child: profile.photoPath == null
                      ? Text(
                          initial,
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: scheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _pickPhoto,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.edit_rounded, size: 18, color: scheme.onPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              profile.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 28),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Edit name'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _editName(profile.name),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_outlined),
                  title: const Text('Change photo'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickPhoto,
                ),
                if (profile.photoPath != null)
                  ListTile(
                    leading: Icon(Icons.no_photography_outlined, color: scheme.error),
                    title: Text('Remove photo', style: TextStyle(color: scheme.error)),
                    onTap: () => ref.read(profileProvider.notifier).removePhoto(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
              title: Text('Delete profile', style: TextStyle(color: scheme.error)),
              subtitle: const Text('Resets your name and removes your photo'),
              onTap: _confirmDeleteProfile,
            ),
          ),
        ],
      ),
    );
  }
}
