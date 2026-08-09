// Feature: rms-flutter-frontend
// Implements: Requirements 4.1–4.9

import 'package:auth/auth.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:staff_portal/onboarding/onboarding_bloc.dart';
import 'package:staff_portal/onboarding/onboarding_repository.dart';
import 'package:staff_portal/onboarding/razorpay_payment_handler.dart';
import 'package:staff_portal/utils/money_parser.dart';
import 'package:staff_portal/router/app_router.dart';
import 'package:staff_portal/subscription/subscription_guard_cubit.dart';

/// Multi-step onboarding wizard with Razorpay subscription payment.
///
/// Steps: Restaurant Details → Plan Selection → Payment → Confirmation
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  RazorpayPaymentHandler? _razorpay;
  PaymentCheckoutReady? _lastCheckout;

  @override
  void initState() {
    super.initState();
    _razorpay = RazorpayPaymentHandler(
      onSuccess: ({required paymentId, required orderId, required signature}) {
        context.read<OnboardingBloc>().add(PaymentSucceeded(
              paymentId: paymentId,
              orderId: orderId,
              signature: signature,
            ));
      },
      onFailure: (message) {
        context.read<OnboardingBloc>().add(PaymentFailed(message: message));
      },
      onDismiss: () {
        context.read<OnboardingBloc>().add(const PaymentDismissed());
      },
    );
    _razorpay!.init();
    context.read<OnboardingBloc>().add(const OnboardingStarted());
  }

  @override
  void dispose() {
    _razorpay?.dispose();
    super.dispose();
  }

  void _openCheckoutIfNeeded(OnboardingState state) {
    if (state is! PaymentCheckoutReady) return;
    if (_lastCheckout?.subscriptionId == state.subscriptionId &&
        _lastCheckout?.payment.razorpayOrderId ==
            state.payment.razorpayOrderId) {
      return;
    }
    _lastCheckout = state;
    _razorpay?.open(
      state.payment.toCheckoutParams(),
      email: state.contactEmail,
      contact: state.contactPhone,
    );
  }

  int _stepIndex(OnboardingState state) {
    return switch (state) {
      RestaurantDetailsStep() => 0,
      PlanSelectionStep() => 1,
      PaymentCheckoutReady() => 2,
      OnboardingLoading(:final message) when message != null => 2,
      ProvisioningStep() => 3,
      OnboardingComplete() => 3,
      OnboardingError(:final step) => step - 1,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<OnboardingBloc, OnboardingState>(
          listenWhen: (prev, curr) => curr is PaymentCheckoutReady,
          listener: (context, state) => _openCheckoutIfNeeded(state),
        ),
        BlocListener<OnboardingBloc, OnboardingState>(
          listenWhen: (prev, curr) => curr is OnboardingComplete,
          listener: (context, state) {
            if (state is OnboardingComplete) {
              context.read<SubscriptionGuardCubit>().markPaymentComplete();
              context.read<AuthBloc>().add(
                    RestaurantSelected(restaurantId: state.restaurantId),
                  );
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) => curr is TenantAuthenticated,
          listener: (context, state) {
            context.go(AppRoutes.dashboard);
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(title: const Text('Setup Your Restaurant')),
        body: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          final stepIndex = _stepIndex(state);

          return Column(
            children: [
              _StepIndicator(currentStep: stepIndex),
              const Divider(height: 1),
              Expanded(
                child: switch (state) {
                  OnboardingLoading(:final message) =>
                    _LoadingStep(message: message),
                  OnboardingInitial() => const _LoadingStep(),
                  RestaurantDetailsStep(:final errorMessage) =>
                    _RestaurantDetailsStep(errorMessage: errorMessage),
                  PlanSelectionStep(
                    :final restaurantId,
                    :final plans,
                    :final errorMessage,
                    :final pendingSubscriptionId,
                  ) =>
                    _PlanSelectionStep(
                      restaurantId: restaurantId,
                      plans: plans,
                      errorMessage: errorMessage,
                      pendingSubscriptionId: pendingSubscriptionId,
                    ),
                  PaymentCheckoutReady() => const _PaymentStep(),
                  OnboardingComplete() => const _ConfirmationStep(),
                  ProvisioningStep() => const _ProvisioningStep(),
                  OnboardingError(:final message, :final step) =>
                    _ErrorStep(message: message, step: step),
                },
              ),
            ],
          );
        },
        ),
      ),
    );
  }
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  static const _labels = ['Details', 'Plan', 'Payment', 'Done'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cardSurface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final isCompleted = i ~/ 2 < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted ? AppTheme.primary : AppTheme.border,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;
          return _StepCircle(
            label: _labels[stepIndex],
            number: stepIndex + 1,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
          );
        }),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.label,
    required this.number,
    required this.isCompleted,
    required this.isCurrent,
  });

  final String label;
  final int number;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final active = isCompleted || isCurrent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.border,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: AppTheme.onPrimary)
                : Text(
                    '$number',
                    style: TextStyle(
                      color: active ? AppTheme.onPrimary : AppTheme.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            color: isCurrent ? AppTheme.primary : AppTheme.mutedText,
          ),
        ),
      ],
    );
  }
}

