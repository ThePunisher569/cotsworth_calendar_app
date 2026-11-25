import 'cotsworth_converter.dart';
import 'cotsworth_month.dart';

/// 28-day natural cycle phases aligned with each Cotsworth month.
enum NaturalCyclePhase {
  week1Renewal(1, 'New Moon · Renewal', 'Days 1–7'),
  week2Rise(2, 'Waxing · Rising', 'Days 8–14'),
  week3Peak(3, 'Full Moon · Peak', 'Days 15–21'),
  week4Rest(4, 'Waning · Reflection', 'Days 22–28');

  const NaturalCyclePhase(this.weekNumber, this.title, this.dayRangeLabel);
  final int weekNumber;
  final String title;
  final String dayRangeLabel;

  static NaturalCyclePhase fromDay(int day) {
    if (day < 1 || day > 28) throw RangeError.range(day, 1, 28, 'day');
    return values[(day - 1) ~/ 7];
  }
}

/// Sealed domain hierarchy for all valid Cotsworth Calendar dates.
sealed class CotsworthDate implements Comparable<CotsworthDate> {
  const CotsworthDate({required this.year});
  final int year;

  /// 1-indexed day of year.
  int get dayOfYear;

  /// Human-readable label.
  String formatFull();

  /// Equivalent Gregorian DateTime.
  DateTime toGregorian() => CotsworthConverter.toGregorian(this);

  @override
  int compareTo(CotsworthDate other) {
    final yc = year.compareTo(other.year);
    if (yc != 0) return yc;
    return dayOfYear.compareTo(other.dayOfYear);
  }
}

/// A standard day inside one of the 13 Cotsworth months (1..28).
final class RegularCotsworthDate extends CotsworthDate {
  RegularCotsworthDate({
    required super.year,
    required this.month,
    required this.day,
  }) {
    if (day < 1 || day > 28) throw RangeError.range(day, 1, 28, 'day');
  }

  final CotsworthMonth month;
  final int day;

  int get weekdayIndex => (day - 1) % 7;
  int get weekOfMonth => ((day - 1) ~/ 7) + 1;
  NaturalCyclePhase get cyclePhase => NaturalCyclePhase.fromDay(day);

  String get weekdayName => const [
        'Sunday', 'Monday', 'Tuesday', 'Wednesday',
        'Thursday', 'Friday', 'Saturday',
      ][weekdayIndex];

  String get weekdayShortName => const [
        'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
      ][weekdayIndex];

  @override
  int get dayOfYear {
    final leapOffset =
        CotsworthConverter.isLeapYear(year) && month.number >= 7 ? 1 : 0;
    return (month.number - 1) * 28 + day + leapOffset;
  }

  @override
  String formatFull() => '${month.fullName} $day, $year';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegularCotsworthDate &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'RegularCotsworthDate(${formatFull()})';
}

/// Intercalary Leap Day after June 28 in leap years. Gregorian June 17.
final class LeapDay extends CotsworthDate {
  LeapDay({required super.year}) {
    if (!CotsworthConverter.isLeapYear(year)) {
      throw ArgumentError('Year $year is not a leap year.');
    }
  }

  @override
  int get dayOfYear => 169;

  @override
  String formatFull() => 'Leap Day, $year';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LeapDay && year == other.year;

  @override
  int get hashCode => Object.hash(LeapDay, year);

  @override
  String toString() => 'LeapDay($year)';
}

/// Intercalary Year Day after December 28 every year. Gregorian December 31.
final class YearDay extends CotsworthDate {
  const YearDay({required super.year});

  @override
  int get dayOfYear => CotsworthConverter.isLeapYear(year) ? 366 : 365;

  @override
  String formatFull() => 'Year Day, $year';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is YearDay && year == other.year;

  @override
  int get hashCode => Object.hash(YearDay, year);

  @override
  String toString() => 'YearDay($year)';
}
