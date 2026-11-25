import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:cotsworth_calendar_app/app.dart';
import 'package:cotsworth_calendar_app/core/calendar_engine/cotsworth_month.dart';
import 'package:cotsworth_calendar_app/core/storage/local_storage_service.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    bool loggedIn = false,
    Size size = const Size(1440, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryLocalStorageService(guestLoggedIn: loggedIn);
    await tester.pumpWidget(CotsworthApp(storage: storage));
    await tester.pumpAndSettle();
  }

  group('Login & Theme Flow', () {
    testWidgets('shows LoginScreen and rejects invalid credentials', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('Cotsworth Calendar'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('login_username')), 'Wrong');
      await tester.enterText(find.byKey(const Key('login_password')), 'pass');
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      expect(
        find.text('Invalid credentials. Use: Guest / guest'),
        findsOneWidget,
      );
    });

    testWidgets('logs in with Guest / guest and toggles theme', (tester) async {
      await pumpApp(tester);

      await tester.enterText(find.byKey(const Key('login_username')), 'Guest');
      await tester.enterText(find.byKey(const Key('login_password')), 'guest');
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      expect(find.text('Cotsworth 13-Month Calendar'), findsOneWidget);

      await tester.tap(find.byKey(const Key('theme_toggle_button')));
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.dark));
    });
  });

  group('Home Calendar Screen', () {
    testWidgets(
      'displays 28 day tiles and shows Leap Day only on leap-year June',
      (tester) async {
        final storage = InMemoryLocalStorageService(guestLoggedIn: true);
        await storage.saveLastViewedMonth(2024, CotsworthMonth.june.number);

        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(CotsworthApp(storage: storage));
        await tester.pumpAndSettle();

        expect(find.text('June 2024'), findsOneWidget);
        expect(find.text('28'), findsOneWidget);
        expect(find.text('Leap Day'), findsOneWidget);

        // Navigate to June 2025 (13 months forward)
        for (var i = 0; i < 13; i++) {
          await tester.tap(find.byKey(const Key('next_month_button')));
        }
        await tester.pumpAndSettle();

        expect(find.text('June 2025'), findsOneWidget);
        expect(find.text('Leap Day'), findsNothing);
      },
    );
  });

  group('Converter Screen', () {
    testWidgets(
      'converts 2026-06-18 to Sol 1, 2026, handles 2025-02-29, and jumps to Calendar',
      (tester) async {
        await pumpApp(tester, loggedIn: true);

        await tester.tap(find.text('Convert'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('gregorian_input_field')),
          '2025-02-29',
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Invalid calendar date (e.g. Feb 29 in a non-leap year).'),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const Key('gregorian_input_field')),
          '2026-06-18',
        );
        await tester.pumpAndSettle();
        expect(find.text('Sol 1, 2026'), findsAtLeastNWidgets(1));

        await tester.tap(find.byKey(const Key('view_on_calendar_button')));
        await tester.pumpAndSettle();
        expect(find.text('Sol 2026'), findsOneWidget);
      },
    );
  });

  group('Responsive Breakpoints', () {
    testWidgets('renders cleanly at Mobile (375x812) and Tablet (768x1024)', (
      tester,
    ) async {
      await pumpApp(tester, loggedIn: true, size: const Size(375, 812));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byKey(const Key('drawer_menu_button')), findsOneWidget);

      await pumpApp(tester, loggedIn: true, size: const Size(768, 1024));
      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });
}
