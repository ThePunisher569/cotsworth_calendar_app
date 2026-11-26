# Cotsworth Calendar App

A cross-platform **13-month, 28-day calendar** application built with **Flutter** and **Firebase**, implementing the International Fixed Calendar (Cotsworth Plan) across Android, iOS, Web, macOS, Windows, and Linux.

---

## How the 13×28 Cotsworth Calendar Works

- **13 Equal Months:** January through December plus **Sol** (Month 7, placed between June and July).
- **28 Days Every Month:** Every month starts on **Sunday** and ends on **Saturday**—an identical 7×4 grid year-round.
- **Intercalary Days (Outside the 7-Day Week):**
  - **Year Day:** Follows December 28 every year (Gregorian December 31).
  - **Leap Day:** Follows June 28 in leap years (Gregorian June 17).

---

## Features

- **Monthly 7×4 Calendar (`features/calendar`):** Swipeable fixed-grid monthly view with dual Cotsworth/Gregorian date awareness, intercalary day support, and event management.
- **Bidirectional Date Converter (`features/converter`):** Instant conversion between Gregorian and Cotsworth dates, including leap-year and intercalary edge cases.
- **13-Month Year Overview (`features/year_overview`):** Full annual bird's-eye matrix with 1-tap navigation to any month.
- **Authentication & Guest Mode (`features/auth`):** Firebase Authentication with anonymous guest access (`guest_account_badge.dart`) and seamless account linking.
- **Adaptive Cross-Platform Shell (`shared/widgets/adaptive_scaffold.dart`):** Responsive navigation layout driven by `NavigationCubit` for mobile, tablet, web, and desktop viewports.
- **Theme System (`core/theme`):** Custom light and dark palettes with design previews stored in `theme_ss/`.

---

## Project Structure

```text
cotsworth_calendar_app/
├── .github/                        # CI/CD workflows
├── android/                        # Android platform runner
├── ios/                            # iOS platform runner
├── linux/                          # Linux desktop runner
├── macos/                          # macOS desktop runner
├── web/                            # Web platform runner
├── windows/                        # Windows desktop runner
├── theme_ss/                       # UI & theme preview screenshots
├── test/                           # Unit, Cubit/BLoC, and widget tests
└── lib/
    ├── main.dart                   # App bootstrap & Firebase initialization
    ├── app.dart                    # Root MaterialApp, theme & navigation wiring
    ├── core/
    │   ├── calendar_engine/        # Pure-Dart 13×28 Cotsworth <-> Gregorian engine
    │   ├── storage/                # Local & cloud persistence abstractions
    │   ├── theme/                  # Light/Dark ThemeData & design tokens
    │   └── utils/                  # Shared helpers and extensions
    ├── features/
    │   ├── auth/                   # Firebase Auth & guest account flows
    │   ├── calendar/               # 7×4 month view, day selection & event CRUD
    │   ├── converter/              # Bidirectional Gregorian <-> Cotsworth converter
    │   └── year_overview/          # 13-month annual overview grid
    └── shared/
        └── widgets/
            ├── adaptive_scaffold.dart      # Responsive multi-platform navigation shell
            ├── cotsworth_logo.dart         # Brand mark widget
            ├── guest_account_badge.dart    # Guest session status & upgrade prompt
            └── navigation_cubit.dart       # Top-level tab/destination Cubit
```

---

## Tech Stack

- **Frontend:** Flutter (Dart 3, Material 3)
- **State Management:** `flutter_bloc` (BLoC / Cubit)
- **Backend:** Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`, optional `firebase_ai` + `firebase_app_check`)
- **Targets:** Android, iOS, Web, macOS, Windows, Linux

---

## Getting Started

### Prerequisites

- Flutter SDK (stable channel, Dart 3+)
- Firebase CLI & FlutterFire CLI (`dart pub global activate flutterfire_cli`)

### Setup

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```
2. **Configure Firebase (if `firebase_options.dart` is git-ignored):**
   ```bash
   flutterfire configure
   ```
3. **Run the app:**
   ```bash
   # Mobile / Desktop
   flutter run

   # Web
   flutter run -d chrome
   ```

---

## Testing & Verification

```bash
# Check formatting
dart format --output=none --set-exit-if-changed .

# Static analysis
flutter analyze

# Run full test suite
flutter test
```

---

## Build Commands

```bash
# Android APK
flutter build apk --release

# Web (WebAssembly)
flutter build web --wasm

# Desktop (run on target OS)
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

---

## Screenshots

UI and theme reference captures are kept in [`theme_ss/`](./theme_ss/). Update the paths below to embed them directly in GitHub:

```markdown
| Light Theme | Dark Theme |
|---|---|
| ![Light](theme_ss/light.png) | ![Dark](theme_ss/dark.png) |
```