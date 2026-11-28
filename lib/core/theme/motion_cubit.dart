import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../storage/local_storage_service.dart';

/// Global motion reduction cubit combining user preference with system
/// [MediaQuery.disableAnimationsOf].
class MotionCubit extends Cubit<bool> {
  MotionCubit(this._storage) : super(_storage.reduceMotion);

  final LocalStorageService _storage;

  Future<void> setReduceMotion(bool value) async {
    await _storage.setReduceMotion(value);
    emit(value);
  }

  Future<void> toggle() => setReduceMotion(!state);

  /// Returns `true` when either the OS disables animations or the user enabled
  /// reduced motion in app settings. Safe in both `build` and `didChangeDependencies`.
  static bool shouldReduceMotion(BuildContext context, {bool listen = true}) {
    final osDisabled = MediaQuery.disableAnimationsOf(context);
    if (osDisabled) return true;
    try {
      return listen
          ? context.watch<MotionCubit>().state
          : context.read<MotionCubit>().state;
    } catch (_) {
      return false;
    }
  }
}
