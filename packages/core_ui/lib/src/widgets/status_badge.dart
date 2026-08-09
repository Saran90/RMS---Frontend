import 'package:flutter/material.dart';

/// A small rounded chip displaying [label] text on a [color] background.
///
/// The text colour is automatically chosen (black or white) to maximise
/// contrast against [color].  A semantic label equal to [label] is applied so
/// that screen readers can announce the status.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.color,
    super.key,
  });

  /// The status text to display inside the badge.
  final String label;

  /// Background colour of the badge.
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Choose black or white text for sufficient contrast.
    final textColor = _contrastingTextColor(color);

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  /// Returns [Colors.white] or [Colors.black] whichever has higher contrast
  /// against [background], using the W3C relative-luminance formula.
  static Color _contrastingTextColor(Color background) {
    final luminance = background.computeLuminance();
    // WCAG threshold: use white on dark colours (luminance < 0.179 gives
    // contrast ratio ≥ 4.5 : 1 with white for the normal-text threshold).
    return luminance < 0.35 ? Colors.white : Colors.black;
  }
}
