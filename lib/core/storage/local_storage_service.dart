import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Interface for local persistence (settings via SharedPreferences, cache via Hive).
abstract interface class LocalStorageService {
  bool get isDarkMode;
  Future<void> setDarkMode(bool value);
  bool get autoSolarTheme;
  Future<void> setAutoSolarTheme(bool value);
  bool get reduceMotion;
  Future<void> setReduceMotion(bool value);
  bool get isGuestLoggedIn;
  Future<void> setGuestLoggedIn(bool value);
  ({int year, int monthNumber})? getLastViewedMonth();
  Future<void> saveLastViewedMonth(int year, int monthNumber);
  List<Map<String, dynamic>> getConverterHistory();
  Future<void> saveConverterHistory(List<Map<String, dynamic>> entries);
  ({double lat, double lon})? getLastKnownLocation();
  Future<void> saveLastKnownLocation(double lat, double lon);
  Map<String, dynamic>? getCachedWeather(String gridKey);
  Future<void> saveCachedWeather(String gridKey, Map<String, dynamic> data);
}

class AppLocalStorageService implements LocalStorageService {
  AppLocalStorageService._(this._prefs, this._calendarBox, this._converterBox);

  static const _kDarkMode = 'settings.is_dark_mode';
  static const _kAutoSolarTheme = 'settings.auto_solar_theme';
  static const _kReduceMotion = 'settings.reduce_motion';
  static const _kGuestLoggedIn = 'auth.is_guest_logged_in';
  static const _kCalendarBoxName = 'calendar_cache';
  static const _kConverterBoxName = 'converter_history';

  final SharedPreferences _prefs;
  final Box<dynamic> _calendarBox;
  final Box<dynamic> _converterBox;

  static Future<AppLocalStorageService> initialize() async {
    await Hive.initFlutter();
    final prefs = await SharedPreferences.getInstance();
    final calendarBox = await Hive.openBox<dynamic>(_kCalendarBoxName);
    final converterBox = await Hive.openBox<dynamic>(_kConverterBoxName);
    return AppLocalStorageService._(prefs, calendarBox, converterBox);
  }

  /// Defaults to dark mode on fresh launch to match the dark calendar theme.
  @override
  bool get isDarkMode => _prefs.getBool(_kDarkMode) ?? true;
  @override
  Future<void> setDarkMode(bool value) => _prefs.setBool(_kDarkMode, value);

  @override
  bool get autoSolarTheme => _prefs.getBool(_kAutoSolarTheme) ?? true;
  @override
  Future<void> setAutoSolarTheme(bool value) =>
      _prefs.setBool(_kAutoSolarTheme, value);

  @override
  bool get reduceMotion => _prefs.getBool(_kReduceMotion) ?? false;
  @override
  Future<void> setReduceMotion(bool value) =>
      _prefs.setBool(_kReduceMotion, value);

  @override
  bool get isGuestLoggedIn => _prefs.getBool(_kGuestLoggedIn) ?? false;
  @override
  Future<void> setGuestLoggedIn(bool value) =>
      _prefs.setBool(_kGuestLoggedIn, value);

  @override
  ({int year, int monthNumber})? getLastViewedMonth() {
    final y = _calendarBox.get('last_year');
    final m = _calendarBox.get('last_month');
    if (y is int && m is int && m >= 1 && m <= 13) {
      return (year: y, monthNumber: m);
    }
    return null;
  }

  @override
  Future<void> saveLastViewedMonth(int year, int monthNumber) async {
    await _calendarBox.put('last_year', year);
    await _calendarBox.put('last_month', monthNumber);
  }

  @override
  List<Map<String, dynamic>> getConverterHistory() {
    final raw = _converterBox.get('history');
    if (raw is! List) return const [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  @override
  Future<void> saveConverterHistory(List<Map<String, dynamic>> entries) =>
      _converterBox.put('history', entries);

  @override
  ({double lat, double lon})? getLastKnownLocation() {
    final lat = _calendarBox.get('sky_lat');
    final lon = _calendarBox.get('sky_lon');
    if (lat is num && lon is num) {
      return (lat: lat.toDouble(), lon: lon.toDouble());
    }
    return null;
  }

  @override
  Future<void> saveLastKnownLocation(double lat, double lon) async {
    await _calendarBox.put('sky_lat', lat);
    await _calendarBox.put('sky_lon', lon);
  }

  @override
  Map<String, dynamic>? getCachedWeather(String gridKey) {
    final raw = _calendarBox.get('weather_$gridKey');
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  @override
  Future<void> saveCachedWeather(String gridKey, Map<String, dynamic> data) =>
      _calendarBox.put('weather_$gridKey', data);
}

/// In-memory implementation for tests.
class InMemoryLocalStorageService implements LocalStorageService {
  InMemoryLocalStorageService({
    bool darkMode = false,
    bool autoSolarTheme = true,
    bool reduceMotion = false,
    bool guestLoggedIn = false,
  }) : _dark = darkMode,
       _autoSolar = autoSolarTheme,
       _motionReduced = reduceMotion,
       _guest = guestLoggedIn;

  bool _dark;
  bool _autoSolar;
  bool _motionReduced;
  bool _guest;
  ({int year, int monthNumber})? _lastMonth;
  ({double lat, double lon})? _lastLocation;
  List<Map<String, dynamic>> _history = [];
  final Map<String, Map<String, dynamic>> _weatherCache = {};

  @override
  bool get isDarkMode => _dark;
  @override
  Future<void> setDarkMode(bool value) async => _dark = value;
  @override
  bool get autoSolarTheme => _autoSolar;
  @override
  Future<void> setAutoSolarTheme(bool value) async => _autoSolar = value;
  @override
  bool get reduceMotion => _motionReduced;
  @override
  Future<void> setReduceMotion(bool value) async => _motionReduced = value;
  @override
  bool get isGuestLoggedIn => _guest;
  @override
  Future<void> setGuestLoggedIn(bool value) async => _guest = value;
  @override
  ({int year, int monthNumber})? getLastViewedMonth() => _lastMonth;
  @override
  Future<void> saveLastViewedMonth(int year, int monthNumber) async =>
      _lastMonth = (year: year, monthNumber: monthNumber);
  @override
  List<Map<String, dynamic>> getConverterHistory() => _history;
  @override
  Future<void> saveConverterHistory(List<Map<String, dynamic>> entries) async =>
      _history = List.from(entries);
  @override
  ({double lat, double lon})? getLastKnownLocation() => _lastLocation;
  @override
  Future<void> saveLastKnownLocation(double lat, double lon) async =>
      _lastLocation = (lat: lat, lon: lon);
  @override
  Map<String, dynamic>? getCachedWeather(String gridKey) =>
      _weatherCache[gridKey];
  @override
  Future<void> saveCachedWeather(
    String gridKey,
    Map<String, dynamic> data,
  ) async => _weatherCache[gridKey] = Map<String, dynamic>.from(data);
}
