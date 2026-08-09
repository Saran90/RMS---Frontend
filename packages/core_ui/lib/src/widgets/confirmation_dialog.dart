import 'package:flutter/material.dart';

/// An [AlertDialog] asking the user to confirm or cancel an action.
///
/// Use [showConfirmationDialog] as a convenience wrapper that pushes the dialog
/// and returns the user's choice as a [bool].
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
    super.key,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
  });

  /// Title shown at the top of the dialog.
  final String title;

  /// Descriptive message body.
  final String message;

  /// Label for the confirmation button.  Defaults to `"Confirm"`.
  final String confirmLabel;

  /// Label for the cancellation button.  Defaults to `"Cancel"`.
  final String cancelLabel;

  /// Callback invoked when the user taps the confirm button.
  final VoidCallback onConfirm;

  /// Callback invoked when the user taps the cancel button.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

/// Shows a [ConfirmationDialog] and returns `true` when the user confirms,
/// `false` when the user cancels or dismisses the dialog.
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmationDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    ),
  );
  return result ?? false;
}
