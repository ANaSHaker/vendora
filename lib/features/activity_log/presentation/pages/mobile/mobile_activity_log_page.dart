import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../domain/entities/activity_log_entity.dart';
import '../../../domain/usecases/activity_log_usecases.dart';
import '../../cubit/activity_log_cubit.dart';
import '../../cubit/activity_log_state.dart';

class MobileActivityLogPage extends StatelessWidget {
  const MobileActivityLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ActivityLogCubit(
        getActivityLog: getIt<GetActivityLogUseCase>(),
        getUsers: getIt<GetActivityLogUsersUseCase>(),
      )..load(),
      child: const _MobileActivityLogContent(),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String? _actionKey(String action) {
  return switch (action) {
    'auth.login'                => 'actionAuthLogin',
    'auth.logout'               => 'actionAuthLogout',
    'auth.logout_device'        => 'actionLogoutDevice',
    'auth.logout_all_devices'   => 'actionLogoutAllDevices',
    'security.suspicious_login' => 'actionSuspiciousLogin',
    'user_device.blocked'       => 'actionDeviceBlocked',
    'user_device.unblocked'     => 'actionDeviceUnblocked',
    'orders.create'             => 'actionOrderCreated',
    'orders.refund'             => 'actionOrderRefunded',
    'products.update'           => 'actionProductUpdated',
    'users.create'              => 'actionUserCreated',
    'users.update'              => 'actionUsersUpdate',
    'users.delete'              => 'actionUsersDelete',
    'roles.create'              => 'actionRolesCreate',
    'roles.update'              => 'actionRolesUpdate',
    'roles.delete'              => 'actionRolesDelete',
    _ when action.startsWith('stock_adjustment') => 'actionStockAdjustment',
    _ when action.startsWith('stock_count')      => 'actionStockCount',
    _ when action.startsWith('stock_transfer')   => 'actionStockTransfer',
    _                           => null,
  };
}

String _localizedAction(String action, AppLocalizations l10n) {
  final key = _actionKey(action);
  if (key == null) return action;
  final translated = l10n.t(key);
  return translated == key ? action : translated;
}

(Color fg, Color bg) _badgeColors(String action) {
  return switch (action) {
    'auth.login'                => (AppColors.infoForeground, AppColors.infoLight),
    'auth.logout'               => (AppColors.mutedForeground, AppColors.muted),
    'auth.logout_device'        => (AppColors.mutedForeground, AppColors.muted),
    'auth.logout_all_devices'   => (AppColors.mutedForeground, AppColors.muted),
    'security.suspicious_login' => (AppColors.destructive, AppColors.destructiveLight),
    'user_device.blocked'       => (AppColors.destructive, AppColors.destructiveLight),
    'user_device.unblocked'     => (AppColors.successForeground, AppColors.successLight),
    'orders.create'             => (AppColors.successForeground, AppColors.successLight),
    'orders.refund'             => (AppColors.warningForeground, AppColors.warningLight),
    'products.update'           => (AppColors.infoForeground, AppColors.infoLight),
    'users.create'              => (AppColors.successForeground, AppColors.successLight),
    'users.update'              => (AppColors.infoForeground, AppColors.infoLight),
    'users.delete'              => (AppColors.destructive, AppColors.destructiveLight),
    'roles.create'              => (AppColors.successForeground, AppColors.successLight),
    'roles.update'              => (AppColors.infoForeground, AppColors.infoLight),
    'roles.delete'              => (AppColors.destructive, AppColors.destructiveLight),
    _                           => (AppColors.mutedForeground, AppColors.muted),
  };
}

String _fmtDateTime(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    final date =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  } catch (_) {
    return iso;
  }
}

const _knownActions = [
  'auth.login',
  'auth.logout',
  'auth.logout_device',
  'auth.logout_all_devices',
  'security.suspicious_login',
  'user_device.blocked',
  'user_device.unblocked',
  'orders.create',
  'orders.refund',
  'products.update',
  'users.create',
  'users.update',
  'users.delete',
  'roles.create',
  'roles.update',
  'roles.delete',
];

// ── Content ───────────────────────────────────────────────────────────────────

