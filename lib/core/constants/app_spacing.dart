/// Spacing system from the Design System (Part 10.4).
/// Base unit: 4px. All values are multiples of 4.
/// Never hardcode spacing values inline — use these constants.
abstract final class AppSpacing {
  // ─── Scale Tokens ─────────────────────────────────────────────────────

  /// 4dp — Icon-to-label micro gap
  static const double space1 = 4.0;

  /// 8dp — Chip horizontal padding, tight gaps
  static const double space2 = 8.0;

  /// 12dp — List tile vertical padding
  static const double space3 = 12.0;

  /// 16dp — Screen horizontal margin, card padding
  static const double space4 = 16.0;

  /// 20dp — Label-to-input gap
  static const double space5 = 20.0;

  /// 24dp — Between unrelated components
  static const double space6 = 24.0;

  /// 32dp — Between major screen sections
  static const double space8 = 32.0;

  /// 40dp — Screen top padding below app bar
  static const double space10 = 40.0;

  /// 48dp — Hero section vertical padding
  static const double space12 = 48.0;

  /// 64dp — Bottom nav buffer
  static const double space16 = 64.0;

  // ─── Fixed Layout Values ──────────────────────────────────────────────

  /// Screen horizontal margin: 16dp
  static const double screenMargin = 16.0;

  /// AppBar height: 56dp
  static const double appBarHeight = 56.0;

  /// Bottom nav height: 80dp (64dp bar + 16dp safe area)
  static const double bottomNavHeight = 80.0;

  /// Card internal padding: 16dp
  static const double cardPadding = 16.0;

  /// Compact list card padding: 12dp
  static const double cardPaddingCompact = 12.0;

  /// Section spacing: 32dp
  static const double sectionSpacing = 32.0;

  /// Minimum touch target: 48×48dp
  static const double minTouchTarget = 48.0;

  /// FAB offset from right edge: 16dp
  static const double fabRightOffset = 16.0;

  /// FAB offset above bottom nav: 16dp
  static const double fabBottomOffset = 16.0;

  /// Bottom sheet handle width: 32dp
  static const double bottomSheetHandleWidth = 32.0;

  /// Bottom sheet handle height: 4dp
  static const double bottomSheetHandleHeight = 4.0;

  /// Bottom sheet handle top margin: 8dp
  static const double bottomSheetHandleTop = 8.0;

  // ─── Border Radius ────────────────────────────────────────────────────

  /// Card radius: 16dp
  static const double radiusCard = 16.0;

  /// Hero card radius: 20dp
  static const double radiusHeroCard = 20.0;

  /// Button radius: 12dp
  static const double radiusButton = 12.0;

  /// Compact card radius: 12dp
  static const double radiusCompactCard = 12.0;

  /// Input field top corners: 12dp
  static const double radiusInput = 12.0;

  /// Dialog radius: 24dp
  static const double radiusDialog = 24.0;

  /// Bottom sheet radius: 28dp
  static const double radiusBottomSheet = 28.0;

  /// Full / pill radius: 100dp
  static const double radiusFull = 100.0;

  /// FAB large radius: 16dp
  static const double radiusFabLarge = 16.0;

  /// SnackBar radius: 12dp
  static const double radiusSnackBar = 12.0;
}
