import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../design_system/theme/app_border_radius.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_text_styles.dart';
import '../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../design_system/widgets/tables/app_pagination.dart';
import '../../domain/entities/admin_plan_entity.dart';
import '../../domain/entities/admin_subscription_entity.dart';
import '../../domain/entities/admin_vendor_entity.dart';
import '../../domain/usecases/admin_usecases.dart';
import '../cubit/admin_subscriptions_cubit.dart';
import '../cubit/admin_subscriptions_state.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final dt = DateTime.parse(iso);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso.length > 10 ? iso.substring(0, 10) : iso;
  }
}

// ── Page Entry ────────────────────────────────────────────────────────────────

class AdminSubscriptionsPage extends StatelessWidget {
  const AdminSubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminSubscriptionsCubit(
        getSubscriptions: getIt<GetAdminSubscriptionsUseCase>(),
        assignSubscription: getIt<AssignVendorSubscriptionUseCase>(),
        updateSubscription: getIt<UpdateAdminSubscriptionUseCase>(),
      )..load(),
      child: const _SubscriptionsContent(),
    );
  }
}

// ── Main Content ──────────────────────────────────────────────────────────────

class _SubscriptionsContent extends StatelessWidget {
  const _SubscriptionsContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.t('adminSubscriptions'),
                          style: AppTextStyles.h4.copyWith(color: fg)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(l10n.t('adminSubscriptionsSubtitle'),
                          style: AppTextStyles.bodySm.copyWith(color: muted)),
                    ],
                  ),
                ),
                _PrimaryButton(
                  label: l10n.t('newSubscription'),
                  icon: Icons.add_rounded,
                  onTap: () => _showCreateDialog(context, l10n, isDark),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Status filter
            BlocBuilder<AdminSubscriptionsCubit, AdminSubscriptionsState>(
              buildWhen: (p, c) {
                if (p is! AdminSubscriptionsLoaded ||
                    c is! AdminSubscriptionsLoaded) return true;
                return p.statusFilter != c.statusFilter;
              },
              builder: (context, state) {
                final current = state is AdminSubscriptionsLoaded
                    ? state.statusFilter ?? ''
                    : '';
                return _FilterDropdown(
                  value: current,
                  isDark: isDark,
                  items: [
                    ('', l10n.t('allStatuses')),
                    ('active', l10n.t('status_active')),
                    ('trial', l10n.t('status_trial')),
                    ('past_due', l10n.t('status_past_due')),
                    ('cancelled', l10n.t('status_cancelled')),
                    ('suspended', l10n.t('status_suspended')),
                    ('expired', l10n.t('status_expired')),
                  ],
                  onChanged: (v) => context
                      .read<AdminSubscriptionsCubit>()
                      .filterByStatus(v.isEmpty ? null : v),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Table
            Expanded(
              child: BlocConsumer<AdminSubscriptionsCubit, AdminSubscriptionsState>(
                listener: (context, state) {
                  if (state is AdminSubscriptionsLoaded && state.saveSuccess) {
                    AppSnackbar.success(context, l10n.t('saved'));
                  }
                },
                builder: (context, state) {
                  if (state is AdminSubscriptionsLoading) {
                    return Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: AppRadius.brLg,
                        border: Border.all(color: borderColor),
                      ),
                      child: const ShimmerTableRows(rows: 10),
                    );
                  }
                  if (state is AdminSubscriptionsError) {
                    return AppErrorWidget(
                      message: state.message,
                      onRetry: () =>
                          context.read<AdminSubscriptionsCubit>().load(),
                    );
                  }
                  if (state is AdminSubscriptionsLoaded) {
                    if (state.subscriptions.isEmpty) {
                      return AppEmptyState(message: l10n.t('noSubscriptions'));
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: AppRadius.brLg,
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              children: [
                                _TableHeader(
                                  l10n: l10n,
                                  isDark: isDark,
                                  borderColor: borderColor,
                                  muted: muted,
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: state.subscriptions.length,
                                    itemBuilder: (ctx, i) => _SubscriptionRow(
                                      subscription: state.subscriptions[i],
                                      l10n: l10n,
                                      isDark: isDark,
                                      borderColor: borderColor,
                                      fg: fg,
                                      muted: muted,
                                      onEdit: () => _showEditDialog(
                                        context,
                                        l10n,
                                        isDark,
                                        state.subscriptions[i],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: AppPagination(
                            meta: state.meta,
                            onPageChanged: (p) => context
                                .read<AdminSubscriptionsCubit>()
                                .changePage(p),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(
      BuildContext context, AppLocalizations l10n, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminSubscriptionsCubit>(),
        child: _CreateSubscriptionDialog(l10n: l10n, isDark: isDark),
      ),
    );
  }

  void _showEditDialog(
      BuildContext context,
      AppLocalizations l10n,
      bool isDark,
      AdminSubscriptionEntity sub) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminSubscriptionsCubit>(),
        child: _EditSubscriptionDialog(
            l10n: l10n, isDark: isDark, subscription: sub),
      ),
    );
  }
}

// ── Table Header ──────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isDark;
  final Color borderColor;
  final Color muted;

  const _TableHeader({
    required this.l10n,
    required this.isDark,
    required this.borderColor,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkMuted : AppColors.muted;
    final TextStyle s = AppTextStyles.tableHeader.copyWith(color: muted);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(l10n.t('colVendor'), style: s)),
          Expanded(flex: 3, child: Text(l10n.t('colPlan'), style: s)),
          Expanded(flex: 2, child: Text(l10n.t('statusLabel'), style: s)),
          Expanded(flex: 2, child: Text(l10n.t('startsAt'), style: s)),
          Expanded(flex: 2, child: Text(l10n.t('expiresAt'), style: s)),
          SizedBox(
            width: 60,
            child: Text(l10n.t('colActions'),
                textAlign: TextAlign.center, style: s),
          ),
        ],
      ),
    );
  }
}

// ── Table Row ─────────────────────────────────────────────────────────────────

class _SubscriptionRow extends StatelessWidget {
  final AdminSubscriptionEntity subscription;
  final AppLocalizations l10n;
  final bool isDark;
  final Color borderColor;
  final Color fg;
  final Color muted;
  final VoidCallback onEdit;

  const _SubscriptionRow({
    required this.subscription,
    required this.l10n,
    required this.isDark,
    required this.borderColor,
    required this.fg,
    required this.muted,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subscription;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Vendor
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(sub.vendorName,
                    style: AppTextStyles.tableCell.copyWith(
                        color: fg, fontWeight: FontWeight.w500)),
                if (sub.vendorSlug != null)
                  Text(sub.vendorSlug!,
                      style: AppTextStyles.labelXs.copyWith(
                          color: muted, fontFamily: 'monospace')),
              ],
            ),
          ),
          // Plan
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(sub.planName,
                    style: AppTextStyles.tableCell.copyWith(color: fg)),
                Text(AppFormatters.currency(sub.planPrice),
                    style: AppTextStyles.labelXs.copyWith(color: muted)),
              ],
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: _SubStatusBadge(status: sub.status, l10n: l10n),
          ),
          // Starts At
          Expanded(
            flex: 2,
            child: Text(_fmtDate(sub.startsAt),
                style: AppTextStyles.tableCell.copyWith(color: muted)),
          ),
          // Expires At
          Expanded(
            flex: 2,
            child: sub.expiresAt != null
                ? Text(_fmtDate(sub.expiresAt),
                    style: AppTextStyles.tableCell.copyWith(
                      color: sub.isExpired
                          ? AppColors.destructive
                          : muted,
                    ))
                : Text(l10n.t('neverExpires'),
                    style: AppTextStyles.labelXs.copyWith(color: muted)),
          ),
          // Actions
          SizedBox(
            width: 60,
            child: Center(
              child: IconButton(
                icon: Icon(Icons.edit_rounded, size: 16, color: muted),
                tooltip: l10n.t('edit'),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _SubStatusBadge extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;
  const _SubStatusBadge({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    final mutedBg = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkMuted
        : AppColors.muted;

    final (color, bg) = switch (status) {
      'active' => (AppColors.statusPaid, AppColors.statusPaidBg),
      'trial' => (AppColors.primary, AppColors.primaryLight),
      'past_due' => (AppColors.warning, AppColors.warningLight),
      'cancelled' || 'expired' =>
        (AppColors.statusCancelled, AppColors.statusCancelledBg),
      'suspended' => (muted, mutedBg),
      _ => (AppColors.statusPending, AppColors.statusPendingBg),
    };
    final label = l10n.t('status_$status');
    return StatusBadge(
        label: label.startsWith('status_') ? status : label,
        color: color,
        bgColor: bg);
  }
}

// ── Filter Dropdown ───────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: fg),
          style: AppTextStyles.labelSm.copyWith(color: fg),
          dropdownColor: bg,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item.$1,
                    child: Text(item.$2,
                        style: AppTextStyles.labelSm.copyWith(color: fg)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Primary Button ────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: AppRadius.brMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: AppSpacing.xs),
            Text(label,
                style: AppTextStyles.labelSm.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ── Create Subscription Dialog ────────────────────────────────────────────────

class _CreateSubscriptionDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final bool isDark;
  const _CreateSubscriptionDialog({required this.l10n, required this.isDark});

  @override
  State<_CreateSubscriptionDialog> createState() =>
      _CreateSubscriptionDialogState();
}

class _CreateSubscriptionDialogState
    extends State<_CreateSubscriptionDialog> {
  final _startsAt = TextEditingController();
  final _expiresAt = TextEditingController();
  final _notes = TextEditingController();
  String _vendorId = '';
  String _planId = '';
  String _status = 'active';
  bool _saving = false;
  String? _error;
  List<AdminVendorEntity> _vendors = [];
  List<AdminPlanEntity> _plans = [];
  bool _loadingVendors = true;
  bool _loadingPlans = true;

  @override
  void initState() {
    super.initState();
    _startsAt.text = _todayStr();
    _loadVendors();
    _loadPlans();
  }

  @override
  void dispose() {
    _startsAt.dispose();
    _expiresAt.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadVendors() async {
    final result = await getIt<GetAdminVendorsUseCase>()(perPage: 200);
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _loadingVendors = false),
      (resp) => setState(() {
        _vendors = resp.data;
        _loadingVendors = false;
      }),
    );
  }

  Future<void> _loadPlans() async {
    final result = await getIt<GetAdminPlansUseCase>()();
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _loadingPlans = false),
      (plans) => setState(() {
        _plans = plans.where((p) => p.isActive).toList();
        _loadingPlans = false;
      }),
    );
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (_vendorId.isEmpty || _planId.isEmpty || _startsAt.text.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await context.read<AdminSubscriptionsCubit>().createSubscription(
      _vendorId,
      {
        'plan_id': _planId,
        'status': _status,
        'starts_at': _startsAt.text,
        if (_expiresAt.text.isNotEmpty) 'expires_at': _expiresAt.text,
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      },
    );
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(context, widget.l10n.t('subscriptionCreated'));
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = widget.l10n.t('errorSaving');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isDark = widget.isDark;
    return _SubscriptionDialogShell(
      title: l10n.t('createSubscription'),
      isDark: isDark,
      error: _error,
      saving: _saving,
      submitLabel: l10n.t('createSubscription'),
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: _submit,
      body: _buildBody(l10n, isDark),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool isDark) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vendor
        _FormLabel(label: l10n.t('colVendor'), fg: fg),
        const SizedBox(height: AppSpacing.xs),
        _loadingVendors
            ? const LinearProgressIndicator(minHeight: 36)
            : _EntityDropdown<AdminVendorEntity>(
                value: _vendorId,
                isDark: isDark,
                placeholder: l10n.t('selectVendorPlaceholder'),
                items: _vendors,
                getId: (v) => v.id,
                getLabel: (v) => v.name,
                onChanged: (v) => setState(() => _vendorId = v),
              ),
        const SizedBox(height: AppSpacing.md),

        // Plan
        _FormLabel(label: l10n.t('colPlan'), fg: fg),
        const SizedBox(height: AppSpacing.xs),
        _loadingPlans
            ? const LinearProgressIndicator(minHeight: 36)
            : _EntityDropdown<AdminPlanEntity>(
                value: _planId,
                isDark: isDark,
                placeholder: l10n.t('selectPlan'),
                items: _plans,
                getId: (p) => p.id,
                getLabel: (p) =>
                    '${p.name} — ${AppFormatters.currency(p.price)}',
                onChanged: (v) => setState(() => _planId = v),
              ),
        const SizedBox(height: AppSpacing.md),

        // Status
        _FormLabel(label: l10n.t('statusLabel'), fg: fg),
        const SizedBox(height: AppSpacing.xs),
        _SelectField(
          value: _status,
          isDark: isDark,
          items: [
            ('active', l10n.t('status_active')),
            ('trial', l10n.t('status_trial')),
            ('past_due', l10n.t('status_past_due')),
          ],
          onChanged: (v) => setState(() => _status = v),
        ),
        const SizedBox(height: AppSpacing.md),

        // Starts At / Expires At
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormLabel(label: l10n.t('startsAt'), fg: fg),
                  const SizedBox(height: AppSpacing.xs),
                  _DateField(
                    controller: _startsAt,
                    isDark: isDark,
                    placeholder: l10n.t('selectDate'),
                    onTap: () => _pickDate(_startsAt),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormLabel(
                      label: '${l10n.t('expiresAt')} (optional)',
                      fg: fg),
                  const SizedBox(height: AppSpacing.xs),
                  _DateField(
                    controller: _expiresAt,
                    isDark: isDark,
                    placeholder: l10n.t('neverExpires'),
                    onTap: () => _pickDate(_expiresAt),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Notes
        _FormLabel(label: l10n.t('notes'), fg: fg),
        const SizedBox(height: AppSpacing.xs),
        _TextAreaField(
          controller: _notes,
          isDark: isDark,
          hint: l10n.t('optionalPlaceholder'),
        ),
      ],
    );
  }
}

// ── Edit Subscription Dialog ──────────────────────────────────────────────────

class _EditSubscriptionDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final bool isDark;
  final AdminSubscriptionEntity subscription;

  const _EditSubscriptionDialog({
    required this.l10n,
    required this.isDark,
    required this.subscription,
  });

  @override
  State<_EditSubscriptionDialog> createState() =>
      _EditSubscriptionDialogState();
}

