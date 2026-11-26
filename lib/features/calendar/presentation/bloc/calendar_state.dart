import 'package:equatable/equatable.dart';

import '../../../../core/calendar_engine/cotsworth_converter.dart';
import '../../../../core/calendar_engine/cotsworth_date.dart';
import '../../../../core/calendar_engine/cotsworth_month.dart';

class CalendarState extends Equatable {
  const CalendarState({
    required this.focusedYear,
    required this.focusedMonth,
    required this.selectedDate,
    required this.today,
  });

  final int focusedYear;
  final CotsworthMonth focusedMonth;
  final CotsworthDate selectedDate;
  final CotsworthDate today;

  bool get isFocusedYearLeap => CotsworthConverter.isLeapYear(focusedYear);
  bool get showLeapDayBanner =>
      focusedMonth == CotsworthMonth.june && isFocusedYearLeap;
  bool get showYearDayBanner => focusedMonth == CotsworthMonth.december;

  List<({RegularCotsworthDate cotsworth, DateTime gregorian})> get monthDays =>
      CotsworthConverter.getMonthDays(focusedYear, focusedMonth);

  ({DateTime start, DateTime end}) get gregorianSpan =>
      CotsworthConverter.getMonthGregorianSpan(focusedYear, focusedMonth);

  CalendarState copyWith({
    int? focusedYear,
    CotsworthMonth? focusedMonth,
    CotsworthDate? selectedDate,
    CotsworthDate? today,
  }) => CalendarState(
    focusedYear: focusedYear ?? this.focusedYear,
    focusedMonth: focusedMonth ?? this.focusedMonth,
    selectedDate: selectedDate ?? this.selectedDate,
    today: today ?? this.today,
  );

  @override
  List<Object?> get props => [focusedYear, focusedMonth, selectedDate, today];
}
