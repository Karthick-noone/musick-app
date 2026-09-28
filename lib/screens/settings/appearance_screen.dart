import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/color_themes.dart';
import '../../providers/theme_provider.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text('Theme', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          _ModeOption(
            label: 'System Default',
            selected: themeState.mode == ThemeMode.system,
            onTap: () => notifier.setMode(ThemeMode.system),
          ),
          _ModeOption(
            label: 'Light',
            selected: themeState.mode == ThemeMode.light,
            onTap: () => notifier.setMode(ThemeMode.light),
          ),
          _ModeOption(
            label: 'Dark',
            selected: themeState.mode == ThemeMode.dark,
            onTap: () => notifier.setMode(ThemeMode.dark),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 4),
            child: Text('Color Themes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: AppColorThemes.all.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final accent = AppColorThemes.all[index];
                final selected = themeState.accent.id == accent.id;
                return _AccentSwatch(
                  accent: accent,
                  selected: selected,
                  onTap: () => notifier.setAccent(accent),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(label),
      dense: true,
      onTap: onTap,
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  final AppColorTheme accent;
  final bool selected;
  final VoidCallback onTap;
  const _AccentSwatch({required this.accent, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.seed,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                  : Border.all(color: Colors.transparent, width: 3),
              boxShadow: [
                BoxShadow(color: accent.seed.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            alignment: Alignment.center,
            child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 22) : null,
          ),
          const SizedBox(height: 6),
          Text(
            accent.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
