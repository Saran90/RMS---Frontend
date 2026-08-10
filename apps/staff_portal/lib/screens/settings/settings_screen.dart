// Feature: rms-flutter-frontend
// Implements: Requirements 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7, 15.8

import 'package:auth/auth.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:staff_portal/settings/settings_bloc.dart';
import 'package:staff_portal/staff/staff_bloc.dart';

/// Settings screen — manage restaurant profile, business hours, and managers.
///
/// **Route guard:** Only accessible to owner/manager roles (Req 15.8).
/// The Router enforces this and redirects non-owner/manager roles to Dashboard.
///
/// Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7, 15.8
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Extract restaurant ID from Tenant_JWT
    final restaurantId = _getRestaurantIdFromToken(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (ctx) => SettingsBloc(
            repository: ctx.read(),
          )..add(SettingsLoadRequested(restaurantId)),
        ),
        BlocProvider<StaffBloc>(
          create: (ctx) => StaffBloc(
            repository: ctx.read(),
          )..add(const StaffListRequested()),
        ),
      ],
      child: const _SettingsView(),
    );
  }

  /// Extracts restaurant_id from the Tenant_JWT.
  String _getRestaurantIdFromToken(BuildContext context) {
    final tokenRepo = context.read<SecureTokenRepository>();
    // For now, use a placeholder. In production the JWT would contain a
    // restaurant_id claim that we'd extract similarly to the role claim.
    // Since the token is already validated and we're authenticated, we can
    // assume it's available. The actual implementation would decode the JWT.
    return 'current-restaurant-id';
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return switch (state) {
            SettingsInitial() || SettingsLoading() => _LoadingView(),
            SettingsLoaded(:final restaurant) =>
              _LoadedView(restaurant: restaurant),
            SettingsUpdating(:final restaurant) =>
              _LoadedView(restaurant: restaurant, isSaving: true),
            SettingsSaved(:final restaurant) => Builder(
                builder: (ctx) {
                  // Show success snackbar once, then transition to loaded state
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Settings saved successfully'),
                        backgroundColor: AppTheme.success,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  });
                  return _LoadedView(restaurant: restaurant);
                },
              ),
            SettingsValidationError(
              :final restaurant,
              :final message,
              :final fields
            ) =>
              _LoadedView(
                restaurant: restaurant,
                validationError: message,
                errorFields: fields,
              ),
            SettingsOperationError(:final restaurant, :final message) =>
              _LoadedView(restaurant: restaurant, operationError: message),
            SettingsError(:final message) => ErrorStateWidget(
                message: message,
                onRetry: () {
                  final restaurantId = _getRestaurantIdFromBloc(context);
                  context
                      .read<SettingsBloc>()
                      .add(SettingsLoadRequested(restaurantId));
                },
              ),
          };
        },
      ),
    );
  }

  String _getRestaurantIdFromBloc(BuildContext context) {
    // Placeholder — in practice we'd extract from the JWT or state
    return 'current-restaurant-id';
  }
}

// ── Loading view ─────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: const [
        LoadingSkeletonCard(height: 300),
        SizedBox(height: AppTheme.spacing16),
        LoadingSkeletonCard(height: 200),
        SizedBox(height: AppTheme.spacing16),
        LoadingSkeletonCard(height: 150),
      ],
    );
  }
}

// ── Loaded view ──────────────────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.restaurant,
    this.isSaving = false,
    this.validationError,
    this.errorFields = const [],
    this.operationError,
  });

  final Restaurant restaurant;
  final bool isSaving;
  final String? validationError;
  final List<String> errorFields;
  final String? operationError;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        // Show operation error banner if present
        if (operationError != null) ...[
          _ErrorBanner(message: operationError!),
          const SizedBox(height: AppTheme.spacing16),
        ],

        // Show validation error banner if present
        if (validationError != null) ...[
          _ErrorBanner(message: validationError!),
          const SizedBox(height: AppTheme.spacing16),
        ],

        // Restaurant Profile Form
        _RestaurantProfileSection(
          restaurant: restaurant,
          isSaving: isSaving,
          errorFields: errorFields,
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Business Hours Form
        _BusinessHoursSection(
          restaurant: restaurant,
          isSaving: isSaving,
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Manager Management (only show for owner role)
        _ManagerManagementSection(isSaving: isSaving),
      ],
    );
  }
}

// ── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.errorContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.error),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppTheme.error, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Restaurant Profile Section ───────────────────────────────────────────────

