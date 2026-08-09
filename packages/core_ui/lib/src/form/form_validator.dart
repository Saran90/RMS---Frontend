import 'package:flutter/material.dart';

/// A field descriptor pairing a [GlobalKey<FormFieldState>] with its
/// [FocusNode] so [FormValidator] can inspect per-field error state after
/// validation.
class FormFieldEntry {
  const FormFieldEntry({
    required this.fieldKey,
    required this.focusNode,
  });

  /// Key attached to the [FormField] (e.g. [TextFormField]).
  final GlobalKey<FormFieldState<dynamic>> fieldKey;

  /// The [FocusNode] that will receive focus when this field has an error.
  final FocusNode focusNode;
}

/// Utility class for form validation with automatic focus management.
///
/// Satisfies Requirement 20.4: when a form fails validation, focus is moved
/// programmatically to the **first field with an error** before any other
/// UI update.
class FormValidator {
  FormValidator._();

  /// Validates the form identified by [formKey], then — if invalid — moves
  /// focus to the [FocusNode] of the **first** [FormFieldEntry] whose
  /// [FormFieldState] reports an error.
  ///
  /// [fields] must be ordered to match the top-to-bottom field order in the
  /// form.  A `null` entry in the list is skipped (field has no focus node).
  ///
  /// Returns `true` when all fields are valid; `false` when at least one fails.
  ///
  /// Focus is requested synchronously before this method returns, so it
  /// precedes any subsequent `setState` / BLoC `emit` call in the caller.
  static bool submitAndFocus(
    GlobalKey<FormState> formKey,
    List<FormFieldEntry?> fields,
  ) {
    final formState = formKey.currentState;
    if (formState == null) return false;

    // Trigger validation on all fields.
    final isValid = formState.validate();

    if (!isValid) {
      // Walk fields in order and focus the first one that has an error.
      for (final entry in fields) {
        if (entry == null) continue;
        final fieldState = entry.fieldKey.currentState;
        if (fieldState != null && fieldState.hasError) {
          entry.focusNode.requestFocus();
          break;
        }
      }
    }

    return isValid;
  }

  /// Simplified variant for cases where the caller controls validation
  /// themselves (e.g. programmatic field checks) and only needs the
  /// focus-routing behaviour.
  ///
  /// [errorIndices] is the sorted list of field indices that failed.
  /// Focus is moved to the [FocusNode] at the lowest index.
  static void focusFirstError(
    List<FocusNode?> orderedFocusNodes,
    List<int> errorIndices,
  ) {
    if (errorIndices.isEmpty) return;
    errorIndices.sort();
    for (final idx in errorIndices) {
      if (idx >= 0 && idx < orderedFocusNodes.length) {
        final node = orderedFocusNodes[idx];
        if (node != null) {
          node.requestFocus();
          return;
        }
      }
    }
  }
}
