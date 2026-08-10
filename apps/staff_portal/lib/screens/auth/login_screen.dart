// Feature: rms-flutter-frontend
// Implements: Requirements 2.2, 2.3

import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

const Color _creamBg = Color(0xFFF5F0E8);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _cardBorder = Color(0xFFE8E0D0);
const Color _titleColor = Color(0xFF1A1208);
const Color _hintColor = Color(0xFFAA9880);
const Color _mutedText = Color(0xFF9A8870);
const Color _accentOrange = Color(0xFFBF4010);
const Color _accentLight = Color(0xFFF5EDE0);
const Color _errorRed = Color(0xFFDC2626);

const Color _brandBg = Color(0xFF1A0F00);
const Color _brandBorder = Color(0xFF2E1A06);
const Color _brandText = Color(0xFFF5E6D0);
const Color _brandMuted = Color(0xFF9A7A5A);
const Color _brandOrange = Color(0xFFE87020);

/// Unified sign-in / owner registration screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _tabIndex = 0;

  final _signInFormKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  final _registerFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscureRegPassword = true;
  bool _isRegistering = false;
  String? _registerError;

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateLoginId(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Email or username is required';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    return null;
  }

  String? _validateNewPassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    return null;
  }

  void _submitSignIn() {
    setState(() => _errorMessage = null);
    if (!_signInFormKey.currentState!.validate()) return;
    final loginId = _loginIdController.text.trim();
    final isEmail = loginId.contains('@');
    context.read<AuthBloc>().add(LoginRequested(
          email: isEmail ? loginId : null,
          username: isEmail ? null : loginId,
          password: _passwordController.text,
        ));
  }

  void _submitRegister() {
    setState(() => _registerError = null);
    if (!_registerFormKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(RegisterRequested(
          name: _nameController.text.trim(),
          email: _regEmailController.text.trim(),
          password: _regPasswordController.text,
          phoneNumber: _phoneController.text.trim(),
        ));
  }

  void _onAuthState(BuildContext context, AuthState state) {
    if (state is AuthLoading) {
      setState(() {
        _isSubmitting = _tabIndex == 0;
        _isRegistering = _tabIndex == 1;
        _errorMessage = null;
        _registerError = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = false;
      _isRegistering = false;
    });

    if (state is AuthError) {
      final msg = state.message;
      final isCredentialError = msg.toLowerCase().contains('invalid') ||
          msg.toLowerCase().contains('credentials') ||
          msg.toLowerCase().contains('password') ||
          msg.toLowerCase().contains('unauthorized');

      if (_tabIndex == 0) {
        setState(() => _errorMessage =
            isCredentialError
                ? 'Invalid email, username, or password'
                : msg);
      } else {
        setState(() => _registerError = msg);
      }
    }

    if (state is Unauthenticated && _tabIndex == 1) {
      setState(() {
        _tabIndex = 0;
        _registerError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _onAuthState,
      child: Scaffold(
        backgroundColor: _creamBg,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isSplit = constraints.maxWidth >= 900;
            if (isSplit) {
              return Row(
                children: [
                  SizedBox(
                    width: constraints.maxWidth * 0.42,
                    child: _BrandPanel(compact: false),
                  ),
                  Expanded(child: _FormPanel(state: this)),
                ],
              );
            }
            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BrandPanel(compact: true),
                    _FormPanel(state: this, embedded: true),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Brand panel (dark left / mobile header) ───────────────────────────────────

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 48,
        vertical: compact ? 28 : 56,
      ),
      child: Column(
        crossAxisAlignment:
            compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          if (!compact) const SizedBox(height: 40),
          Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Container(
                width: compact ? 44 : 52,
                height: compact ? 44 : 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF09030), Color(0xFFD06010)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.soup_kitchen,
                  color: Colors.white,
                  size: compact ? 24 : 28,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'TableFlow',
                style: TextStyle(
                  fontSize: compact ? 26 : 32,
                  fontWeight: FontWeight.w800,
                  color: _brandText,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 20),
          Text(
            compact
                ? 'Sign in to your restaurant workspace'
                : 'Run your restaurant\nfrom one place.',
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: compact ? 15 : 22,
              fontWeight: FontWeight.w600,
              color: _brandText.withValues(alpha: 0.92),
              height: 1.35,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: compact ? 8 : 14),
          Text(
            'Owners use email · Staff use username',
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              fontSize: 13,
              color: _brandMuted,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 48),
            _BrandFeature(
              icon: Icons.receipt_long_outlined,
              title: 'Orders & tables',
              subtitle: 'Seat guests, take orders, track service',
            ),
            const SizedBox(height: 20),
            _BrandFeature(
              icon: Icons.kitchen_outlined,
              title: 'Kitchen display',
              subtitle: 'Route items to stations in real time',
            ),
            const SizedBox(height: 20),
            _BrandFeature(
              icon: Icons.point_of_sale_outlined,
              title: 'Billing & reports',
              subtitle: 'Payments, GST, and daily insights',
            ),
          ],
        ],
      ),
    );

    if (compact) {
      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: _brandBg,
          border: Border(bottom: BorderSide(color: _brandBorder)),
        ),
        child: content,
      );
    }

    return Container(
      color: _brandBg,
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brandOrange.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brandOrange.withValues(alpha: 0.05),
              ),
            ),
          ),
          content,
        ],
      ),
    );
  }
}

