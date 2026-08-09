// Feature: rms-flutter-frontend
// Implements: Requirements 2.2, 2.3

import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:staff_portal/router/app_router.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

const Color _bg = Color(0xFFF5F0E8);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _labelColor = Color(0xFF1A1208);
const Color _hintColor = Color(0xFFAA9880);
const Color _inputBorder = Color(0xFFE0D8CC);
const Color _inputBg = Color(0xFFFFFFFF);
const Color _accentOrange = Color(0xFFBF4010);
const Color _accentOrangeLight = Color(0xFFF5F0E8);
const Color _tabInactive = Color(0xFFD8CEBF);
const Color _mutedText = Color(0xFF9A8870);
const Color _errorRed = Color(0xFFDC2626);

/// Login screen — redesigned to match the TableFlow warm-cream theme.
///
/// Keeps all existing auth logic (Requirements 2.2, 2.3) unchanged.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 0 = Sign In, 1 = Create Account
  int _tabIndex = 0;

  // ── Sign In fields ──────────────────────────────────────────────────────────
  final _signInFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // ── Create Account fields ───────────────────────────────────────────────────
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
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Validators ──────────────────────────────────────────────────────────────

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

  // ── Submit: Sign In ─────────────────────────────────────────────────────────

  void _submitSignIn() {
    setState(() => _errorMessage = null);
    if (!_signInFormKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(LoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ));
  }

  // ── Submit: Register ────────────────────────────────────────────────────────

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

  // ── BlocListener ────────────────────────────────────────────────────────────

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
            isCredentialError ? 'Invalid email or password' : msg);
      } else {
        setState(() => _registerError = msg);
      }
    }

    // On successful registration → switch to Sign In tab
    if (state is Unauthenticated && _tabIndex == 1) {
      setState(() {
        _tabIndex = 0;
        _registerError = null;
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _onAuthState,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return isWide ? _wideLayout() : _narrowLayout();
            },
          ),
        ),
      ),
    );
  }

  // ── Wide layout (tablet / web) ───────────────────────────────────────────────

  Widget _wideLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildCard(),
              const SizedBox(height: 20),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Narrow layout (mobile) ───────────────────────────────────────────────────

  Widget _narrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _buildHeader(),
          const SizedBox(height: 28),
          _buildCard(),
          const SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Header: back arrow + logo + title ────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        // Back to landing
        GestureDetector(
          onTap: () => context.go(AppRoutes.landing),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _inputBorder),
            ),
            child: const Icon(Icons.arrow_back, size: 18, color: _labelColor),
          ),
        ),
        const SizedBox(width: 12),
        // Logo
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF09030), Color(0xFFD06010)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.soup_kitchen, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          'Owner',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _labelColor,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ── Card ─────────────────────────────────────────────────────────────────────

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabToggle(),
          const SizedBox(height: 24),
          if (_tabIndex == 0) _buildSignInForm() else _buildRegisterForm(),
        ],
      ),
    );
  }

  // ── Tab toggle: Sign In / Create Account ─────────────────────────────────────

  Widget _buildTabToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _accentOrangeLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab('Sign In', 0),
          _buildTab('Create Account', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _tabIndex = index;
          _errorMessage = null;
          _registerError = null;
        }),
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
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? _labelColor : _tabInactive,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sign In form ──────────────────────────────────────────────────────────────

  Widget _buildSignInForm() {
    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            _buildErrorBanner(_errorMessage!),
            const SizedBox(height: 16),
          ],
          _buildFieldLabel('Email Address'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _emailController,
            hint: 'james@goldenfork.co',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Password'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passwordController,
            hint: '••••••••',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitSignIn(),
            validator: _validatePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: _mutedText,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
            label: 'Sign In to Dashboard',
            loading: _isSubmitting,
            onPressed: _submitSignIn,
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Password reset is not yet available.')),
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

  // ── Register form ─────────────────────────────────────────────────────────────

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_registerError != null) ...[
            _buildErrorBanner(_registerError!),
            const SizedBox(height: 16),
          ],
          _buildFieldLabel('Full Name'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _nameController,
            hint: 'Your full name',
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            validator: _validateName,
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Email Address'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _regEmailController,
            hint: 'james@goldenfork.co',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Phone Number'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _phoneController,
            hint: '9876543210',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Password'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _regPasswordController,
            hint: 'Min. 8 characters',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureRegPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitRegister(),
            validator: _validateNewPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: _mutedText,
              ),
              onPressed: () =>
                  setState(() => _obscureRegPassword = !_obscureRegPassword),
            ),
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
            label: 'Continue to Setup →',
            loading: _isRegistering,
            onPressed: _submitRegister,
          ),
        ],
      ),
    );
  }

  // ── Shared sub-widgets ────────────────────────────────────────────────────────

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _labelColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
    FormFieldValidator<String>? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _labelColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
        prefixIcon: Icon(prefixIcon, size: 18, color: _hintColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBF4010), width: 1.5),
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

  Widget _buildPrimaryButton({
    required String label,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentOrange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _accentOrange.withValues(alpha: 0.6),
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
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _errorRed.withValues(alpha: 0.4)),
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

  // ── Footer ────────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return const Center(
      child: Text(
        'By continuing, you agree to our Terms of Service.',
        style: TextStyle(
          color: _mutedText,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
