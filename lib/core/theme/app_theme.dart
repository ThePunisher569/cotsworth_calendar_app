import 'package:material_ui/material_ui.dart';

/// Default Flutter Material 3 light & dark themes with typography helpers.
abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return _applyTypography(base);
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return _applyTypography(base);
  }

  static ThemeData _applyTypography(ThemeData base) {
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: base.colorScheme.outlineVariant.withAlpha(150),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }

  /// TextStyle with tabular figures for aligned numbers.
  static TextStyle tabular(TextStyle? base) {
    return (base ?? const TextStyle()).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static Color solAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF59E0B)
        : const Color(0xFFD97706);
  }

  static Color intercalaryAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2DD4BF)
        : const Color(0xFF0D9488);
  }
}
