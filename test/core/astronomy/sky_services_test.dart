import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'package:cotsworth_calendar_app/core/astronomy/astronomy_service.dart';
import 'package:cotsworth_calendar_app/core/calendar_engine/cotsworth_date.dart';
import 'package:cotsworth_calendar_app/core/calendar_engine/cotsworth_month.dart';
import 'package:cotsworth_calendar_app/core/network/weather_service.dart';
import 'package:cotsworth_calendar_app/core/storage/local_storage_service.dart';
import 'package:cotsworth_calendar_app/core/theme/theme_cubit.dart';
import 'package:cotsworth_calendar_app/core/utils/date_clipboard_formatter.dart';
import 'package:cotsworth_calendar_app/features/calendar/presentation/bloc/sky_cubit.dart';

void main() {
  group('AstronomyService & WeatherService & Clipboard Formatter', () {
    test('computes deterministic lunar phase & solar daylight by UTC time', () {
      // Noon in London on June 21 -> daylight
      final noonLondon = AstronomyService.snapshot(
        instantUtc: DateTime.utc(2026, 6, 21, 12, 0),
        latitude: 51.5072,
        longitude: -0.1276,
      );
      expect(noonLondon.solarSnapshot.isDaylight, isTrue);
      expect(noonLondon.solarSnapshot.elevationDeg, greaterThan(45));
      expect(
        noonLondon.lunar.illuminationPercent,
        inInclusiveRange(0.0, 100.0),
      );

      // Midnight in London on June 21 -> night
      final midnightLondon = AstronomyService.snapshot(
        instantUtc: DateTime.utc(2026, 6, 21, 0, 0),
        latitude: 51.5072,
        longitude: -0.1276,
      );
      expect(midnightLondon.solarSnapshot.isDaylight, isFalse);
    });

    test(
      'WeatherService caches responses for 30 minutes and maps conditions',
      () async {
        var calls = 0;
        var now = DateTime.utc(2026, 10, 15, 10, 0);
        final storage = InMemoryLocalStorageService();
        final client = MockClient((request) async {
          calls++;
          return http.Response(
            jsonEncode({
              'current': {
                'temperature_2m': 14.5,
                'weather_code': 61,
                'is_day': 1,
                'wind_speed_10m': 12.0,
              },
            }),
            200,
          );
        });

        final service = WeatherService(
          storage,
          client: client,
          clock: () => now,
        );

        final first = await service.fetchWeather(
          latitude: 28.61,
          longitude: 77.20,
        );
        expect(first, isNotNull);
        expect(first!.condition, equals(SkyWeatherCondition.rain));
        expect(first.fromCache, isFalse);
        expect(calls, equals(1));

        // Within 30 minutes -> hits cache, 0 extra HTTP requests
        now = now.add(const Duration(minutes: 15));
        final second = await service.fetchWeather(
          latitude: 28.61,
          longitude: 77.20,
        );
        expect(second!.fromCache, isTrue);
        expect(calls, equals(1));

        // After 31 minutes -> refreshes via HTTP
        now = now.add(const Duration(minutes: 20));
        final third = await service.fetchWeather(
          latitude: 28.61,
          longitude: 77.20,
        );
        expect(third!.fromCache, isFalse);
        expect(calls, equals(2));

        expect(
          WeatherService.mapWmoToCondition(
            wmoCode: 1,
            temperatureC: 14,
            windSpeedKmh: 18,
            latitude: 40,
            instantUtc: DateTime.utc(2026, 10, 15),
          ),
          equals(SkyWeatherCondition.autumn),
        );
      },
    );

    test(
      'SkyCubit auto-solar theme switches between light (day) and dark (night)',
      () async {
        final storage = InMemoryLocalStorageService(
          darkMode: true,
          autoSolarTheme: true,
        );
        final themeCubit = ThemeCubit(storage);
        final skyCubit = SkyCubit(storage: storage, themeCubit: themeCubit);

        // Noon UTC in London -> daylight -> ThemeMode.light
        await skyCubit.applyManualSnapshot(
          latitude: 51.5072,
          longitude: -0.1276,
          instantUtc: DateTime.utc(2026, 6, 21, 12, 0),
        );
        expect(skyCubit.state.isDaylight, isTrue);
        expect(themeCubit.state, equals(ThemeMode.light));

        // Midnight UTC in London -> night -> ThemeMode.dark
        await skyCubit.applyManualSnapshot(
          latitude: 51.5072,
          longitude: -0.1276,
          instantUtc: DateTime.utc(2026, 6, 21, 0, 0),
        );
        expect(skyCubit.state.isDaylight, isFalse);
        expect(themeCubit.state, equals(ThemeMode.dark));
      },
    );

    test('DateClipboardFormatter formats Copy Both template accurately', () {
      final formatted = DateClipboardFormatter.formatCopyBoth(
        gregorian: DateTime(2026, 6, 18),
        cotsworth: RegularCotsworthDate(
          year: 2026,
          month: CotsworthMonth.sol,
          day: 1,
        ),
      );
      expect(
        formatted,
        equals(
          'Actual Calendar Date -> Thursday, June 18, 2026\n'
          '13-Month Calendar equivalent Sol 1, 2026',
        ),
      );
    });
  });
}
