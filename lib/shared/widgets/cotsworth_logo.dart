import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Geometric vector logo for the Cotsworth 13-Month Calendar.
///
/// Renders a 13-dot solar/lunar orbital ring (highlighting the 7th month Sol)
/// surrounding a 28-day lunar crescent emblem.
class CotsworthLogo extends StatelessWidget {
  const CotsworthLogo({super.key, this.size = 40, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CotsworthLogoPainter(
          primaryColor: theme.colorScheme.primary,
          solColor: AppTheme.solAccent(context),
          surfaceColor: theme.colorScheme.surfaceContainerHigh,
        ),
      ),
    );

    if (!showWordmark) return badge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cotsworth',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              '13 × 28 Cycle',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CotsworthLogoPainter extends CustomPainter {
  _CotsworthLogoPainter({
    required this.primaryColor,
    required this.solColor,
    required this.surfaceColor,
  });

  final Color primaryColor;
  final Color solColor;
  final Color surfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;

    final bgPaint = Paint()..color = surfaceColor;
    canvas.drawCircle(center, radius, bgPaint);

    final ringPaint = Paint()
      ..color = primaryColor.withAlpha(65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size.shortestSide * 0.045);
    canvas.drawCircle(center, radius * 0.76, ringPaint);

    final dotRadius = math.max(1.4, size.shortestSide * 0.055);
    for (var i = 0; i < 13; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / 13);
      final dotCenter = Offset(
        center.dx + radius * 0.76 * math.cos(angle),
        center.dy + radius * 0.76 * math.sin(angle),
      );
      final isSol = i == 0;
      final dotPaint = Paint()
        ..color = isSol ? solColor : primaryColor.withAlpha(215);
      canvas.drawCircle(
        dotCenter,
        isSol ? dotRadius * 1.35 : dotRadius,
        dotPaint,
      );
    }

    final innerPaint = Paint()..color = primaryColor;
    canvas.drawCircle(center, radius * 0.34, innerPaint);

    final crescentCutPaint = Paint()..color = surfaceColor;
    canvas.drawCircle(
      Offset(center.dx + radius * 0.14, center.dy - radius * 0.08),
      radius * 0.26,
      crescentCutPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CotsworthLogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.solColor != solColor ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}
