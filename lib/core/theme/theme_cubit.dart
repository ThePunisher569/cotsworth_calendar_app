import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../storage/local_storage_service.dart';

/// Cubit managing Light/Dark ThemeMode persisted with SharedPreferences,
/// supporting manual toggle as well as automatic local daylight/night updates.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._storage)
    : super(_storage.isDarkMode ? ThemeMode.dark : ThemeMode.light);

  final LocalStorageService _storage;

  bool get isDarkMode => state == ThemeMode.dark;

  Future<void> toggleTheme() async {
    final nextIsDark = !isDarkMode;
    await _storage.setDarkMode(nextIsDark);
    emit(nextIsDark ? ThemeMode.dark : ThemeMode.light);
  }

  /// Applies day/night theme automatically when Auto-Solar Theme is active.
  Future<void> applySolarTheme({required bool isDaylight}) async {
    final targetIsDark = !isDaylight;
    if (isDarkMode == targetIsDark) return;
    await _storage.setDarkMode(targetIsDark);
    emit(targetIsDark ? ThemeMode.dark : ThemeMode.light);
  }
}
