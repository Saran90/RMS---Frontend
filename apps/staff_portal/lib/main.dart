import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:auth/auth.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:staff_portal/billing/billing_repository.dart';
import 'package:staff_portal/connectivity/connectivity_cubit.dart';
import 'package:staff_portal/dashboard/dashboard_repository.dart';
import 'package:staff_portal/inventory/inventory_repository.dart';
import 'package:staff_portal/kds/kds_repository.dart';
import 'package:staff_portal/menu/menu_repository.dart';
import 'package:staff_portal/onboarding/onboarding_repository.dart';
import 'package:staff_portal/orders/order_repository.dart';
import 'package:staff_portal/reports/reports_repository.dart';
import 'package:staff_portal/reservation/reservation_bloc.dart';
import 'package:staff_portal/reservation/reservation_repository.dart';
import 'package:staff_portal/restaurant_selector/restaurant_repository.dart';
import 'package:staff_portal/router/app_router.dart';
import 'package:staff_portal/settings/settings_repository.dart';
import 'package:staff_portal/staff/staff_repository.dart';
import 'package:staff_portal/subscription/subscription_guard_cubit.dart';
import 'package:staff_portal/tables/table_repository.dart';

void main() {
  runApp(const StaffPortalApp());
}

class StaffPortalApp extends StatefulWidget {
  const StaffPortalApp({super.key});

  @override
  State<StaffPortalApp> createState() => _StaffPortalAppState();
}

class _StaffPortalAppState extends State<StaffPortalApp> {
  late final SecureTokenRepository _tokenRepository;
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final OnboardingRepository _onboardingRepository;
  late final RestaurantRepository _restaurantRepository;
  late final ReservationRepository _reservationRepository;
  late final AuthBloc _authBloc;
  late final SubscriptionGuardCubit _subscriptionGuardCubit;
  late final ReservationBloc _reservationBloc;
  late final ConnectivityCubit _connectivityCubit;
  late final AppRouter _appRouter;
  StreamSubscription<AuthState>? _authSubscription;
  String? _lastRedirectRoute;
  DateTime? _lastRedirectAt;

  /// Shared navigator key — created here so it can be passed to both
  /// [ApiClient] (for [RedirectInterceptor]) and [AppRouter] (for GoRouter).
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    _tokenRepository = SecureTokenRepository();

    _authRepository = _buildAuthRepository();
    _onboardingRepository = OnboardingRepository(apiClient: _apiClient);
    _restaurantRepository = RestaurantRepository(apiClient: _apiClient);
    _reservationRepository = ReservationRepository(apiClient: _apiClient);

    _subscriptionGuardCubit = SubscriptionGuardCubit(
      onboardingRepository: _onboardingRepository,
      tokenRepository: _tokenRepository,
    );

    _authBloc = AuthBloc(
      authRepository: _authRepository,
      tokenRepository: _tokenRepository,
    )..add(const AppStarted());

    _authSubscription = _authBloc.stream.listen((state) {
      if (state is TenantAuthenticated) {
        // Only check the restaurant in the tenant JWT — never scan all venues.
        _subscriptionGuardCubit.checkPendingPayment();
      } else if (state is BaseAuthenticated) {
        // No restaurant selected yet — skip subscription checks.
        _subscriptionGuardCubit.markPaymentComplete();
      } else if (state is Unauthenticated) {
        _subscriptionGuardCubit.reset();
      }
    });

    _reservationBloc = ReservationBloc(repository: _reservationRepository);

    _connectivityCubit = ConnectivityCubit();
    _appRouter = AppRouter(
      authBloc: _authBloc,
      subscriptionGuard: _subscriptionGuardCubit,
      navigatorKey: _navigatorKey,
    );
  }

  AuthRepository _buildAuthRepository() {
    _apiClient = ApiClient(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000',
      ),
      tokenRepository: _tokenRepository,
      onRedirect: (destination) {
        // Backend sends redirect=billing for inactive subscriptions — that means
        // subscription payment, not the POS billing screen (/billing).
        if (destination == 'billing') {
          destination = 'payment';
        }

        const routes = <String, String>{
          'login': '/login',
          'payment': '/subscription/payment',
          'billing': '/billing',
          'support': '/support',
          'restaurant_setup': '/onboarding',
        };
        final route = routes[destination];
        if (route == null) return;
        final context = _navigatorKey.currentContext;
        if (context == null) return;
        // Avoid bouncing off the payment page when tenant APIs 403.
        final current = GoRouterState.of(context).matchedLocation;
        if (route == AppRoutes.billing &&
            current == AppRoutes.subscriptionPayment) {
          return;
        }
        if (route == AppRoutes.subscriptionPayment &&
            current == AppRoutes.subscriptionPayment) {
          return;
        }
        // Debounce duplicate redirects from parallel 403 responses.
        final now = DateTime.now();
        if (_lastRedirectRoute == route &&
            _lastRedirectAt != null &&
            now.difference(_lastRedirectAt!) <
                const Duration(milliseconds: 1500)) {
          return;
        }
        _lastRedirectRoute = route;
        _lastRedirectAt = now;
        GoRouter.of(context).go(route);
      },
      onTokenRefreshFailed: () {
        _authBloc.add(const TokenRefreshFailed());
      },
    );

    return AuthRepository(apiClient: _apiClient);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authBloc.close();
    _subscriptionGuardCubit.close();
    _reservationBloc.close();
    _connectivityCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SecureTokenRepository>.value(value: _tokenRepository),
        RepositoryProvider<ApiClient>.value(value: _apiClient),
        RepositoryProvider<DashboardRepository>(
            create: (_) => DashboardRepository(apiClient: _apiClient)),
        RepositoryProvider<MenuRepository>(
            create: (_) => MenuRepository(apiClient: _apiClient)),
        RepositoryProvider<OrderRepository>(
            create: (_) => OrderRepository(apiClient: _apiClient)),
        RepositoryProvider<TableRepository>(
            create: (_) => TableRepository(apiClient: _apiClient)),
        RepositoryProvider<KdsRepository>(
            create: (_) => KdsRepository(apiClient: _apiClient)),
        RepositoryProvider<BillingRepository>(
            create: (_) => BillingRepository(apiClient: _apiClient)),
        RepositoryProvider<StaffRepository>(
            create: (_) => StaffRepository(apiClient: _apiClient)),
        RepositoryProvider<InventoryRepository>(
            create: (_) => InventoryRepository(apiClient: _apiClient)),
        RepositoryProvider<ReportsRepository>(
            create: (_) => ReportsRepository(apiClient: _apiClient)),
        RepositoryProvider<SettingsRepository>(
            create: (_) => SettingsRepository(apiClient: _apiClient)),
        RepositoryProvider<RestaurantRepository>.value(
            value: _restaurantRepository),
        RepositoryProvider<OnboardingRepository>.value(
            value: _onboardingRepository),
        RepositoryProvider<ReservationRepository>(
            create: (_) => ReservationRepository(apiClient: _apiClient)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: _authBloc),
          BlocProvider<SubscriptionGuardCubit>.value(
            value: _subscriptionGuardCubit,
          ),
          BlocProvider<ConnectivityCubit>.value(value: _connectivityCubit),
          BlocProvider<ReservationBloc>.value(value: _reservationBloc),
        ],
        child: MaterialApp.router(
          title: 'RMS Staff Portal',
          theme: AppTheme.light,
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}
