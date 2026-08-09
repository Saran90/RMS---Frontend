import 'package:api_client/api_client.dart';
import 'package:auth/auth.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:staff_portal/onboarding/onboarding_repository.dart';
import 'package:staff_portal/utils/money_parser.dart';
import 'package:staff_portal/onboarding/razorpay_payment_handler.dart';
import 'package:staff_portal/router/app_router.dart';
import 'package:staff_portal/subscription/subscription_guard_cubit.dart';

/// Resumes or completes subscription payment when tenant APIs return 403.
class SubscriptionPaymentScreen extends StatefulWidget {
  const SubscriptionPaymentScreen({super.key});

  @override
  State<SubscriptionPaymentScreen> createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  RazorpayPaymentHandler? _razorpay;
  bool _loading = true;
  String? _error;
  String? _restaurantId;
  SubscriptionRecord? _subscription;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _razorpay = RazorpayPaymentHandler(
      onSuccess: ({required paymentId, required orderId, required signature}) {
        _verifyAndFinish(
          paymentId: paymentId,
          orderId: orderId,
          signature: signature,
        );
      },
      onFailure: (message) {
        setState(() {
          _error = message;
          _statusMessage = null;
        });
      },
      onDismiss: () {
        setState(() {
          _error = 'Payment cancelled. Please try again.';
          _statusMessage = null;
        });
      },
    );
    _razorpay!.init();
    _load();
  }

  @override
  void dispose() {
    _razorpay?.dispose();
    super.dispose();
  }

  void _setStateIfMounted(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _backToRestaurantSelector() async {
    context.read<SubscriptionGuardCubit>().markPaymentComplete();

    final authBloc = context.read<AuthBloc>();
    if (authBloc.state is! BaseAuthenticated) {
      authBloc.add(const RestaurantSwitchRequested());
      await authBloc.stream
          .firstWhere((state) => state is BaseAuthenticated)
          .timeout(const Duration(seconds: 5));
    }

    if (!mounted) return;
    context.go(AppRoutes.restaurantSelector);
  }

  Future<void> _load() async {
    _setStateIfMounted(() {
      _loading = true;
      _error = null;
      _statusMessage = null;
    });

    final tokenRepo = context.read<SecureTokenRepository>();
    final onboardingRepo = context.read<OnboardingRepository>();

    try {
      if (!tokenRepo.isTenantTokenValid()) {
        _setStateIfMounted(() {
          _loading = false;
          _error = 'Select a restaurant to manage subscription payment.';
        });
        return;
      }

      final tenantToken = await tokenRepo.getTenantToken();
      final restaurantId = tenantToken != null
          ? SecureTokenRepository.extractRestaurantId(tenantToken)
          : null;

      if (restaurantId == null || restaurantId.isEmpty) {
        _setStateIfMounted(() {
          _loading = false;
          _error = 'Select a restaurant to manage subscription payment.';
        });
        return;
      }

      _restaurantId = restaurantId;
      _subscription =
          await onboardingRepo.getSubscriptionForRestaurant(restaurantId);

      if (_subscription == null) {
        _setStateIfMounted(() {
          _loading = false;
          _error = 'No subscription found. Please complete onboarding.';
        });
        return;
      }

      if (_subscription!.status == 'active') {
        _setStateIfMounted(() {
          _loading = false;
          _error = null;
        });
        if (!mounted) return;
        context.read<SubscriptionGuardCubit>().markPaymentComplete();
        if (context.read<AuthBloc>().state is TenantAuthenticated) {
          context.go(AppRoutes.dashboard);
        } else {
          context.read<AuthBloc>().add(
                RestaurantSelected(restaurantId: restaurantId),
              );
        }
        return;
      }

      if (_subscription!.status != 'pending_payment') {
        _setStateIfMounted(() {
          _loading = false;
          _error =
              'Subscription status "${_subscription!.status}" cannot be paid here. '
              'Please contact support.';
        });
        return;
      }

      _setStateIfMounted(() => _loading = false);
    } on ApiException catch (e) {
      _setStateIfMounted(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      _setStateIfMounted(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _startPayment() async {
    final sub = _subscription;
    if (sub == null) return;

    final onboardingRepo = context.read<OnboardingRepository>();

    _setStateIfMounted(() {
      _loading = true;
      _error = null;
      _statusMessage = 'Preparing payment…';
    });

    try {
      final payment = await onboardingRepo.initiatePayment(sub.subscriptionId);
      _setStateIfMounted(() {
        _loading = false;
        _statusMessage = 'Complete payment in the Razorpay window…';
      });
      _razorpay?.open(payment.toCheckoutParams());
    } on ApiException catch (e) {
      _setStateIfMounted(() {
        _loading = false;
        _error = e.message;
        _statusMessage = null;
      });
    }
  }

  Future<void> _verifyAndFinish({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    final sub = _subscription;
    final restaurantId = _restaurantId;
    if (sub == null || restaurantId == null) return;

    final onboardingRepo = context.read<OnboardingRepository>();
    final authBloc = context.read<AuthBloc>();
    final navigator = GoRouter.of(context);

    _setStateIfMounted(() {
      _loading = true;
      _error = null;
      _statusMessage = 'Verifying payment…';
    });

    try {
      await onboardingRepo.verifyPayment(
            subscriptionId: sub.subscriptionId,
            razorpayPaymentId: paymentId,
            razorpayOrderId: orderId,
            razorpaySignature: signature,
          );

      _setStateIfMounted(
        () => _statusMessage = 'Setting up your restaurant…',
      );
      await onboardingRepo.waitForProvisioning(restaurantId);

      if (!mounted) return;
      context.read<SubscriptionGuardCubit>().markPaymentComplete();
      if (authBloc.state is TenantAuthenticated) {
        navigator.go(AppRoutes.dashboard);
        return;
      }
      authBloc.add(RestaurantSelected(restaurantId: restaurantId));
    } on ApiException catch (e) {
      _setStateIfMounted(() {
        _loading = false;
        _error = e.message;
        _statusMessage = null;
      });
    } catch (e) {
      _setStateIfMounted(() {
        _loading = false;
        _error = e.toString();
        _statusMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is TenantAuthenticated,
      listener: (context, state) {
        context.go(AppRoutes.dashboard);
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Choose restaurant',
            onPressed: _backToRestaurantSelector,
          ),
          title: const Text('Subscription Payment'),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildBody(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (_statusMessage != null) ...[
            const SizedBox(height: AppTheme.spacing16),
            Text(
              _statusMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.mutedText),
            ),
          ],
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InlineError(message: _error!),
          const SizedBox(height: AppTheme.spacing24),
          FilledButton(
            onPressed: _load,
            child: const Text('Retry'),
          ),
          const SizedBox(height: AppTheme.spacing12),
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.onboarding),
            child: const Text('Set up new restaurant'),
          ),
          const SizedBox(height: AppTheme.spacing12),
          TextButton.icon(
            onPressed: _backToRestaurantSelector,
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: const Text('Choose another restaurant'),
          ),
        ],
      );
    }

    final sub = _subscription;
    if (sub == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.onboarding),
            child: const Text('Start onboarding'),
          ),
          const SizedBox(height: AppTheme.spacing12),
          TextButton.icon(
            onPressed: _backToRestaurantSelector,
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: const Text('Choose another restaurant'),
          ),
        ],
      );
    }

    final price = formatRupeesFromPaise(sub.planAmountPaise);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.credit_card_outlined,
            size: 64, color: AppTheme.primary),
        const SizedBox(height: AppTheme.spacing24),
        Text(
          'Complete your subscription',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacing12),
        Text(
          'Plan: ${sub.planId.replaceAll('_', ' ')}\n'
          'Amount: ₹$price / ${sub.billingCycle}',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.mutedText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacing32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _startPayment,
            child: const Text('Pay now'),
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        OutlinedButton(
          onPressed: () => context.go(AppRoutes.support),
          child: const Text('Contact support'),
        ),
        const SizedBox(height: AppTheme.spacing12),
        TextButton.icon(
          onPressed: _backToRestaurantSelector,
          icon: const Icon(Icons.storefront_outlined, size: 18),
          label: const Text('Choose another restaurant'),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusInput),
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
