// Feature: rms-flutter-frontend
// Implements: Requirements 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7, 12.8, 12.9, 12.10

import 'package:auth/auth.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart' hide Table;
import 'package:staff_portal/staff/staff_bloc.dart';
import 'package:staff_portal/staff/staff_repository.dart';

/// Staff Management screen.
///
/// Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7, 12.8, 12.9, 12.10
class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffBloc>(
      create: (ctx) =>
          StaffBloc(repository: ctx.read())..add(const StaffListRequested()),
      child: const _StaffView(),
    );
  }
}

// ── Main view ─────────────────────────────────────────────────────────────────

class _StaffView extends StatefulWidget {
  const _StaffView();

  @override
  State<_StaffView> createState() => _StaffViewState();
}

class _StaffViewState extends State<_StaffView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// Cache the last loaded staff list so the Staff tab stays populated even
  /// when the BLoC transitions to StaffShiftsLoaded.
  List<Staff> _cachedStaff = [];

  /// Cache the last loaded shifts list so the Shifts tab stays populated even
  /// when the BLoC transitions to StaffLoaded.
  List<StaffShift> _cachedShifts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      // Shifts tab selected — dispatch StaffShiftsRequested (Req 12.10)
      context.read<StaffBloc>().add(const StaffShiftsRequested());
    } else {
      context.read<StaffBloc>().add(const StaffListRequested());
    }
  }

  /// Returns true when the current user is owner or manager (Req 12.9).
  bool _canManage(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is TenantAuthenticated) {
      return authState.role == StaffRole.owner ||
          authState.role == StaffRole.manager;
    }
    return false;
  }

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<StaffBloc>(),
        child: _InviteStaffSheet(parentContext: context),
      ),
    );
  }

  void _showAddShiftSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<StaffBloc>(),
        child: _ShiftFormSheetWithStaffPicker(
          staff: _cachedStaff,
          initialDate: DateTime.now(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage = _canManage(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              if (_tabController.index == 0) {
                context.read<StaffBloc>().add(const StaffListRequested());
              } else {
                context.read<StaffBloc>().add(const StaffShiftsRequested());
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.onPrimary,
          unselectedLabelColor: AppTheme.onPrimary.withValues(alpha: 0.65),
          indicatorColor: AppTheme.onPrimary,
          tabs: const [
            Tab(text: 'Staff'),
            Tab(text: 'Shifts'),
          ],
        ),
      ),
      floatingActionButton: BlocBuilder<StaffBloc, StaffState>(
        builder: (context, state) {
          if (_tabController.index == 0 && canManage) {
            return FloatingActionButton.extended(
              onPressed: () => _showInviteSheet(context),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Invite Staff'),
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
            );
          } else if (_tabController.index == 1 && canManage) {
            // Add shift button for Shifts tab
            return FloatingActionButton.extended(
              onPressed: () => _showAddShiftSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Shift'),
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: BlocConsumer<StaffBloc, StaffState>(
        listener: (context, state) {
          if (state is StaffLoaded ||
              state is StaffInviteSent ||
              state is StaffOperationError) {
            // Cache staff list whenever we get it
            if (state is StaffLoaded) _cachedStaff = state.staff;
            if (state is StaffInviteSent) _cachedStaff = state.staff;
            if (state is StaffOperationError) _cachedStaff = state.staff;
          }
          if (state is StaffShiftsLoaded) {
            _cachedShifts = state.shifts;
          }
          // Show success snackbar after invite (Req 12.3)
          if (state is StaffInviteSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invitation sent successfully.'),
                backgroundColor: AppTheme.success,
              ),
            );
          }
          // Show error snackbar for operation errors (Req 12.8)
          if (state is StaffOperationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          // Update caches from current state synchronously
          if (state is StaffLoaded) _cachedStaff = state.staff;
          if (state is StaffInviteSent) _cachedStaff = state.staff;
          if (state is StaffOperationError) _cachedStaff = state.staff;
          if (state is StaffShiftsLoaded) _cachedShifts = state.shifts;

          return TabBarView(
            controller: _tabController,
            children: [
              // ── Tab 0: Staff list ──────────────────────────────────────────
              _buildStaffTab(context, state, canManage),
              // ── Tab 1: Shift scheduling (Req 12.10) ───────────────────────
              _buildShiftsTab(context, state, canManage),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStaffTab(
      BuildContext context, StaffState state, bool canManage) {
    return switch (state) {
      StaffInitial() || StaffLoading() => _LoadingView(),
      StaffLoaded(:final staff) ||
      StaffInviteSent(:final staff) ||
      StaffOperationError(:final staff) =>
        _StaffListView(staff: staff, canManage: canManage),
      StaffError(:final message) => ErrorStateWidget(
          message: message,
          onRetry: () =>
              context.read<StaffBloc>().add(const StaffListRequested()),
        ),
      StaffShiftsLoaded() => _cachedStaff.isEmpty
          ? _LoadingView()
          : _StaffListView(staff: _cachedStaff, canManage: canManage),
    };
  }

  Widget _buildShiftsTab(
      BuildContext context, StaffState state, bool canManage) {
    return switch (state) {
      StaffShiftsLoaded(:final shifts) =>
        _ShiftSchedulingView(shifts: shifts, staff: _cachedStaff),
      StaffLoading() when _cachedShifts.isEmpty => _LoadingView(),
      StaffError(:final message) => ErrorStateWidget(
          message: message,
          onRetry: () =>
              context.read<StaffBloc>().add(const StaffShiftsRequested()),
        ),
      _ => _cachedShifts.isEmpty && _cachedStaff.isEmpty
          ? _LoadingView()
          : _ShiftSchedulingView(shifts: _cachedShifts, staff: _cachedStaff),
    };
  }
}

// ── Loading — skeleton placeholders ──────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: const [
        LoadingSkeletonCard(height: 72),
        SizedBox(height: AppTheme.spacing8),
        LoadingSkeletonCard(height: 72),
        SizedBox(height: AppTheme.spacing8),
        LoadingSkeletonCard(height: 72),
      ],
    );
  }
}

// ── Staff list ─────────────────────────────────────────────────────────────────

class _StaffListView extends StatelessWidget {
  const _StaffListView({required this.staff, required this.canManage});

  final List<Staff> staff;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline,
                  size: 48, color: AppTheme.mutedText),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'No staff members yet.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.mutedText),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: staff.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing8),
      itemBuilder: (context, index) => _StaffTile(
        member: staff[index],
        canManage: canManage,
      ),
    );
  }
}

// ── Staff tile ─────────────────────────────────────────────────────────────────

class _StaffTile extends StatelessWidget {
  const _StaffTile({required this.member, required this.canManage});

  final Staff member;
  final bool canManage;

  Future<void> _onEditRole(BuildContext context) async {
    final bloc = context.read<StaffBloc>();
    StaffRole? selected = member.role;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Edit Role — ${member.name}'),
          content: DropdownButtonFormField<StaffRole>(
            initialValue: selected,
            decoration: const InputDecoration(labelText: 'Role'),
            items: StaffRole.values
                .map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text(_roleLabel(r)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => selected = v);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    if ((confirmed ?? false) && selected != null && selected != member.role) {
      bloc.add(StaffRoleUpdateRequested(
        id: member.id,
        role: selected!.jsonValue,
      ));
    }
  }

  Future<void> _onDeactivate(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Deactivate Staff',
      message:
          'Are you sure you want to deactivate ${member.name}? They will lose access to the portal.',
      confirmLabel: 'Deactivate',
    );
    if (confirmed) {
      // ignore: use_build_context_synchronously
      context.read<StaffBloc>().add(StaffDeactivateRequested(member.id));
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing12,
        ),
        child: Row(
          children: [
            // Avatar circle
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.forRole(member.role.jsonValue)
                  .withValues(alpha: 0.15),
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: AppColors.forRole(member.role.jsonValue),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            // Name, email, badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.email,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.mutedText),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Row(
                    children: [
                      _RoleBadge(role: member.role),
                      const SizedBox(width: AppTheme.spacing8),
                      _StatusChip(isActive: member.isActive),
                    ],
                  ),
                ],
              ),
            ),
            // Management actions — only for owner/manager (Req 12.9)
            if (canManage) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit Role',
                color: AppTheme.primary,
                onPressed: () => _onEditRole(context),
              ),
              if (member.isActive)
                IconButton(
                  icon: const Icon(Icons.person_off_outlined, size: 20),
                  tooltip: 'Deactivate',
                  color: AppTheme.warning,
                  onPressed: () => _onDeactivate(context),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Role badge chip ────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final StaffRole role;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forRole(role.jsonValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
      ),
      child: Text(
        _roleLabel(role),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Active/inactive status chip ────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.success : AppTheme.mutedText;
    final label = isActive ? 'Active' : 'Inactive';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Invite Staff bottom sheet ──────────────────────────────────────────────────

class _InviteStaffSheet extends StatefulWidget {
  const _InviteStaffSheet({required this.parentContext});

  /// The parent screen context, used to show the success SnackBar after the
  /// sheet closes (Req 12.3).
  final BuildContext parentContext;

  @override
  State<_InviteStaffSheet> createState() => _InviteStaffSheetState();
}

class _InviteStaffSheetState extends State<_InviteStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  StaffRole _selectedRole = StaffRole.waiter;
  String? _serverError;

  // Roles that can be invited (Req 12.3) — not owner/manager
  static const _invitableRoles = [
    StaffRole.waiter,
    StaffRole.chef,
    StaffRole.cashier,
    StaffRole.deliveryStaff,
  ];

  static final _emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<StaffBloc>().add(
          StaffInviteRequested(
            email: _emailController.text.trim(),
            role: _selectedRole.jsonValue,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StaffBloc, StaffState>(
      listener: (context, state) {
        if (state is StaffInviteSent) {
          // Close the sheet — the parent listener shows the success SnackBar
          Navigator.of(context).pop();
        }
        if (state is StaffOperationError) {
          // Show inline error while form is open (Req 12.5)
          setState(() => _serverError = state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is StaffLoading;

        return Padding(
          padding: EdgeInsets.only(
            left: AppTheme.spacing24,
            right: AppTheme.spacing24,
            top: AppTheme.spacing24,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Invite Staff Member',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Email field (Req 12.4 — validate before HTTP call)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    hintText: 'staff@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!_emailRegExp.hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Role dropdown
                DropdownButtonFormField<StaffRole>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: _invitableRoles
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(_roleLabel(r)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedRole = v);
                  },
                  validator: (v) => v == null ? 'Please select a role' : null,
                ),

                // Server-side error (Req 12.5)
                if (_serverError != null) ...[
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    _serverError!,
                    style: const TextStyle(
                      color: AppTheme.error,
                      fontSize: 13,
                    ),
                  ),
                ],

                const SizedBox(height: AppTheme.spacing24),

                // Submit button
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.onPrimary,
                          ),
                        )
                      : const Text('Send Invitation'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Human-readable label for a [StaffRole].
String _roleLabel(StaffRole role) {
  switch (role) {
    case StaffRole.owner:
      return 'Owner';
    case StaffRole.manager:
      return 'Manager';
    case StaffRole.waiter:
      return 'Waiter';
    case StaffRole.chef:
      return 'Chef';
    case StaffRole.cashier:
      return 'Cashier';
    case StaffRole.deliveryStaff:
      return 'Delivery Staff';
  }
}

// ── Shift Scheduling view (Req 12.10) ─────────────────────────────────────────

/// Weekly shift calendar showing shifts per staff member for the current week.
///
/// Requirements: 12.10
class _ShiftSchedulingView extends StatefulWidget {
  const _ShiftSchedulingView({
    required this.shifts,
    required this.staff,
  });

  final List<StaffShift> shifts;
  final List<Staff> staff;

  @override
  State<_ShiftSchedulingView> createState() => _ShiftSchedulingViewState();
}

class _ShiftSchedulingViewState extends State<_ShiftSchedulingView> {
  DateTime _currentWeekStart = _getWeekStart(DateTime.now());

  /// Returns the Monday of the week containing [date].
  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  /// Returns dates for the current week (Mon-Sun).
  List<DateTime> _getWeekDates() {
    return List.generate(
      7,
      (i) => _currentWeekStart.add(Duration(days: i)),
    );
  }

  /// Groups shifts by staffId + date.
  Map<String, Map<String, List<StaffShift>>> _groupShifts() {
    final grouped = <String, Map<String, List<StaffShift>>>{};
    for (final shift in widget.shifts) {
      grouped.putIfAbsent(shift.staffId, () => {});
      grouped[shift.staffId]!.putIfAbsent(shift.shiftDate, () => []);
      grouped[shift.staffId]![shift.shiftDate]!.add(shift);
    }
    return grouped;
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  void _thisWeek() {
    setState(() {
      _currentWeekStart = _getWeekStart(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show empty state if no staff members exist
    if (widget.staff.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline,
                  size: 48, color: AppTheme.mutedText),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'No staff members yet.',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppTheme.mutedText),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                'Invite staff members from the Staff tab first.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.mutedText),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Show shifts calendar
    final weekDates = _getWeekDates();
    final grouped = _groupShifts();
    final now = DateTime.now();
    final isCurrentWeek = _currentWeekStart.isBefore(now) &&
        _currentWeekStart.add(const Duration(days: 7)).isAfter(now);

    return Column(
      children: [
        // Week navigation header
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceVariant,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousWeek,
                tooltip: 'Previous Week',
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_currentWeekStart.day} ${_monthName(_currentWeekStart.month)} - ${weekDates.last.day} ${_monthName(weekDates.last.month)} ${weekDates.last.year}',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (!isCurrentWeek)
                      TextButton.icon(
                        onPressed: _thisWeek,
                        icon: const Icon(Icons.today, size: 16),
                        label: const Text('This Week'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextWeek,
                tooltip: 'Next Week',
              ),
            ],
          ),
        ),

        // Scrollable table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Table(
                  border: TableBorder.all(color: AppTheme.border, width: 0.5),
                  defaultColumnWidth: const FixedColumnWidth(110),
                  columnWidths: const {
                    0: FixedColumnWidth(120), // Staff name column
                  },
                  children: [
                    // Header row with day names and dates
                    TableRow(
                      decoration:
                          const BoxDecoration(color: AppTheme.surfaceVariant),
                      children: [
                        const _HeaderCell(text: 'Staff'),
                        ...weekDates.map((date) => _HeaderCell(
                              text:
                                  '${_dayName(date.weekday)}\n${date.day}/${date.month}',
                            )),
                      ],
                    ),
                    // One row per staff member
                    ...widget.staff.map((member) {
                      final memberShifts = grouped[member.id] ?? {};
                      return TableRow(
                        children: [
                          // Staff name cell
                          Padding(
                            padding: const EdgeInsets.all(AppTheme.spacing8),
                            child: Text(
                              member.name,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // One cell per day with shifts on that date
                          ...weekDates.map((date) {
                            final dateStr =
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                            final dayShifts = memberShifts[dateStr] ?? [];
                            return _ShiftCell(
                              shifts: dayShifts,
                              staffId: member.id,
                              date: date,
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _dayName(int weekday) {
    return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
  }

  static String _monthName(int month) {
    return const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][month - 1];
  }
}

// ── Table header cell ─────────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing8,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Shift cell ────────────────────────────────────────────────────────────────

class _ShiftCell extends StatelessWidget {
  const _ShiftCell({
    required this.shifts,
    required this.staffId,
    required this.date,
  });

  final List<StaffShift> shifts;
  final String staffId;
  final DateTime date;

  void _showAddShiftSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<StaffBloc>(),
        child: _ShiftFormSheet(
          staffId: staffId,
          date: date,
          existingShift: null,
        ),
      ),
    );
  }

  void _showEditShiftSheet(BuildContext context, StaffShift shift) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<StaffBloc>(),
        child: _ShiftFormSheet(
          staffId: staffId,
          date: date,
          existingShift: shift,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cellDate = DateTime(date.year, date.month, date.day);
    final isPast = cellDate.isBefore(today);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing8),
      constraints: const BoxConstraints(minHeight: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Existing shifts
          ...shifts.map((shift) => GestureDetector(
                onTap: () => _showEditShiftSheet(context, shift),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPast
                        ? AppTheme.mutedText.withValues(alpha: 0.2)
                        : AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${shift.startTime}–${shift.endTime}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isPast
                          ? AppTheme.mutedText
                          : AppTheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )),
          // Add button - always visible with better styling
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _showAddShiftSheet(context),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isPast
                      ? AppTheme.mutedText.withValues(alpha: 0.3)
                      : AppTheme.primary.withValues(alpha: 0.5),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.add,
                size: 18,
                color: isPast
                    ? AppTheme.mutedText.withValues(alpha: 0.5)
                    : AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shift form sheet ──────────────────────────────────────────────────────────

/// Bottom sheet for adding or editing a shift entry.
///
/// Requirements: 12.10
class _ShiftFormSheet extends StatefulWidget {
  const _ShiftFormSheet({
    required this.staffId,
    required this.date,
    required this.existingShift,
  });

  final String staffId;
  final DateTime date;
  final StaffShift? existingShift;

  @override
  State<_ShiftFormSheet> createState() => _ShiftFormSheetState();
}

class _ShiftFormSheetState extends State<_ShiftFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  late DateTime _selectedDate;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.existingShift?.date ?? widget.date;
    _startCtrl = TextEditingController(
      text: widget.existingShift?.startTime ?? '',
    );
    _endCtrl = TextEditingController(
      text: widget.existingShift?.endTime ?? '',
    );
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  static final _timeRegExp = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  String? _validateTime(String? value) {
    if (value == null || value.trim().isEmpty) return 'Time is required';
    if (!_timeRegExp.hasMatch(value.trim())) return 'Use HH:MM format (24h)';
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final payload = <String, dynamic>{
      'staff_id': widget.staffId,
      'shift_date': dateStr,
      'start_time': _startCtrl.text.trim(),
      'end_time': _endCtrl.text.trim(),
    };

    // Include id for edits (POST vs PATCH distinction in repository)
    if (widget.existingShift != null) {
      payload['id'] = widget.existingShift!.id;
    }

    context.read<StaffBloc>().add(StaffShiftSaveRequested(payload));

    // Listen for the next state to handle errors
    final subscription = context.read<StaffBloc>().stream.listen((state) {
      if (!mounted) return;

      if (state is StaffShiftsLoaded) {
        // Success - close the sheet
        Navigator.of(context).pop();
      } else if (state is StaffError) {
        // Show error inline
        setState(() {
          _submitting = false;
          _errorMessage = _formatErrorMessage(state.message);
        });
      }
    });

    // Cancel subscription after 5 seconds or when widget is disposed
    Future.delayed(const Duration(seconds: 5), subscription.cancel);
  }

  String _formatErrorMessage(String error) {
    // Parse specific API error codes
    if (error.contains('SHIFT_OVERLAP')) {
      return 'This shift overlaps with an existing shift for this staff member on this date.';
    } else if (error.contains('INVALID_SHIFT_TIMES')) {
      return 'Start time must be before end time.';
    } else if (error.contains('NOT_FOUND')) {
      return 'Staff member not found.';
    }
    return error;
  }

  Future<void> _delete() async {
    if (widget.existingShift == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Shift'),
        content: const Text('Are you sure you want to delete this shift?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context
          .read<StaffBloc>()
          .add(StaffShiftDeleteRequested(widget.existingShift!.id));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingShift != null;

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacing24,
        right: AppTheme.spacing24,
        top: AppTheme.spacing24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Shift' : 'Add Shift',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Row(
                  children: [
                    if (isEdit)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: AppTheme.error,
                        onPressed: _delete,
                        tooltip: 'Delete Shift',
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Date picker
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Time inputs
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startCtrl,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      hintText: '09:00',
                      helperText: '24-hour format',
                    ),
                    validator: _validateTime,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: TextFormField(
                    controller: _endCtrl,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      hintText: '17:00',
                      helperText: '24-hour format',
                    ),
                    validator: _validateTime,
                  ),
                ),
              ],
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: AppTheme.spacing12),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.error, size: 20),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppTheme.spacing24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.onPrimary,
                      ),
                    )
                  : Text(isEdit ? 'Save Changes' : 'Add Shift'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shift form sheet with staff picker ───────────────────────────────────────

/// Bottom sheet for adding a shift with staff member selection.
/// Used when clicking the FAB on Shifts tab (when no specific cell is selected).
class _ShiftFormSheetWithStaffPicker extends StatefulWidget {
  const _ShiftFormSheetWithStaffPicker({
    required this.staff,
    required this.initialDate,
  });

  final List<Staff> staff;
  final DateTime initialDate;

  @override
  State<_ShiftFormSheetWithStaffPicker> createState() =>
      _ShiftFormSheetWithStaffPickerState();
}

class _ShiftFormSheetWithStaffPickerState
    extends State<_ShiftFormSheetWithStaffPicker> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  late DateTime _selectedDate;
  String? _selectedStaffId;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _startCtrl = TextEditingController();
    _endCtrl = TextEditingController();
    // Pre-select first staff member if available
    if (widget.staff.isNotEmpty) {
      _selectedStaffId = widget.staff.first.id;
    }
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  static final _timeRegExp = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  String? _validateTime(String? value) {
    if (value == null || value.trim().isEmpty) return 'Time is required';
    if (!_timeRegExp.hasMatch(value.trim())) return 'Use HH:MM format (24h)';
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedStaffId == null) {
      setState(() => _errorMessage = 'Please select a staff member');
      return;
    }
    setState(() => _submitting = true);

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final payload = <String, dynamic>{
      'staff_id': _selectedStaffId!,
      'shift_date': dateStr,
      'start_time': _startCtrl.text.trim(),
      'end_time': _endCtrl.text.trim(),
    };

    context.read<StaffBloc>().add(StaffShiftSaveRequested(payload));

    // Listen for the next state to handle errors
    final subscription = context.read<StaffBloc>().stream.listen((state) {
      if (!mounted) return;

      if (state is StaffShiftsLoaded) {
        // Success - close the sheet
        Navigator.of(context).pop();
      } else if (state is StaffError) {
        // Show error inline
        setState(() {
          _submitting = false;
          _errorMessage = _formatErrorMessage(state.message);
        });
      }
    });

    // Cancel subscription after 5 seconds or when widget is disposed
    Future.delayed(const Duration(seconds: 5), subscription.cancel);
  }

  String _formatErrorMessage(String error) {
    // Parse specific API error codes
    if (error.contains('SHIFT_OVERLAP')) {
      return 'This shift overlaps with an existing shift for this staff member on this date.';
    } else if (error.contains('INVALID_SHIFT_TIMES')) {
      return 'Start time must be before end time.';
    } else if (error.contains('NOT_FOUND')) {
      return 'Staff member not found.';
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacing24,
        right: AppTheme.spacing24,
        top: AppTheme.spacing24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Shift',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Show message if no staff members
            if (widget.staff.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.warning, size: 20),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: Text(
                        'No staff members available. Invite staff members from the Staff tab first.',
                        style: TextStyle(
                          color: AppTheme.warning.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
            ],

            // Staff member dropdown
            if (widget.staff.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedStaffId,
                decoration: const InputDecoration(
                  labelText: 'Staff Member',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: widget.staff
                    .map(
                      (staff) => DropdownMenuItem(
                        value: staff.id,
                        child: Text(staff.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedStaffId = v);
                },
                validator: (v) =>
                    v == null ? 'Please select a staff member' : null,
              ),
            if (widget.staff.isNotEmpty)
              const SizedBox(height: AppTheme.spacing16),

            // Date picker
            if (widget.staff.isNotEmpty)
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            if (widget.staff.isNotEmpty)
              const SizedBox(height: AppTheme.spacing16),

            // Time inputs
            if (widget.staff.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startCtrl,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        hintText: '09:00',
                        helperText: '24-hour format',
                      ),
                      validator: _validateTime,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: TextFormField(
                      controller: _endCtrl,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        hintText: '17:00',
                        helperText: '24-hour format',
                      ),
                      validator: _validateTime,
                    ),
                  ),
                ],
              ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: AppTheme.spacing12),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.error, size: 20),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppTheme.spacing24),
            FilledButton(
              onPressed: (widget.staff.isEmpty || _submitting) ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.onPrimary,
                      ),
                    )
                  : const Text('Add Shift'),
            ),
          ],
        ),
      ),
    );
  }
}
