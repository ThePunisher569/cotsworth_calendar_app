import 'package:equatable/equatable.dart';

import '../../../../core/calendar_engine/cotsworth_date.dart';
import '../../../../core/calendar_engine/cotsworth_month.dart';

sealed class CalendarEvent extends Equatable {
  const CalendarEvent();
  @override
  List<Object?> get props => [];
}

final class CalendarNextMonth extends CalendarEvent {
  const CalendarNextMonth();
}

final class CalendarPreviousMonth extends CalendarEvent {
  const CalendarPreviousMonth();
}

final class CalendarJumpToToday extends CalendarEvent {
  const CalendarJumpToToday();
}

final class CalendarMonthYearSelected extends CalendarEvent {
  const CalendarMonthYearSelected({required this.year, required this.month});
  final int year;
  final CotsworthMonth month;
  @override
  List<Object?> get props => [year, month];
}

final class CalendarDateSelected extends CalendarEvent {
  const CalendarDateSelected(this.date);
  final CotsworthDate date;
  @override
  List<Object?> get props => [date];
}

final class CalendarJumpToDate extends CalendarEvent {
  const CalendarJumpToDate(this.date);
  final CotsworthDate date;
  @override
  List<Object?> get props => [date];
}
