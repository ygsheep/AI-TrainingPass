import 'package:flutter/widgets.dart';

/// Responsive Breakpoints
/// Mobile: < 768px
/// Tablet: 768px - 1024px
/// Desktop: >= 1024px
class Breakpoints {
  static const double mobile = 375;
  static const double tablet = 768;
  static const double desktop = 1024;

  /// Maximum content width for desktop
  static const double maxContentWidth = 1200;

  /// Grid columns for desktop layout
  static const int gridColumns = 12;

  /// Content padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
}

/// Responsive utilities
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < Breakpoints.tablet;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.tablet &&
      MediaQuery.of(context).size.width < Breakpoints.desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.desktop;

  /// Get padding based on screen size
  static double getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.tablet) return Breakpoints.paddingMedium;
    if (width < Breakpoints.desktop) return Breakpoints.paddingLarge;
    return Breakpoints.paddingXLarge;
  }

  /// Get columns count for grid layout
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }
}
