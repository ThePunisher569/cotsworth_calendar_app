import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/astronomy/astronomy_service.dart';
import '../../../../core/network/weather_service.dart';
import '../../../../core/permissions/location_permission_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/theme_cubit.dart';

class SkyState extends Equatable {
  const SkyState({
    required this.astronomy,
    required this.autoSolarTheme,
    this.weather,
    this.permissionStatus,
    this.isRefreshing = false,
    this.usingLiveLocation = false,
  });

  final SkyAstronomySnapshot astronomy;
  final WeatherSnapshot? weather;
  final LocationAccessStatus? permissionStatus;
  final bool autoSolarTheme;
  final bool isRefreshing;
  final bool usingLiveLocation;

  bool get isDaylight => weather?.isDay ?? astronomy.solarSnapshot.isDaylight;

  SkyWeatherCondition get effectiveCondition =>
      weather?.condition ?? SkyWeatherCondition.clear;

  SkyState copyWith({
    SkyAstronomySnapshot? astronomy,
    WeatherSnapshot? weather,
    LocationAccessStatus? permissionStatus,
    bool? autoSolarTheme,
    bool? isRefreshing,
    bool? usingLiveLocation,
  }) {
    return SkyState(
      astronomy: astronomy ?? this.astronomy,
      weather: weather ?? this.weather,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      autoSolarTheme: autoSolarTheme ?? this.autoSolarTheme,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      usingLiveLocation: usingLiveLocation ?? this.usingLiveLocation,
    );
  }

  @override
  List<Object?> get props => [
    astronomy.instantUtc,
    astronomy.latitude,
    astronomy.longitude,
    weather?.condition,
    weather?.temperatureC,
    weather?.isDay,
    permissionStatus,
    autoSolarTheme,
    isRefreshing,
    usingLiveLocation,
  ];
}

/// Manages local astronomical phase/daylight state, cross-platform location
/// permissions, cached Open-Meteo weather, and Auto-Solar Day/Night theme sync.
class SkyCubit extends Cubit<SkyState> {
  SkyCubit({
    required LocalStorageService storage,
    required ThemeCubit themeCubit,
    LocationPermissionService? locationService,
    WeatherService? weatherService,
    DateTime Function()? clock,
  }) : _storage = storage,
       _themes = themeCubit,
       _locationService = locationService ?? const LocationPermissionService(),
       _weatherService =
           weatherService ?? WeatherService(storage, clock: clock),
       _clock = clock ?? DateTime.now,
       super(_initialState(storage, clock ?? DateTime.now));

  // Neutral fallback coordinates before live GPS is granted.
  static const double _defaultLat = 20.5937;
  static const double _defaultLon = 78.9629;

  final LocalStorageService _storage;
  final ThemeCubit _themes;
  final LocationPermissionService _locationService;
  final WeatherService _weatherService;
  final DateTime Function() _clock;

  static SkyState _initialState(
    LocalStorageService storage,
    DateTime Function() clock,
  ) {
    final saved = storage.getLastKnownLocation();
    final lat = saved?.lat ?? _defaultLat;
    final lon = saved?.lon ?? _defaultLon;
    final nowUtc = clock().toUtc();
    return SkyState(
      astronomy: AstronomyService.snapshot(
        instantUtc: nowUtc,
        latitude: lat,
        longitude: lon,
      ),
      autoSolarTheme: storage.autoSolarTheme,
      usingLiveLocation: saved != null,
    );
  }

  /// Resolves live GPS/coarse coordinates, recomputes local moon/sun state,
  /// fetches Open-Meteo weather, and applies Auto-Solar theme if enabled.
  Future<void> loadLiveSky({
    bool requestPermission = false,
    bool forceWeatherRefresh = false,
  }) async {
    if (state.isRefreshing) return;
    emit(state.copyWith(isRefreshing: true));

    var lat = state.astronomy.latitude;
    var lon = state.astronomy.longitude;
    var permStatus = state.permissionStatus;
    var liveLoc = state.usingLiveLocation;

    final locResult = await _locationService.resolveLocation(
      requestIfNeeded: requestPermission,
    );
    if (locResult != null) {
      permStatus = locResult.status;
      if (locResult.status == LocationAccessStatus.granted) {
        lat = locResult.latitude;
        lon = locResult.longitude;
        liveLoc = true;
        await _storage.saveLastKnownLocation(lat, lon);
      }
    }

    final astronomy = AstronomyService.snapshot(
      instantUtc: _clock().toUtc(),
      latitude: lat,
      longitude: lon,
    );

    final weather = await _weatherService.fetchWeather(
      latitude: lat,
      longitude: lon,
      forceRefresh: forceWeatherRefresh,
    );

    final nextState = state.copyWith(
      astronomy: astronomy,
      weather: weather,
      permissionStatus: permStatus,
      isRefreshing: false,
      usingLiveLocation: liveLoc,
    );
    emit(nextState);

    if (nextState.autoSolarTheme) {
      await _themes.applySolarTheme(isDaylight: nextState.isDaylight);
    }
  }

  Future<void> setAutoSolarTheme(bool enabled) async {
    await _storage.setAutoSolarTheme(enabled);
    emit(state.copyWith(autoSolarTheme: enabled));
    if (enabled) {
      await _themes.applySolarTheme(isDaylight: state.isDaylight);
    }
  }

  /// Applies a deterministic snapshot in tests or preview modes.
  Future<void> applyManualSnapshot({
    required double latitude,
    required double longitude,
    DateTime? instantUtc,
    WeatherSnapshot? weather,
  }) async {
    final astronomy = AstronomyService.snapshot(
      instantUtc: (instantUtc ?? _clock()).toUtc(),
      latitude: latitude,
      longitude: longitude,
    );
    final nextState = state.copyWith(
      astronomy: astronomy,
      weather: weather,
      usingLiveLocation: true,
    );
    emit(nextState);
    if (nextState.autoSolarTheme) {
      await _themes.applySolarTheme(isDaylight: nextState.isDaylight);
    }
  }

  Future<void> openLocationSettings() =>
      _locationService.openAppLocationSettings();
}
