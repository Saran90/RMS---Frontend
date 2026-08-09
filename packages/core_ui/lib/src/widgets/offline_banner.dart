import 'package:flutter/material.dart';

/// An amber banner displayed when the device has no internet connection.
///
/// Visibility is controlled externally via [isVisible].  When `false` the
/// widget renders as a zero-height [SizedBox] so that it does not consume
/// layout space.
///
/// Auto-dismiss logic (e.g. listening to connectivity changes) should be
/// handled by the parent widget/BLoC that owns the [isVisible] state.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    required this.isVisible,
    super.key,
  });

  /// When `true` the amber banner is shown; when `false` it is hidden.
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Semantics(
      liveRegion: true,
      label: 'No internet connection',
      child: Container(
        width: double.infinity,
        color: Colors.amber,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, size: 18, color: Colors.black87),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No internet connection',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
