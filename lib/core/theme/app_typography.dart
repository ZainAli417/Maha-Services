import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography helpers bridging the ~900 per-widget `GoogleFonts.plusJakartaSans`
/// call sites toward the central theme. Screens migrate their private
/// `_T.label/head/body` helpers onto these with a mechanical rename.
///
/// The theme's `textTheme` (see [AppTheme]) is the long-term source of truth;
/// `AppText` exists so screens can migrate off private helpers incrementally.
abstract final class AppText {
  static TextStyle heading({
    double fs = 14,
    Color? color,
    FontWeight fw = FontWeight.w600,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fs,
        fontWeight: fw,
        color: color ?? AppColors.ink,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle body({
    double fs = 13,
    Color? color,
    FontWeight fw = FontWeight.w400,
    double? height,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fs,
        fontWeight: fw,
        color: color ?? AppColors.textSecondary,
        height: height,
      );

  static TextStyle label({
    double fs = 11,
    Color? color,
    FontWeight fw = FontWeight.w500,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fs,
        fontWeight: fw,
        color: color ?? AppColors.textMuted,
        letterSpacing: letterSpacing,
      );
}