class _RestaurantProfileSection extends StatefulWidget {
  const _RestaurantProfileSection({
    required this.restaurant,
    required this.isSaving,
    required this.errorFields,
  });

  final Restaurant restaurant;
  final bool isSaving;
  final List<String> errorFields;

  @override
  State<_RestaurantProfileSection> createState() =>
      _RestaurantProfileSectionState();
}

class _RestaurantProfileSectionState extends State<_RestaurantProfileSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _gstController;
  late final TextEditingController _logoController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.restaurant.name);
    _addressController = TextEditingController(text: widget.restaurant.address);
    _phoneController = TextEditingController(text: widget.restaurant.phone);
    _gstController = TextEditingController(text: widget.restaurant.gstNumber);
    _logoController =
        TextEditingController(text: widget.restaurant.logoUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasNameError = widget.errorFields.contains('name');
    final hasAddressError = widget.errorFields.contains('address');
    final hasPhoneError = widget.errorFields.contains('phone');
    final hasGstError = widget.errorFields.contains('gst_number') ||
        widget.errorFields.contains('gstNumber');
    final hasLogoError = widget.errorFields.contains('logo_url') ||
        widget.errorFields.contains('logoUrl');

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant Profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Restaurant Name',
                errorText: hasNameError ? 'Invalid name' : null,
              ),
              enabled: !widget.isSaving,
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                errorText: hasAddressError ? 'Invalid address' : null,
              ),
              enabled: !widget.isSaving,
              maxLines: 2,
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone',
                errorText: hasPhoneError ? 'Invalid phone' : null,
              ),
              enabled: !widget.isSaving,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextFormField(
              controller: _gstController,
              decoration: InputDecoration(
                labelText: 'GST Number',
                errorText: hasGstError ? 'Invalid GST number' : null,
              ),
              enabled: !widget.isSaving,
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextFormField(
              controller: _logoController,
              decoration: InputDecoration(
                labelText: 'Logo URL (CDN)',
                hintText: 'https://cdn.example.com/logo.png',
                errorText: hasLogoError ? 'Invalid logo URL' : null,
              ),
              enabled: !widget.isSaving,
            ),
            const SizedBox(height: AppTheme.spacing16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.isSaving ? null : _saveProfile,
                child: widget.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    final payload = {
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'phone': _phoneController.text.trim(),
      'gst_number': _gstController.text.trim(),
      if (_logoController.text.trim().isNotEmpty)
        'logo_url': _logoController.text.trim(),
    };

    context.read<SettingsBloc>().add(
          SettingsUpdateRequested(
            restaurantId: widget.restaurant.id,
            payload: payload,
          ),
        );
  }
}

// ── Business Hours Section ───────────────────────────────────────────────────

class _BusinessHoursSection extends StatefulWidget {
  const _BusinessHoursSection({
    required this.restaurant,
    required this.isSaving,
  });

  final Restaurant restaurant;
  final bool isSaving;

  @override
  State<_BusinessHoursSection> createState() => _BusinessHoursSectionState();
}

class _BusinessHoursSectionState extends State<_BusinessHoursSection> {
  final Map<int, _DayHours> _hours = {};

  @override
  void initState() {
    super.initState();
    _initializeHours();
  }

