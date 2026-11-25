import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Interface for local persistence (settings via SharedPreferences, cache via Hive).
abstract interface class LocalStorageService {
  bool get isDarkMode;
  Future<void> setDarkMode(bool value);
  bool get isGuestLoggedIn;
  Future<void> setGuestLoggedIn(bool value);
  ({int year, int monthNumber})? getLastViewedMonth();
  Future<void> saveLastViewedMonth(int year, int monthNumber);
  List<Map<String, dynamic>> getConverterHistory();
  Future<void> saveConverterHistory(List<Map<String, dynamic>> entries);
}

class AppLocalStorageService implements LocalStorageService {
  AppLocalStorageService._(this._prefs, this._calendarBox, this._converterBox);

  static const _kDarkMode = 'settings.is_dark_mode';
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

  @override
  bool get isDarkMode => _prefs.getBool(_kDarkMode) ?? false;
  @override
  Future<void> setDarkMode(bool value) => _prefs.setBool(_kDarkMode, value);

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
}

/// In-memory implementation for tests.
class InMemoryLocalStorageService implements LocalStorageService {
  InMemoryLocalStorageService({
    bool darkMode = false,
    bool guestLoggedIn = false,
  }) : _dark = darkMode,
       _guest = guestLoggedIn;

  bool _dark;
  bool _guest;
  ({int year, int monthNumber})? _lastMonth;
  List<Map<String, dynamic>> _history = [];

  @override
  bool get isDarkMode => _dark;
  @override
  Future<void> setDarkMode(bool value) async => _dark = value;
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
}
