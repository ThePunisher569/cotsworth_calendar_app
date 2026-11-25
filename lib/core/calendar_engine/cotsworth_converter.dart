import 'cotsworth_date.dart';
import 'cotsworth_month.dart';

/// Pure Dart conversion engine between Gregorian dates and the 13-month
/// International Fixed Calendar (Cotsworth Calendar).
///
/// All internal date arithmetic uses UTC midnight to eliminate Daylight Saving
/// Time drift across all platforms.
abstract final class CotsworthConverter {
  /// Returns `true` if [year] is a leap year under Gregorian/Cotsworth rules.
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Total days in [year] (`365` in common years, `366` in leap years).
  static int daysInYear(int year) => isLeapYear(year) ? 366 : 365;

  /// Computes the 1-indexed day of year (`1..365` or `1..366`) using UTC math.
  static int dayOfYearUtc(DateTime gregorian) {
    final startOfYear = DateTime.utc(gregorian.year, 1, 1);
    final normalized = DateTime.utc(
      gregorian.year,
      gregorian.month,
      gregorian.day,
    );
    return normalized.difference(startOfYear).inDays + 1;
  }

  /// Converts a `(year, doy)` pair into a clean date-only [DateTime].
  static DateTime gregorianFromDoy(int year, int doy) {
    final maxDoy = daysInYear(year);
    if (doy < 1 || doy > maxDoy) {
      throw RangeError.range(doy, 1, maxDoy, 'doy');
    }
    final utc = DateTime.utc(year, 1, 1).add(Duration(days: doy - 1));
    return DateTime(utc.year, utc.month, utc.day);
  }

  /// Converts a Gregorian [DateTime] into its exact [CotsworthDate].
  static CotsworthDate fromGregorian(DateTime date) {
    final year = date.year;
    final doy = dayOfYearUtc(date);
    final leap = isLeapYear(year);

    if (!leap) {
      // Common year
      if (doy == 365) return YearDay(year: year);
      final m = ((doy - 1) ~/ 28) + 1;
      final d = ((doy - 1) % 28) + 1;
      return RegularCotsworthDate(
        year: year,
        month: CotsworthMonth.fromNumber(m),
        day: d,
      );
    }

    // Leap year
    if (doy == 366) return YearDay(year: year);
    if (doy == 169) return LeapDay(year: year);
    if (doy <= 168) {
      final m = ((doy - 1) ~/ 28) + 1;
      final d = ((doy - 1) % 28) + 1;
      return RegularCotsworthDate(
        year: year,
        month: CotsworthMonth.fromNumber(m),
        day: d,
      );
    }

    // Days after Leap Day (DOY 170..365): shift back by 1.
    final adj = doy - 1;
    final m = ((adj - 1) ~/ 28) + 1;
    final d = ((adj - 1) % 28) + 1;
    return RegularCotsworthDate(
      year: year,
      month: CotsworthMonth.fromNumber(m),
      day: d,
    );
  }

  /// Converts a [CotsworthDate] into its exact Gregorian [DateTime].
  static DateTime toGregorian(CotsworthDate date) {
    return switch (date) {
      YearDay(:final year) => gregorianFromDoy(
          year,
          isLeapYear(year) ? 366 : 365,
        ),
      LeapDay(:final year) => () {
          if (!isLeapYear(year)) {
            throw ArgumentError(
              'Year $year is not a leap year and has no Leap Day.',
            );
          }
          return gregorianFromDoy(year, 169);
        }(),
      RegularCotsworthDate(:final year, :final month, :final day) => () {
          final leapOffset = isLeapYear(year) && month.number >= 7 ? 1 : 0;
          final doy = (month.number - 1) * 28 + day + leapOffset;
          return gregorianFromDoy(year, doy);
        }(),
    };
  }

  /// Adds [days] (positive, zero, or negative) to [date] crossing all
  /// boundaries accurately via UTC Gregorian math.
  static CotsworthDate addDays(CotsworthDate date, int days) {
    final g = toGregorian(date);
    final shiftedUtc = DateTime.utc(g.year, g.month, g.day).add(
      Duration(days: days),
    );
    return fromGregorian(shiftedUtc);
  }

  /// Returns all 28 paired Cotsworth + Gregorian entries for [month] in [year].
  static List<({RegularCotsworthDate cotsworth, DateTime gregorian})>
      getMonthDays(int year, CotsworthMonth month) {
    return List.generate(28, (index) {
      final cotsworth = RegularCotsworthDate(
        year: year,
        month: month,
        day: index + 1,
      );
      return (cotsworth: cotsworth, gregorian: toGregorian(cotsworth));
    });
  }

  /// Returns the Gregorian start and end dates covered by [month] in [year].
  static ({DateTime start, DateTime end}) getMonthGregorianSpan(
    int year,
    CotsworthMonth month,
  ) {
    final start = toGregorian(
      RegularCotsworthDate(year: year, month: month, day: 1),
    );
    final end = toGregorian(
      RegularCotsworthDate(year: year, month: month, day: 28),
    );
    return (start: start, end: end);
  }
}
