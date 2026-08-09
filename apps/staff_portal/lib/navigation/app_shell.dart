import 'package:auth/auth.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:staff_portal/connectivity/connectivity_cubit.dart';
import 'package:staff_portal/navigation/nav_items.dart';

// ── Design tokens (sidebar matches dashboard mockup) ──────────────────────────

const Color _sidebarBg = Color(0xFF1A0F00);
const Color _sidebarBorder = Color(0xFF2E1A06);
const Color _sidebarText = Color(0xFFF5E6D0);
const Color _sidebarMuted = Color(0xFF7A6048);
const Color _sidebarHover = Color(0xFF2A1800);
const Color _activeItemBg = Color(0xFFBF4010);
const Color _activeItemText = Color(0xFFFFFFFF);
const Color _logoOrange = Color(0xFFE87020);
const Color _planBadgeBg = Color(0xFF2A1800);
const Color _planBadgeText = Color(0xFFE87020);
const Color _signOutColor = Color(0xFF9A7A5A);
const Color _contentBg = Color(0xFFF5F0E8);

/// The navigation shell that wraps every authenticated screen.
///
/// Wide (≥ 700 dp): dark sidebar (220 dp) + content area.
/// Narrow (< 700 dp): bottom navigation bar.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.child,
    required this.location,
    super.key,
  });

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final role = authState is TenantAuthenticated ? authState.role : null;
        final items = role != null ? navItemsForRole(role) : <NavItem>[];

        return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
          builder: (context, connectivity) {
            final isOffline = connectivity == ConnectivityStatus.disconnected;

            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 700) {
                  return _WideShell(
                    items: items,
                    location: location,
                    isOffline: isOffline,
                    authState: authState,
                    child: child,
                  );
                }
                return _CompactShell(
                  items: items,
                  location: location,
                  isOffline: isOffline,
                  child: child,
                );
              },
            );
          },
        );
      },
    );
  }
}

// ── Wide shell: sidebar + content ─────────────────────────────────────────────

class _WideShell extends StatelessWidget {
  const _WideShell({
    required this.items,
    required this.location,
    required this.isOffline,
    required this.authState,
    required this.child,
  });

  final List<NavItem> items;
  final String location;
  final bool isOffline;
  final AuthState authState;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _contentBg,
      body: Column(
        children: [
          OfflineBanner(isVisible: isOffline),
          Expanded(
            child: Row(
              children: [
                _Sidebar(
                  items: items,
                  location: location,
                  authState: authState,
                ),
                Expanded(
                  child: ClipRect(child: child),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.location,
    required this.authState,
  });

  final List<NavItem> items;
  final String location;
  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    // Resolve display name and restaurant name from auth state
    String userName = 'Owner';
    String restaurantName = 'My Restaurant';
    String planLabel = 'Professional Plan';

    if (authState is TenantAuthenticated) {
      final role = (authState as TenantAuthenticated).role;
      userName = role.name[0].toUpperCase() + role.name.substring(1);
    }

    return Container(
      width: 220,
      color: _sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Logo + brand
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF09030), Color(0xFFD06010)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.soup_kitchen,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                const Text(
                  'TableFlow',
                  style: TextStyle(
                    color: _sidebarText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Restaurant name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              restaurantName,
              style: const TextStyle(
                color: _sidebarMuted,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Plan badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _planBadgeBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                planLabel,
                style: const TextStyle(
                  color: _planBadgeText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isActive = location.startsWith(item.route);
                return _NavItem(
                  item: item,
                  isActive: isActive,
                  onTap: () => context.go(item.route),
                );
              },
            ),
          ),

          // Bottom: user info + sign out
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _sidebarBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: _logoOrange,
                      child: Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: _sidebarText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            userName,
                            style: const TextStyle(
                              color: _sidebarMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => context
                      .read<AuthBloc>()
                      .add(const RestaurantSwitchRequested()),
                  child: const Row(
                    children: [
                      Icon(Icons.storefront_outlined,
                          size: 13, color: _signOutColor),
                      SizedBox(width: 6),
                      Text(
                        'Switch restaurant',
                        style: TextStyle(
                          color: _signOutColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () =>
                      context.read<AuthBloc>().add(const LogoutRequested()),
                  child: const Row(
                    children: [
                      Icon(Icons.logout, size: 13, color: _signOutColor),
                      SizedBox(width: 6),
                      Text(
                        'Sign out',
                        style: TextStyle(
                          color: _signOutColor,
                          fontSize: 11.5,
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

// ── Nav item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isActive ? _activeItemBg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: _sidebarHover,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 17,
                  color: isActive ? _activeItemText : _sidebarMuted,
                ),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isActive ? _activeItemText : _sidebarMuted,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Compact shell (< 700 dp) ──────────────────────────────────────────────────

class _CompactShell extends StatelessWidget {
  const _CompactShell({
    required this.items,
    required this.location,
    required this.isOffline,
    required this.child,
  });

  final List<NavItem> items;
  final String location;
  final bool isOffline;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const maxBottom = 5;
    final primaryItems =
        items.length <= maxBottom ? items : items.sublist(0, 4);
    final overflowItems =
        items.length > maxBottom ? items.sublist(4) : <NavItem>[];

    final selectedIdx =
        items.indexWhere((item) => location.startsWith(item.route));
    final bottomIdx = selectedIdx < primaryItems.length ? selectedIdx : 0;

    return Scaffold(
      backgroundColor: _contentBg,
      body: Column(
        children: [
          OfflineBanner(isVisible: isOffline),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : BottomNavigationBar(
              backgroundColor: _sidebarBg,
              selectedItemColor: _logoOrange,
              unselectedItemColor: _sidebarMuted,
              currentIndex: bottomIdx < 0 ? 0 : bottomIdx,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              onTap: (i) {
                if (i < primaryItems.length) {
                  context.go(primaryItems[i].route);
                }
              },
              items: [
                ...primaryItems.map(
                  (item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
                ),
                if (overflowItems.isNotEmpty)
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.more_horiz),
                    label: 'More',
                  ),
              ],
            ),
      endDrawer: overflowItems.isNotEmpty
          ? Drawer(
              backgroundColor: _sidebarBg,
              child: ListView(
                children: overflowItems
                    .map(
                      (item) => ListTile(
                        leading: Icon(item.icon, color: _sidebarMuted),
                        title: Text(item.label,
                            style: const TextStyle(color: _sidebarText)),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(item.route);
                        },
                      ),
                    )
                    .toList(),
              ),
            )
          : null,
    );
  }
}
