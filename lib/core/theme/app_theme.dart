import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// iOS-inspired dark calendar theme with IBM Plex Sans typography.
///
/// Matches the visual hierarchy of the reference calendar widgets:
/// - Deep black canvas (`#000000`) & matte charcoal cards (`#1C1C1E`)
/// - Elevated nested surfaces (`#2C2C2E`, `#3A3A3C`) with subtle `1px` borders
/// - Coral red accent (`#FF3B30` / `#FF453A`) for today & active month titles
/// - Muted gray (`#8E8E93`) for weekday headers and weekend columns
/// - Warm amber for Sol (13th month) and teal for Intercalary days
abstract final class AppTheme {
  // ─── Dark Palette ────────────────────────────────────────────────
  static const _scaffoldDark = Color(0xFF000000);
  static const _surfaceDark = Color(0xFF141416);
  static const _surfaceContainerLowDark = Color(0xFF18181A);
  static const _surfaceContainerDark = Color(0xFF1C1C1E);
  static const _surfaceContainerHighDark = Color(0xFF2C2C2E);
  static const _surfaceContainerHighestDark = Color(0xFF3A3A3C);
  static const _onSurfaceDark = Color(0xFFFFFFFF);
  static const _onSurfaceVariantDark = Color(0xFF8E8E93);
  static const _outlineDark = Color(0xFF48484A);
  static const _outlineVariantDark = Color(0xFF2C2C2E);

  // ─── Light Palette ───────────────────────────────────────────────
  static const _scaffoldLight = Color(0xFFF2F2F7);
  static const _surfaceLight = Color(0xFFFFFFFF);
  static const _surfaceContainerLowLight = Color(0xFFF9F9FB);
  static const _surfaceContainerLight = Color(0xFFF2F2F7);
  static const _surfaceContainerHighLight = Color(0xFFE5E5EA);
  static const _surfaceContainerHighestLight = Color(0xFFD1D1D6);
  static const _onSurfaceLight = Color(0xFF1C1C1E);
  static const _onSurfaceVariantLight = Color(0xFF6E6E73);
  static const _outlineLight = Color(0xFFC7C7CC);
  static const _outlineVariantLight = Color(0xFFE5E5EA);

  // ─── Accents ─────────────────────────────────────────────────────
  static const todayRed = Color(0xFFFF3B30);
  static const _primaryDark = Color(0xFFFF453A);
  static const _primaryLight = Color(0xFFFF3B30);

  static const _solDark = Color(0xFFFF9F0A);
  static const _solLight = Color(0xFFD97706);

  static const _intercalaryDark = Color(0xFF2DD4BF);
  static const _intercalaryLight = Color(0xFF0D9488);

