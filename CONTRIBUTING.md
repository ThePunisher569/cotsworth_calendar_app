# Contributing to Cotsworth Calendar App

Thank you for your interest in contributing to **Cotsworth Calendar App**! Whether you are fixing a bug, adding a new feature, improving cross-platform UI polish, or writing tests, your contributions are welcome.

---

## Ways to Contribute

- **New Features:** Propose and build features from the roadmap (e.g., local reminders, event search, recurring rules, AI quick-add, export/import, or accessibility improvements).
- **Bug Fixes:** Squash UI layout issues, platform-specific glitches, or date edge cases.
- **Tests & Coverage:** Expand unit tests for the 13×28 calendar engine, Cubit/BLoC tests, and responsive widget tests.
- **UI/UX & Cross-Platform Polish:** Improve keyboard shortcuts, desktop/web hover ergonomics, dark/light theme contrast, or localization.
- **Documentation:** Clarify setup steps, architecture notes, or code comments.

---

## Before You Start

1. **Check Existing Issues & PRs:** Search open issues and pull requests to make sure nobody is already working on the same feature or fix.
2. **Open a Feature Proposal First:** For anything larger than a small bug fix or typo, open a GitHub Issue describing:
   - The problem or user need
   - Your proposed UX and architectural approach
   - Any new packages or Firebase changes required
   
   Wait for maintainer alignment before investing time in large refactors.

---

## Local Development Setup

### Prerequisites

- **Flutter SDK:** Stable channel (Dart 3+)
- **Git**
- **Firebase CLI & FlutterFire CLI** (required only if testing or modifying Firebase features):
  ```bash
  dart pub global activate flutterfire_cli
  ```

### Fork, Clone & Run

1. **Fork** the repository on GitHub, then clone your fork locally:
   ```bash
   git clone [https://github.com/](https://github.com/)<your-username>/cotsworth_calendar_app.git
   cd cotsworth_calendar_app
   ```
2. **Add the upstream remote** to keep your fork synced:
   ```bash
   git remote add upstream [https://github.com/](https://github.com/)<maintainer-username>/cotsworth_calendar_app.git
   ```
3. **Install dependencies:**
   ```bash
   flutter pub get
   ```
4. **Configure Firebase (for Auth / Firestore / AI features):**
   - Production Firebase config files are intentionally excluded from version control.
   - Create your own free Firebase Spark project and run:
     ```bash
     flutterfire configure
     ```
   - **Never commit** `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, or any API keys/service account JSON files.
5. **Run the app:**
   ```bash
   flutter run -d chrome   # Web
   flutter run             # Connected mobile/desktop device
   ```

---

## Project Architecture & Where to Add Code

This project follows a **feature-first architecture** with `flutter_bloc` (BLoC/Cubit) state management:

```text
lib/
├── main.dart                     # App entry point & service/Firebase init
├── app.dart                      # Root MaterialApp, theme & top-level providers
├── core/
│   ├── calendar_engine/          # Pure-Dart 13×28 Cotsworth <-> Gregorian math
│   ├── storage/                  # Local & Firestore persistence adapters
│   ├── theme/                    # Light/Dark ThemeData & design tokens
│   └── utils/                    # Shared pure helper functions
├── features/
│   ├── auth/                     # Firebase Auth & anonymous Guest Mode
│   ├── calendar/                 # 7×4 month view, intercalary days & event CRUD
│   ├── converter/                # Bidirectional Gregorian <-> Cotsworth converter
│   └── year_overview/            # 13-month annual overview matrix
└── shared/
    └── widgets/
        ├── adaptive_scaffold.dart    # Cross-platform responsive navigation shell
        ├── cotsworth_logo.dart       # Brand mark
        ├── guest_account_badge.dart  # Guest session indicator & upgrade prompt
        └── navigation_cubit.dart     # Top-level navigation state
