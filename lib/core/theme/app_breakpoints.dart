import 'package:flutter/widgets.dart';

/// Responsive breakpoints consolidating the per-screen `_BP` classes.
///
/// Values chosen to match the dominant clusters already in the codebase
/// (~700 for phone, ~1024/1100 for desktop). Screens that intentionally use
/// 768 keep behaving as before until their modernization pass.
abstract final class AppBreakpoints {
  static const double mobile = 700; // < mobile  → phone layout
  static const double tablet = 1024; // mobile..tablet → collapsed sidebar
  static const double desktop = 1100; // >= desktop → full rail + wide grids
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isMobile => screenWidth < AppBreakpoints.mobile;
  bool get isTablet =>
      screenWidth >= AppBreakpoints.mobile && screenWidth < AppBreakpoints.desktop;
  bool get isDesktop => screenWidth >= AppBreakpoints.desktop;
}
