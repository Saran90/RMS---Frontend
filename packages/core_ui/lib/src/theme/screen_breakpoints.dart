/// Breakpoint constants that drive the responsive layout decisions across the
/// RMS Flutter frontend.
///
/// Layout rules (Requirement 17):
/// - width < [compact]  → single-column layout with bottom navigation bar
/// - [compact] ≤ width < [medium] → two-column layout with nav rail
/// - width ≥ [medium]  → master-detail layout with permanent side drawer
abstract final class ScreenBreakpoints {
  ScreenBreakpoints._();

  /// Minimum width (dp) for the medium (tablet) breakpoint.
  ///
  /// Devices with a screen width **at or above** this value up to (but not
  /// including) [medium] receive a persistent side navigation rail and
  /// two-column list/detail layouts.
  static const double compact = 600;

  /// Minimum width (dp) for the expanded (desktop / large tablet) breakpoint.
  ///
  /// Devices with a screen width **at or above** this value receive a permanent
  /// expanded side navigation drawer and master-detail layouts.
  static const double medium = 1024;
}
