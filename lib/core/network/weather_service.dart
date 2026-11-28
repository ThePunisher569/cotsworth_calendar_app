import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/local_storage_service.dart';

/// Weather condition buckets driving the animated Sky Hero illustration.
enum SkyWeatherCondition {
  clear('Clear Sky'),
  partlyCloudy('Partly Cloudy'),
  cloudy('Cloudy'),
  rain('Rainy'),
  storm('Thunderstorm'),
  snow('Snowy'),
  fog('Misty / Fog'),
  autumn('Autumn Breeze');

  const SkyWeatherCondition(this.label);
  final String label;
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.condition,
    required this.temperatureC,
    required this.isDay,
    required this.fetchedAtUtc,
    this.windSpeedKmh,
    this.fromCache = false,
  });

  final SkyWeatherCondition condition;
  final double temperatureC;
  final bool isDay;
  final DateTime fetchedAtUtc;
  final double? windSpeedKmh;
  final bool fromCache;
}

/// Free, zero-API-key Open-Meteo weather client with 30-minute coordinate grid caching.
class WeatherService {
  WeatherService(
    this._storage, {
    http.Client? client,
    DateTime Function()? clock,
  }) : _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now;

  static const Duration cacheTtl = Duration(minutes: 30);

  final LocalStorageService _storage;
  final http.Client _client;
  final DateTime Function() _clock;

  /// Rounds coordinates to ~11 km grid cell to maximize cache hits & privacy.
  static String gridKey(double lat, double lon) {
    return '${lat.toStringAsFixed(1)},${lon.toStringAsFixed(1)}';
  }

  Future<WeatherSnapshot?> fetchWeather({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    final nowUtc = _clock().toUtc();
    final key = gridKey(latitude, longitude);

    if (!forceRefresh) {
      final cached = _readValidCache(key, nowUtc);
      if (cached != null) return cached;
    }

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toStringAsFixed(3),
      'longitude': longitude.toStringAsFixed(3),
      'current': 'temperature_2m,weather_code,is_day,wind_speed_10m',
      'timezone': 'auto',
    });

    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return _readValidCache(key, nowUtc, ignoreTtl: true);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final current = decoded['current'];
      if (current is! Map<String, dynamic>) return null;

      final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 22.0;
      final wmoCode = (current['weather_code'] as num?)?.toInt() ?? 0;
      final isDay = ((current['is_day'] as num?)?.toInt() ?? 1) == 1;
      final wind = (current['wind_speed_10m'] as num?)?.toDouble();

      final condition = mapWmoToCondition(
        wmoCode: wmoCode,
        temperatureC: temp,
        windSpeedKmh: wind,
        latitude: latitude,
        instantUtc: nowUtc,
      );

      final snapshot = WeatherSnapshot(
        condition: condition,
        temperatureC: temp,
        isDay: isDay,
        windSpeedKmh: wind,
        fetchedAtUtc: nowUtc,
      );

      await _storage.saveCachedWeather(key, {
        'temp': temp,
        'wmo': wmoCode,
        'isDay': isDay,
        'wind': wind,
        'condition': condition.name,
        'ts': nowUtc.toIso8601String(),
      });

      return snapshot;
    } catch (_) {
      return _readValidCache(key, nowUtc, ignoreTtl: true);
    }
  }

  WeatherSnapshot? _readValidCache(
    String key,
    DateTime nowUtc, {
    bool ignoreTtl = false,
  }) {
    final map = _storage.getCachedWeather(key);
    if (map == null) return null;
    final tsRaw = map['ts'];
    final temp = (map['temp'] as num?)?.toDouble();
    final isDay = map['isDay'];
    final condName = map['condition'];
    if (tsRaw is! String ||
        temp == null ||
        isDay is! bool ||
        condName is! String) {
      return null;
    }
    final fetchedAt = DateTime.tryParse(tsRaw)?.toUtc();
    if (fetchedAt == null) return null;
    if (!ignoreTtl && nowUtc.difference(fetchedAt) > cacheTtl) {
      return null;
    }
    final cond = SkyWeatherCondition.values.firstWhere(
      (c) => c.name == condName,
      orElse: () => SkyWeatherCondition.clear,
    );
    return WeatherSnapshot(
      condition: cond,
      temperatureC: temp,
      isDay: isDay,
      windSpeedKmh: (map['wind'] as num?)?.toDouble(),
      fetchedAtUtc: fetchedAt,
      fromCache: true,
    );
  }

  /// Maps WMO weather codes (plus meteorological autumn cool-breeze heuristic)
  /// to a visual [SkyWeatherCondition].
  static SkyWeatherCondition mapWmoToCondition({
    required int wmoCode,
    required double temperatureC,
    required double? windSpeedKmh,
    required double latitude,
    required DateTime instantUtc,
  }) {
    if (wmoCode >= 95) return SkyWeatherCondition.storm;
    if ((wmoCode >= 51 && wmoCode <= 67) || (wmoCode >= 80 && wmoCode <= 82)) {
      return SkyWeatherCondition.rain;
    }
    if ((wmoCode >= 71 && wmoCode <= 77) || (wmoCode >= 85 && wmoCode <= 86)) {
      return SkyWeatherCondition.snow;
    }
    if (wmoCode == 45 || wmoCode == 48) return SkyWeatherCondition.fog;
    if (wmoCode == 3) return SkyWeatherCondition.cloudy;

    final isNorthernAutumn =
        latitude >= 0 && (instantUtc.month >= 9 && instantUtc.month <= 11);
    final isSouthernAutumn =
        latitude < 0 && (instantUtc.month >= 3 && instantUtc.month <= 5);
    final isCoolBreeze =
        temperatureC >= 5 && temperatureC <= 19 && (windSpeedKmh ?? 0) >= 14;
    if ((isNorthernAutumn || isSouthernAutumn) &&
        isCoolBreeze &&
        wmoCode <= 2) {
      return SkyWeatherCondition.autumn;
    }

    if (wmoCode == 1 || wmoCode == 2) {
      return SkyWeatherCondition.partlyCloudy;
    }
    return SkyWeatherCondition.clear;
  }
}
