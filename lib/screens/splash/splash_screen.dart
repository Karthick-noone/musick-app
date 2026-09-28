import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme/color_themes.dart';
import '../../providers/library_provider.dart';
import '../../providers/theme_provider.dart';
import '../root_shell.dart';

/// Shows briefly on cold start. Performance approach (the "reduce loading"
/// ask):
///  - The splash animation and the library bootstrap run *at the same
///    time* — we never wait for the animation to finish before starting
///    real work, and never block the animation on I/O.
///  - libraryProvider's bootstrap already shows cached DB rows immediately
///    and refreshes in the background (see Phase 1), so by the time this
///    screen navigates away there's usually already something to show —
///    no separate "scanning..." wait screen bolted on top.
///  - The only fixed wait is a small minimum (350ms) purely so the
///    animation doesn't flash on/off on a fast device; it never *adds*
///    delay on a slow one, since it races against the real bootstrap with
///    Future.wait rather than running after it.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final minDelay = Future.delayed(const Duration(milliseconds: 350));

    // Kick library bootstrap (permission check + cached-song load) and the
    // minimum splash timer in parallel — whichever finishes last decides
    // when we navigate, so we never add the two durations together.
    await Future.wait([
      minDelay,
      ref.read(libraryProvider.notifier).ready,
    ]);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RootShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider).accent;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SizedBox(
          width: 220,
          height: 220,
          child: Lottie.asset(
            'assets/animations/splash.json',
            fit: BoxFit.contain,
            repeat: true,
            errorBuilder: (context, error, stack) => _FallbackMark(accent: accent),
          ),
        ),
      ),
    );
  }
}

/// Shown if assets/animations/splash.json hasn't been added yet, or fails
/// to parse, so the app still launches cleanly either way.
class _FallbackMark extends StatelessWidget {
  final AppColorTheme accent;
  const _FallbackMark({required this.accent});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [accent.seed, accent.seed.withValues(alpha: 0.6)]),
        ),
        child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 56),
      ),
    );
  }
}
