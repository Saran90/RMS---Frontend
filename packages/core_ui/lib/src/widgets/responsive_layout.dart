import 'package:flutter/widgets.dart';

import '../theme/screen_breakpoints.dart';

/// A widget that renders different layouts based on the current screen width.
///
/// Uses [ScreenBreakpoints] to decide which slot to display:
/// - width < [ScreenBreakpoints.compact] (600) → [compact]
/// - [ScreenBreakpoints.compact] ≤ width < [ScreenBreakpoints.medium] (1024) → [medium]
/// - width ≥ [ScreenBreakpoints.medium] (1024) → [expanded]
///
/// Satisfies Requirements 17.1, 17.2, 17.3.
class ResponsiveLayout extends StatelessWidget {
  /// Creates a [ResponsiveLayout] with the three required layout slots.
  ///
  /// All three parameters are required. Each slot is only built when it is the
  /// active breakpoint, so expensive sub-trees are not built unnecessarily.
  const ResponsiveLayout({
    super.key,
    required this.compact,
    required this.medium,
    required this.expanded,
  });

  /// Widget rendered when the screen width is less than [ScreenBreakpoints.compact] (< 600 dp).
  ///
  /// Typically a single-column layout with a bottom navigation bar.
  final Widget compact;

  /// Widget rendered when the screen width is in the medium range
  /// ([ScreenBreakpoints.compact] ≤ width < [ScreenBreakpoints.medium], i.e. 600–1023 dp).
  ///
  /// Typically a two-column layout with a navigation rail.
  final Widget medium;

  /// Widget rendered when the screen width is at or above [ScreenBreakpoints.medium] (≥ 1024 dp).
  ///
  /// Typically a master-detail layout with a permanent side drawer.
  final Widget expanded;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    if (width >= ScreenBreakpoints.medium) {
      return expanded;
    } else if (width >= ScreenBreakpoints.compact) {
      return medium;
    } else {
      return compact;
    }
  }
}