class _BrandFeature extends StatelessWidget {
  const _BrandFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _brandOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _brandOrange.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, size: 20, color: _brandOrange),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _brandText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: _brandMuted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Form panel ────────────────────────────────────────────────────────────────

class _FormPanel extends StatelessWidget {
  const _FormPanel({required this.state, this.embedded = false});

  final _LoginScreenState state;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: embedded ? 20 : 40,
          vertical: embedded ? 24 : 32,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                state._tabIndex == 0 ? 'Welcome back' : 'Create your account',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _titleColor,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state._tabIndex == 0
                    ? 'Sign in to continue to your restaurant'
                    : 'Register as a restaurant owner',
                style: const TextStyle(fontSize: 13.5, color: _mutedText),
              ),
              const SizedBox(height: 28),
              _TabToggle(
                tabIndex: state._tabIndex,
                onChanged: (i) => state.setState(() {
                  state._tabIndex = i;
                  state._errorMessage = null;
                  state._registerError = null;
                }),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: state._tabIndex == 0
                    ? _SignInForm(state: state)
                    : _RegisterForm(state: state),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'By continuing, you agree to our Terms of Service.',
                  style: TextStyle(color: _mutedText, fontSize: 11.5),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.tabIndex, required this.onChanged});

  final int tabIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _accentLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          _tab('Sign in', 0),
          _tab('Create account', 1),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final selected = tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? _cardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? _titleColor : _hintColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInForm extends StatelessWidget {
  const _SignInForm({required this.state});

  final _LoginScreenState state;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: state._signInFormKey,
      child: Column(
        key: const ValueKey('sign-in'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state._errorMessage != null) ...[
            _ErrorBanner(message: state._errorMessage!),
            const SizedBox(height: 16),
          ],
          const _FieldLabel('Email or username'),
          const SizedBox(height: 6),
          _LoginTextField(
            controller: state._loginIdController,
            hint: 'owner@email.com or john.smith',
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            validator: state._validateLoginId,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Password'),
          const SizedBox(height: 6),
          _LoginTextField(
            controller: state._passwordController,
            hint: 'Your password',
            prefixIcon: Icons.lock_outline,
            obscureText: state._obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => state._submitSignIn(),
            validator: state._validatePassword,
            suffixIcon: IconButton(
              icon: Icon(
                state._obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: _mutedText,
              ),
              onPressed: () =>
                  state.setState(() => state._obscurePassword = !state._obscurePassword),
            ),
          ),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: 'Sign in',
            loading: state._isSubmitting,
            onPressed: state._submitSignIn,
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset is not yet available.'),
                  behavior: SnackBarBehavior.floating,
                ),
              ),
              child: const Text(
                'Forgot your password?',
                style: TextStyle(
                  color: _mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({required this.state});

  final _LoginScreenState state;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: state._registerFormKey,
      child: Column(
        key: const ValueKey('register'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state._registerError != null) ...[
            _ErrorBanner(message: state._registerError!),
            const SizedBox(height: 16),
          ],
          const _FieldLabel('Full name'),
          const SizedBox(height: 6),
          _LoginTextField(
            controller: state._nameController,
            hint: 'Your full name',
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            validator: state._validateName,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Email address'),
          const SizedBox(height: 6),
          _LoginTextField(
            controller: state._regEmailController,
            hint: 'james@goldenfork.co',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: state._validateEmail,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Phone number'),
          const SizedBox(height: 6),
          _LoginTextField(
            controller: state._phoneController,
            hint: '9876543210',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Password'),
          const SizedBox(height: 6),
          _LoginTextField(
            controller: state._regPasswordController,
            hint: 'Min. 8 characters',
            prefixIcon: Icons.lock_outline,
            obscureText: state._obscureRegPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => state._submitRegister(),
            validator: state._validateNewPassword,
            suffixIcon: IconButton(
              icon: Icon(
                state._obscureRegPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: _mutedText,
              ),
              onPressed: () => state.setState(
                  () => state._obscureRegPassword = !state._obscureRegPassword),
            ),
          ),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: 'Create account',
            loading: state._isRegistering,
            onPressed: state._submitRegister,
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _titleColor,
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _titleColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
        prefixIcon: Icon(prefixIcon, size: 18, color: _hintColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _cardBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorRed, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _errorRed, fontSize: 11.5),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentOrange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _accentOrange.withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _errorRed.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _errorRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _errorRed,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