// ── Loading step ──────────────────────────────────────────────────────────────

class _LoadingStep extends StatelessWidget {
  const _LoadingStep({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacing16),
            Text(
              message!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.mutedText),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Step 1: Restaurant Details ────────────────────────────────────────────────

class _RestaurantDetailsStep extends StatefulWidget {
  const _RestaurantDetailsStep({this.errorMessage});
  final String? errorMessage;

  @override
  State<_RestaurantDetailsStep> createState() => _RestaurantDetailsStepState();
}

class _RestaurantDetailsStepState extends State<_RestaurantDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _gstController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _gstController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    context.read<OnboardingBloc>().add(RestaurantDetailsSubmitted(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          gstNumber: _gstController.text.trim(),
          contactEmail: _emailController.text.trim(),
          contactPhone: _phoneController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 0,
            color: AppTheme.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Restaurant Details',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      'Tell us about your restaurant.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.mutedText),
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    if (widget.errorMessage != null) ...[
                      _InlineError(message: widget.errorMessage!),
                      const SizedBox(height: AppTheme.spacing16),
                    ],
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Name *',
                        hintText: 'e.g. Spice Garden',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Restaurant name is required'
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Contact Email *',
                        hintText: 'e.g. owner@restaurant.com',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Contact email is required';
                        }
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone *',
                        hintText: 'e.g. 9876543210',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Contact phone is required'
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Address *',
                        hintText: 'Full address including city and pincode',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Address is required'
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    TextFormField(
                      controller: _gstController,
                      decoration: const InputDecoration(
                        labelText: 'GST Number *',
                        hintText: 'e.g. 29ABCDE1234F1Z5',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'GST number is required'
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _submit,
                        child: const Text('Continue →'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step 2: Plan Selection ────────────────────────────────────────────────────

class _PlanSelectionStep extends StatelessWidget {
  const _PlanSelectionStep({
    required this.restaurantId,
    required this.plans,
    this.errorMessage,
    this.pendingSubscriptionId,
  });

  final String restaurantId;
  final List<SubscriptionPlan> plans;
  final String? errorMessage;
  final String? pendingSubscriptionId;

  static String _formatPlanPrice(SubscriptionPlan plan) {
    final rupees = formatRupeesFromPaise(plan.amountPaise);
    return '₹$rupees/${plan.billingCycle}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Choose a Plan',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Select a plan and complete payment to activate your restaurant.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.mutedText),
              ),
              const SizedBox(height: AppTheme.spacing16),
              if (pendingSubscriptionId != null) ...[
                OutlinedButton.icon(
                  onPressed: () => context
                      .read<OnboardingBloc>()
                      .add(const PaymentRetryRequested()),
                  icon: const Icon(Icons.payment_outlined, size: 18),
                  label: const Text('Resume pending payment'),
                ),
                const SizedBox(height: AppTheme.spacing16),
              ],
              if (errorMessage != null) ...[
                _InlineError(message: errorMessage!),
                const SizedBox(height: AppTheme.spacing16),
              ],
              ...plans.map((plan) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                    child: _PlanCard(
                      plan: plan,
                      priceLabel: _formatPlanPrice(plan),
                      onSelect: () => context
                          .read<OnboardingBloc>()
                          .add(PlanSelected(planId: plan.id)),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.priceLabel,
    required this.onSelect,
  });

  final SubscriptionPlan plan;
  final String priceLabel;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(plan.name,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Text(
                    priceLabel,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppTheme.primary),
                  ),
                ],
              ),
              if (plan.features.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacing12),
                ...plan.features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: AppTheme.success),
                        const SizedBox(width: AppTheme.spacing8),
                        Expanded(
                          child: Text(f,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacing16),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSelect,
                  child: const Text('Select Plan & Pay →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 3: Payment (Razorpay checkout) ───────────────────────────────────────

class _PaymentStep extends StatelessWidget {
  const _PaymentStep();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payment_outlined, size: 48, color: AppTheme.primary),
            const SizedBox(height: AppTheme.spacing24),
            Text(
              'Complete your payment',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'The Razorpay payment window should open automatically. '
              'If it did not, go back and try again.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.mutedText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 4: Provisioning (polling) ───────────────────────────────────────────

class _ProvisioningStep extends StatelessWidget {
  const _ProvisioningStep();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: AppTheme.spacing24),
            Text(
              'Setting up your restaurant…',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'This usually takes a few seconds.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.mutedText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 4: Confirmation ──────────────────────────────────────────────────────

class _ConfirmationStep extends StatelessWidget {
  const _ConfirmationStep();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              "You're all set!",
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Your restaurant is now active on the RMS platform.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppTheme.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing32),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Redirecting to your dashboard…',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.mutedText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error step ────────────────────────────────────────────────────────────────

class _ErrorStep extends StatelessWidget {
  const _ErrorStep({required this.message, required this.step});

  final String message;
  final int step;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InlineError(message: message),
            const SizedBox(height: AppTheme.spacing24),
            OutlinedButton(
              onPressed: () =>
                  context.read<OnboardingBloc>().add(const OnboardingStarted()),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

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
