# MVP 02 Execution Tracker — Cotsworth 13-Month Calendar App

## Overview
- **Goal**: Elevate the MVP 01 foundation into **MVP 02** with refined iOS-inspired Dark & Light design, `IBM Plex Sans` typography, high-frame-rate motion & performance optimizations, public-repo-safe Firebase Authentication & Firestore user profiles, animated Splash Screen, live location-aware Astronomical Moon & Weather Sky Hero, Profile management, and automated GitHub Pages CI/CD.
- **Target Platforms**: Android, iOS, Web (GitHub Pages at `https://thepunisher569.github.io/cotsworth_calendar_app/`).
- **Architecture**: Clean Architecture (`core/` + feature-first `features/` + `shared/`), BLoC & Cubit state management (`CalendarBloc`, `AuthCubit`, `SkyCubit`, `ThemeCubit`, `MotionCubit`, `NavigationCubit`, `ConverterCubit`), Hive + `SharedPreferences` local persistence, and compile-time `--dart-define` Firebase configuration.

---

## MVP 02 Deliverables Checklist

### Phase 1: Visual System, Typography & Layout Polish
- [x] Redesigned `lib/core/theme/app_theme.dart` with soothing iOS-calendar-inspired Dark (`#0B0C0E` / `#14161A` / `#EF4444` & `#FF453A`) and Light palettes (`#F4F5F7` / `#FFFFFF`)
- [x] Applied Google Fonts `IBM Plex Sans` hierarchy across headlines, body copy, tabular numbers, and micro-labels
- [x] Added rounded pill styling for sliders (`SliderThemeData`) and progress indicators (`ProgressIndicatorThemeData`)
- [x] Moved mobile drawer trigger to trailing right (`Scaffold.endDrawer`) so the animated brand logo sits cleanly on the left (`AdaptiveScaffold`)
- [x] Styled `NavigationRail` bottom action buttons (`Motion On/Off`, `Dark/Light Mode`, `Sign Out`) into cohesive themed pill buttons
- [x] Standardized Copy Both clipboard template via `lib/core/utils/date_clipboard_formatter.dart`:
  ```text
  Actual Calendar Date -> <Gregorian_Date>
  13-Month Calendar equivalent <CotsWorth_Date>
  ```

### Phase 2: Animation Architecture & Frame-Rate Optimization
- [x] Created `MotionCubit` (`lib/core/theme/motion_cubit.dart`) synced with OS `disableAnimations` accessibility setting and user preference persistence
- [x] Created `SmoothSlideFadeRoute`, `SmoothViewSwitcher`, and `StaggeredEntrance` (`lib/shared/widgets/smooth_page_transitions.dart`)
- [x] Added `RepaintBoundary` isolation around `DayCell`, `CotsworthGrid`, and `SkyHeroCard` for smooth 60–120 FPS transitions
- [x] Fixed `CotsworthApp` state initialization (`lib/app.dart`) so repository singletons (`_authRepo`, `_calendarCache`, `_converterHistory`) persist cleanly across splash completion rebuilds

### Phase 3: Splash Screen & Astronomical / Weather Sky Hero
- [x] Added `SplashScreen` (`lib/features/splash/splash_screen.dart`) with animated `CotsworthLogo`, **Brand Promo Header**, and rounded `LinearProgressIndicator`
- [x] Created pure-Dart `AstronomyService` (`lib/core/astronomy/astronomy_service.dart`) computing real-time lunar phase (0–1 cycle, illumination %, age in days) and local solar elevation / daylight window
- [x] Created `LocationPermissionService` (`lib/core/permissions/location_permission_service.dart`) + Android (`AndroidManifest.xml`) and iOS (`Info.plist`) location permissions
- [x] Created Open-Meteo `WeatherService` (`lib/core/network/weather_service.dart`) with 30-minute in-memory caching for live temperature, wind, cloud cover, and seasonal/sky conditions (Sun, Clouds, Rain, Autumn, Moon)
- [x] Created `SkyCubit` (`lib/features/calendar/presentation/bloc/sky_cubit.dart`) with automatic daylight/night Light & Dark theme synchronization
- [x] Built `SkyHeroCard` (`lib/features/calendar/presentation/widgets/sky_hero_card.dart`) displaying animated Lottie sky illustrations (`assets/animations/*.json`) directly above the 13-month grid on Home

### Phase 4: Firebase Auth, Profile Page & Public-Repo Security Hardening
- [x] Configured environment-driven `AppEnv` (`lib/core/config/app_env.dart`) and `DefaultFirebaseOptions` (`lib/firebase_options.dart`) using `--dart-define-from-file=.env` locally and GitHub Secrets in CI (zero keys in source)
- [x] Hardened `.gitignore` to exclude `.env`, `.env.*` (keeping `.env.example`), `.firebaserc`, `firebase.json`, `google-services.json`, `GoogleService-Info.plist`, `key.properties`, keystores (`*.jks`, `*.keystore`, `*.p12`), and service-account JSONs
- [x] Configured `android/app/build.gradle.kts` to apply `com.google.gms.google-services` only when local `google-services.json` is present
- [x] Hardened `firestore.rules` with per-user owner-only access (`isOwner(uid)`), explicit allowed-key schema validation, field type/length bounds, and default deny (`/{document=**}`)
- [x] Built `LoginScreen` (`lib/features/auth/presentation/screens/login_screen.dart`), `RegisterScreen` (`lib/features/auth/presentation/screens/register_screen.dart`), `AccountSignOutDialog`, and Temp `Guest / guest` fallback mode
- [x] Built `ProfileScreen` (`lib/features/profile/profile_screen.dart`) with:
  - Identity header & vibrant green `#00E676` (`AppTheme.verifiedGreen`) verified account tick
  - Editable **Display Name** (`Update Profile`) & disabled **Account Email** field (`enabled: false`, `readOnly: true`)
  - **Sign Out** & **Delete Account Permanently** (with re-authentication prompt when required)
  - Removed the `Security & Verification` section from Profile view
