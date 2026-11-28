import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/motion_cubit.dart';

/// Smoothly animated lunar cycle logo for the Cotsworth 13-Month Calendar.
///
/// Renders a glowing moon morphing continuously across its synodic cycle
/// (`0.0 -> 1.0`) encircled by a 13-month orbital dot ring (highlighting Sol).
/// Animation ticks drive [_LunarCycleLogoPainter] directly via [Listenable]
/// inside a dedicated [RepaintBoundary] with zero widget-tree rebuilds.
class CotsworthLogo extends StatefulWidget {
  const CotsworthLogo({
    super.key,
    this.size = 40,
    this.showWordmark = false,
    this.animate = true,
  });

  final double size;
  final bool showWordmark;
  final bool animate;

  @override
  State<CotsworthLogo> createState() => _CotsworthLogoState();
}

class _CotsworthLogoState extends State<CotsworthLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
      value: 0.35,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationState(listen: true);
  }

  @override
  void didUpdateWidget(covariant CotsworthLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      _syncAnimationState(listen: false);
    }
  }

  void _syncAnimationState({required bool listen}) {
    final reduceMotion = MotionCubit.shouldReduceMotion(
      context,
      listen: listen,
    );
    if (!widget.animate || reduceMotion) {
      _controller.stop();
      _controller.value = 0.35;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final badge = RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _LunarCycleLogoPainter(
            animation: _controller,
            isDark: isDark,
            primaryColor: theme.colorScheme.primary,
            solColor: AppTheme.solAccent(context),
            surfaceColor: theme.colorScheme.surfaceContainerHigh,
            onSurfaceColor: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );

    if (!widget.showWordmark) return badge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cotsworth',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '13 × 28 Cycle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LunarCycleLogoPainter extends CustomPainter {
  _LunarCycleLogoPainter({
    required this.animation,
    required this.isDark,
    required this.primaryColor,
    required this.solColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final bool isDark;
  final Color primaryColor;
  final Color solColor;
  final Color surfaceColor;
  final Color onSurfaceColor;

  final Paint _bgPaint = Paint();
  final Paint _haloPaint = Paint();
  final Paint _ringPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _dotPaint = Paint();
  final Paint _moonShadowPaint = Paint();
  final Paint _moonLitPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final phase = animation.value; // 0.0 (New) -> 0.5 (Full) -> 1.0 (New)

    // Pre-composed luminous outer glow / sheen (no BackdropFilter).
    final haloColor = isDark
        ? primaryColor.withAlpha(70)
        : solColor.withAlpha(55);
    final innerGlow = isDark
        ? const Color(0xFFE5E5EA).withAlpha(42)
        : onSurfaceColor.withAlpha(24);
    _haloPaint.shader = RadialGradient(
      colors: [innerGlow, haloColor, Colors.transparent],
      stops: const [0.35, 0.72, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, _haloPaint);

    // Core surface disc
    _bgPaint.color = surfaceColor;
    canvas.drawCircle(center, radius * 0.86, _bgPaint);

    // 13-month orbital ring
    final orbitRadius = radius * 0.74;
    _ringPaint
      ..color = primaryColor.withAlpha(isDark ? 72 : 58)
      ..strokeWidth = math.max(1.1, size.shortestSide * 0.036);
    canvas.drawCircle(center, orbitRadius, _ringPaint);

    // 13 month nodes around the orbital ring (Sol highlighted at top)
    final dotRadius = math.max(1.2, size.shortestSide * 0.044);
    final activeNodeIndex = (phase * 13).floor() % 13;
    for (var i = 0; i < 13; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / 13);
      final dotCenter = Offset(
        center.dx + orbitRadius * math.cos(angle),
        center.dy + orbitRadius * math.sin(angle),
      );
      final isSol = i == 0;
      final isOrbitHighlight = i == activeNodeIndex;
      _dotPaint.color = isSol
          ? solColor
          : isOrbitHighlight
          ? (isDark ? Colors.white : primaryColor)
          : primaryColor.withAlpha(180);
      canvas.drawCircle(
        dotCenter,
        isSol
            ? dotRadius * 1.35
            : isOrbitHighlight
            ? dotRadius * 1.15
            : dotRadius,
        _dotPaint,
      );
    }

    // Morphing glowing moon disc at the center
    final moonRadius = radius * 0.42;
    _moonShadowPaint.color = isDark
        ? const Color(0xFF141416)
        : const Color(0xFF3A3A3C).withAlpha(42);
    canvas.drawCircle(center, moonRadius, _moonShadowPaint);

    // Subtle moon rim glow proportional to illumination
    final illumination = 0.5 * (1.0 - math.cos(2 * math.pi * phase));
    final moonColor = Color.lerp(
      primaryColor,
      isDark ? const Color(0xFFF5F5F7) : const Color(0xFF3A3A3C),
      isDark ? 0.55 + 0.35 * illumination : 0.35,
    )!;
    _moonLitPaint
      ..color = moonColor
      ..shader = null;

    final path = _buildMoonPhasePath(center, moonRadius, phase);
    canvas.drawPath(path, _moonLitPaint);
  }

  /// Builds the exact illuminated crescent/gibbous silhouette for [phase] in `[0, 1)`.
  Path _buildMoonPhasePath(Offset center, double r, double phase) {
    final path = Path();
    if (phase <= 0.01 || phase >= 0.99) {
      // Thin New Moon solar-crimson rim hint so emblem remains legible
      path.addArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        math.pi,
      );
      path.arcTo(
        Rect.fromCenter(center: center, width: r * 1.84, height: r * 2),
        math.pi / 2,
        -math.pi,
        false,
      );
      return path..close();
    }

    final waxing = phase < 0.5;
    // Signed terminator horizontal semi-axis: +r -> -r across waxing, -r -> +r across waning
    final cosAngle = math.cos(2 * math.pi * phase);
    final terminatorRx = r * cosAngle.abs();
    const steps = 20;

    // Outer limb (right half when waxing, left half when waning)
    final limbStart = -math.pi / 2;
    final limbSweep = waxing ? math.pi : -math.pi;
    path.addArc(
      Rect.fromCircle(center: center, radius: r),
      limbStart,
      limbSweep,
    );

    // Terminator curve returning from bottom to top
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final theta = math.pi / 2 - t * math.pi; // +pi/2 (bottom) -> -pi/2 (top)
      final y = center.dy + r * math.sin(theta);
      final ellipseX = terminatorRx * math.cos(theta);
      // Determine x sign based on crescent vs gibbous and waxing vs waning
      final bool litBeyondHalf = illuminationIsGibbous(phase);
      final double dx;
      if (waxing) {
        dx = litBeyondHalf ? -ellipseX : ellipseX;
      } else {
        dx = litBeyondHalf ? ellipseX : -ellipseX;
      }
      path.lineTo(center.dx + dx, y);
    }

    return path..close();
  }

  bool illuminationIsGibbous(double phase) => phase > 0.25 && phase < 0.75;

  @override
  bool shouldRepaint(covariant _LunarCycleLogoPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.solColor != solColor ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.onSurfaceColor != onSurfaceColor;
  }
}
