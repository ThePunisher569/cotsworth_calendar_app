import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/calendar_engine/cotsworth_converter.dart';
import '../../../../core/calendar_engine/cotsworth_date.dart';
import '../../../../core/calendar_engine/cotsworth_month.dart';
import '../../data/calendar_cache_repository.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  CalendarBloc(this._cache, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(_initial(_cache, clock ?? DateTime.now)) {
    on<CalendarNextMonth>(_onNext);
    on<CalendarPreviousMonth>(_onPrev);
    on<CalendarJumpToToday>(_onToday);
    on<CalendarMonthYearSelected>(_onMonthYear);
    on<CalendarDateSelected>(_onDateSelected);
    on<CalendarJumpToDate>(_onJumpToDate);
  }

  final CalendarCacheRepository _cache;
  final DateTime Function() _clock;

  static CalendarState _initial(
    CalendarCacheRepository cache,
    DateTime Function() clock,
  ) {
    final today = CotsworthConverter.fromGregorian(clock());
    final cached = cache.getLastViewedMonth();
    final year = cached?.year ?? today.year;
    final month = cached?.month ?? _monthOf(today);
    return CalendarState(
      focusedYear: year,
      focusedMonth: month,
      selectedDate: today,
      today: today,
    );
  }

  static CotsworthMonth _monthOf(CotsworthDate d) => switch (d) {
    RegularCotsworthDate(:final month) => month,
    LeapDay() => CotsworthMonth.june,
    YearDay() => CotsworthMonth.december,
  };

  Future<void> _onNext(CalendarNextMonth e, Emitter<CalendarState> emit) async {
    final n = state.focusedMonth.next();
    final y = (state.focusedYear + n.yearDelta).clamp(1, 9999);
    await _cache.saveLastViewedMonth(y, n.month);
    emit(state.copyWith(focusedYear: y, focusedMonth: n.month));
  }

  Future<void> _onPrev(
    CalendarPreviousMonth e,
    Emitter<CalendarState> emit,
  ) async {
    final p = state.focusedMonth.previous();
    final y = (state.focusedYear + p.yearDelta).clamp(1, 9999);
    await _cache.saveLastViewedMonth(y, p.month);
    emit(state.copyWith(focusedYear: y, focusedMonth: p.month));
  }

  Future<void> _onToday(
    CalendarJumpToToday e,
    Emitter<CalendarState> emit,
  ) async {
    final today = CotsworthConverter.fromGregorian(_clock());
    final m = _monthOf(today);
    await _cache.saveLastViewedMonth(today.year, m);
    emit(
      state.copyWith(
        focusedYear: today.year,
        focusedMonth: m,
        selectedDate: today,
        today: today,
      ),
    );
  }

  Future<void> _onMonthYear(
    CalendarMonthYearSelected e,
    Emitter<CalendarState> emit,
  ) async {
    final y = e.year.clamp(1, 9999);
    await _cache.saveLastViewedMonth(y, e.month);
    emit(state.copyWith(focusedYear: y, focusedMonth: e.month));
  }

  void _onDateSelected(CalendarDateSelected e, Emitter<CalendarState> emit) {
    emit(state.copyWith(selectedDate: e.date));
  }

  Future<void> _onJumpToDate(
    CalendarJumpToDate e,
    Emitter<CalendarState> emit,
  ) async {
    final m = _monthOf(e.date);
    await _cache.saveLastViewedMonth(e.date.year, m);
    emit(
      state.copyWith(
        focusedYear: e.date.year,
        focusedMonth: m,
        selectedDate: e.date,
      ),
    );
  }
}