  // ─── IBM Plex Sans Typography Scale ──────────────────────────────
  static TextTheme _ibmPlexSansTheme(TextTheme base, Color onSurface) {
    final themed = GoogleFonts.ibmPlexSansTextTheme(base)
        .apply(bodyColor: onSurface, displayColor: onSurface);
    return themed.copyWith(
      displaySmall: GoogleFonts.ibmPlexSans(
        textStyle: themed.displaySmall,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: onSurface,
      ),
      headlineLarge: GoogleFonts.ibmPlexSans(
        textStyle: themed.headlineLarge,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.18,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.ibmPlexSans(
        textStyle: themed.headlineMedium,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        height: 1.2,
        color: onSurface,
      ),
      headlineSmall: GoogleFonts.ibmPlexSans(
        textStyle: themed.headlineSmall,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: onSurface,
      ),
      titleLarge: GoogleFonts.ibmPlexSans(
        textStyle: themed.titleLarge,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.ibmPlexSans(
        textStyle: themed.titleMedium,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: onSurface,
      ),
      titleSmall: GoogleFonts.ibmPlexSans(
        textStyle: themed.titleSmall,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      bodyLarge: GoogleFonts.ibmPlexSans(
        textStyle: themed.bodyLarge,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      bodyMedium: GoogleFonts.ibmPlexSans(
        textStyle: themed.bodyMedium,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodySmall: GoogleFonts.ibmPlexSans(
        textStyle: themed.bodySmall,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      labelLarge: GoogleFonts.ibmPlexSans(
        textStyle: themed.labelLarge,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.ibmPlexSans(
        textStyle: themed.labelMedium,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
      labelSmall: GoogleFonts.ibmPlexSans(
        textStyle: themed.labelSmall,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
  }

  // ─── Dark Theme ──────────────────────────────────────────────────
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.dark(
      primary: _primaryDark,
      onPrimary: Colors.white,
      primaryContainer: _primaryDark.withAlpha(42),
      onPrimaryContainer: _primaryDark,
      secondary: _solDark,
      onSecondary: Colors.black,
      tertiary: _intercalaryDark,
      surface: _surfaceDark,
      onSurface: _onSurfaceDark,
      onSurfaceVariant: _onSurfaceVariantDark,
      surfaceContainerLowest: _scaffoldDark,
      surfaceContainerLow: _surfaceContainerLowDark,
      surfaceContainer: _surfaceContainerDark,
      surfaceContainerHigh: _surfaceContainerHighDark,
      surfaceContainerHighest: _surfaceContainerHighestDark,
      outline: _outlineDark,
      outlineVariant: _outlineVariantDark,
      error: const Color(0xFFFF6961),
      errorContainer: const Color(0xFF4C1111),
      onError: Colors.white,
      onErrorContainer: const Color(0xFFFFDAD6),
    );
    final textTheme = _ibmPlexSansTheme(base.textTheme, _onSurfaceDark);

    return base.copyWith(
      scaffoldBackgroundColor: _scaffoldDark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _scaffoldDark,
        foregroundColor: _onSurfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.ibmPlexSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _onSurfaceDark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _surfaceContainerDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _outlineVariantDark, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surfaceDark,
        indicatorColor: _primaryDark.withAlpha(38),
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? _primaryDark : _onSurfaceVariantDark,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.ibmPlexSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? _primaryDark : _onSurfaceVariantDark,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _surfaceDark,
        indicatorColor: _primaryDark.withAlpha(38),
        selectedIconTheme: const IconThemeData(color: _primaryDark),
        unselectedIconTheme: const IconThemeData(color: _onSurfaceVariantDark),
        selectedLabelTextStyle: GoogleFonts.ibmPlexSans(
          fontWeight: FontWeight.w600,
          color: _primaryDark,
        ),
        unselectedLabelTextStyle: GoogleFonts.ibmPlexSans(
          fontWeight: FontWeight.w500,
          color: _onSurfaceVariantDark,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: _surfaceDark,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceContainerDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: _outlineVariantDark),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceContainerHighDark,
        selectedColor: _primaryDark.withAlpha(45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: _outlineVariantDark),
        labelStyle: GoogleFonts.ibmPlexSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _onSurfaceDark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceContainerHighDark.withAlpha(140),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _outlineVariantDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _outlineVariantDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryDark, width: 1.5),
        ),
        labelStyle: GoogleFonts.ibmPlexSans(color: _onSurfaceVariantDark),
        hintStyle: GoogleFonts.ibmPlexSans(
          color: _onSurfaceVariantDark.withAlpha(150),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: GoogleFonts.ibmPlexSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _onSurfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: _outlineDark),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: GoogleFonts.ibmPlexSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryDark,
          textStyle: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _primaryDark.withAlpha(42);
            }
            return _surfaceContainerDark;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _primaryDark;
            }
            return _onSurfaceDark;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: _outlineVariantDark),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _outlineVariantDark,
        thickness: 0.75,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surfaceContainerHighDark,
        contentTextStyle: GoogleFonts.ibmPlexSans(color: _onSurfaceDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearTrackColor: _surfaceContainerHighDark,
        color: _primaryDark,
      ),
    );
  }

  // ─── Light Theme ─────────────────────────────────────────────────
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme = ColorScheme.light(
      primary: _primaryLight,
      onPrimary: Colors.white,
      primaryContainer: _primaryLight.withAlpha(28),
      onPrimaryContainer: _primaryLight,
      secondary: _solLight,
      onSecondary: Colors.white,
      tertiary: _intercalaryLight,
      surface: _surfaceLight,
      onSurface: _onSurfaceLight,
      onSurfaceVariant: _onSurfaceVariantLight,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: _surfaceContainerLowLight,
      surfaceContainer: _surfaceContainerLight,
      surfaceContainerHigh: _surfaceContainerHighLight,
      surfaceContainerHighest: _surfaceContainerHighestLight,
      outline: _outlineLight,
      outlineVariant: _outlineVariantLight,
      error: const Color(0xFFD32F2F),
      errorContainer: const Color(0xFFFFDAD6),
      onError: Colors.white,
      onErrorContainer: const Color(0xFF93000A),
    );
    final textTheme = _ibmPlexSansTheme(base.textTheme, _onSurfaceLight);

    return base.copyWith(
      scaffoldBackgroundColor: _scaffoldLight,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceLight,
        foregroundColor: _onSurfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.ibmPlexSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _onSurfaceLight,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _outlineVariantLight, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surfaceLight,
        indicatorColor: _primaryLight.withAlpha(28),
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? _primaryLight : _onSurfaceVariantLight,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.ibmPlexSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? _primaryLight : _onSurfaceVariantLight,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _surfaceLight,
        indicatorColor: _primaryLight.withAlpha(28),
        selectedIconTheme: const IconThemeData(color: _primaryLight),
        unselectedIconTheme: const IconThemeData(color: _onSurfaceVariantLight),
        selectedLabelTextStyle: GoogleFonts.ibmPlexSans(
          fontWeight: FontWeight.w600,
          color: _primaryLight,
        ),
        unselectedLabelTextStyle: GoogleFonts.ibmPlexSans(
          fontWeight: FontWeight.w500,
          color: _onSurfaceVariantLight,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: _surfaceLight,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: _outlineVariantLight),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceContainerLight,
        selectedColor: _primaryLight.withAlpha(30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: _outlineVariantLight),
        labelStyle: GoogleFonts.ibmPlexSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _onSurfaceLight,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceContainerLowLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _outlineVariantLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _outlineVariantLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryLight, width: 1.5),
        ),
        labelStyle: GoogleFonts.ibmPlexSans(color: _onSurfaceVariantLight),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: GoogleFonts.ibmPlexSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _onSurfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: _outlineLight),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: GoogleFonts.ibmPlexSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryLight,
          textStyle: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _primaryLight.withAlpha(28);
            }
            return _surfaceLight;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _primaryLight;
            }
            return _onSurfaceLight;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: _outlineVariantLight),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _outlineVariantLight,
        thickness: 0.75,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _onSurfaceLight,
        contentTextStyle: GoogleFonts.ibmPlexSans(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearTrackColor: _surfaceContainerHighLight,
        color: _primaryLight,
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  /// Applies tabular numerals for perfectly aligned grid numbers & counters.
  static TextStyle tabular(TextStyle? base) {
    return (base ?? GoogleFonts.ibmPlexSans()).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Sol (7th month) solar amber accent.
  static Color solAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _solDark
        : _solLight;
  }

  /// Intercalary (Leap Day / Year Day) teal accent.
  static Color intercalaryAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _intercalaryDark
        : _intercalaryLight;
  }

  /// Coral-red highlight accent for today and active month titles.
  static Color todayAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _primaryDark
        : _primaryLight;
  }
}