- [x] Fixed `AuthRepository` (`userChanges()`, best-effort `reload()`, non-blocking Firestore profile updates without overwriting `createdAt`, comprehensive Firebase error code mapping) and `AuthCubit` stream suppression during registration/profile updates
- [x] Implemented `AuthFeedbackBanner` + 4-second auto-hide timer in `AuthCubit` (`emit` / `close`) + dismiss button + `hideCurrentSnackBar()` on clipboard SnackBars so status/toast messages disappear cleanly

### Phase 5: Automated Testing & CI/CD Verification
- [x] `test/core/calendar_engine/cotsworth_converter_test.dart` (golden vectors, 1900–2100 round-trip, validation & boundary helpers)
- [x] `test/core/astronomy/sky_services_test.dart` (lunar phase determinism, solar daylight, Open-Meteo 30m cache, SkyCubit auto-theme, Copy Both template)
- [x] `test/features/app_widget_test.dart` (responsive breakpoints `360px`–`1440px`, right-side `endDrawer`, `RepaintBoundary`, `SplashScreen`, `SkyHeroCard`, Converter)
- [x] `test/features/auth_flow_test.dart` (registration, forgot password, login, green verified tick, disabled Profile email field, removed Security section, auto-hiding messages, profile update error/success, account deletion)
- [x] `dart format lib test` — Clean
- [x] `flutter analyze` — **No issues found!**
- [x] `flutter test` — **29/29 tests passed!**
- [x] `flutter build web --release --no-pub --base-href "/cotsworth_calendar_app/" --dart-define-from-file=.env` — **Built `build\web` cleanly!**

---

## Security Audit Summary (Public Repository Readiness)
- **Tracked Files Scan (`git ls-files` / `git grep`)**: Verified zero `.env`, `google-services.json`, `GoogleService-Info.plist`, keystores, or hardcoded Firebase API keys/project IDs are committed in Git.
- **Firestore Protection (`firestore.rules`)**: Anonymous/cross-user reads & writes blocked; `/users/{uid}` validates ownership (`request.auth.uid == uid`), allowed keys only, string length caps (`displayName <= 80`, `email <= 254`), and `calendarSystem == 'cotsworth_13x28'`.
- **CI Secrets Injection (`.github/workflows/deploy.yaml`)**: Release web builds consume GitHub Actions encrypted `${{ secrets.* }}` at build time with least-privilege permissions (`contents: read`, `pages: write`, `id-token: write`).

---

## Next Deployment to GitHub Pages Procedure

Follow these steps in order to deploy MVP 02 to **GitHub Pages** (`https://thepunisher569.github.io/cotsworth_calendar_app/`):

### 1. Verify GitHub Repository Secrets
In **GitHub → `thepunisher569/cotsworth_calendar_app` → Settings → Secrets and variables → Actions → Repository secrets**, verify all required secrets exist (matching your `.env`):
- `FIREBASE_PROJECT_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_DATABASE_URL` *(can be empty string or omitted if unused, though keep consistent with workflow)*
- `FIREBASE_WEB_API_KEY`
- `FIREBASE_WEB_APP_ID`
- `FIREBASE_WEB_MEASUREMENT_ID`
- `APP_PUBLIC_BASE_URL` (`https://thepunisher569.github.io/cotsworth_calendar_app/`)

### 2. Verify GitHub Pages Build Source
In **GitHub → Settings → Pages**:
- Set **Source** to **GitHub Actions**.

### 3. Verify Firebase Console & API Key Restrictions
In **Firebase Console** (`cotsworth-calendar-app`):
1. **Authentication → Sign-in method**: Ensure **Email/Password** provider is **Enabled**.
2. **Authentication → Settings → Authorized domains**: Ensure `thepunisher569.github.io` and `localhost` are both present.
3. **Firestore Database → Rules**: Publish the updated [`firestore.rules`](firestore.rules) (`firebase deploy --only firestore:rules` or paste into Console).
4. **Google Cloud Console → APIs & Services → Credentials → Web API Key**: Under HTTP referrers, ensure `https://thepunisher569.github.io/*`, `http://localhost/*`, and `http://127.0.0.1/*` are allowed if referrer restrictions are active.

### 4. Double-Check Local Cleanliness Before Pushing
Run locally to confirm no secrets are staged:
```powershell
git status -s
git ls-files | Select-String -Pattern "\.env|google-services|GoogleService-Info|keystore|\.jks"
```
Ensure `.env`, `.firebaserc`, and `firebase.json` do **not** appear in `git status -s`.

### 5. Commit & Push to `main` (Triggers Auto-Deploy)
```powershell
git add .
git commit -m "chore(mvp2): finalize profile updates, auto-hiding toasts, security hardening & tracker"
git push origin main
```

### 6. Monitor Action & Verify Live Site
1. Open **GitHub → Actions → Test, Build & Deploy to GitHub Pages** and wait for both `build_and_test` and `deploy` jobs to turn green.
2. Open `https://thepunisher569.github.io/cotsworth_calendar_app/` in an incognito window to verify:
   - Splash screen -> Login / Register -> Calendar view with live Sky Hero
   - Profile page (disabled email field, no Security & Verification card, auto-hiding feedback banners)
   - SPA fallback routing (`404.html`) on refresh.
