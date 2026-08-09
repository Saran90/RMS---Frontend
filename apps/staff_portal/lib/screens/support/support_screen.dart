import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Shown when the tenant's database provisioning has failed and
/// manual intervention is required.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppTheme.error),
                const SizedBox(height: AppTheme.spacing24),
                Text(
                  'Setup Failed',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  'There was a problem setting up your restaurant. '
                  'Please contact support and we\'ll resolve it for you.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.mutedText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing32),
                FilledButton(
                  onPressed: () {
                    // TODO: open support chat / email
                  },
                  child: const Text('Contact Support'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
