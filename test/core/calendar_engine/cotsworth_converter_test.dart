import 'package:flutter_test/flutter_test.dart';

import 'package:cotsworth_calendar_app/core/calendar_engine/cotsworth_converter.dart';
import 'package:cotsworth_calendar_app/core/calendar_engine/cotsworth_date.dart';
import 'package:cotsworth_calendar_app/core/calendar_engine/cotsworth_extensions.dart';
import 'package:cotsworth_calendar_app/core/calendar_engine/cotsworth_month.dart';

void main() {
  group('Leap Year Rules', () {
    test('identifies common, leap, century, and 400-year leap years', () {
      expect(CotsworthConverter.isLeapYear(2025), isFalse);
      expect(CotsworthConverter.isLeapYear(2024), isTrue);
      expect(CotsworthConverter.isLeapYear(2028), isTrue);
      expect(CotsworthConverter.isLeapYear(1900), isFalse);
      expect(CotsworthConverter.isLeapYear(2000), isTrue);
      expect(CotsworthConverter.isLeapYear(2100), isFalse);
    });
  });

  group('All 17 Golden Test Vectors (both directions)', () {
    final vectors =
        <
          ({
            DateTime gregorian,
            CotsworthDate cotsworth,
            int doy,
            String? weekday,
          })
        >[
          (
            gregorian: DateTime(2025, 1, 1),
            cotsworth: RegularCotsworthDate(
              year: 2025,
              month: CotsworthMonth.january,
              day: 1,
            ),
            doy: 1,
            weekday: 'Sunday',
          ),
          (
            gregorian: DateTime(2025, 1, 28),
            cotsworth: RegularCotsworthDate(
              year: 2025,
              month: CotsworthMonth.january,
              day: 28,
            ),
            doy: 28,
            weekday: 'Saturday',
          ),
          (
            gregorian: DateTime(2025, 1, 29),
            cotsworth: RegularCotsworthDate(
              year: 2025,
              month: CotsworthMonth.february,
              day: 1,
            ),
            doy: 29,
            weekday: 'Sunday',
          ),
          (
            gregorian: DateTime(2025, 6, 17),
            cotsworth: RegularCotsworthDate(
              year: 2025,
              month: CotsworthMonth.june,
              day: 28,
            ),
            doy: 168,
            weekday: 'Saturday',
          ),
          (
            gregorian: DateTime(2025, 6, 18),
            cotsworth: RegularCotsworthDate(
              year: 2025,
              month: CotsworthMonth.sol,
              day: 1,
            ),
            doy: 169,
            weekday: 'Sunday',
          ),
          (
            gregorian: DateTime(2025, 7, 15),
            cotsworth: RegularCotsworthDate(
              year: 2025,
              month: CotsworthMonth.sol,
              day: 28,
            ),
            doy: 196,
            weekday: 'Saturday',
          ),
          (
            gregorian: DateTime(2025, 7, 16),
            cotsworth: RegularCotsworthDate(
              year: 2025,
              month: CotsworthMonth.july,
              day: 1,
            ),
            doy: 197,
            weekday: 'Sunday',
          ),
          (
            gregorian: DateTime(2025, 12, 30),
            cotsworth: RegularCotsworthDate(
              year: 2025,
              month: CotsworthMonth.december,
              day: 28,
            ),
            doy: 364,
            weekday: 'Saturday',
          ),
          (
            gregorian: DateTime(2025, 12, 31),
            cotsworth: const YearDay(year: 2025),
            doy: 365,
            weekday: null,
          ),
          (
            gregorian: DateTime(2024, 2, 29),
            cotsworth: RegularCotsworthDate(
              year: 2024,
              month: CotsworthMonth.march,
              day: 4,
            ),
            doy: 60,
            weekday: 'Wednesday',
          ),
          (
            gregorian: DateTime(2024, 6, 16),
            cotsworth: RegularCotsworthDate(
              year: 2024,
              month: CotsworthMonth.june,
              day: 28,
            ),
            doy: 168,
            weekday: 'Saturday',
          ),
          (
            gregorian: DateTime(2024, 6, 17),
            cotsworth: LeapDay(year: 2024),
            doy: 169,
            weekday: null,
          ),
          (
            gregorian: DateTime(2024, 6, 18),
            cotsworth: RegularCotsworthDate(
              year: 2024,
              month: CotsworthMonth.sol,
              day: 1,
            ),
            doy: 170,
            weekday: 'Sunday',
          ),
          (
            gregorian: DateTime(2024, 12, 30),
            cotsworth: RegularCotsworthDate(
              year: 2024,
              month: CotsworthMonth.december,
              day: 28,
            ),
            doy: 365,
            weekday: 'Saturday',
          ),
          (
            gregorian: DateTime(2024, 12, 31),
            cotsworth: const YearDay(year: 2024),
            doy: 366,
            weekday: null,
          ),
          (
            gregorian: DateTime(1900, 6, 17),
            cotsworth: RegularCotsworthDate(
              year: 1900,
              month: CotsworthMonth.june,
              day: 28,
            ),
            doy: 168,
            weekday: 'Saturday',
          ),
          (
            gregorian: DateTime(2000, 6, 17),
            cotsworth: LeapDay(year: 2000),
            doy: 169,
            weekday: null,
          ),
        ];

    test('converts all 17 golden vectors in both directions', () {
      expect(vectors.length, equals(17));
      for (final v in vectors) {
        // Gregorian -> Cotsworth
        final actualCotsworth = CotsworthConverter.fromGregorian(v.gregorian);
        expect(
          actualCotsworth,
          equals(v.cotsworth),
          reason: 'fromGregorian(${v.gregorian}) should be ${v.cotsworth}',
        );
        expect(actualCotsworth.dayOfYear, equals(v.doy));

        if (v.weekday != null) {
          expect(actualCotsworth, isA<RegularCotsworthDate>());
          expect(
            (actualCotsworth as RegularCotsworthDate).weekdayName,
            equals(v.weekday),
          );
        } else {
          expect(actualCotsworth.isIntercalary, isTrue);
        }

        // Cotsworth -> Gregorian
        final backToGregorian = CotsworthConverter.toGregorian(v.cotsworth);
        expect(
          backToGregorian,
          equals(v.gregorian),
          reason: 'toGregorian(${v.cotsworth}) should be ${v.gregorian}',
        );
      }
    });
  });

  group('Validation Errors', () {
    test('throws when constructing LeapDay in common year', () {
      expect(() => LeapDay(year: 2025), throwsArgumentError);
      expect(() => LeapDay(year: 1900), throwsArgumentError);
    });

    test('throws for invalid day or month numbers', () {
      expect(
        () => RegularCotsworthDate(
          year: 2026,
          month: CotsworthMonth.january,
          day: 0,
        ),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => RegularCotsworthDate(
          year: 2026,
          month: CotsworthMonth.january,
          day: 29,
        ),
        throwsA(isA<RangeError>()),
      );
      expect(() => CotsworthMonth.fromNumber(0), throwsA(isA<RangeError>()));
      expect(() => CotsworthMonth.fromNumber(14), throwsA(isA<RangeError>()));
    });
  });

  group('Round-Trip 1900-01-01 through 2100-12-31', () {
    test('every single day round-trips identically (~73414 days)', () {
      var cursor = DateTime.utc(1900, 1, 1);
      final end = DateTime.utc(2100, 12, 31);
      var count = 0;

      while (!cursor.isAfter(end)) {
        final gDate = DateTime(cursor.year, cursor.month, cursor.day);
        final cotsworth = CotsworthConverter.fromGregorian(gDate);
        final back = CotsworthConverter.toGregorian(cotsworth);
        expect(
          back,
          equals(gDate),
          reason: 'Round-trip mismatch on $gDate -> $cotsworth',
        );
        cursor = cursor.add(const Duration(days: 1));
        count++;
      }

      expect(count, equals(73414));
    });
  });

  group('addDays & Month Helpers', () {
    test('crosses Leap Day in 2024', () {
      final june28 = RegularCotsworthDate(
        year: 2024,
        month: CotsworthMonth.june,
        day: 28,
      );
      expect(
        CotsworthConverter.addDays(june28, 1),
        equals(LeapDay(year: 2024)),
      );
      expect(
        CotsworthConverter.addDays(june28, 2),
        equals(
          RegularCotsworthDate(year: 2024, month: CotsworthMonth.sol, day: 1),
        ),
      );
      expect(
        CotsworthConverter.addDays(
          RegularCotsworthDate(year: 2024, month: CotsworthMonth.sol, day: 1),
          -1,
        ),
        equals(LeapDay(year: 2024)),
      );
    });

    test('crosses Year Day and year rollover', () {
      final dec28 = RegularCotsworthDate(
        year: 2025,
        month: CotsworthMonth.december,
        day: 28,
      );
      expect(
        CotsworthConverter.addDays(dec28, 1),
        equals(const YearDay(year: 2025)),
      );
      expect(
        CotsworthConverter.addDays(dec28, 2),
        equals(
          RegularCotsworthDate(
            year: 2026,
            month: CotsworthMonth.january,
            day: 1,
          ),
        ),
      );
    });

    test('getMonthDays returns 28 days for Sol', () {
      final solDays = CotsworthConverter.getMonthDays(2026, CotsworthMonth.sol);
      expect(solDays.length, equals(28));
      expect(solDays.first.cotsworth.day, equals(1));
      expect(
        solDays.first.cotsworth.cyclePhase,
        equals(NaturalCyclePhase.week1Renewal),
      );
      expect(solDays.first.gregorian, equals(DateTime(2026, 6, 18)));
      expect(solDays.last.cotsworth.day, equals(28));
      expect(
        solDays.last.cotsworth.cyclePhase,
        equals(NaturalCyclePhase.week4Rest),
      );
      expect(solDays.last.gregorian, equals(DateTime(2026, 7, 15)));
    });
  });
}
