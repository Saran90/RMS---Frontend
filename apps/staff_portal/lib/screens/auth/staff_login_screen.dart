// Staff login screen — used by Waiter, Billing, and Kitchen roles.
//
// Each role gets its own accent colour, icon, title, and button label.
// Fields: Staff ID + PIN (not email/password).
// Auth is still routed through the existing AuthBloc / LoginRequested event
// so the backend integration is unchanged.

import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:staff_portal/router/app_router.dart';

// ── Role configuration ────────────────────────────────────────────────────────

class StaffRoleConfig {
  const StaffRoleConfig({
    required this.title,
    required this.buttonLabel,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
  });

  final String title;
  final String buttonLabel;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
}

const Map<String, StaffRoleConfig> staffRoleConfigs = {
  'waiter': StaffRoleConfig(
    title: 'Waiter Login',
    buttonLabel: 'Sign In to Tables',
    icon: Icons.room_service_outlined,
    accentColor: Color(0xFFE82060),
    gradientColors: [Color(0xFFE82060), Color(0xFFC0105A)],
  ),
  'billing': StaffRoleConfig(
    title: 'Billing Login',
    buttonLabel: 'Sign In to Billing',
    icon: Icons.credit_card_outlined,
    accentColor: Color(0xFF00B8C8),
    gradientColors: [Color(0xFF00B8C8), Color(0xFF0090A8)],
  ),
  'kitchen': StaffRoleConfig(
    title: 'Kitchen Display',
    buttonLabel: 'Open Kitchen Display',
    icon: Icons.soup_kitchen_outlined,
    accentColor: Color(0xFF8040D8),
    gradientColors: [Color(0xFF8040D8), Color(0xFF6020B8)],
  ),
};

// ── Design tokens (dark theme) ────────────────────────────────────────────────

const Color _bg = Color(0xFF140A00);
const Color _bgGradientCenter = Color(0xFF3D1F00);
const Color _cardBg = Color(0xFF1C1108);
const Color _cardBorder = Color(0xFF2A1A08);
const Color _fieldBg = Color(0xFF251508);
const Color _fieldBorder = Color(0xFF3A2010);
const Color _titleColor = Color(0xFFF5E6D0);
const Color _subtitleColor = Color(0xFF7A6048);
const Color _labelColor = Color(0xFF9A8060);
const Color _hintColor = Color(0xFF5A4030);
const Color _inputText = Color(0xFFD0B890);
const Color _backLinkColor = Color(0xFF7A6048);
const Color _demoTextColor = Color(0xFF5A4030);
const Color _errorRed = Color(0xFFFF6060);

// ── Screen ────────────────────────────────────────────────────────────────────

class StaffLoginScreen extends StatefulWidget {
  /// Role key — one of: 'waiter', 'billing', 'kitchen'
  final String role;

  const StaffLoginScreen({required this.role, super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  // ── Sign In fields ───────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  StaffRoleConfig get _config =>
      staffRoleConfigs[widget.role] ?? staffRoleConfigs['waiter']!;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  // ── Submit ───────────────────────────────────────────────────────────────────

  void _submit() {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(LoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ));
  }

  // ── BlocListener ────────────────────────────────────────────────────────────

  void _onAuthState(BuildContext context, AuthState state) {
    if (state is AuthLoading) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });
      return;
    }
    setState(() => _isSubmitting = false);
    if (state is AuthError) {
      setState(() => _errorMessage = 'Invalid email or password');
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _onAuthState,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            // Warm radial glow
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.1),
                    radius: 0.85,
                    colors: [_bgGradientCenter, _bg],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  return isWide ? _wideLayout() : _narrowLayout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Wide layout ───────────────────────────────────────────────────────────────

  Widget _wideLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackLink(),
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 24),
              _buildCard(),
              const SizedBox(height: 16),
              _buildDemoHint(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Narrow layout ─────────────────────────────────────────────────────────────

  Widget _narrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackLink(),
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 24),
          _buildCard(),
          const SizedBox(height: 16),
          _buildDemoHint(),
        ],
      ),
    );
  }

  // ── Back link ─────────────────────────────────────────────────────────────────

  Widget _buildBackLink() {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.landing),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: 14, color: _backLinkColor),
          SizedBox(width: 6),
          Text(
            'Back to roles',
            style: TextStyle(
              color: _backLinkColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header: icon + title + subtitle ──────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        // Gradient icon badge
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _config.gradientColors,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_config.icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _config.title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _titleColor,
                letterSpacing: -0.3,
              ),
            ),
            const Text(
              'The Golden Fork',
              style: TextStyle(
                fontSize: 12,
                color: _subtitleColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Card ──────────────────────────────────────────────────────────────────────

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              _buildErrorBanner(_errorMessage!),
              const SizedBox(height: 16),
            ],

            // Email field
            _buildFieldLabel('Email Address'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _emailController,
              hint: 'your@email.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),

            // Password field
            _buildFieldLabel('Password'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _passwordController,
              hint: '••••••••',
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: _validatePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 17,
                  color: _hintColor,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 20),

            // Submit button
            _buildButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: _labelColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
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
      style: const TextStyle(fontSize: 14, color: _inputText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _config.accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _errorRed, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _errorRed, fontSize: 11),
      ),
    );
  }

  Widget _buildButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _config.accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _config.accentColor.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                _config.buttonLabel,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0808),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _errorRed.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _errorRed, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _errorRed,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoHint() {
    return const Center(
      child: Text(
        'Use your staff email and password',
        style: TextStyle(color: _demoTextColor, fontSize: 12),
      ),
    );
  }
}
