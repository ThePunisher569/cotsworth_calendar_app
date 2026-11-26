import 'cotsworth_converter.dart';
import 'cotsworth_date.dart';

/// Ergonomic extensions on [DateTime] for Cotsworth conversion.
extension GregorianToCotsworthExt on DateTime {
  CotsworthDate toCotsworth() => CotsworthConverter.fromGregorian(this);

  bool isSameCalendarDate(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

/// Ergonomic extensions on [CotsworthDate].
extension CotsworthDateExt on CotsworthDate {
  bool get isLeapYear => CotsworthConverter.isLeapYear(year);
  int get totalDaysInYear => CotsworthConverter.daysInYear(year);
  double get yearProgress => dayOfYear / totalDaysInYear;
  bool get isIntercalary => this is LeapDay || this is YearDay;

  String get weekdayLabel => switch (this) {
    RegularCotsworthDate(:final weekdayName) => weekdayName,
    LeapDay() || YearDay() => 'No Weekday (Intercalary)',
  };

  String get cycleAlignmentLabel => switch (this) {
    RegularCotsworthDate(:final day, :final cyclePhase) =>
      'Cycle Day $day of 28 · ${cyclePhase.title}',
    LeapDay() => 'Intercalary Pause · Outside 28-Day Cycle',
    YearDay() => 'Annual Reset · Outside 28-Day Cycle',
  };

  CotsworthDate addDays(int days) => CotsworthConverter.addDays(this, days);
}
