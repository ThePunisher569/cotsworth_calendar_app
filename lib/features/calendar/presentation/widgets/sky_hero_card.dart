import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/astronomy/astronomy_service.dart';
import '../../../../core/network/weather_service.dart';
import '../../../../core/permissions/location_permission_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/motion_cubit.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../bloc/sky_cubit.dart';

/// Dynamic location-aware celestial & live weather hero displayed above the
/// calendar grid.
///
/// - At night: renders a large animated Moon illustration aligned with the
///   observer's exact local visible phase & parallactic sky tilt angle, over
///   twinkling Lottie starlight.
/// - During daylight: switches smoothly to glowing Sun, Clouds, Rain, or Autumn
///   Lottie animations driven by live Open-Meteo weather.
/// - All continuous animation ticks are isolated inside [RepaintBoundary] layers.
class SkyHeroCard extends StatefulWidget {
  const SkyHeroCard({super.key, this.autoFetchOnMount = true});

  final bool autoFetchOnMount;

  @override
  State<SkyHeroCard> createState() => _SkyHeroCardState();
}

class _SkyHeroCardState extends State<SkyHeroCard>
    with SingleTickerProviderStateMixin {
  static final DateFormat _timeFmt = DateFormat('h:mm a');

  late final AnimationController _moonGlowController;

  @override
  void initState() {
    super.initState();
    _moonGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (widget.autoFetchOnMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<SkyCubit>().loadLiveSky(requestPermission: true);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MotionCubit.shouldReduceMotion(context, listen: true);
    if (reduce) {
      _moonGlowController.stop();
      _moonGlowController.value = 0.5;
    } else if (!_moonGlowController.isAnimating) {
      _moonGlowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _moonGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screen = ResponsiveLayout.of(context);
    final isMobile = screen == ScreenSizeClass.mobile;
    final horizontalInset = switch (screen) {
      ScreenSizeClass.mobile => 12.0,
      ScreenSizeClass.tablet => 20.0,
      ScreenSizeClass.desktop => 16.0,
    };
    final reduceMotion = MotionCubit.shouldReduceMotion(context);

    return BlocBuilder<SkyCubit, SkyState>(
      builder: (context, sky) {
        final isDay = sky.isDaylight;
        final lunar = sky.astronomy.lunar;
        final solar = sky.astronomy.solarSnapshot;
        final weather = sky.weather;
        final condition = sky.effectiveCondition;

        final List<Color> gradientColors = isDay
            ? switch (condition) {
                SkyWeatherCondition.rain || SkyWeatherCondition.storm => [
                  const Color(0xFFDBEAFE),
                  const Color(0xFFBFDBFE),
                ],
                SkyWeatherCondition.autumn => [
                  const Color(0xFFFEF3C7),
                  const Color(0xFFFDE68A),
                ],
                SkyWeatherCondition.cloudy || SkyWeatherCondition.fog => [
                  const Color(0xFFE2E8F0),
                  const Color(0xFFCBD5E1),
                ],
                _ => [const Color(0xFFFFF7ED), const Color(0xFFFEF3C7)],
              }
            : [const Color(0xFF0E1324), const Color(0xFF1C1C2E)];

        final Color heroTextColor = isDay
            ? const Color(0xFF1E293B)
            : Colors.white;
        final Color heroSubtleColor = isDay
            ? const Color(0xFF475569)
            : const Color(0xFFA1A1AA);

        final needsPermissionHint =
            sky.permissionStatus == LocationAccessStatus.denied ||
            sky.permissionStatus == LocationAccessStatus.deniedForever;

        final String locationCaption = sky.usingLiveLocation
            ? '${sky.astronomy.latitude.toStringAsFixed(2)}°, ${sky.astronomy.longitude.toStringAsFixed(2)}°'
            : 'Default Sky · Tap to enable GPS';

        final String solarTimingLabel;
        if (isDay && solar.sunsetUtc != null) {
          solarTimingLabel =
              'Sunset ${_timeFmt.format(solar.sunsetUtc!.toLocal())}';
        } else if (!isDay && solar.sunriseUtc != null) {
          solarTimingLabel =
              'Sunrise ${_timeFmt.format(solar.sunriseUtc!.toLocal())}';
        } else {
          solarTimingLabel = 'Alt ${lunar.altitudeDeg.toStringAsFixed(0)}°';
        }

        return RepaintBoundary(
          child: Container(
            margin: EdgeInsetsDirectional.fromSTEB(
              horizontalInset,
              4,
              horizontalInset,
              8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: gradientColors,
              ),
              border: Border.all(
                color: isDay
                    ? const Color(0xFFD1D5DB).withAlpha(140)
                    : const Color(0xFF2C2C3E),
              ),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.all(isMobile ? 16 : 20),
              child: Row(
                children: [
                  RepaintBoundary(
                    child: SizedBox(
                      width: isMobile ? 92 : 108,
                      height: isMobile ? 92 : 108,
                      child: isDay
                          ? _DayWeatherIllustration(
                              condition: condition,
                              reduceMotion: reduceMotion,
                            )
                          : _NightMoonIllustration(
                              lunar: lunar,
                              glowAnimation: _moonGlowController,
                              reduceMotion: reduceMotion,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isDay
                                    ? condition.label.toUpperCase()
                                    : 'LIVE LOCAL SKY · NIGHT',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  letterSpacing: 0.9,
                                  fontWeight: FontWeight.w700,
                                  color: isDay
                                      ? const Color(0xFFD97706)
                                      : AppTheme.todayRed,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (weather != null)
                              Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: heroTextColor.withAlpha(18),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${weather.temperatureC.round()}°C',
                                  style: AppTheme.tabular(
                                    theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: heroTextColor,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isDay
                              ? '${lunar.phaseName} · ${lunar.illuminationPercent.toStringAsFixed(0)}% lit'
                              : lunar.phaseName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: isMobile ? 18 : 21,
                            fontWeight: FontWeight.w700,
                            color: heroTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isDay
                              ? '$solarTimingLabel · $locationCaption'
                              : '${lunar.illuminationPercent.toStringAsFixed(1)}% illuminated · $solarTimingLabel',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: heroSubtleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _ActionPill(
                              icon: sky.isRefreshing
                                  ? Icons.sync_rounded
                                  : needsPermissionHint
                                  ? Icons.location_off_outlined
                                  : Icons.my_location_rounded,
                              label: sky.isRefreshing
                                  ? 'Syncing...'
                                  : needsPermissionHint
                                  ? 'Enable Location'
                                  : 'Refresh Sky',
                              textColor: heroTextColor,
                              onTap: sky.isRefreshing
                                  ? null
                                  : () {
                                      if (sky.permissionStatus ==
                                          LocationAccessStatus.deniedForever) {
                                        context
                                            .read<SkyCubit>()
                                            .openLocationSettings();
                                      } else {
                                        context.read<SkyCubit>().loadLiveSky(
                                          requestPermission: true,
                                          forceWeatherRefresh: true,
                                        );
                                      }
                                    },
                            ),
                            _ActionPill(
                              icon: sky.autoSolarTheme
                                  ? Icons.wb_twilight_rounded
                                  : Icons.brightness_medium_outlined,
                              label: sky.autoSolarTheme
                                  ? 'Auto Solar: On'
                                  : 'Auto Solar: Off',
                              textColor: heroTextColor,
                              onTap: () => context
                                  .read<SkyCubit>()
                                  .setAutoSolarTheme(!sky.autoSolarTheme),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: textColor.withAlpha(18),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayWeatherIllustration extends StatelessWidget {
  const _DayWeatherIllustration({
    required this.condition,
    required this.reduceMotion,
  });

  final SkyWeatherCondition condition;
  final bool reduceMotion;

  String get _assetPath => switch (condition) {
    SkyWeatherCondition.clear => 'assets/animations/sun_glow.json',
    SkyWeatherCondition.partlyCloudy ||
    SkyWeatherCondition.cloudy ||
    SkyWeatherCondition.fog ||
    SkyWeatherCondition.snow => 'assets/animations/clouds.json',
    SkyWeatherCondition.rain ||
    SkyWeatherCondition.storm => 'assets/animations/rain.json',
    SkyWeatherCondition.autumn => 'assets/animations/autumn_breeze.json',
  };

  IconData get _fallbackIcon => switch (condition) {
    SkyWeatherCondition.clear => Icons.wb_sunny_rounded,
    SkyWeatherCondition.partlyCloudy => Icons.wb_cloudy_rounded,
    SkyWeatherCondition.cloudy ||
    SkyWeatherCondition.fog => Icons.cloud_rounded,
    SkyWeatherCondition.rain ||
    SkyWeatherCondition.storm => Icons.grain_rounded,
    SkyWeatherCondition.snow => Icons.ac_unit_rounded,
    SkyWeatherCondition.autumn => Icons.eco_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      _assetPath,
      fit: BoxFit.contain,
      animate: !reduceMotion,
      repeat: !reduceMotion,
      errorBuilder: (_, _, _) =>
          Icon(_fallbackIcon, size: 64, color: AppTheme.solAccent(context)),
    );
  }
}

class _NightMoonIllustration extends StatelessWidget {
  const _NightMoonIllustration({
    required this.lunar,
    required this.glowAnimation,
    required this.reduceMotion,
  });

  final LunarSnapshot lunar;
  final Animation<double> glowAnimation;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Positioned.fill(
          child: Lottie.asset(
            'assets/animations/night_stars.json',
            fit: BoxFit.cover,
            animate: !reduceMotion,
            repeat: !reduceMotion,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        CustomPaint(
          size: const Size.square(96),
          painter: _LiveMoonPhasePainter(
            glowAnimation: glowAnimation,
            phaseFraction: lunar.phaseFraction,
            localSkyTiltRad: lunar.localSkyTiltRad,
          ),
        ),
      ],
    );
  }
}

class _LiveMoonPhasePainter extends CustomPainter {
  _LiveMoonPhasePainter({
    required this.glowAnimation,
    required this.phaseFraction,
    required this.localSkyTiltRad,
  }) : super(repaint: glowAnimation);

  final Animation<double> glowAnimation;
  final double phaseFraction;
  final double localSkyTiltRad;

  final Paint _haloPaint = Paint();
  final Paint _darkSidePaint = Paint()..color = const Color(0xFF1A2035);
  final Paint _litSidePaint = Paint()..color = const Color(0xFFF8FAFC);
  final Paint _craterPaint = Paint()..color = const Color(0xFFE2E8F0);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 2;
    final moonR = maxR * 0.68;
    final pulse = 0.85 + 0.15 * glowAnimation.value;

    // Pre-composed radial moonlight halo (no BackdropFilter)
    _haloPaint.shader = RadialGradient(
      colors: [
        Color.fromRGBO(226, 232, 240, 0.34 * pulse),
        Color.fromRGBO(148, 163, 184, 0.12 * pulse),
        Colors.transparent,
      ],
      stops: const [0.45, 0.78, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR, _haloPaint);

    // Earthshine dark lunar hemisphere
    canvas.drawCircle(center, moonR, _darkSidePaint);

    // Align bright limb with local observer horizon tilt
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(localSkyTiltRad);

    final path = _buildMoonPhasePath(moonR, phaseFraction);
    canvas.drawPath(path, _litSidePaint);

    // Subtle clipped craters inside lit area
    canvas.clipPath(path);
    canvas.drawCircle(
      Offset(-moonR * 0.25, -moonR * 0.2),
      moonR * 0.12,
      _craterPaint,
    );
    canvas.drawCircle(
      Offset(moonR * 0.2, moonR * 0.28),
      moonR * 0.16,
      _craterPaint,
    );
    canvas.drawCircle(
      Offset(moonR * 0.12, -moonR * 0.32),
      moonR * 0.08,
      _craterPaint,
    );
    canvas.restore();
  }

  Path _buildMoonPhasePath(double r, double phase) {
    final path = Path();
    if (phase <= 0.015 || phase >= 0.985) {
      return path; // New Moon: Earthshine disc only
    }
    if ((phase - 0.5).abs() <= 0.015) {
      return path..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
    }

    final waxing = phase < 0.5;
    final cosAngle = math.cos(2 * math.pi * phase);
    final terminatorRx = r * cosAngle.abs();
    const steps = 24;
    final bool isGibbous = phase > 0.25 && phase < 0.75;

    path.addArc(
      Rect.fromCircle(center: Offset.zero, radius: r),
      -math.pi / 2,
      waxing ? math.pi : -math.pi,
    );

    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final theta = math.pi / 2 - t * math.pi;
      final y = r * math.sin(theta);
      final ellipseX = terminatorRx * math.cos(theta);
      final double dx;
      if (waxing) {
        dx = isGibbous ? -ellipseX : ellipseX;
      } else {
        dx = isGibbous ? ellipseX : -ellipseX;
      }
      path.lineTo(dx, y);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _LiveMoonPhasePainter oldDelegate) {
    return oldDelegate.phaseFraction != phaseFraction ||
        oldDelegate.localSkyTiltRad != localSkyTiltRad;
  }
}