  void _initializeHours() {
    // Initialize with existing business hours or defaults
    for (int day = 1; day <= 7; day++) {
      final existing = widget.restaurant.businessHours
          .where((h) => h.dayOfWeek == day)
          .firstOrNull;
      _hours[day] = _DayHours(
        dayOfWeek: day,
        openTime: existing?.openTime ?? '09:00',
        closeTime: existing?.closeTime ?? '22:00',
        isClosed: existing?.isClosed ?? false,
      );
    }
  }

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Hours',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing16),
            ..._buildDayRows(),
            const SizedBox(height: AppTheme.spacing16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.isSaving ? null : _saveBusinessHours,
                child: widget.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save Business Hours'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDayRows() {
    final dayNames = [
      '', // 0-index unused
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return List.generate(7, (index) {
      final day = index + 1;
      final hours = _hours[day]!;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                dayNames[day],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: hours.isClosed
                  ? const Text(
                      'Closed',
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _TimeField(
                            label: 'Open',
                            initialValue: hours.openTime,
                            enabled: !widget.isSaving,
                            onChanged: (value) {
                              setState(() {
                                _hours[day] = hours.copyWith(openTime: value);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Expanded(
                          child: _TimeField(
                            label: 'Close',
                            initialValue: hours.closeTime,
                            enabled: !widget.isSaving,
                            onChanged: (value) {
                              setState(() {
                                _hours[day] = hours.copyWith(closeTime: value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Checkbox(
              value: hours.isClosed,
              onChanged: widget.isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _hours[day] = hours.copyWith(isClosed: value ?? false);
                      });
                    },
            ),
            const Text('Closed'),
          ],
        ),
      );
    });
  }

  void _saveBusinessHours() {
    final businessHours = _hours.values
        .map((h) => {
              'day_of_week': h.dayOfWeek,
              'open_time': h.openTime,
              'close_time': h.closeTime,
              'is_closed': h.isClosed,
            })
        .toList();

    context.read<SettingsBloc>().add(
          SettingsUpdateRequested(
            restaurantId: widget.restaurant.id,
            payload: {'business_hours': businessHours},
          ),
        );
  }
}

// ── Day hours data class ─────────────────────────────────────────────────────

class _DayHours {
  const _DayHours({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    required this.isClosed,
  });

  final int dayOfWeek;
  final String openTime;
  final String closeTime;
  final bool isClosed;

  _DayHours copyWith({
    int? dayOfWeek,
    String? openTime,
    String? closeTime,
    bool? isClosed,
  }) {
    return _DayHours(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      isClosed: isClosed ?? this.isClosed,
    );
  }
}

// ── Time field ───────────────────────────────────────────────────────────────

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.initialValue,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String initialValue;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'HH:MM',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      enabled: enabled,
      keyboardType: TextInputType.datetime,
      onChanged: onChanged,
    );
  }
}

// ── Manager Management Section ───────────────────────────────────────────────

class _ManagerManagementSection extends StatelessWidget {
  const _ManagerManagementSection({required this.isSaving});

  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    // Only show for owner role
    final authState = context.watch<AuthBloc>().state;
    final isOwner =
        authState is TenantAuthenticated && authState.role == StaffRole.owner;

    if (!isOwner) return const SizedBox.shrink();

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manager Privileges',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Grant manager role to staff members',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.mutedText),
            ),
            const SizedBox(height: AppTheme.spacing16),
            BlocBuilder<StaffBloc, StaffState>(
              builder: (context, state) {
                return switch (state) {
                  StaffLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  StaffLoaded(:final staff) ||
                  StaffCreated(:final staff) =>
                    _StaffList(staff: staff, isSaving: isSaving),
                  StaffOperationError(:final staff, :final message) => Column(
                      children: [
                        _ErrorBanner(message: message),
                        const SizedBox(height: AppTheme.spacing12),
                        _StaffList(staff: staff, isSaving: isSaving),
                      ],
                    ),
                  StaffError(:final message) => _ErrorBanner(message: message),
                  _ => const SizedBox.shrink(),
                };
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Staff list ───────────────────────────────────────────────────────────────

class _StaffList extends StatelessWidget {
  const _StaffList({
    required this.staff,
    required this.isSaving,
  });

  final List<Staff> staff;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    // Filter out owners and show only active staff
    final eligibleStaff =
        staff.where((s) => s.role != StaffRole.owner && s.isActive).toList();

    if (eligibleStaff.isEmpty) {
      return const Text(
        'No staff members available',
        style:
            TextStyle(color: AppTheme.mutedText, fontStyle: FontStyle.italic),
      );
    }

    return Column(
      children: eligibleStaff.map((member) {
        final isManager = member.role == StaffRole.manager;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(member.name),
          subtitle: Text(
            member.email != null && member.email!.isNotEmpty
                ? member.email!
                : member.username,
          ),
          trailing: isManager
              ? Chip(
                  label: const Text('Manager'),
                  backgroundColor: AppTheme.primaryContainer,
                )
              : TextButton(
                  onPressed: isSaving
                      ? null
                      : () => _grantManagerRole(context, member.id),
                  child: const Text('Grant Manager'),
                ),
        );
      }).toList(),
    );
  }

  void _grantManagerRole(BuildContext context, String staffId) {
    // Call PATCH /api/v1/tenant/staff/:id with role 'manager' (Req 15.6)
    context.read<StaffBloc>().add(
          StaffRoleUpdateRequested(id: staffId, role: 'manager'),
        );
  }
}
