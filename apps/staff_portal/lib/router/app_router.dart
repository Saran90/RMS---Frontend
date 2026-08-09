import 'dart:async';

import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:staff_portal/billing/billing_screen.dart';
import 'package:staff_portal/navigation/app_shell.dart';
import 'package:staff_portal/screens/auth/change_password_screen.dart';
import 'package:staff_portal/screens/auth/login_screen.dart';
import 'package:staff_portal/screens/auth/staff_login_screen.dart';
import 'package:staff_portal/screens/landing/landing_screen.dart';
import 'package:staff_portal/screens/auth/register_screen.dart';
import 'package:staff_portal/screens/dashboard/dashboard_screen.dart';
import 'package:staff_portal/screens/menu/menu_screen.dart';
import 'package:staff_portal/onboarding/onboarding_bloc.dart';
import 'package:staff_portal/onboarding/onboarding_repository.dart';
import 'package:staff_portal/screens/onboarding/onboarding_screen.dart';
import 'package:staff_portal/screens/orders/create_order_screen.dart';
import 'package:staff_portal/screens/orders/order_detail_screen.dart';
import 'package:staff_portal/screens/orders/orders_screen.dart';
import 'package:staff_portal/screens/kds/kds_screen.dart';
import 'package:staff_portal/screens/restaurant_selector/restaurant_selector_screen.dart';
import 'package:staff_portal/screens/inventory/inventory_screen.dart';
import 'package:staff_portal/screens/settings/settings_screen.dart';
import 'package:staff_portal/screens/staff/staff_screen.dart';
import 'package:staff_portal/screens/subscription/subscription_payment_screen.dart';
import 'package:staff_portal/screens/support/support_screen.dart';
import 'package:staff_portal/reports/reports_screen.dart';
import 'package:staff_portal/reservation/reservations_screen.dart';
import 'package:staff_portal/subscription/subscription_guard_cubit.dart';
import 'package:staff_portal/tables/tables_screen.dart';

// ---------------------------------------------------------------------------
// Route path constants
// ---------------------------------------------------------------------------

abstract final class AppRoutes {
  static const landing = '/';
  static const login = '/login';
  static const loginWaiter = '/login/waiter';
  static const loginBilling = '/login/billing';
  static const loginKitchen = '/login/kitchen';
  static const register = '/register';
  static const restaurantSelector = '/restaurant-selector';
  static const onboarding = '/onboarding';
  static const subscriptionPayment = '/subscription/payment';
  static const support = '/support';
  static const dashboard = '/dashboard';
  static const menu = '/menu';
  static const tables = '/tables';
  static const reservations = '/reservations';
  static const orders = '/orders';
  static const orderDetail = '/orders/:id';
  static const orderCreate = '/orders/create';
  static const kds = '/kds';
  static const billing = '/billing';
  static const billingDetail = '/billing/:id';
  static const staff = '/staff';
  static const inventory = '/inventory';
  static const reports = '/reports';
  static const settings = '/settings';
  static const changePassword = '/change-password';
}

// ---------------------------------------------------------------------------
// Role permission map — which routes each role may access
// ---------------------------------------------------------------------------

const Map<StaffRole, Set<String>> _rolePermissions = {
  StaffRole.owner: {
    AppRoutes.dashboard,
    AppRoutes.orders,
    AppRoutes.orderDetail,
    AppRoutes.orderCreate,
    AppRoutes.menu,
    AppRoutes.tables,
    AppRoutes.reservations,
    AppRoutes.kds,
    AppRoutes.billing,
    AppRoutes.billingDetail,
    AppRoutes.staff,
    AppRoutes.inventory,
    AppRoutes.reports,
    AppRoutes.settings,
  },
  StaffRole.manager: {
    AppRoutes.dashboard,
    AppRoutes.orders,
    AppRoutes.orderDetail,
    AppRoutes.orderCreate,
    AppRoutes.menu,
    AppRoutes.tables,
    AppRoutes.reservations,
    AppRoutes.kds,
    AppRoutes.billing,
    AppRoutes.billingDetail,
    AppRoutes.staff,
    AppRoutes.inventory,
    AppRoutes.reports,
  },
  StaffRole.waiter: {
    AppRoutes.dashboard,
    AppRoutes.orders,
    AppRoutes.orderDetail,
    AppRoutes.orderCreate,
    AppRoutes.tables,
    AppRoutes.reservations,
  },
  StaffRole.chef: {AppRoutes.dashboard, AppRoutes.kds},
  StaffRole.cashier: {
    AppRoutes.dashboard,
    AppRoutes.orders,
    AppRoutes.orderDetail,
    AppRoutes.billing,
    AppRoutes.billingDetail,
  },
  StaffRole.deliveryStaff: {
    AppRoutes.dashboard,
    AppRoutes.orders,
    AppRoutes.orderDetail,
  },
};

