import 'package:flutter/material.dart';

/// All color tokens for the "Midnight Precision" Design System.
/// DO NOT USE HARDCODED COLORS. USE THEME CONTEXT: `Theme.of(context).colorScheme.*`
abstract final class AppColors {
  // ─── Surfaces & Backgrounds ───────────────────────────────────────────
  static const Color background = Color(0xFF0F141E);
  static const Color surface = Color(0xFF1A202C);
  static const Color surfaceElevated = Color(0xFF1E293B);

  // ─── Brand Colors ───────────────────────────────────────────────────
  static const Color primary = Color(0xFF6366F1);
  static const Color secondaryAccent = Color(0xFF22D3EE);

  // ─── Typography ─────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFF9CA3AF);

  // ─── Semantic (ONLY for status meaning) ─────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}
