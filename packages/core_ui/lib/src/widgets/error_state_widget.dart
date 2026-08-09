import 'package:flutter/material.dart';

import 'package:core_ui/src/widgets/retry_button.dart';

/// Displays a centred error [message] together with a [RetryButton].
///
/// The retry callback is optional — when omitted the [RetryButton] is not
/// rendered.
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    required this.message,
    super.key,
    this.onRetry,
  });

  /// Human-readable error message shown to the user.
  final String message;

  /// Optional callback forwarded to [RetryButton].  When `null` the button is
  /// not displayed.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              RetryButton(onPressed: onRetry!),
            ],
          ],
        ),
      ),
    );
  }
}
