// Feature: rms-flutter-frontend
// Implements: Requirements 2.1

import 'package:auth/auth.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:staff_portal/router/app_router.dart';

/// Register screen — new user account creation.
///
/// Validates name, email, and password (≥ 8 chars) inline before submitting.
/// On success ([Unauthenticated]), navigates to [AppRoutes.login].
/// On [AuthError], shows an inline error banner below the form.
///
/// Requirements: 2.1
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  /// Inline error message shown below the form on auth failure.
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  void _submit() {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          RegisterRequested(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  // ── BlocListener callback ─────────────────────────────────────────────────

  void _onAuthStateChange(BuildContext context, AuthState state) {
    if (state is AuthLoading) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });
      return;
    }

    setState(() => _isSubmitting = false);

    if (state is Unauthenticated) {
      // Registration succeeded; navigate to login (Requirement 2.1).
      context.go(AppRoutes.login);
      return;
    }

    if (state is AuthError) {
      // Show inline error banner below the form (Requirement 2.1).
      setState(() => _errorMessage = state.message);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _onAuthStateChange,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing16,
              vertical: AppTheme.spacing24,
            ),
            child: Center(
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
                          // Logo area
                          const _LogoArea(),
                          const SizedBox(height: AppTheme.spacing8),

                          // Subtitle — screen title in titleLarge
                          Text(
                            'Create Account',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.spacing24),

                          // Inline error banner (shown on AuthError)
                          if (_errorMessage != null) ...[
                            _ErrorBanner(message: _errorMessage!),
                            const SizedBox(height: AppTheme.spacing16),
                          ],

                          // Full Name field
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'Enter your full name',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: _validateName,
                          ),
                          const SizedBox(height: AppTheme.spacing16),

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email address',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: AppTheme.spacing16),

                          // Password field with show/hide toggle
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Minimum 8 characters',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  semanticLabel: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: AppTheme.spacing24),

                          // Register button — full width, min height 48dp
                          SizedBox(
                            width: double.infinity,
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
                                  : const Text('Create Account'),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing16),

                          // "Already have an account? Sign In →"
                          Center(
                            child: TextButton(
                              onPressed: () => context.go(AppRoutes.login),
                              child: const Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Already have an account? ',
                                      style: TextStyle(
                                        color: AppTheme.mutedText,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Sign In →',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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

// ── Logo area widget ──────────────────────────────────────────────────────────

class _LogoArea extends StatelessWidget {
  const _LogoArea();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.restaurant,
          size: 48,
          color: AppTheme.primary,
          semanticLabel: 'Restaurant icon',
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'RMS Staff Portal',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Inline error banner ───────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.error,
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
