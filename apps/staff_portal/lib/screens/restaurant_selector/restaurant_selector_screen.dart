// Feature: rms-flutter-frontend
// Implements: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7

import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:staff_portal/navigation/role_navigation.dart';
import 'package:staff_portal/restaurant_selector/restaurant_bloc.dart'
    hide RestaurantSelected;
import 'package:staff_portal/restaurant_selector/restaurant_repository.dart';
import 'package:staff_portal/router/app_router.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

const Color _sidebarBg = Color(0xFF1A0F00);
const Color _sidebarBorder = Color(0xFF2E1A06);
const Color _logoOrange = Color(0xFFE87020);
const Color _planBadgeBg = Color(0xFF2A1800);
const Color _planBadgeText = Color(0xFFE87020);
const Color _sidebarText = Color(0xFFF5E6D0);
const Color _sidebarMuted = Color(0xFF7A6048);
const Color _signOutColor = Color(0xFF9A7A5A);

const Color _contentBg = Color(0xFFF5F0E8);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _cardBorder = Color(0xFFE8E0D0);
const Color _titleColor = Color(0xFF1A1208);
const Color _mutedColor = Color(0xFF9A8060);
const Color _accentOrange = Color(0xFFBF4010);
const Color _addCardBorder = Color(0xFFD8C8A8);
const Color _addCardBg = Color(0xFFFAF6EE);
const Color _statusActive = Color(0xFF16A34A);

// Card height — enough for icon + name + address + footer link
const double _kCardHeight = 170.0;

// ── Screen ────────────────────────────────────────────────────────────────────

class RestaurantSelectorScreen extends StatelessWidget {
  const RestaurantSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RestaurantBloc>(
      create: (ctx) => RestaurantBloc(
        repository: ctx.read<RestaurantRepository>(),
      ),
      child: const _RestaurantSelectorView(),
    );
  }
}

