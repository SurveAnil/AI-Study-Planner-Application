import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens from the Design System (Part 10.3).
/// Display/UI font: Plus Jakarta Sans
/// Monospace/stats font: DM Mono (timers, numeric stats)
abstract final class AppTextStyles {
  // ─── Display ──────────────────────────────────────────────────────────

  /// 57sp / w700 / 1.12 — Hero score numbers, splash screens
  static TextStyle displayLarge = GoogleFonts.plusJakartaSans(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    height: 1.12,
  );

  /// 45sp / w700 / 1.16 — Timer MM:SS countdown (DM Mono)
  static TextStyle displayMedium = GoogleFonts.dmMono(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 1.16,
  );

  /// 36sp / w600 / 1.22 — Section hero stats
  static TextStyle displaySmall = GoogleFonts.plusJakartaSans(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.22,
  );

  // ─── Headline ─────────────────────────────────────────────────────────

  /// 32sp / w700 / 1.25 — Screen titles, plan headings
  static TextStyle headlineLarge = GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  /// 28sp / w600 / 1.28 — Card headings, subject names
  static TextStyle headlineMedium = GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.28,
  );

  /// 24sp / w600 / 1.33 — Section headers within screens
  static TextStyle headlineSmall = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  // ─── Title ────────────────────────────────────────────────────────────

  /// 22sp / w600 / 1.27 — Dialog titles, bottom sheet headers
  static TextStyle titleLarge = GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
  );

  /// 16sp / w500 / 1.50 — List item titles, task names
  static TextStyle titleMedium = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.50,
  );

  /// 14sp / w500 / 1.43 — Chip labels, tab bar labels
  static TextStyle titleSmall = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
  );

  // ─── Body ─────────────────────────────────────────────────────────────

  /// 16sp / w400 / 1.50 — Primary body copy
  static TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.50,
  );

  /// 14sp / w400 / 1.43 — Secondary body, card descriptions
  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
  );

  /// 12sp / w400 / 1.33 — Captions, helper text, metadata
  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
  );

  // ─── Label ────────────────────────────────────────────────────────────

  /// 14sp / w500 / 1.43 — Button labels
  static TextStyle labelLarge = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
  );

  /// 12sp / w500 / 1.33 — Chip text, badge labels
  static TextStyle labelMedium = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
  );

  /// 11sp / w500 / 1.45 — Overlines, category tags
  static TextStyle labelSmall = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  // ─── Mono (for stats/timers) ──────────────────────────────────────────

  /// DM Mono 16sp / w500 — Numeric stats, hex codes
  static TextStyle monoMedium = GoogleFonts.dmMono(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.50,
  );

  /// DM Mono 14sp / w400 — Small numeric displays
  static TextStyle monoSmall = GoogleFonts.dmMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
  );
}