// ---------------------------------------------------------------------------
// GoRouterRefreshStream — bridges a Bloc stream to ChangeNotifier
// ---------------------------------------------------------------------------

/// Adapts any [Stream] into a [ChangeNotifier] that GoRouter can listen to.
///
/// Disposes of the subscription when [dispose] is called.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Listens to multiple bloc/cubit streams so GoRouter re-evaluates redirects.
class CombinedRefreshListenable extends ChangeNotifier {
  CombinedRefreshListenable(List<Stream<dynamic>> streams) {
    notifyListeners();
    for (final stream in streams) {
      stream.asBroadcastStream().listen((_) => notifyListeners());
    }
  }
}

// ---------------------------------------------------------------------------
// AppRouter
// ---------------------------------------------------------------------------

/// Declares all GoRouter routes and wires AuthBloc-driven redirect guards.
///
/// Guards (Requirements 2.8, 2.9, 16.7, 16.8):
/// - [AuthInitial] / [AuthLoading] → wait (no redirect)
/// - [Unauthenticated] → `/login`
/// - [BaseAuthenticated] → `/restaurant-selector` (or payment if pending)
/// - [TenantAuthenticated] but role lacks permission → `/dashboard`
class AppRouter {
  AppRouter({
    required AuthBloc authBloc,
    required SubscriptionGuardCubit subscriptionGuard,
    required GlobalKey<NavigatorState> navigatorKey,
  })  : _authBloc = authBloc,
        _subscriptionGuard = subscriptionGuard,
        navigatorKey = navigatorKey;

  final AuthBloc _authBloc;
  final SubscriptionGuardCubit _subscriptionGuard;

  /// Navigator key shared with [ApiClient] so [RedirectInterceptor] can
  /// navigate without a BuildContext.
  final GlobalKey<NavigatorState> navigatorKey;

