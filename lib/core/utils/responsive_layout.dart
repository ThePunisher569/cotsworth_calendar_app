import 'package:material_ui/material_ui.dart';

enum ScreenSizeClass { mobile, tablet, desktop }

abstract final class ResponsiveLayout {
  static const double mobileBreakpoint = 600;
  static const double desktopBreakpoint = 1024;

  static ScreenSizeClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static ScreenSizeClass fromWidth(double width) {
    if (width < mobileBreakpoint) return ScreenSizeClass.mobile;
    if (width < desktopBreakpoint) return ScreenSizeClass.tablet;
    return ScreenSizeClass.desktop;
  }

  static bool isMobile(BuildContext context) =>
      of(context) == ScreenSizeClass.mobile;
  static bool isDesktop(BuildContext context) =>
      of(context) == ScreenSizeClass.desktop;
}
