// Landing screen — role selection hub shown before login.
//
// Layout rules:
//   < 600 dp (mobile) and web  → portrait: stacked list rows
//   ≥ 600 dp (tablet/desktop)  → landscape: 4-column card grid

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:staff_portal/router/app_router.dart';

// ── Design tokens (dark warm theme for landing only) ─────────────────────────

const Color _bg = Color(0xFF140A00);
const Color _bgGradientCenter = Color(0xFF3D1F00);
const Color _cardBg = Color(0xFF1E1008);
const Color _cardBorder = Color(0xFF2E1A06);
const Color _titleColor = Color(0xFFF5E6D0);
const Color _subtitleColor = Color(0xFF9A7A5A);
const Color _bodyColor = Color(0xFF8A6A4A);
const Color _accentOrange = Color(0xFFE87020);

// ── Role card data ────────────────────────────────────────────────────────────

class _RoleCard {
  const _RoleCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.route,
  });

  final String label;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final String route;
}

final List<_RoleCard> _roles = [
  _RoleCard(
    label: 'Owner',
    description: 'Manage your restaurant, track revenue and operations.',
    icon: Icons.store_outlined,
    gradientColors: const [Color(0xFFE8820C), Color(0xFFD4580A)],
    route: AppRoutes.login,
  ),
  _RoleCard(
    label: 'Waiter',
    description: 'View your tables, take orders and manage your section.',
    icon: Icons.room_service_outlined,
    gradientColors: const [Color(0xFFE82060), Color(0xFFC0105A)],
    route: AppRoutes.loginWaiter,
  ),
  _RoleCard(
    label: 'Billing',
    description: 'Process payments, print bills and handle checkout.',
    icon: Icons.credit_card_outlined,
    gradientColors: const [Color(0xFF00B8C8), Color(0xFF0090A8)],
    route: AppRoutes.loginBilling,
  ),
  _RoleCard(
    label: 'Kitchen',
    description: 'View incoming KOTs, update status and manage the kitchen.',
    icon: Icons.soup_kitchen_outlined,
    gradientColors: const [Color(0xFF8040D8), Color(0xFF6020B8)],
    route: AppRoutes.loginKitchen,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Radial warm glow in the centre
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 0.9,
                  colors: [_bgGradientCenter, _bg],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use portrait (list) layout for mobile AND for web/responsive
                // (width < 700 treated as portrait regardless of platform).
                final usePortrait = constraints.maxWidth < 700;
                return usePortrait
                    ? _PortraitLayout(roles: _roles)
                    : _LandscapeLayout(roles: _roles);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header (shared) ───────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 40.0 : 52.0;
    final titleSize = compact ? 26.0 : 32.0;
    final subtitleSize = compact ? 13.0 : 14.0;

    return Column(
      children: [
        // Logo row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF09030), Color(0xFFD06010)],
                ),
                borderRadius: BorderRadius.circular(iconSize * 0.25),
              ),
              child: Icon(
                Icons.soup_kitchen,
                color: Colors.white,
                size: iconSize * 0.55,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'TableFlow',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                color: _titleColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Restaurant management, beautifully simplified.',
          style: TextStyle(
            fontSize: subtitleSize,
            color: _subtitleColor,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Footer (shared) ───────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'New restaurant? ',
          style: TextStyle(color: _subtitleColor, fontSize: 13),
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.onboarding),
          child: const Text(
            'Get started free →',
            style: TextStyle(
              color: _accentOrange,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Portrait layout (mobile + responsive web) ─────────────────────────────────

class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout({required this.roles});

  final List<_RoleCard> roles;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const _Header(compact: true),
          const SizedBox(height: 36),
          ...roles.map(
            (role) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PortraitRoleCard(role: role),
            ),
          ),
          const SizedBox(height: 24),
          const _Footer(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PortraitRoleCard extends StatelessWidget {
  const _PortraitRoleCard({required this.role});

  final _RoleCard role;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go(role.route),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cardBorder),
          ),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: role.gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(role.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.label,
                      style: const TextStyle(
                        color: _titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.description,
                      style: const TextStyle(
                        color: _bodyColor,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in →',
                      style: TextStyle(
                        color: _accentOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Landscape layout (tablet / desktop) ──────────────────────────────────────

class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout({required this.roles});

  final List<_RoleCard> roles;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const _Header(),
              const SizedBox(height: 48),
              // 4-column card row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: roles
                    .map(
                      (role) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _LandscapeRoleCard(role: role),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 40),
              const _Footer(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandscapeRoleCard extends StatelessWidget {
  const _LandscapeRoleCard({required this.role});

  final _RoleCard role;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(role.route),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: role.gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(role.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                role.label,
                style: const TextStyle(
                  color: _titleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                role.description,
                style: const TextStyle(
                  color: _bodyColor,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in →',
                style: TextStyle(
                  color: _accentOrange,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
