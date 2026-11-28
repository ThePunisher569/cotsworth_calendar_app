import 'dart:math' as math;

import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/motion_cubit.dart';

/// Shared motion duration & curve tokens inspired by smooth wallet-style
/// spring/easeOutCubic micro-interactions.
abstract final class AppMotion {
  static const Duration transitionDuration = Duration(milliseconds: 280);
  static const Duration fastDuration = Duration(milliseconds: 180);
  static const Curve transitionCurve = Curves.easeOutCubic;
  static const double verticalSlidePx = 12.0;
  static const int staggerIntervalMs = 35;
  static const int maxStaggerDelayMs = 250;

  static Duration staggerDelayFor(int index) {
    final ms = math.min(
      math.max(index, 0) * staggerIntervalMs,
      maxStaggerDelayMs,
    );
    return Duration(milliseconds: ms);
  }
}

/// Custom route transition featuring a subtle 12 px vertical slide + fade
/// with [Curves.easeOutCubic] (280 ms), automatically respecting [MotionCubit].
class SmoothSlideFadeRoute<T> extends PageRouteBuilder<T> {
  SmoothSlideFadeRoute({
    required WidgetBuilder builder,
    super.settings,
    bool reduceMotion = false,
  }) : super(
         transitionDuration: reduceMotion
             ? Duration.zero
             : AppMotion.transitionDuration,
         reverseTransitionDuration: reduceMotion
             ? Duration.zero
             : AppMotion.fastDuration,
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           if (reduceMotion || MediaQuery.disableAnimationsOf(context)) {
             return child;
           }
           final curved = CurvedAnimation(
             parent: animation,
             curve: AppMotion.transitionCurve,
             reverseCurve: Curves.easeInCubic,
           );
           return AnimatedBuilder(
             animation: curved,
             child: child,
             builder: (context, child) {
               final dy = AppMotion.verticalSlidePx * (1.0 - curved.value);
               return Opacity(
                 opacity: curved.value.clamp(0.0, 1.0),
                 child: Transform.translate(
                   offset: Offset(0, dy),
                   child: child,
                 ),
               );
             },
           );
         },
       );
}

/// Drop-in switcher for top-level views using a 12 px vertical slide + fade
/// wrapped in a [RepaintBoundary] so transitions stay off surrounding layers.
class SmoothViewSwitcher extends StatelessWidget {
  const SmoothViewSwitcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = MotionCubit.shouldReduceMotion(context);
    if (reduce) {
      return RepaintBoundary(child: child);
    }

    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: AppMotion.transitionDuration,
        reverseDuration: AppMotion.fastDuration,
        switchInCurve: AppMotion.transitionCurve,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              final dy = AppMotion.verticalSlidePx * (1.0 - animation.value);
              return Opacity(
                opacity: animation.value.clamp(0.0, 1.0),
                child: Transform.translate(offset: Offset(0, dy), child: child),
              );
            },
          );
        },
        child: child,
      ),
    );
  }
}

/// Staggered entrance reveal using [flutter_animate] with 35 ms stagger steps
/// capped at 250 ms total delay, bypassed cleanly when reduceMotion is active.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = MotionCubit.shouldReduceMotion(context);
    if (reduce) return child;

    return child
        .animate(delay: AppMotion.staggerDelayFor(index))
        .fadeIn(
          duration: AppMotion.transitionDuration,
          curve: AppMotion.transitionCurve,
        )
        .moveY(
          begin: AppMotion.verticalSlidePx,
          end: 0,
          duration: AppMotion.transitionDuration,
          curve: AppMotion.transitionCurve,
        );
  }
}
