import 'package:moon_sighting/moon_sighting.dart' as moon;
import 'package:solar_events/solar_events.dart' as solar;

/// Pure-Dart immutable lunar snapshot for a given UTC instant and location.
///
/// Zero Flutter or Firebase imports.
class LunarSnapshot {
  const LunarSnapshot({
    required this.phaseFraction,
    required this.illuminationPercent,
    required this.phaseName,
    required this.isWaxing,
    required this.brightLimbAngleRad,
    required this.parallacticAngleRad,
    required this.altitudeDeg,
    required this.azimuthDeg,
    required this.nextFullMoonUtc,
    required this.nextNewMoonUtc,
  });

  /// Synodic cycle fraction in `[0.0, 1.0)` (`0 = New`, `0.25 = First Quarter`,
  /// `0.5 = Full`, `0.75 = Last Quarter`).
  final double phaseFraction;

  /// Illuminated percentage in `[0.0, 100.0]`.
  final double illuminationPercent;

  /// Human-readable phase name (e.g., `"Waxing Crescent"`).
  final String phaseName;

  /// `true` while illumination is increasing toward Full Moon.
  final bool isWaxing;

  /// Position angle of the bright limb midpoint (radians).
  final double brightLimbAngleRad;

  /// Observer's parallactic angle (radians) aligning bright limb with local zenith.
  final double parallacticAngleRad;

  /// Topocentric altitude above horizon (degrees; `> 0` is visible above horizon).
  final double altitudeDeg;

  /// Topocentric azimuth (degrees clockwise from North).
  final double azimuthDeg;

  final DateTime nextFullMoonUtc;
  final DateTime nextNewMoonUtc;

  /// Angle (radians) of the Moon's bright limb relative to local horizon zenith.
  double get localSkyTiltRad => brightLimbAngleRad - parallacticAngleRad;

  bool get isAboveHorizon => altitudeDeg > -0.5;
}

/// Pure-Dart solar elevation and sunrise/sunset snapshot for an observer location.
class SolarSnapshot {
  const SolarSnapshot({
    required this.elevationDeg,
    required this.azimuthDeg,
    required this.isDaylight,
    required this.sunriseUtc,
    required this.sunsetUtc,
  });

  final double elevationDeg;
  final double azimuthDeg;
  final bool isDaylight;
  final DateTime? sunriseUtc;
  final DateTime? sunsetUtc;
}

/// Combined celestial snapshot for the Home Sky Hero and Auto-Solar Theme.
class SkyAstronomySnapshot {
  const SkyAstronomySnapshot({
    required this.instantUtc,
    required this.latitude,
    required this.longitude,
    required this.lunar,
    required this.solarSnapshot,
  });

  final DateTime instantUtc;
  final double latitude;
  final double longitude;
  final LunarSnapshot lunar;
  final SolarSnapshot solarSnapshot;
}

/// Offline pure-Dart astronomical engine backed by `moon_sighting` (Meeus)
/// and `solar_events` (NOAA).
abstract final class AstronomyService {
  static SkyAstronomySnapshot snapshot({
    required DateTime instantUtc,
    required double latitude,
    required double longitude,
  }) {
    final utc = instantUtc.toUtc();
    final safeLat = latitude.clamp(-89.9, 89.9);
    final safeLon = longitude.clamp(-180.0, 180.0);

    final phase = moon.getMoonPhase(utc);
    final illum = moon.getMoonIllumination(utc);
    final moonPos = moon.getMoonPosition(utc, safeLat, safeLon);

    final sunPos = solar.sunPosition(
      utc,
      latitude: safeLat,
      longitude: safeLon,
    );
    final sunTimes = solar.SunTimes(
      date: DateTime.utc(utc.year, utc.month, utc.day),
      latitude: safeLat,
      longitude: safeLon,
    );

    final DateTime? sunriseUtc = switch (sunTimes.sunrise) {
      solar.SunEventAt(:final time) => time,
      solar.SunAlwaysUp() || solar.SunAlwaysDown() => null,
    };
    final DateTime? sunsetUtc = switch (sunTimes.sunset) {
      solar.SunEventAt(:final time) => time,
      solar.SunAlwaysUp() || solar.SunAlwaysDown() => null,
    };

    return SkyAstronomySnapshot(
      instantUtc: utc,
      latitude: safeLat,
      longitude: safeLon,
      lunar: LunarSnapshot(
        phaseFraction: illum.phase.clamp(0.0, 0.999999),
        illuminationPercent: phase.illumination.clamp(0.0, 100.0),
        phaseName: phase.phaseName,
        isWaxing: illum.isWaxing,
        brightLimbAngleRad: illum.angle,
        parallacticAngleRad: moonPos.parallacticAngle,
        altitudeDeg: moonPos.altitude,
        azimuthDeg: moonPos.azimuth,
        nextFullMoonUtc: phase.nextFullMoon,
        nextNewMoonUtc: phase.nextNewMoon,
      ),
      solarSnapshot: SolarSnapshot(
        elevationDeg: sunPos.elevation,
        azimuthDeg: sunPos.azimuth,
        // Sun above geometric horizon including standard refraction (-0.833 deg)
        isDaylight: sunPos.elevation > solar.sunriseAltitude,
        sunriseUtc: sunriseUtc,
        sunsetUtc: sunsetUtc,
      ),
    );
  }
}
