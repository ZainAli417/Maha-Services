import 'package:flutter/material.dart';

/// Central semantic color tokens for Maha Services.
///
/// Values are copied verbatim from the palette already used across the app
/// (the de-facto indigo/slate scheme) so screens migrated onto these tokens
/// do not visually change. Names are semantic (and dark-mode-ready) rather
/// than literal, but the program ships light-only for now.
abstract final class AppColors {
  // ── Brand (navy + teal, derived from images/logo_new.jpeg) ──────────
  static const primary = Color(0xFF14507F); // brand navy — dominant brand
  static const primaryDark = Color(0xFF0A2E4F); // deep navy — hover/pressed
  static const primaryLight = Color(0xFF2178B5); // blue — charts/accents
  static const primarySoft = Color(0xFFE8F1F8); // navy 50 — tinted fills
  static const accent = Color(0xFF2EC4B6); // teal — gradients/accents

  // ── Ink / neutrals (Tailwind slate scale, already in use everywhere) ─
  static const ink = Color(0xFF0B2239); // deep ink navy — headings/body
  static const navy = Color(0xFF061C31); // deep navy — dark hero surfaces
  static const textSecondary = Color(0xFF475569); // slate 600
  static const textMuted = Color(0xFF64748B); // slate 500
  static const textFaint = Color(0xFF94A3B8); // slate 400 — placeholders
  static const border = Color(0xFFE2E8F0); // slate 200 — borders/dividers
  static const surfaceAlt = Color(0xFFF1F5F9); // slate 100 — hover rows, chips
  static const background = Color(0xFFF8FAFC); // slate 50  — page background
  static const surface = Color(0xFFFFFFFF);
  static const inputFill = Color(0xFFFAFAFA); // existing input fill

  // ── Status (each with a soft container tint for badges) ─────────────
  static const success = Color(0xFF10B981);
  static const successSoft = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const info = Color(0xFF06B6D4);
  static const infoSoft = Color(0xFFCFFAFE);
}