class _EditSubscriptionDialogState extends State<_EditSubscriptionDialog> {
  final _startsAt = TextEditingController();
  final _expiresAt = TextEditingController();
  final _notes = TextEditingController();
  late String _planId;
  late String _status;
  bool _saving = false;
  String? _error;
  List<AdminPlanEntity> _plans = [];
  bool _loadingPlans = true;

  @override
  void initState() {
    super.initState();
    final sub = widget.subscription;
    _planId = sub.planId;
    _status = sub.status;
    _startsAt.text = _fmtDate(sub.startsAt);
    _expiresAt.text = sub.expiresAt != null ? _fmtDate(sub.expiresAt) : '';
    _notes.text = sub.notes ?? '';
    _loadPlans();
  }

  @override
  void dispose() {
    _startsAt.dispose();
    _expiresAt.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    final result = await getIt<GetAdminPlansUseCase>()();
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _loadingPlans = false),
      (plans) => setState(() {
        _plans = plans;
        _loadingPlans = false;
      }),
    );
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(ctrl.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await context
        .read<AdminSubscriptionsCubit>()
        .updateSubscription(widget.subscription.id, {
      'plan_id': _planId,
      'status': _status,
      'starts_at': _startsAt.text,
      'expires_at': _expiresAt.text.isNotEmpty ? _expiresAt.text : null,
      'notes': _notes.text.trim().isNotEmpty ? _notes.text.trim() : null,
    });
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(context, widget.l10n.t('subscriptionUpdated'));
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = widget.l10n.t('errorSaving');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isDark = widget.isDark;
    return _SubscriptionDialogShell(
      title: l10n.t('editSubscription'),
      isDark: isDark,
      error: _error,
      saving: _saving,
      submitLabel: l10n.t('save'),
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: _submit,
      body: _buildBody(l10n, isDark),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool isDark) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final sub = widget.subscription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vendor (read-only)
        _FormLabel(label: l10n.t('colVendor'), fg: fg),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkMuted : AppColors.muted,
            borderRadius: AppRadius.brMd,
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              sub.vendorSlug != null
                  ? '${sub.vendorName} (${sub.vendorSlug})'
                  : sub.vendorName,
              style: AppTextStyles.labelSm.copyWith(color: muted),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Plan
        _FormLabel(label: l10n.t('colPlan'), fg: fg),
        const SizedBox(height: AppSpacing.xs),
        _loadingPlans
            ? const LinearProgressIndicator(minHeight: 36)
            : _EntityDropdown<AdminPlanEntity>(
                value: _planId,
                isDark: isDark,
                placeholder: l10n.t('selectPlan'),
                items: _plans,
                getId: (p) => p.id,
                getLabel: (p) =>
                    '${p.name} — ${AppFormatters.currency(p.price)}',
                onChanged: (v) => setState(() => _planId = v),
              ),
        const SizedBox(height: AppSpacing.md),

        // Status — all statuses allowed on edit
        _FormLabel(label: l10n.t('statusLabel'), fg: fg),
        const SizedBox(height: AppSpacing.xs),
        _SelectField(
          value: _status,
          isDark: isDark,
          items: [
            ('active', l10n.t('status_active')),
            ('trial', l10n.t('status_trial')),
            ('past_due', l10n.t('status_past_due')),
            ('cancelled', l10n.t('status_cancelled')),
            ('suspended', l10n.t('status_suspended')),
            ('expired', l10n.t('status_expired')),
          ],
          onChanged: (v) => setState(() => _status = v),
        ),
        const SizedBox(height: AppSpacing.md),

        // Starts At / Expires At
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormLabel(label: l10n.t('startsAt'), fg: fg),
                  const SizedBox(height: AppSpacing.xs),
                  _DateField(
                    controller: _startsAt,
                    isDark: isDark,
                    placeholder: l10n.t('selectDate'),
                    onTap: () => _pickDate(_startsAt),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormLabel(
                      label: '${l10n.t('expiresAt')} (optional)',
                      fg: fg),
                  const SizedBox(height: AppSpacing.xs),
                  _DateField(
                    controller: _expiresAt,
                    isDark: isDark,
                    placeholder: l10n.t('neverExpires'),
                    onTap: () => _pickDate(_expiresAt),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Notes
        _FormLabel(label: l10n.t('notes'), fg: fg),
        const SizedBox(height: AppSpacing.xs),
        _TextAreaField(
          controller: _notes,
          isDark: isDark,
          hint: l10n.t('optionalPlaceholder'),
        ),
      ],
    );
  }
}

