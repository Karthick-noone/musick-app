import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/color_themes.dart';

/// Persisted app-wide appearance state: System/Light/Dark + selected accent.
/// Both survive app restarts via SharedPreferences.
class ThemeState {
  final ThemeMode mode;
  final AppColorTheme accent;

  const ThemeState({required this.mode, required this.accent});

  ThemeState copyWith({ThemeMode? mode, AppColorTheme? accent}) {
    return ThemeState(mode: mode ?? this.mode, accent: accent ?? this.accent);
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier()
      : super(ThemeState(mode: ThemeMode.system, accent: AppColorThemes.fallback)) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(AppConstants.prefThemeMode);
    final accentId = prefs.getString(AppConstants.prefAccentColor);

    state = ThemeState(
      mode: modeIndex != null ? ThemeMode.values[modeIndex] : ThemeMode.system,
      accent: accentId != null ? AppColorThemes.byId(accentId) : AppColorThemes.fallback,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefThemeMode, mode.index);
  }

  Future<void> setAccent(AppColorTheme accent) async {
    state = state.copyWith(accent: accent);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefAccentColor, accent.id);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
