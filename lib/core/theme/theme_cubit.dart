import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../storage/local_storage_service.dart';

/// Cubit managing Light/Dark ThemeMode persisted with SharedPreferences.
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
}
