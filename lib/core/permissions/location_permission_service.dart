import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

enum LocationAccessStatus { granted, denied, deniedForever, serviceDisabled }

class LocationResult {
  const LocationResult({
    required this.status,
    required this.latitude,
    required this.longitude,
    this.isFallback = false,
  });

  final LocationAccessStatus status;
  final double latitude;
  final double longitude;
  final bool isFallback;
}

/// Cross-platform location permission & coordinate resolver (Android, iOS, Web).
class LocationPermissionService {
  const LocationPermissionService();

  /// Resolves current coordinates if permitted, optionally prompting the user
  /// on mobile/web when [requestIfNeeded] is `true`.
  Future<LocationResult?> resolveLocation({
    bool requestIfNeeded = false,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      if (!kIsWeb) {
        var phStatus = await ph.Permission.locationWhenInUse.status;
        if (phStatus.isDenied && requestIfNeeded) {
          phStatus = await ph.Permission.locationWhenInUse.request();
        }
        if (phStatus.isPermanentlyDenied) {
          return const LocationResult(
            status: LocationAccessStatus.deniedForever,
            latitude: 0,
            longitude: 0,
            isFallback: true,
          );
        }
        if (!phStatus.isGranted && !phStatus.isLimited) {
          return const LocationResult(
            status: LocationAccessStatus.denied,
            latitude: 0,
            longitude: 0,
            isFallback: true,
          );
        }
      } else {
        var geoPerm = await Geolocator.checkPermission();
        if (geoPerm == LocationPermission.denied && requestIfNeeded) {
          geoPerm = await Geolocator.requestPermission();
        }
        if (geoPerm == LocationPermission.deniedForever) {
          return const LocationResult(
            status: LocationAccessStatus.deniedForever,
            latitude: 0,
            longitude: 0,
            isFallback: true,
          );
        }
        if (geoPerm == LocationPermission.denied ||
            geoPerm == LocationPermission.unableToDetermine) {
          return const LocationResult(
            status: LocationAccessStatus.denied,
            latitude: 0,
            longitude: 0,
            isFallback: true,
          );
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return LocationResult(
        status: LocationAccessStatus.granted,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> openAppLocationSettings() async {
    if (!kIsWeb) {
      await ph.openAppSettings();
    }
  }
}
