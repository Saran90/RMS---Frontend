// Feature: rms-flutter-frontend
// Implements: Requirements 2.4, 2.5, 2.6

import 'package:auth/auth.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Change Password screen — allows authenticated users to update their password.
///
/// - Validates new password (≥ 8 chars) locally BEFORE any network call
///   (Requirement 2.6).
/// - On wrong current password [AuthError]: shows inline error on the current
///   password field without navigating (Requirement 2.5).
/// - On success [BaseAuthenticated]: shows a success banner (Requirement 2.4).
///
/// Requirements: 2.4, 2.5, 2.6
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _isSubmitting = false;

  /// Set to `true` when the server rejects the current password.
  /// Used to trigger an inline field error (Requirement 2.5).
  bool _currentPasswordWrong = false;

  /// Non-null when the password change succeeded — shows success banner.
  String? _successMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current password is required';
    }
    // Inline error injected by server response (Requirement 2.5).
    if (_currentPasswordWrong) {
      return 'Current password is incorrect';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'New password is required';
    }
    // Client-side validation before any network call (Requirement 2.6).
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  void _submit() {
    // Clear server-side error flag so validator re-evaluates cleanly.
    setState(() {
      _currentPasswordWrong = false;
      _successMessage = null;
    });

    // Validates new password length BEFORE making any network call (Req 2.6).
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          ChangePasswordRequested(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          ),
        );
  }

  // ── BlocListener callback ─────────────────────────────────────────────────

  void _onAuthStateChange(BuildContext context, AuthState state) {
    if (state is AuthLoading) {
      setState(() {
        _isSubmitting = true;
        _successMessage = null;
      });
      return;
    }

    setState(() => _isSubmitting = false);

    if (state is BaseAuthenticated) {
      // Password changed successfully (Requirement 2.4).
      setState(() {
        _successMessage = 'Password updated successfully.';
        _currentPasswordController.clear();
        _newPasswordController.clear();
      });
      return;
    }

    if (state is AuthError) {
      // Treat any auth error here as wrong current password (Requirement 2.5).
      // The form stays open — no navigation.
      setState(() => _currentPasswordWrong = true);
      // Re-run validation to surface the field error.
      _formKey.currentState!.validate();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _onAuthStateChange,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: const Text('Change Password'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  color: AppTheme.cardSurface,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          const Icon(
                            Icons.lock_outline,
                            size: 48,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          Text(
                            'Change Password',
                            style: Theme.of(context).textTheme.displayMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.spacing8),
                          Text(
                            'Enter your current password and choose a new one.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.mutedText),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.spacing24),

                          // Success banner (Requirement 2.4)
                          if (_successMessage != null) ...[
                            _SuccessBanner(message: _successMessage!),
                            const SizedBox(height: AppTheme.spacing16),
                          ],

                          // Current Password field
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: _obscureCurrent,
                            textInputAction: TextInputAction.next,
                            // Clear server error on edit so the user can retry.
                            onChanged: (_) {
                              if (_currentPasswordWrong) {
                                setState(() => _currentPasswordWrong = false);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Current Password',
                              hintText: 'Enter your current password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureCurrent
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  semanticLabel: _obscureCurrent
                                      ? 'Show current password'
                                      : 'Hide current password',
                                ),
                                onPressed: () => setState(
                                  () => _obscureCurrent = !_obscureCurrent,
                                ),
                              ),
                            ),
                            validator: _validateCurrentPassword,
                          ),
                          const SizedBox(height: AppTheme.spacing16),

                          // New Password field
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscureNew,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              hintText: 'Minimum 8 characters',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNew
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  semanticLabel: _obscureNew
                                      ? 'Show new password'
                                      : 'Hide new password',
                                ),
                                onPressed: () => setState(
                                  () => _obscureNew = !_obscureNew,
                                ),
                              ),
                            ),
                            validator: _validateNewPassword,
                          ),
                          const SizedBox(height: AppTheme.spacing24),

                          // Submit button
                          SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _submit,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.onPrimary,
                                      ),
                                    )
                                  : const Text('Update Password'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Success banner ────────────────────────────────────────────────────────────

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.successContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        border: Border.all(color: AppTheme.success),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppTheme.success,
            size: 18,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.success,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
