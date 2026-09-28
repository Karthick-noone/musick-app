import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

/// Purely local "profile" — a display name and an optional photo, used to
/// personalize the app (e.g. a Settings header). Nothing here is ever sent
/// anywhere; the photo is copied into the app's own documents directory so
/// it keeps working even if the original picked file/URI becomes invalid.
class ProfileState {
  final String name;
  final String? photoPath;

  const ProfileState({this.name = 'Music Lover', this.photoPath});

  ProfileState copyWith({String? name, String? photoPath, bool clearPhoto = false}) {
    return ProfileState(
      name: name ?? this.name,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState()) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(AppConstants.prefProfileName);
    final photoPath = prefs.getString(AppConstants.prefProfilePhotoPath);

    // If the stored photo file no longer exists (cleared cache, moved
    // device, etc.) fall back to no photo rather than a broken image.
    final validPhoto = (photoPath != null && await File(photoPath).exists()) ? photoPath : null;

    state = ProfileState(name: name ?? state.name, photoPath: validPhoto);
  }

  Future<void> setName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(name: trimmed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefProfileName, trimmed);
  }

  /// Copies the picked image into the app's documents directory (as
  /// `profile_photo.<ext>`) so the reference stays valid long-term, then
  /// persists that path.
  Future<void> setPhoto(File pickedFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(pickedFile.path);
    final savedPath = p.join(dir.path, 'profile_photo$ext');

    // Remove any previous photo (possibly a different extension) first.
    await _deleteExistingPhoto();

    final saved = await pickedFile.copy(savedPath);
    state = state.copyWith(photoPath: saved.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefProfilePhotoPath, saved.path);
  }

  Future<void> removePhoto() async {
    await _deleteExistingPhoto();
    state = state.copyWith(clearPhoto: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefProfilePhotoPath);
  }

  Future<void> _deleteExistingPhoto() async {
    final current = state.photoPath;
    if (current != null) {
      final f = File(current);
      if (await f.exists()) await f.delete();
    }
  }

  /// "Delete profile": resets name to the default and removes the photo.
  /// Never touches the music library, favorites, or playlists — this is
  /// personalization data only.
  Future<void> deleteProfile() async {
    await _deleteExistingPhoto();
    state = const ProfileState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefProfileName);
    await prefs.remove(AppConstants.prefProfilePhotoPath);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