// ── Dialog Shell ──────────────────────────────────────────────────────────────

class _SubscriptionDialogShell extends StatelessWidget {
  final String title;
  final bool isDark;
  final String? error;
  final bool saving;
  final String submitLabel;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final Widget body;

  const _SubscriptionDialogShell({
    required this.title,
    required this.isDark,
    this.error,
    required this.saving,
    required this.submitLabel,
    required this.onCancel,
    required this.onSubmit,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: borderColor),
      ),
      child: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                      child: Text(title,
                          style: AppTextStyles.h5.copyWith(color: fg))),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: onCancel,
                    color: muted,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Divider(color: borderColor, height: 1),

            // Body
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.destructiveLight,
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Text(error!,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.destructive)),
                    ),
                  body,
                ],
              ),
            ),

            Divider(color: borderColor, height: 1),
            // Footer
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: Text(AppLocalizations.of(context).t('cancel'),
                        style: AppTextStyles.labelSm.copyWith(color: muted)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  InkWell(
                    onTap: saving ? null : onSubmit,
                    borderRadius: AppRadius.brMd,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: saving
                            ? cs.primary.withValues(alpha: 0.6)
                            : cs.primary,
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (saving)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          else
                            const Icon(Icons.check_rounded,
                                size: 14, color: Colors.white),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            saving
                                ? AppLocalizations.of(context).t('saving')
                                : submitLabel,
                            style: AppTextStyles.labelSm
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Form Widgets ───────────────────────────────────────────────────────

class _FormLabel extends StatelessWidget {
  final String label;
  final Color fg;

  const _FormLabel({required this.label, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: AppTextStyles.labelSm
            .copyWith(color: fg, fontWeight: FontWeight.w500));
  }
}

class _TextAreaField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;

  const _TextAreaField(
      {required this.controller, required this.hint, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkMuted : AppColors.muted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return TextField(
      controller: controller,
      maxLines: 2,
      style: AppTextStyles.labelSm.copyWith(color: fg),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.labelSm.copyWith(color: muted),
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        border: OutlineInputBorder(
            borderRadius: AppRadius.brMd,
            borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.brMd,
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.brMd,
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primary)),
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  final String value;
  final bool isDark;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;

  const _SelectField(
      {required this.value,
      required this.isDark,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkMuted : AppColors.muted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: borderColor)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: fg),
          style: AppTextStyles.labelSm.copyWith(color: fg),
          dropdownColor: bg,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item.$1,
                    child: Text(item.$2,
                        style: AppTextStyles.labelSm.copyWith(color: fg)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final String placeholder;
  final VoidCallback onTap;

  const _DateField(
      {required this.controller,
      required this.isDark,
      required this.placeholder,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkMuted : AppColors.muted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 14, color: muted),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, val, __) => Text(
                  val.text.isEmpty ? placeholder : val.text,
                  style: AppTextStyles.labelSm.copyWith(
                    color: val.text.isEmpty ? muted : fg,
                  ),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () => controller.clear(),
                child: Icon(Icons.close_rounded, size: 14, color: muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _EntityDropdown<T> extends StatelessWidget {
  final String value;
  final bool isDark;
  final String placeholder;
  final List<T> items;
  final String Function(T) getId;
  final String Function(T) getLabel;
  final ValueChanged<String> onChanged;

  const _EntityDropdown({
    required this.value,
    required this.isDark,
    required this.placeholder,
    required this.items,
    required this.getId,
    required this.getLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkMuted : AppColors.muted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: borderColor)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          isDense: true,
          isExpanded: true,
          hint: Text(placeholder,
              style: AppTextStyles.labelSm.copyWith(color: muted)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: fg),
          style: AppTextStyles.labelSm.copyWith(color: fg),
          dropdownColor: bg,
          items: items
              .map((item) => DropdownMenuItem(
                    value: getId(item),
                    child: Text(getLabel(item),
                        style: AppTextStyles.labelSm.copyWith(color: fg)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
