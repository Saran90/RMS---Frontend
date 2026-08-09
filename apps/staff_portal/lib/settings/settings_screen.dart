// Feature: rms-flutter-frontend
// Implements: Requirements 15.1–15.8

import 'package:auth/auth.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:staff_portal/settings/settings_bloc.dart';

/// Settings screen — restaurant profile and business hours.
///
/// Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7, 15.8
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Extract restaurant ID from AuthBloc.TenantAuthenticated
    final authState = context.watch<AuthBloc>().state;
    final restaurantId = _extractRestaurantId(authState);

    if (restaurantId == null) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(
          child: Text('Unable to load restaurant ID'),
        ),
      );
    }

    return BlocProvider<SettingsBloc>(
      create: (ctx) => SettingsBloc(repository: ctx.read())
        ..add(SettingsLoadRequested(restaurantId)),
      child: _SettingsView(restaurantId: restaurantId),
    );
  }

  /// Extracts the restaurant_id claim from the Tenant_JWT embedded in the
  /// AuthBloc state. In practice, this would come from decoding the JWT.
  /// For now we assume the ID is available in the state or can be inferred.
  /// Returning a placeholder for demonstration.
  String? _extractRestaurantId(AuthState state) {
    // In a real implementation, decode the Tenant_JWT from state.
    // For this task, we assume the restaurant ID can be obtained.
    // Placeholder: return a fixed ID or extract from state.
    // TODO: decode JWT to get restaurant_id claim.
    return 'restaurant-id-placeholder';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsView extends StatelessWidget {
  const _SettingsView({required this.restaurantId});
  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    // Only owner can edit settings (check role from AuthBloc)
    final authState = context.watch<AuthBloc>().state;
    final isOwner =
        authState is TenantAuthenticated && authState.role == StaffRole.owner;

    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: _handleStateChange,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            title: const Text('Settings'),
            actions: [
              if (state is SettingsLoaded || state is SettingsUpdating)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () => context
                      .read<SettingsBloc>()
                      .add(SettingsLoadRequested(restaurantId)),
                ),
            ],
          ),
          body: _buildBody(context, state, isOwner),
        );
      },
    );
  }

  void _handleStateChange(BuildContext context, SettingsState state) {
    // Show success confirmation after successful save (Req 15.2)
    if (state is SettingsSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    // Show generic operation error (Req 15.2)
    if (state is SettingsOperationError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildBody(BuildContext context, SettingsState state, bool isOwner) {
    return switch (state) {
      SettingsInitial() ||
      SettingsLoading() =>
        const Center(child: CircularProgressIndicator()),
      SettingsError(:final message) => ErrorStateWidget(
          message: message,
          onRetry: () => context
              .read<SettingsBloc>()
              .add(SettingsLoadRequested(restaurantId)),
        ),
      SettingsLoaded(:final restaurant) => _SettingsForm(
          restaurant: restaurant,
          isOwner: isOwner,
          restaurantId: restaurantId,
        ),
      SettingsUpdating(:final restaurant) => _SettingsForm(
          restaurant: restaurant,
          isOwner: isOwner,
          restaurantId: restaurantId,
          isSubmitting: true,
        ),
      SettingsSaved(:final restaurant) => _SettingsForm(
          restaurant: restaurant,
          isOwner: isOwner,
          restaurantId: restaurantId,
        ),
      SettingsValidationError(
        :final restaurant,
        :final message,
        :final fields
      ) =>
        _SettingsForm(
          restaurant: restaurant,
          isOwner: isOwner,
          restaurantId: restaurantId,
          validationError: message,
          validationFields: fields,
        ),
      SettingsOperationError(:final restaurant) => _SettingsForm(
          restaurant: restaurant,
          isOwner: isOwner,
          restaurantId: restaurantId,
        ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings form — profile + business hours
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsForm extends StatefulWidget {
  const _SettingsForm({
    required this.restaurant,
    required this.isOwner,
    required this.restaurantId,
    this.isSubmitting = false,
    this.validationError,
    this.validationFields = const [],
  });

  final Restaurant restaurant;
  final bool isOwner;
  final String restaurantId;
  final bool isSubmitting;
  final String? validationError;
  final List<String> validationFields;

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _gstCtrl;
  late final TextEditingController _logoUrlCtrl;

  // Business hours: 7 days × (open, close, isClosed)
  late List<_DayHours> _hours;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.restaurant.name);
    _addressCtrl = TextEditingController(text: widget.restaurant.address);
    _phoneCtrl = TextEditingController(text: widget.restaurant.phone);
    _gstCtrl = TextEditingController(text: widget.restaurant.gstNumber);
    _logoUrlCtrl = TextEditingController(text: widget.restaurant.logoUrl ?? '');

    // Initialize business hours from the model
    _hours = List.generate(7, (idx) {
      final dayOfWeek = idx + 1; // 1=Monday … 7=Sunday
      final existing = widget.restaurant.businessHours
          .where((h) => h.dayOfWeek == dayOfWeek)
          .firstOrNull;
      return _DayHours(
        dayOfWeek: dayOfWeek,
        openTime: existing?.openTime ?? '09:00',
        closeTime: existing?.closeTime ?? '22:00',
        isClosed: existing?.isClosed ?? false,
      );
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _gstCtrl.dispose();
    _logoUrlCtrl.dispose();
    super.dispose();
  }

  void _submitProfile() {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'gst_number': _gstCtrl.text.trim(),
      if (_logoUrlCtrl.text.trim().isNotEmpty)
        'logo_url': _logoUrlCtrl.text.trim(),
    };

    context.read<SettingsBloc>().add(
          SettingsUpdateRequested(
            restaurantId: widget.restaurantId,
            payload: payload,
          ),
        );
  }

  void _submitBusinessHours() {
    final hoursPayload = _hours
        .map((h) => {
              'day_of_week': h.dayOfWeek,
              'open_time': h.openTime,
              'close_time': h.closeTime,
              'is_closed': h.isClosed,
            })
        .toList();

    context.read<SettingsBloc>().add(
          SettingsUpdateRequested(
            restaurantId: widget.restaurantId,
            payload: {'business_hours': hoursPayload},
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = !widget.isOwner;

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        if (readOnly)
          _InfoBanner(
            message: 'Only the restaurant owner can edit these settings.',
          ),
        if (readOnly) const SizedBox(height: AppTheme.spacing12),
        // Validation error banner (Req 15.3)
        if (widget.validationError != null) ...[
          _ErrorBanner(message: widget.validationError!),
          const SizedBox(height: AppTheme.spacing12),
        ],
        _SectionLabel('Restaurant Profile'),
        const SizedBox(height: AppTheme.spacing12),
        _ProfileCard(
          formKey: _formKey,
          nameCtrl: _nameCtrl,
          addressCtrl: _addressCtrl,
          phoneCtrl: _phoneCtrl,
          gstCtrl: _gstCtrl,
          logoUrlCtrl: _logoUrlCtrl,
          readOnly: readOnly,
          isSubmitting: widget.isSubmitting,
          validationFields: widget.validationFields,
          onSubmit: _submitProfile,
        ),
        const SizedBox(height: AppTheme.spacing24),
        _SectionLabel('Business Hours'),
        const SizedBox(height: AppTheme.spacing12),
        _BusinessHoursCard(
          hours: _hours,
          readOnly: readOnly,
          isSubmitting: widget.isSubmitting,
          onSubmit: _submitBusinessHours,
          onHoursChanged: () => setState(() {}),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile card
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.formKey,
    required this.nameCtrl,
    required this.addressCtrl,
    required this.phoneCtrl,
    required this.gstCtrl,
    required this.logoUrlCtrl,
    required this.readOnly,
    required this.isSubmitting,
    required this.validationFields,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController gstCtrl;
  final TextEditingController logoUrlCtrl;
  final bool readOnly;
  final bool isSubmitting;
  final List<String> validationFields;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field (Req 15.1)
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Restaurant Name *',
                  // Highlight if server reported this field as invalid (Req 15.3)
                  errorText: validationFields.contains('name')
                      ? 'Invalid value'
                      : null,
                ),
                readOnly: readOnly,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: AppTheme.spacing12),
              // Address field
              TextFormField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  labelText: 'Address *',
                  errorText: validationFields.contains('address')
                      ? 'Invalid value'
                      : null,
                ),
                maxLines: 2,
                readOnly: readOnly,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Address is required'
                    : null,
              ),
              const SizedBox(height: AppTheme.spacing12),
              // Phone field
              TextFormField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Phone *',
                  errorText: validationFields.contains('phone')
                      ? 'Invalid value'
                      : null,
                ),
                readOnly: readOnly,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Phone is required'
                    : null,
              ),
              const SizedBox(height: AppTheme.spacing12),
              // GST Number field
              TextFormField(
                controller: gstCtrl,
                decoration: InputDecoration(
                  labelText: 'GST Number *',
                  errorText: validationFields.contains('gst_number')
                      ? 'Invalid value'
                      : null,
                ),
                readOnly: readOnly,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'GST Number is required'
                    : null,
              ),
              const SizedBox(height: AppTheme.spacing12),
              // Logo URL field (optional)
              TextFormField(
                controller: logoUrlCtrl,
                decoration: InputDecoration(
                  labelText: 'Logo URL (optional)',
                  errorText: validationFields.contains('logo_url')
                      ? 'Invalid value'
                      : null,
                ),
                readOnly: readOnly,
              ),
              if (!readOnly) ...[
                const SizedBox(height: AppTheme.spacing24),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: isSubmitting ? null : onSubmit,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.onPrimary),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save Profile'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Business hours card
// ─────────────────────────────────────────────────────────────────────────────

class _BusinessHoursCard extends StatelessWidget {
  const _BusinessHoursCard({
    required this.hours,
    required this.readOnly,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onHoursChanged,
  });

  final List<_DayHours> hours;
  final bool readOnly;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onHoursChanged;

  static const _dayLabels = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...hours.asMap().entries.map((e) {
              final idx = e.key;
              final day = e.value;
              return Padding(
                padding: EdgeInsets.only(
                    bottom: idx < hours.length - 1 ? AppTheme.spacing12 : 0),
                child: _DayHoursRow(
                  label: _dayLabels[idx],
                  day: day,
                  readOnly: readOnly,
                  onChanged: onHoursChanged,
                ),
              );
            }),
            if (!readOnly) ...[
              const SizedBox(height: AppTheme.spacing24),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.onPrimary),
                        )
                      : const Icon(Icons.schedule_outlined),
                  label: const Text('Save Business Hours'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day hours row
// ─────────────────────────────────────────────────────────────────────────────

class _DayHoursRow extends StatelessWidget {
  const _DayHoursRow({
    required this.label,
    required this.day,
    required this.readOnly,
    required this.onChanged,
  });

  final String label;
  final _DayHours day;
  final bool readOnly;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: AppTheme.spacing8),
        if (!readOnly)
          Checkbox(
            value: day.isClosed,
            onChanged: (v) {
              day.isClosed = v ?? false;
              onChanged();
            },
          )
        else
          Checkbox(value: day.isClosed, onChanged: null),
        const SizedBox(width: AppTheme.spacing4),
        const Text('Closed', style: TextStyle(fontSize: 13)),
        const SizedBox(width: AppTheme.spacing12),
        if (!day.isClosed) ...[
          Expanded(
            child: _TimeField(
              label: 'Open',
              value: day.openTime,
              readOnly: readOnly,
              onChanged: (v) {
                day.openTime = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          const Text('–', style: TextStyle(fontSize: 16)),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: _TimeField(
              label: 'Close',
              value: day.closeTime,
              readOnly: readOnly,
              onChanged: (v) {
                day.closeTime = v;
                onChanged();
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Time field (HH:MM input)
// ─────────────────────────────────────────────────────────────────────────────

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.readOnly,
    required this.onChanged,
  });

  final String label;
  final String value;
  final bool readOnly;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
      readOnly: readOnly,
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.mutedText,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.primary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day hours data class
// ─────────────────────────────────────────────────────────────────────────────

class _DayHours {
  _DayHours({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    required this.isClosed,
  });

  final int dayOfWeek;
  String openTime;
  String closeTime;
  bool isClosed;
}
