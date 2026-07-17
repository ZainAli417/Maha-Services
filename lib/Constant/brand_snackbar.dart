import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic snackbar types — each maps to a rich, color-oriented style so
/// feedback is instantly readable across the whole app.
enum SnackType { success, error, warning, info }

/// Dynamic, colour-oriented snackbars shared across every screen (job seeker,
/// recruiter, admin). Floating, rounded, with a tinted icon chip, a bold title
/// and a message. Use [BrandSnack.success] / .error / .warning / .info, or the
/// generic [BrandSnack.show].
///
/// Example:
///   BrandSnack.success(context, 'Profile saved');
///   BrandSnack.error(context, 'Could not save', title: 'Save failed');
class BrandSnack {
  const BrandSnack._();

  static const _navy = Color(0xFF14507F);
  static const _tealDeep = Color(0xFF15A99C);
  static const _success = Color(0xFF10B981);
  static const _error = Color(0xFFEF4444);
  static const _warning = Color(0xFFF59E0B);

  static _Style _styleFor(SnackType type) {
    switch (type) {
      case SnackType.success:
        return const _Style(
          bg: Color(0xFF0E9F72),
          accent: _success,
          icon: Icons.check_circle_rounded,
          defaultTitle: 'Success',
        );
      case SnackType.error:
        return const _Style(
          bg: Color(0xFFD83A3A),
          accent: _error,
          icon: Icons.error_rounded,
          defaultTitle: 'Something went wrong',
        );
      case SnackType.warning:
        return const _Style(
          bg: Color(0xFFE0930C),
          accent: _warning,
          icon: Icons.warning_amber_rounded,
          defaultTitle: 'Heads up',
        );
      case SnackType.info:
        return const _Style(
          bg: _navy,
          accent: _tealDeep,
          icon: Icons.info_rounded,
          defaultTitle: 'Note',
        );
    }
  }

  static void show(
    BuildContext context,
    String message, {
    SnackType type = SnackType.info,
    String? title,
    Duration? duration,
    IconData? icon,
  }) {
    final style = _styleFor(type);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          duration: duration ??
              (type == SnackType.error
                  ? const Duration(seconds: 5)
                  : const Duration(seconds: 3)),
          content: _BrandSnackBody(
            style: style,
            title: title ?? style.defaultTitle,
            message: message,
            icon: icon ?? style.icon,
          ),
        ),
      );
  }

  static void success(BuildContext context, String message,
          {String? title, Duration? duration}) =>
      show(context, message,
          type: SnackType.success, title: title, duration: duration);

  static void error(BuildContext context, String message,
          {String? title, Duration? duration}) =>
      show(context, message,
          type: SnackType.error, title: title, duration: duration);

  static void warning(BuildContext context, String message,
          {String? title, Duration? duration}) =>
      show(context, message,
          type: SnackType.warning, title: title, duration: duration);

  static void info(BuildContext context, String message,
          {String? title, Duration? duration}) =>
      show(context, message,
          type: SnackType.info, title: title, duration: duration);
}

class _Style {
  const _Style({
    required this.bg,
    required this.accent,
    required this.icon,
    required this.defaultTitle,
  });
  final Color bg;
  final Color accent;
  final IconData icon;
  final String defaultTitle;
}

class _BrandSnackBody extends StatelessWidget {
  const _BrandSnackBody({
    required this.style,
    required this.title,
    required this.message,
    required this.icon,
  });

  final _Style style;
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 700;
    return Container(
      constraints: BoxConstraints(maxWidth: isMobile ? width : 460),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.bg, Color.lerp(style.bg, Colors.black, 0.18)!],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: style.accent.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 14,
        vertical: isMobile ? 11 : 13,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