class _MobileActivityLogContent extends StatelessWidget {
  const _MobileActivityLogContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityLogCubit, ActivityLogState>(
      builder: (context, state) {
        final cubit = context.read<ActivityLogCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final surface = isDark ? AppColors.darkSurface : AppColors.surface;

        final filters =
            state is ActivityLogLoaded ? state.filters : const ActivityLogFilters();
        final totalEvents =
            state is ActivityLogLoaded ? state.meta.total : 0;

        final hasActiveFilters = filters.userId != null ||
            filters.action != null ||
            filters.dateFrom != null ||
            filters.dateTo != null;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('activityLog'),
                  style: AppTextStyles.h6.copyWith(
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.foreground,
                  ),
                ),
                if (state is ActivityLogLoaded)
                  Text(
                    '$totalEvents ${l10n.t("activityEvents")}',
                    style: AppTextStyles.bodyXs.copyWith(
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground,
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: hasActiveFilters
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground),
                ),
                onPressed: () => _showFilterSheet(context, cubit, state, l10n),
                tooltip: l10n.t('filters'),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
          ),
          body: switch (state) {
            ActivityLogInitial() || ActivityLogLoading() => ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                itemCount: 8,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ShimmerBox(height: 88),
                ),
              ),
            ActivityLogError(:final message) => AppErrorWidget(
                message: message,
                onRetry: cubit.refresh,
              ),
            ActivityLogLoaded(:final entries) when entries.isEmpty =>
              Center(
                child: AppEmptyState(
                  icon: const Icon(Icons.history_outlined, size: 40),
                  message: l10n.t('noActivityLogs'),
                  subtitle: l10n.t('noActivityLogsSubtitle'),
                ),
              ),
            ActivityLogLoaded(:final entries, :final meta) =>
              RefreshIndicator(
                onRefresh: () async => cubit.refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl4,
                  ),
                  itemCount: entries.length + (meta.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, i) {
                    if (i == entries.length) {
                      return _LoadMoreButton(
                        isDark: isDark,
                        l10n: l10n,
                        onTap: () => cubit.goToPage(meta.currentPage + 1),
                      );
                    }
                    return _MobileActivityCard(
                      entry: entries[i],
                      isDark: isDark,
                      l10n: l10n,
                    );
                  },
                ),
              ),
          },
        );
      },
    );
  }
}

// ── Mobile Activity Card ──────────────────────────────────────────────────────

class _MobileActivityCard extends StatelessWidget {
  final ActivityLogEntry entry;
  final bool isDark;
  final AppLocalizations l10n;

