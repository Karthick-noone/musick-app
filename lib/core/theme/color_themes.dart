import 'package:flutter/material.dart';

/// One selectable accent. `seed` feeds Material 3's
/// [ColorScheme.fromSeed] so every button, slider, chip, and highlight
/// derives from this single color, in both light and dark mode.
class AppColorTheme {
  final String id;
  final String label;
  final String emoji;
  final Color seed;

  const AppColorTheme({
    required this.id,
    required this.label,
    required this.emoji,
    required this.seed,
  });
}

/// The full palette of accent choices offered in Settings > Appearance.
/// Do not hardcode these colors anywhere else in the app — always go
/// through the active ColorScheme.
class AppColorThemes {
  AppColorThemes._();

  static const oceanBlue = AppColorTheme(
    id: 'ocean_blue',
    label: 'Ocean Blue',
    emoji: '🔵',
    seed: Color(0xFF2F6FED),
  );

  static const royalPurple = AppColorTheme(
    id: 'royal_purple',
    label: 'Royal Purple',
    emoji: '🟣',
    seed: Color(0xFF7B4FE0),
  );

  static const emerald = AppColorTheme(
    id: 'emerald',
    label: 'Emerald',
    emoji: '🟢',
    seed: Color(0xFF1FA97A),
  );

  static const sunsetOrange = AppColorTheme(
    id: 'sunset_orange',
    label: 'Sunset Orange',
    emoji: '🟠',
    seed: Color(0xFFE8792F),
  );

  static const ruby = AppColorTheme(
    id: 'ruby',
    label: 'Ruby',
    emoji: '🔴',
    seed: Color(0xFFD6335B),
  );

  static const cyan = AppColorTheme(
    id: 'cyan',
    label: 'Cyan',
    emoji: '🩵',
    seed: Color(0xFF17B3C9),
  );

  static const rose = AppColorTheme(
    id: 'rose',
    label: 'Rose',
    emoji: '🩷',
    seed: Color(0xFFE0669A),
  );

  static const golden = AppColorTheme(
    id: 'golden',
    label: 'Golden',
    emoji: '🟡',
    seed: Color(0xFFD1A32E),
  );

  static const List<AppColorTheme> all = [
    oceanBlue,
    royalPurple,
    emerald,
    sunsetOrange,
    ruby,
    cyan,
    rose,
    golden,
  ];

  static const AppColorTheme fallback = oceanBlue;

  static AppColorTheme byId(String id) {
    return all.firstWhere((t) => t.id == id, orElse: () => fallback);
  }
}