  late final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.landing,
    refreshListenable: CombinedRefreshListenable([
      _authBloc.stream,
      _subscriptionGuard.stream,
    ]),
    redirect: _guard,
    routes: _routes,
  );

  // ── Route definitions ────────────────────────────────────────────────────

  static final List<RouteBase> _routes = [
    // ── Public routes (no shell) ──────────────────────────────────────────
    GoRoute(
      path: AppRoutes.landing,
      builder: (_, __) => const LandingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.loginWaiter,
      builder: (_, __) => const StaffLoginScreen(role: 'waiter'),
    ),
    GoRoute(
      path: AppRoutes.loginBilling,
      builder: (_, __) => const StaffLoginScreen(role: 'billing'),
    ),
    GoRoute(
      path: AppRoutes.loginKitchen,
      builder: (_, __) => const StaffLoginScreen(role: 'kitchen'),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.restaurantSelector,
      builder: (_, __) => const RestaurantSelectorScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, __) => BlocProvider<OnboardingBloc>(
        create: (_) => OnboardingBloc(
          repository: context.read<OnboardingRepository>(),
        ),
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.subscriptionPayment,
      builder: (_, __) => const SubscriptionPaymentScreen(),
    ),
    GoRoute(
      path: AppRoutes.support,
      builder: (_, __) => const SupportScreen(),
    ),
    GoRoute(
      path: AppRoutes.changePassword,
      builder: (_, __) => const ChangePasswordScreen(),
    ),

    // ── Authenticated routes (wrapped in AppShell nav) ────────────────────
    ShellRoute(
      builder: (_, __, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (_, __) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.menu,
          builder: (_, __) => const MenuScreen(),
        ),
        GoRoute(
          path: AppRoutes.tables,
          builder: (_, __) => const TablesScreen(),
        ),
        GoRoute(
          path: AppRoutes.reservations,
          builder: (_, __) => const ReservationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.orders,
          builder: (_, __) => const OrdersScreen(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (_, __) => const CreateOrderScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  OrderDetailScreen(orderId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.kds,
          builder: (_, __) => const KdsScreen(),
        ),
        GoRoute(
          path: AppRoutes.billing,
          builder: (_, __) => const BillingScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => BillingDetailScreen(
                billId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.staff,
          builder: (_, __) => const StaffScreen(),
        ),
        GoRoute(
          path: AppRoutes.inventory,
          builder: (_, __) => const InventoryScreen(),
        ),
        GoRoute(
          path: AppRoutes.reports,
          builder: (_, __) => const ReportsScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, __) => const SettingsScreen(),
        ),
      ],
    ),
  ];

  // ── Redirect guard ───────────────────────────────────────────────────────

  String? _guard(BuildContext context, GoRouterState state) {
    final authState = _authBloc.state;
    final subGuard = _subscriptionGuard.state;
    final location = state.matchedLocation;

    // Public routes that are always accessible
    const publicRoutes = {
      AppRoutes.landing,
      AppRoutes.login,
      AppRoutes.loginWaiter,
      AppRoutes.loginBilling,
      AppRoutes.loginKitchen,
      AppRoutes.register,
    };

    // Routes allowed while subscription payment is outstanding
    const paymentFlowRoutes = {
      AppRoutes.subscriptionPayment,
      AppRoutes.onboarding,
      AppRoutes.support,
      AppRoutes.changePassword,
    };

    // While auth is being determined, stay put
    if (authState is AuthInitial || authState is AuthLoading) {
      return null;
    }

    // Pending payment — redirect to payment page (never POS billing)
    if (subGuard is SubscriptionGuardPaymentRequired) {
      if (!paymentFlowRoutes.contains(location)) {
        return AppRoutes.subscriptionPayment;
      }
      return null;
    }

    // While checking subscription status, block POS billing (403 may redirect there)
    if (subGuard is SubscriptionGuardInitial ||
        subGuard is SubscriptionGuardLoading) {
      if (location == AppRoutes.billing ||
          location.startsWith('${AppRoutes.billing}/')) {
        return AppRoutes.subscriptionPayment;
      }
      if (authState is TenantAuthenticated &&
          (publicRoutes.contains(location) ||
              location == AppRoutes.restaurantSelector ||
              location == AppRoutes.dashboard)) {
        return null;
      }
    }

    // Unauthenticated → landing (or stay on public routes)
    if (authState is Unauthenticated || authState is AuthError) {
      return publicRoutes.contains(location) ? null : AppRoutes.landing;
    }

    // Has only Base_JWT → restaurant selector (onboarding/support while switching)
    if (authState is BaseAuthenticated) {
      if (location == AppRoutes.restaurantSelector ||
          location == AppRoutes.onboarding ||
          location == AppRoutes.support ||
          location == AppRoutes.changePassword) {
        return null;
      }
      return AppRoutes.restaurantSelector;
    }

    // Fully authenticated with Tenant_JWT — skip landing/login/selector
    if (authState is TenantAuthenticated) {
      if (publicRoutes.contains(location) ||
          location == AppRoutes.restaurantSelector) {
        return AppRoutes.dashboard;
      }

      // Check role permission for restricted routes
      final permittedRoutes = _rolePermissions[authState.role] ?? {};
      // Normalize :id params — match the template path
      final templateLocation = _normalizeLocation(location);
      if (!permittedRoutes.contains(templateLocation) &&
          !_isPublicOrSystemRoute(templateLocation)) {
        return AppRoutes.dashboard;
      }

      return null;
    }

    return null;
  }

  /// Converts `/orders/42` → `/orders/:id`, `/billing/7` → `/billing/:id`.
  static String _normalizeLocation(String location) {
    // orders/create — exact match, no normalisation needed
    if (location == AppRoutes.orderCreate) return AppRoutes.orderCreate;

    // orders/:id
    final ordersDetail = RegExp(r'^/orders/[^/]+$');
    if (ordersDetail.hasMatch(location)) return AppRoutes.orderDetail;

    // billing/:id
    final billingDetail = RegExp(r'^/billing/[^/]+$');
    if (billingDetail.hasMatch(location)) return AppRoutes.billingDetail;

    return location;
  }

  static bool _isPublicOrSystemRoute(String location) {
    return location == AppRoutes.landing ||
        location == AppRoutes.login ||
        location == AppRoutes.register ||
        location == AppRoutes.restaurantSelector ||
        location == AppRoutes.onboarding ||
        location == AppRoutes.subscriptionPayment ||
        location == AppRoutes.support ||
        location == AppRoutes.dashboard ||
        location == AppRoutes.changePassword;
  }
}