```

### Adding a New Feature

When building a new feature (e.g., `reminders` or `search`), keep it self-contained under `lib/features/<feature_name>/`:

```text
lib/features/<feature_name>/
├── data/            # Models, DTOs, Firestore/local data sources & repositories
├── domain/          # Pure-Dart entities, repository contracts, use cases
└── presentation/    # Cubits/BLoCs, pages, and feature-specific widgets
```

Mirror the exact folder path under `test/features/<feature_name>/` for your unit, BLoC, and widget tests.

---

## Engineering Guidelines & Calendar Invariants

To keep the codebase reliable across Android, iOS, Web, macOS, Windows, and Linux, all PRs must respect these rules:

1. **Keep `core/calendar_engine/` Pure Dart:**
   - Do **not** import `package:flutter/...` or Firebase packages inside `lib/core/calendar_engine/`.
   - Always normalize dates to `DateTime.utc(year, month, day)` before computing day-of-year offsets to prevent Daylight Saving Time (DST) off-by-one bugs.
   - Treat **Year Day** (after Dec 28) and **Leap Day** (after Jun 28 in leap years) as explicit intercalary types outside the 7-day weekday cycle—never as magic numbers like Day `29` or Month `0`.
2. **Persist Events Using Gregorian UTC Keys:**
   - Store and query events using Gregorian ISO-8601 UTC dates (`yyyy-MM-dd`), then project them onto Cotsworth dates via `core/calendar_engine/`.
   - Scope all Firestore paths per user (`users/{uid}/...`) and preserve compatibility with anonymous Guest Mode (`guest_account_badge.dart`).
3. **Follow Existing State Management Patterns:**
   - Use `flutter_bloc` (Cubit or BLoC) consistently with `navigation_cubit.dart`.
   - Keep date arithmetic and business logic out of widget `build()` methods.
4. **Cross-Platform Responsive UI:**
   - New screens must integrate cleanly with `adaptive_scaffold.dart` and render without overflow on mobile (`390×844`), tablet (`768×1024`), and desktop/web (`1440×900`) viewports.
   - Support both Light and Dark themes via `Theme.of(context)` tokens from `core/theme/`—avoid hardcoded hex colors in widgets.
   - Provide touch feedback on mobile and hover/keyboard accessibility on web and desktop.
5. **Firebase AI Logic (If Applicable):**
   - Never rely on an LLM to calculate 13×28 dates in plain text—use Structured Output or Function Calling and pass extracted dates through `core/calendar_engine/`.
   - Ensure `FirebaseAppCheck` is respected and never hardcode prompts that bypass security rules.
6. **Keep Assets Clean:**
   - Place PR/documentation screenshots in `theme_ss/` only if requested, and do **not** register `theme_ss/` under `flutter.assets` in `pubspec.yaml`.

---

## Branching & Commit Conventions

Create a focused branch from `main` for each feature or fix:

- `feat/<short-description>` — New feature (e.g., `feat/event-search`)
- `fix/<short-description>` — Bug fix (e.g., `fix/leap-day-selection`)
- `docs/<short-description>` — Documentation updates
- `test/<short-description>` — Test additions or improvements
- `refactor/<short-description>` — Code restructuring without behavior changes

Use [Conventional Commits](https://www.conventionalcommits.org/) for clear commit history:

```text
feat(calendar): add quick jump picker for Sol and intercalary days
fix(converter): handle century non-leap year 1900 correctly
test(calendar_engine): add full 366-day round-trip test for 2028
```

---

## Pre-PR Verification Checklist

Run these commands locally and verify they pass with zero warnings before opening a Pull Request:

```bash
# 1. Check code formatting
dart format --output=none --set-exit-if-changed .

# 2. Run static analyzer
flutter analyze

# 3. Run unit, BLoC, and widget tests
flutter test

# 4. Verify web build (if touching UI, routing, or plugins)
flutter build web
```

---

## Submitting a Pull Request

1. Keep PRs small and scoped to a single feature or issue.
2. Include in your PR description:
   - **Summary:** What changed and why (link the issue with `Closes #<issue-number>`).
   - **Platforms Tested:** Which targets you verified (e.g., Android, Web Chrome, Linux).
   - **Screenshots / Screen Recordings:** Required for any UI changes (include both **Light** and **Dark** modes).
   - **Test Coverage:** Mention the unit, Cubit/BLoC, or widget tests added or updated.
3. Respond constructively to review comments and rebase/merge `main` if conflicts arise.

---

## Code of Conduct

Be respectful, constructive, and welcoming in issues, discussions, and code reviews. Critique code, never people. Maintainers reserve the right to remove comments or decline PRs that violate a healthy collaborative environment.
