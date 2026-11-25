# MVP 01 Execution Tracker — Cotsworth 13-Month Calendar App

## Overview
- **Goal**: Build a responsive, cross-platform (Android, iOS, Web) 13-month (12 + Sol, 28 days/month) Cotsworth Calendar app aligned with the 28-day natural lunar/menstrual cycle.
- **Architecture**: Clean Architecture (`core/` + feature-first `features/` + `shared/`), SOLID principles, BLoC (`CalendarBloc`) & Cubits (`ThemeCubit`, `AuthCubit`, `NavigationCubit`, `ConverterCubit`), Hive & `shared_preferences` local persistence, Flutter default Material 3 Light/Dark theme.

---

## Checklist

### Phase 1: Project Scaffolding, Dependencies & Core Theme/Layout
- [x] Add dependencies (`material_ui`, `flutter_bloc`, `equatable`, `intl`, `hive_flutter`, `shared_preferences`)
- [x] Configure Clean Architecture directory structure under `lib/`
- [x] Create `lib/core/theme/app_theme.dart` (Flutter default Material 3 Light/Dark themes + tabular figures & Sol/Intercalary accents)
- [x] Create `lib/core/utils/responsive_layout.dart` (Mobile `< 600`, Tablet `600..1023`, Desktop `>= 1024`)
- [x] Create `lib/core/storage/local_storage_service.dart` (Hive + SharedPreferences implementation & test-safe interface)
- [x] Create shared `CotsworthLogo` widget & `GuestAccountBadge`

### Phase 2: Pure Dart Cotsworth Engine & Exhaustive Unit Tests
- [x] `lib/core/calendar_engine/cotsworth_month.dart` (13 months including Sol)
- [x] `lib/core/calendar_engine/cotsworth_date.dart` (Dart 3 `sealed class` hierarchy: `RegularCotsworthDate`, `LeapDay`, `YearDay` + `NaturalCyclePhase`)
- [x] `lib/core/calendar_engine/cotsworth_converter.dart` (UTC-only math, `isLeapYear`, `fromGregorian`, `toGregorian`, `addDays`, `getMonthDays`, `getMonthGregorianSpan`)
- [x] `lib/core/calendar_engine/cotsworth_extensions.dart`
- [x] `test/core/calendar_engine/cotsworth_converter_test.dart` (17 golden vectors in both directions, validation error tests, 1900–2100 round-trip loop across 73,414 days, `addDays` boundaries)
- [x] Pass `flutter test test/core/calendar_engine/cotsworth_converter_test.dart`

### Phase 3: State Management (BLoC & Cubits) & Auth + Adaptive Navigation Shell
- [x] `ThemeCubit` (Light/Dark toggle persisted with `shared_preferences`)
- [x] `AuthCubit` (Login with temp `Guest` / `guest` credentials, persisted session with `shared_preferences`)
- [x] `NavigationCubit` (Home, Convert, Year View tab navigation)
- [x] `CalendarBloc` (Month/year navigation, date selection, Today jump, cached last-viewed month in Hive)
- [x] `ConverterCubit` (Bidirectional Gregorian <-> Cotsworth conversion, validation, swap, history persisted in Hive)
- [x] `LoginScreen` (`Guest` / `guest` temp credentials + `CotsworthLogo` + `GuestAccountBadge` + Theme toggle)
- [x] `AdaptiveScaffold` (`NavigationBar` + `Drawer` on mobile, `NavigationRail` on tablet/desktop, Switch Theme icon, Temp Guest Account badge)

### Phase 4: Interactive 13-Month Home Calendar UI (with 28-Day Lunar/Cycle Alignment)
- [x] Home Screen (`CalendarScreen`) with `h1` heading, `AppBar`, `CotsworthLogo`, and $7 \times 4$ perpetual calendar grid
- [x] `MonthHeader` (month/year title, Gregorian span subtitle, prev/next chevrons, 13-month quick picker highlighting Sol, Today pill button)
- [x] `CotsworthGrid` & `DayCell` (Sun–Sat fixed header, 28 cells, Gregorian badge, month boundary indicator, Today & Selected states, mouse hover `AnimatedScale` + mobile touch inkwell, `Semantics` labels)
- [x] `IntercalaryBanner` (Leap Day on June in leap years, Year Day on December every year)
- [x] `DayDetailSheet` (side-by-side Cotsworth vs Gregorian comparison, 28-day cycle phase & year progress, Copy Both, Open in Converter; side panel on desktop, modal bottom sheet on mobile/tablet)
- [x] Keyboard shortcuts (`ArrowLeft`, `ArrowRight`, `T`) on desktop/web

### Phase 5: Bidirectional Converter & 13-Month Year Overview Screens
- [x] `ConverterScreen` (`SegmentedButton` mode switcher, Swap button, Gregorian `YYYY-MM-DD` input + `showDatePicker` + presets, Cotsworth year stepper + Day Type selector disabling `Leap Day` on common years + 13-month dropdown + 1–28 day selector, live result card, View on Calendar, Hive-persisted recent history)
- [x] `YearOverviewScreen` (13-month responsive grid showing Gregorian spans, Sol highlight, Leap Day / Year Day markers, tap to jump to Calendar)

### Phase 6: Widget Tests, Analysis, Review & App Verification
- [x] `test/features/app_widget_test.dart` (Login, Theme toggle, 28 tiles & Leap Day June 2024 vs June 2025, Converter `2026-06-18` -> `Sol 1, 2026` & `2025-02-29` validation & View on Calendar, Responsive layouts `375x812`, `768x1024`, `1440x900`)
- [x] `flutter analyze` — **No issues found!**
- [x] `flutter test` — **14/14 tests passed!**
- [x] Web build & live app verification
