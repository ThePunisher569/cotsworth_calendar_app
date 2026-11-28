import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:cotsworth_calendar_app/app.dart';
import 'package:cotsworth_calendar_app/core/calendar_engine/cotsworth_month.dart';
import 'package:cotsworth_calendar_app/core/storage/local_storage_service.dart';
import 'package:cotsworth_calendar_app/features/calendar/presentation/widgets/cotsworth_grid.dart';
import 'package:cotsworth_calendar_app/features/calendar/presentation/widgets/sky_hero_card.dart';
import 'package:cotsworth_calendar_app/features/splash/splash_screen.dart';
import 'package:cotsworth_calendar_app/shared/widgets/cotsworth_logo.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    bool loggedIn = false,
    bool reduceMotion = true,
    bool showSplash = false,
    Size size = const Size(1440, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryLocalStorageService(
      guestLoggedIn: loggedIn,
      reduceMotion: reduceMotion,
    );
    await tester.pumpWidget(
      CotsworthApp(
        key: UniqueKey(),
        storage: storage,
        showSplash: showSplash,
        enableAutoSkyFetch: false,
      ),
    );
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

    testWidgets(
      'starts in dark mode when persisted and toggles to light mode',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final storage = InMemoryLocalStorageService(
          darkMode: true,
          reduceMotion: true,
          guestLoggedIn: true,
        );
        await tester.pumpWidget(
          CotsworthApp(
            key: UniqueKey(),
            storage: storage,
            showSplash: false,
            enableAutoSkyFetch: false,
          ),
        );
        await tester.pumpAndSettle();

        var materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(materialApp.themeMode, equals(ThemeMode.dark));

        await tester.tap(find.byKey(const Key('theme_toggle_button')));
        await tester.pumpAndSettle();

        materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(materialApp.themeMode, equals(ThemeMode.light));
      },
    );
  });

  group('Home Calendar Screen', () {
    testWidgets(
      'displays 28 day tiles and shows Leap Day only on leap-year June',
      (tester) async {
        final storage = InMemoryLocalStorageService(
          guestLoggedIn: true,
          reduceMotion: true,
        );
        await storage.saveLastViewedMonth(2024, CotsworthMonth.june.number);

        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          CotsworthApp(
            key: UniqueKey(),
            storage: storage,
            showSplash: false,
            enableAutoSkyFetch: false,
          ),
        );
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

    testWidgets(
      'mobile bottom sheet closes when opening Converter and Year View renders 13 mini-months',
      (tester) async {
        await pumpApp(tester, loggedIn: true, size: const Size(375, 812));

        // Tap day 15 to open mobile details bottom sheet
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();
        expect(find.text('Open in Converter'), findsOneWidget);

        // Navigating to Converter must dismiss the modal bottom sheet
        await tester.tap(find.text('Open in Converter'));
        await tester.pumpAndSettle();
        expect(find.text('Open in Converter'), findsNothing);
        expect(find.text('Gregorian ↔ Cotsworth Converter'), findsOneWidget);

        // Open Year View and verify mini-month overview renders SOL and DEC
        await tester.tap(find.text('Year View'));
        await tester.pumpAndSettle();
        expect(find.text('SOL'), findsOneWidget);
        expect(find.text('DEC'), findsOneWidget);
      },
    );

    testWidgets(
      'Phase 01 Exit Gate: zero overflow at 360px/390px/768px/834px/1440px, right-side endDrawer, and RepaintBoundary isolation',
      (tester) async {
        // 1. Mobile 390x844: trailing right-side drawer button opens endDrawer
        await pumpApp(tester, loggedIn: true, size: const Size(390, 844));

        // Verify RepaintBoundary isolation on animated lunar logo & 28-day grid
        expect(
          find.descendant(
            of: find.byType(CotsworthLogo).first,
            matching: find.byType(RepaintBoundary),
          ),
          findsAtLeastNWidgets(1),
        );
        expect(
          find.descendant(
            of: find.byType(CotsworthGrid),
            matching: find.byType(RepaintBoundary),
          ),
          findsAtLeastNWidgets(1),
        );

        // Verify trailing AppBar drawer button is on the right side & opens endDrawer
        final drawerBtnRect = tester.getRect(
          find.byKey(const Key('drawer_menu_button')),
        );
        expect(drawerBtnRect.center.dx, greaterThan(195));
        await tester.tap(find.byKey(const Key('drawer_menu_button')));
        await tester.pumpAndSettle();
        expect(find.text('Reduce Motion'), findsOneWidget);

        // Close endDrawer
        await tester.tapAt(const Offset(10, 100));
        await tester.pumpAndSettle();

        // 2. Small Mobile 360x800, Tablet 834x1194, Desktop 1440x900
        for (final viewport in const [
          Size(360, 800),
          Size(834, 1194),
          Size(1440, 900),
        ]) {
          await pumpApp(tester, loggedIn: true, size: viewport);
          expect(find.byType(CotsworthGrid), findsOneWidget);
          await tester.tap(find.byIcon(Icons.swap_horiz_rounded).first);
          await tester.pumpAndSettle();
          expect(find.text('Gregorian ↔ Cotsworth Converter'), findsOneWidget);
          await tester.tap(find.byIcon(Icons.grid_view_rounded).first);
          await tester.pumpAndSettle();
          expect(find.text('SOL'), findsOneWidget);
        }
      },
    );

    testWidgets(
      'animated lunar logo ticks smoothly without pumpAndSettle hang when reduceMotion is false',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final storage = InMemoryLocalStorageService(
          guestLoggedIn: true,
          reduceMotion: false,
        );
        await tester.pumpWidget(
          CotsworthApp(
            key: UniqueKey(),
            storage: storage,
            showSplash: false,
            enableAutoSkyFetch: false,
          ),
        );
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(CotsworthLogo), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'SplashScreen displays brand promo header and rounded progress indicator before transitioning',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final storage = InMemoryLocalStorageService(
          guestLoggedIn: false,
          reduceMotion: true,
        );
        await tester.pumpWidget(
          CotsworthApp(
            key: UniqueKey(),
            storage: storage,
            showSplash: true,
            enableAutoSkyFetch: false,
          ),
        );
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(
          find.text('13 MONTHS · 28 DAYS · PERPETUAL PRECISION'),
          findsOneWidget,
        );
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byType(SplashScreen), findsNothing);
        expect(find.text('Cotsworth Calendar'), findsOneWidget);
      },
    );

    testWidgets(
      'Home renders SkyHeroCard above CotsworthGrid and Copy Both formats clipboard template',
      (tester) async {
        String? copiedClipboard;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copiedClipboard =
                  (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );

        await pumpApp(tester, loggedIn: true, size: const Size(1440, 900));
        expect(find.byType(SkyHeroCard), findsOneWidget);
        final heroTop = tester.getTopLeft(find.byType(SkyHeroCard)).dy;
        final gridTop = tester.getTopLeft(find.byType(CotsworthGrid)).dy;
        expect(heroTop, lessThan(gridTop));

        await tester.tap(find.byKey(const Key('copy_both_button')));
        await tester.pumpAndSettle();
        expect(copiedClipboard, isNotNull);
        expect(copiedClipboard, contains('Actual Calendar Date -> '));
        expect(copiedClipboard, contains('\n13-Month Calendar equivalent '));
      },
    );

    testWidgets(
      'SplashScreen displays brand promo header and rounded progress indicator before transitioning',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final storage = InMemoryLocalStorageService(
          guestLoggedIn: false,
          reduceMotion: true,
        );
        await tester.pumpWidget(
          CotsworthApp(
            key: UniqueKey(),
            storage: storage,
            showSplash: true,
            enableAutoSkyFetch: false,
          ),
        );
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(
          find.text('13 MONTHS · 28 DAYS · PERPETUAL PRECISION'),
          findsOneWidget,
        );
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byType(SplashScreen), findsNothing);
        expect(find.text('Cotsworth Calendar'), findsOneWidget);
      },
    );

    testWidgets(
      'Home renders SkyHeroCard above CotsworthGrid and Copy Both formats clipboard template',
      (tester) async {
        String? copiedClipboard;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copiedClipboard =
                  (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );

        await pumpApp(tester, loggedIn: true, size: const Size(1440, 900));
        expect(find.byType(SkyHeroCard), findsOneWidget);
        final heroTop = tester.getTopLeft(find.byType(SkyHeroCard)).dy;
        final gridTop = tester.getTopLeft(find.byType(CotsworthGrid)).dy;
        expect(heroTop, lessThan(gridTop));

        await tester.tap(find.byKey(const Key('copy_both_button')));
        await tester.pumpAndSettle();
        expect(copiedClipboard, isNotNull);
        expect(copiedClipboard, contains('Actual Calendar Date -> '));
        expect(copiedClipboard, contains('\n13-Month Calendar equivalent '));
      },
    );
  });
}
