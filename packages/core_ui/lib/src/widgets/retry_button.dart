import 'package:flutter/material.dart';

/// An [OutlinedButton] labelled "Retry" with a guaranteed minimum 48 × 48 dp
/// touch target and a semantic label for screen readers.
class RetryButton extends StatelessWidget {
  const RetryButton({
    required this.onPressed,
    super.key,
  });

  /// Callback invoked when the button is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Retry',
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        child: OutlinedButton(
          onPressed: onPressed,
          child: const Text('Retry'),
        ),
      ),
    );
  }
}
