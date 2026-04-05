import 'package:flutter/material.dart';

/// All color tokens from the Design System (Part 10.2).
/// Never hardcode hex values inline — use these constants.
abstract final class AppColors {
  // ─── Primary ──────────────────────────────────────────────────────────

  static const Color primary = Color(0xFF4F6FE8);
  static const Color primaryVariant = Color(0xFF3D59D0);
  static const Color primaryContainer = Color(0xFFEEF2FF);

  static const Color primaryDark = Color(0xFF818CF8);
  static const Color primaryContainerDark = Color(0xFF312E81);

  // ─── Secondary ────────────────────────────────────────────────────────

  static const Color secondary = Color(0xFF34D399);
  static const Color secondaryContainer = Color(0xFFD1FAE5);

  static const Color secondaryDark = Color(0xFF6EE7B7);
  static const Color secondaryContainerDark = Color(0xFF064E3B);

  // ─── Background & Surface ─────────────────────────────────────────────

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF334155);

  // ─── Outline ──────────────────────────────────────────────────────────

  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineDark = Color(0xFF475569);

  // ─── On Colors (Light) ────────────────────────────────────────────────

  static const Color onBackground = Color(0xFF0F172A);
  static const Color onSurface = Color(0xFF1E293B);
  static const Color onSurfaceVariant = Color(0xFF64748B);

  // ─── On Colors (Dark) ─────────────────────────────────────────────────

  static const Color onBackgroundDark = Color(0xFFF1F5F9);
  static const Color onSurfaceDark = Color(0xFFE2E8F0);
  static const Color onSurfaceVariantDark = Color(0xFF94A3B8);

  // ─── Error ────────────────────────────────────────────────────────────

  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEF2F2);

  static const Color errorDark = Color(0xFFFCA5A5);
  static const Color errorContainerDark = Color(0xFF7F1D1D);

  // ─── Semantic ─────────────────────────────────────────────────────────

  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);

  static const Color successDark = Color(0xFF6EE7B7);
  static const Color successContainerDark = Color(0xFF064E3B);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);

  static const Color warningDark = Color(0xFFFCD34D);

  // ─── Revision Calendar Type Colors ────────────────────────────────────

  static const Color revisionBlue = Color(0xFF4F6FE8);
  static const Color practiceOrange = Color(0xFFF59E0B);
  static const Color testRed = Color(0xFFEF4444);
  static const Color finalPurple = Color(0xFF8B5CF6);
}
