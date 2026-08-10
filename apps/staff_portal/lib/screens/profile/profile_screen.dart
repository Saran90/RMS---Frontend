import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:staff_portal/navigation/role_navigation.dart';
import 'package:staff_portal/router/app_router.dart';

const Color _bg = Color(0xFFF5F0E8);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _cardBorder = Color(0xFFE8E0D0);
const Color _titleColor = Color(0xFF1A1208);
const Color _mutedColor = Color(0xFF9A8060);
const Color _accentOrange = Color(0xFFBF4010);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! TenantAuthenticated) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _accentOrange)),
      );
    }

    final role = authState.role;
    final roleLabel = roleDisplayLabel(role);
    final displayName = authState.displayName;
    final canSwitch = canSwitchRestaurant(role);

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _titleColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your account at this restaurant',
                    style: TextStyle(fontSize: 12.5, color: _mutedColor),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              _accentOrange.withValues(alpha: 0.12),
                          child: Text(
                            userInitials(displayName),
                            style: const TextStyle(
                              color: _accentOrange,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _titleColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _accentOrange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  roleLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _accentOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ActionCard(
                    icon: Icons.lock_outlined,
                    title: 'Change password',
                    subtitle: 'Update your sign-in password',
                    onTap: () => context.push(AppRoutes.changePassword),
                  ),
                  if (canSwitch) ...[
                    const SizedBox(height: 10),
                    _ActionCard(
                      icon: Icons.storefront_outlined,
                      title: 'Switch restaurant',
                      subtitle: 'Manage a different venue',
                      onTap: () => context
                          .read<AuthBloc>()
                          .add(const RestaurantSwitchRequested()),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.logout,
                    title: 'Sign out',
                    subtitle: 'Log out of TableFlow',
                    onTap: () =>
                        context.read<AuthBloc>().add(const LogoutRequested()),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFDC2626) : _titleColor;
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: isDestructive ? color : _mutedColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: _mutedColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: _mutedColor),
            ],
          ),
        ),
      ),
    );
  }
}