  const _MobileActivityCard({
    required this.entry,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final (badgeFg, badgeBg) = _badgeColors(entry.action);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: action badge + time
            Row(
              children: [
                StatusBadge.custom(
                  label: _localizedAction(entry.action, l10n),
                  color: badgeFg,
                  bgColor: badgeBg,
                ),
                const Spacer(),
                Text(
                  _fmtDateTime(entry.createdAt),
                  style: AppTextStyles.bodyXs.copyWith(color: muted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Employee info
            Row(
              children: [
                _MobileAvatar(name: entry.causer?.name ?? '?'),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.causer?.name ?? '—',
                        style: AppTextStyles.labelSm.copyWith(color: fg),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (entry.causer?.email != null)
                        Text(
                          entry.causer!.email!,
                          style: AppTextStyles.bodyXs.copyWith(color: muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Entity + IP row
            if (entry.entity != null || entry.ip != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(height: 1, color: border),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (entry.entity != null) ...[
                    Icon(Icons.inventory_2_outlined, size: 12, color: muted),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        entry.entity!,
                        style: AppTextStyles.bodyXs.copyWith(color: muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (entry.ip != null) ...[
                    Icon(Icons.wifi_outlined, size: 12, color: muted),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      entry.ip!,
                      style: AppTextStyles.bodyXs.copyWith(color: muted),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Mobile Avatar ─────────────────────────────────────────────────────────────

class _MobileAvatar extends StatelessWidget {
  final String name;

  const _MobileAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.primaryMuted,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: AppTextStyles.labelSm.copyWith(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Load More Button ──────────────────────────────────────────────────────────

class _LoadMoreButton extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _LoadMoreButton({
    required this.isDark,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: TextButton(
          onPressed: onTap,
          child: Text(
            l10n.t('loadMore'),
            style: AppTextStyles.labelSm.copyWith(color: muted),
          ),
        ),
      ),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────

void _showFilterSheet(
  BuildContext context,
  ActivityLogCubit cubit,
  ActivityLogState state,
  AppLocalizations l10n,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _FilterSheet(state: state, l10n: l10n),
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  final ActivityLogState state;
  final AppLocalizations l10n;

  const _FilterSheet({required this.state, required this.l10n});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _selectedUserId;
  late String? _selectedAction;
  late String? _dateFrom;
  late String? _dateTo;

  @override
  void initState() {
    super.initState();
    final filters = widget.state is ActivityLogLoaded
        ? (widget.state as ActivityLogLoaded).filters
        : const ActivityLogFilters();
    _selectedUserId = filters.userId;
    _selectedAction = filters.action;
    _dateFrom = filters.dateFrom;
    _dateTo = filters.dateTo;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final current = isFrom ? _dateFrom : _dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null
          ? (DateTime.tryParse(current) ?? DateTime.now())
          : DateTime.now(),
      firstDate: isFrom
          ? DateTime(2020)
          : (_dateFrom != null
              ? (DateTime.tryParse(_dateFrom!) ?? DateTime(2020))
              : DateTime(2020)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        if (isFrom) {
          _dateFrom = formatted;
        } else {
          _dateTo = formatted;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final cubit = context.read<ActivityLogCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final users = widget.state is ActivityLogLoaded
        ? (widget.state as ActivityLogLoaded).users
        : <ActivityLogUser>[];

    final userOptions = <AppSelectOption<String?>>[
      AppSelectOption(value: null, label: l10n.t('allEmployees')),
      ...users.map((u) => AppSelectOption(value: u.id, label: u.name)),
    ];

    final actionOptions = <AppSelectOption<String?>>[
      AppSelectOption(value: null, label: l10n.t('allActions')),
      ..._knownActions.map(
        (a) => AppSelectOption(value: a, label: _localizedAction(a, l10n)),
      ),
    ];

    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final fillColor = isDark ? AppColors.darkMuted : AppColors.muted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.brSm,
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.sm, AppSpacing.sm),
            child: Row(
              children: [
                Text(l10n.t('filters'), style: AppTextStyles.h6),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedUserId = null;
                    _selectedAction = null;
                    _dateFrom = null;
                    _dateTo = null;
                  }),
                  child: Text(
                    l10n.t('clearFilters'),
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.mutedForeground),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Filter fields
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSelectField<String?>(
                  label: l10n.t('filterEmployee'),
                  hint: l10n.t('allEmployees'),
                  value: users.any((u) => u.id == _selectedUserId)
                      ? _selectedUserId
                      : null,
                  options: userOptions,
                  onChanged: (v) => setState(() => _selectedUserId = v),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSelectField<String?>(
                  label: l10n.t('filterAction'),
                  hint: l10n.t('allActions'),
                  value: _selectedAction,
                  options: actionOptions,
                  onChanged: (v) => setState(() => _selectedAction = v),
                ),
                const SizedBox(height: AppSpacing.md),
                // Date range row
                Row(
                  children: [
                    Expanded(
                      child: _MobileDatePickerField(
                        label: l10n.t('filterDateFrom'),
                        value: _dateFrom,
                        isDark: isDark,
                        borderColor: borderColor,
                        fillColor: fillColor,
                        fg: fg,
                        muted: muted,
                        onTap: () => _pickDate(isFrom: true),
                        onClear: () => setState(() => _dateFrom = null),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _MobileDatePickerField(
                        label: l10n.t('filterDateTo'),
                        value: _dateTo,
                        isDark: isDark,
                        borderColor: borderColor,
                        fillColor: fillColor,
                        fg: fg,
                        muted: muted,
                        onTap: () => _pickDate(isFrom: false),
                        onClear: () => setState(() => _dateTo = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.brMd),
                    ),
                    onPressed: () {
                      cubit.applyFilters(ActivityLogFilters(
                        userId: _selectedUserId,
                        action: _selectedAction,
                        dateFrom: _dateFrom,
                        dateTo: _dateTo,
                      ));
                      Navigator.pop(context);
                    },
                    child: Text(
                      l10n.t('applyFilters'),
                      style: AppTextStyles.labelMd
                          .copyWith(color: AppColors.white),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileDatePickerField extends StatelessWidget {
  final String label;
  final String? value;
  final bool isDark;
  final Color borderColor;
  final Color fillColor;
  final Color fg;
  final Color muted;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _MobileDatePickerField({
    required this.label,
    required this.value,
    required this.isDark,
    required this.borderColor,
    required this.fillColor,
    required this.fg,
    required this.muted,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.labelMd.copyWith(color: fg)),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brMd,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: fillColor,
              border: Border.all(color: borderColor),
              borderRadius: AppRadius.brMd,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: muted),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    value ?? '—',
                    style: AppTextStyles.bodySm.copyWith(
                      color: value != null ? fg : muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (value != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.close, size: 14, color: muted),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
