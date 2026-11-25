import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/calendar_engine/cotsworth_converter.dart';
import '../../../../core/calendar_engine/cotsworth_date.dart';
import '../../../../core/calendar_engine/cotsworth_month.dart';
import '../../data/converter_history_repository.dart';
import 'converter_state.dart';

class ConverterCubit extends Cubit<ConverterState> {
  ConverterCubit(this._historyRepo)
      : super(
          ConverterState(
            cotsworthYear: DateTime.now().year,
            cotsworthMonth: CotsworthMonth.january,
            history: _historyRepo.loadHistory(),
          ),
        );

  final ConverterHistoryRepository _historyRepo;

  void setDirection(ConversionDirection dir) {
    emit(state.copyWith(direction: dir, clearResult: true, clearError: true));
    if (dir == ConversionDirection.cotsworthToGregorian) {
      _tryConvertCotsworth();
    } else if (state.gregorianInput.isNotEmpty) {
      _tryConvertGregorian(state.gregorianInput);
    }
  }

  void swapDirection() {
    final currentResult = state.result;
    if (state.direction == ConversionDirection.gregorianToCotsworth) {
      if (currentResult != null) {
        final c = currentResult.cotsworth;
        final dayType = switch (c) {
          RegularCotsworthDate() => CotsworthDayType.regular,
          LeapDay() => CotsworthDayType.leapDay,
          YearDay() => CotsworthDayType.yearDay,
        };
        emit(
          state.copyWith(
            direction: ConversionDirection.cotsworthToGregorian,
            cotsworthYear: c.year,
            cotsworthMonth: c is RegularCotsworthDate
                ? c.month
                : state.cotsworthMonth ?? CotsworthMonth.january,
            cotsworthDay: c is RegularCotsworthDate ? c.day : state.cotsworthDay,
            cotsworthDayType: dayType,
            clearError: true,
          ),
        );
        _tryConvertCotsworth();
        return;
      }
      emit(
        state.copyWith(
          direction: ConversionDirection.cotsworthToGregorian,
          clearResult: true,
          clearError: true,
        ),
      );
      _tryConvertCotsworth();
    } else {
      if (currentResult != null) {
        final g = currentResult.gregorian;
        final formatted = _formatIso(g);
        emit(
          state.copyWith(
            direction: ConversionDirection.gregorianToCotsworth,
            gregorianInput: formatted,
            clearError: true,
          ),
        );
        _tryConvertGregorian(formatted);
        return;
      }
      emit(
        state.copyWith(
          direction: ConversionDirection.gregorianToCotsworth,
          clearResult: true,
          clearError: true,
        ),
      );
    }
  }

  void openFromCalendar(CotsworthDate date) {
    final dayType = switch (date) {
      RegularCotsworthDate() => CotsworthDayType.regular,
      LeapDay() => CotsworthDayType.leapDay,
      YearDay() => CotsworthDayType.yearDay,
    };
    emit(
      state.copyWith(
        direction: ConversionDirection.cotsworthToGregorian,
        cotsworthYear: date.year,
        cotsworthMonth: date is RegularCotsworthDate
            ? date.month
            : CotsworthMonth.january,
        cotsworthDay: date is RegularCotsworthDate ? date.day : 1,
        cotsworthDayType: dayType,
        clearError: true,
      ),
    );
    _tryConvertCotsworth();
  }

  void setGregorianInput(String value) {
    emit(
      state.copyWith(
        gregorianInput: value,
        clearError: true,
        clearResult: true,
      ),
    );
    _tryConvertGregorian(value);
  }

  void setCotsworthYear(int year) {
    final clamped = year.clamp(1, 9999);
    var nextDayType = state.cotsworthDayType;
    if (nextDayType == CotsworthDayType.leapDay &&
        !CotsworthConverter.isLeapYear(clamped)) {
      nextDayType = CotsworthDayType.regular;
    }
    emit(
      state.copyWith(
        cotsworthYear: clamped,
        cotsworthDayType: nextDayType,
        clearError: true,
        clearResult: true,
      ),
    );
    _tryConvertCotsworth();
  }

  void setCotsworthMonth(CotsworthMonth month) {
    emit(
      state.copyWith(
        cotsworthMonth: month,
        clearError: true,
        clearResult: true,
      ),
    );
    _tryConvertCotsworth();
  }

  void setCotsworthDay(int day) {
    emit(
      state.copyWith(
        cotsworthDay: day.clamp(1, 28),
        clearError: true,
        clearResult: true,
      ),
    );
    _tryConvertCotsworth();
  }

  void setCotsworthDayType(CotsworthDayType type) {
    emit(
      state.copyWith(
        cotsworthDayType: type,
        clearError: true,
        clearResult: true,
      ),
    );
    _tryConvertCotsworth();
  }

  Future<void> clearHistory() async {
    await _historyRepo.saveHistory(const []);
    emit(state.copyWith(history: const []));
  }

  String _formatIso(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  void _recordHistory(({CotsworthDate cotsworth, DateTime gregorian}) item) {
    final deduped = [
      item,
      ...state.history.where((e) => e.gregorian != item.gregorian),
    ].take(ConverterHistoryRepository.maxHistoryItems).toList();
    _historyRepo.saveHistory(deduped);
    emit(state.copyWith(result: item, history: deduped, clearError: true));
  }

  void _tryConvertGregorian(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    final match = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(trimmed);
    if (match == null) {
      if (trimmed.length >= 10) {
        emit(state.copyWith(error: 'Use YYYY-MM-DD format (e.g., 2026-06-18).'));
      }
      return;
    }

    final y = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    final d = int.parse(match.group(3)!);

    if (y < 1 || y > 9999 || m < 1 || m > 12 || d < 1 || d > 31) {
      emit(state.copyWith(error: 'Invalid date values.'));
      return;
    }

    final date = DateTime(y, m, d);
    if (date.year != y || date.month != m || date.day != d) {
      emit(
        state.copyWith(
          error: 'Invalid calendar date (e.g. Feb 29 in a non-leap year).',
        ),
      );
      return;
    }

    final cotsworth = CotsworthConverter.fromGregorian(date);
    _recordHistory((cotsworth: cotsworth, gregorian: date));
  }

  void _tryConvertCotsworth() {
    if (state.direction != ConversionDirection.cotsworthToGregorian) return;
    final year = state.cotsworthYear;
    if (year == null) return;

    try {
      final CotsworthDate cotsworth;
      switch (state.cotsworthDayType) {
        case CotsworthDayType.leapDay:
          if (!CotsworthConverter.isLeapYear(year)) {
            emit(state.copyWith(error: '$year is not a leap year.'));
            return;
          }
          cotsworth = LeapDay(year: year);
        case CotsworthDayType.yearDay:
          cotsworth = YearDay(year: year);
        case CotsworthDayType.regular:
          final month = state.cotsworthMonth ?? CotsworthMonth.january;
          cotsworth = RegularCotsworthDate(
            year: year,
            month: month,
            day: state.cotsworthDay,
          );
      }
      final greg = CotsworthConverter.toGregorian(cotsworth);
      _recordHistory((cotsworth: cotsworth, gregorian: greg));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
