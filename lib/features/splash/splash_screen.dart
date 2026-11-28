import 'dart:async';

import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/motion_cubit.dart';
import '../../shared/widgets/cotsworth_logo.dart';

/// Branded launch splash screen displaying a promo header, animated lunar logo,
/// rounded loading progress indicator, and Lottie shader/asset pre-warming.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  bool _completed = false;

  static const _lottieAssets = <String>[
    'assets/animations/sun_glow.json',
    'assets/animations/clouds.json',
    'assets/animations/rain.json',
    'assets/animations/autumn_breeze.json',
    'assets/animations/night_stars.json',
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completed) {
        _completed = true;
        widget.onCompleted();
      }
    });
    unawaited(_prewarmLottieAssets());
  }

  Future<void> _prewarmLottieAssets() async {
    for (final path in _lottieAssets) {
      try {
        await AssetLottie(path).load();
      } catch (_) {
        // Asset pre-warm is best-effort.
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MotionCubit.shouldReduceMotion(context, listen: false);
    if (reduce) {
      _progressController.duration = const Duration(milliseconds: 80);
    }
    if (!_progressController.isAnimating &&
        _progressController.status != AnimationStatus.completed) {
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand Promo Ad Header Pill
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: theme.colorScheme.primary.withAlpha(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withAlpha(80),
                      ),
                    ),
                    child: Text(
                      '13 MONTHS · 28 DAYS · PERPETUAL PRECISION',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10.5,
                        letterSpacing: 0.9,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const CotsworthLogo(size: 96),
                  const SizedBox(height: 24),
                  Text(
                    'Cotsworth Calendar',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Every month begins on Sunday, mirrors the 28-day lunar & natural rhythm, and celebrates Sol at midsummer.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Promo Feature Highlights Card
                  Container(
                    padding: const EdgeInsetsDirectional.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isDark
                          ? const Color(0xFF1C1C1E)
                          : theme.colorScheme.surface,
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Aligning celestial & calendar cycles...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, _) {
                                final pct = (_progressController.value * 100)
                                    .round();
                                return Text(
                                  '$pct%',
                                  style: AppTheme.tabular(
                                    theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, _) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: _progressController.value,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