class _RestaurantSelectorView extends StatelessWidget {
  const _RestaurantSelectorView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<RestaurantBloc, RestaurantState>(
      listenWhen: (_, state) => state is RestaurantLoaded,
      listener: (context, state) {
        if (state is RestaurantLoaded && state.restaurants.length == 1) {
          final id = state.restaurants.first.id;
          context
              .read<AuthBloc>()
              .add(RestaurantSelected(restaurantId: id));
          context
              .read<RestaurantBloc>()
              .add(RestaurantItemSelected(restaurantId: id));
        }
      },
      child: BlocListener<RestaurantBloc, RestaurantState>(
      listener: (context, state) {
        if (state is RestaurantSelectError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _contentBg,
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 700) {
              return Row(
                children: [
                  const _Sidebar(),
                  Expanded(child: _ContentArea()),
                ],
              );
            }
            return Column(
              children: [
                _NarrowHeader(),
                Expanded(child: _ContentArea()),
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String displayName = 'User';
    String roleSubtitle = 'Owner';
    if (authState is TenantAuthenticated) {
      displayName = authState.displayName;
      roleSubtitle = roleDisplayLabel(authState.role);
    } else if (authState is BaseAuthenticated) {
      displayName = authState.displayName;
    }
    final initials = userInitials(displayName);

    return Container(
      width: 220,
      color: _sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF09030), Color(0xFFD06010)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.soup_kitchen,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'TableFlow',
                  style: TextStyle(
                    color: _sidebarText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _planBadgeBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Select Restaurant',
                style: TextStyle(
                  color: _planBadgeText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Bottom user block
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _sidebarBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _logoOrange,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: _sidebarText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            roleSubtitle,
                            style:
                                const TextStyle(color: _sidebarMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () =>
                      context.read<AuthBloc>().add(const LogoutRequested()),
                  child: const Row(
                    children: [
                      Icon(Icons.logout, size: 14, color: _signOutColor),
                      SizedBox(width: 6),
                      Text(
                        'Sign out',
                        style: TextStyle(
                          color: _signOutColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Narrow header ─────────────────────────────────────────────────────────────

class _NarrowHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _sidebarBg,
      padding: const EdgeInsets.fromLTRB(16, 48, 8, 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFF09030), Color(0xFFD06010)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.soup_kitchen, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Text('TableFlow',
              style: TextStyle(
                  color: _sidebarText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.logout, color: _signOutColor, size: 20),
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
          ),
        ],
      ),
    );
  }
}

// ── Content area (state switcher) ─────────────────────────────────────────────

class _ContentArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestaurantBloc, RestaurantState>(
      builder: (context, state) {
        return switch (state) {
          RestaurantLoading() => _buildScrollable(
              context,
              _SkeletonGrid(),
            ),
          RestaurantEmpty() => _buildScrollable(context, _AddRestaurantCard()),
          RestaurantLoaded(:final restaurants) when restaurants.length == 1 =>
            _buildScrollable(
              context,
              const _AutoSelectingView(),
            ),
          RestaurantLoaded(:final restaurants) => _buildScrollable(
              context,
              _RestaurantGrid(restaurants: restaurants, selectingId: null),
            ),
          RestaurantSelecting(:final restaurants, :final selectingId) =>
            _buildScrollable(
              context,
              _RestaurantGrid(
                  restaurants: restaurants, selectingId: selectingId),
            ),
          RestaurantSelectError(:final restaurants) => _buildScrollable(
              context,
              _RestaurantGrid(restaurants: restaurants, selectingId: null),
            ),
          RestaurantError(:final message) => _ErrorView(message: message),
          _ => _buildScrollable(context, _SkeletonGrid()),
        };
      },
    );
  }

  Widget _buildScrollable(BuildContext context, Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          const Text(
            'Select Restaurant',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _titleColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose a restaurant to manage or add a new one.',
            style: TextStyle(fontSize: 13, color: _mutedColor),
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

// ── Auto-selecting (single restaurant) ────────────────────────────────────────

class _AutoSelectingView extends StatelessWidget {
  const _AutoSelectingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _accentOrange,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Opening your restaurant…',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _titleColor,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Staff accounts are linked to one venue',
              style: TextStyle(fontSize: 13, color: _mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: _mutedColor),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(color: _titleColor, fontSize: 15),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context
                  .read<RestaurantBloc>()
                  .add(const RestaurantListRequested()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton grid ─────────────────────────────────────────────────────────────

class _SkeletonGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = (constraints.maxWidth / 260).floor().clamp(1, 4);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisExtent: _kCardHeight,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cardBorder),
          ),
        ),
      );
    });
  }
}

// ── Restaurant grid ───────────────────────────────────────────────────────────

class _RestaurantGrid extends StatelessWidget {
  const _RestaurantGrid({required this.restaurants, required this.selectingId});

  final List<Restaurant> restaurants;
  final String? selectingId;

  void _selectRestaurant(BuildContext context, String restaurantId) {
    context
        .read<AuthBloc>()
        .add(RestaurantSelected(restaurantId: restaurantId));
    context
        .read<RestaurantBloc>()
        .add(RestaurantItemSelected(restaurantId: restaurantId));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = (constraints.maxWidth / 260).floor().clamp(1, 4);
      final itemCount = restaurants.length + 1; // +1 for add card

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisExtent: _kCardHeight,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: itemCount,
        itemBuilder: (ctx, index) {
          if (index == restaurants.length) {
            return _AddRestaurantCard();
          }
          final r = restaurants[index];
          return _RestaurantCard(
            restaurant: r,
            isSelecting: selectingId == r.id,
            onTap: selectingId != null
                ? null
                : () => _selectRestaurant(context, r.id),
          );
        },
      );
    });
  }
}

// ── Restaurant card ───────────────────────────────────────────────────────────

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.restaurant,
    required this.isSelecting,
    required this.onTap,
  });

  final Restaurant restaurant;
  final bool isSelecting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelecting ? _accentOrange : _cardBorder,
              width: isSelecting ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.store_outlined,
                        color: _accentOrange, size: 20),
                  ),
                  const Spacer(),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: _statusActive,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Active',
                    style: TextStyle(
                      color: _statusActive,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                restaurant.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                restaurant.address,
                style: const TextStyle(fontSize: 11.5, color: _mutedColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (isSelecting)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _accentOrange),
                )
              else
                const Row(
                  children: [
                    Text(
                      'Open Dashboard',
                      style: TextStyle(
                        color: _accentOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward, size: 12, color: _accentOrange),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add restaurant card ───────────────────────────────────────────────────────

class _AddRestaurantCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _addCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.go(AppRoutes.onboarding),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _addCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E0D0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: _mutedColor, size: 20),
              ),
              const SizedBox(height: 10),
              const Text(
                'Add Restaurant',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Set up a new restaurant',
                style: TextStyle(fontSize: 11.5, color: _mutedColor),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Text(
                    'Get started',
                    style: TextStyle(
                      color: _mutedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward, size: 12, color: _mutedColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
