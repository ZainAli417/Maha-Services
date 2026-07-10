import 'package:flutter/widgets.dart';

/// 4pt spacing grid matching the paddings already used across the app.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Corner-radius tokens.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;

  static final BorderRadius cardRadius = BorderRadius.circular(md);
  static final BorderRadius smRadius = BorderRadius.circular(sm);
  static final BorderRadius lgRadius = BorderRadius.circular(lg);
}
