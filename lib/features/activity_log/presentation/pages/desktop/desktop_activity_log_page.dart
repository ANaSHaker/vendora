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
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/activity_log_entity.dart';
import '../../../domain/usecases/activity_log_usecases.dart';
import '../../cubit/activity_log_cubit.dart';
import '../../cubit/activity_log_state.dart';

class DesktopActivityLogPage extends StatelessWidget {
  const DesktopActivityLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ActivityLogCubit(
        getActivityLog: getIt<GetActivityLogUseCase>(),
        getUsers: getIt<GetActivityLogUsersUseCase>(),
      )..load(),
      child: const _ActivityLogContent(),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _localizedAction(String action, AppLocalizations l10n) {
  String? key = _actionKey(action);
  if (key == null) return action;
  final translated = l10n.t(key);
  return translated == key ? action : translated;
}

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

// ── Page Content ──────────────────────────────────────────────────────────────

class _ActivityLogContent extends StatefulWidget {
  const _ActivityLogContent();

  @override
  State<_ActivityLogContent> createState() => _ActivityLogContentState();
}

class _ActivityLogContentState extends State<_ActivityLogContent> {
  List<ActivityLogUser> _cachedUsers = [];
  ActivityLogFilters _cachedFilters = const ActivityLogFilters();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityLogCubit, ActivityLogState>(
      builder: (context, state) {
        final cubit = context.read<ActivityLogCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted =
            isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

        if (state is ActivityLogLoaded) {
          _cachedUsers = state.users;
          _cachedFilters = state.filters;
        }

        final filters = _cachedFilters;
        final users = _cachedUsers;

        return ColoredBox(
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('activityLog'),
                      style: AppTextStyles.h4.copyWith(color: fg),
                    ),
                    if (state is ActivityLogLoaded)
                      Text(
                        '${state.meta.total} ${l10n.t("activityEvents")}',
                        style: AppTextStyles.bodySm.copyWith(color: muted),
                      ),
                  ],
                ),
              ),

              // ── Filter Bar ──
              _FilterBar(
                filters: filters,
                users: users,
                cubit: cubit,
                isDark: isDark,
                l10n: l10n,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Table ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.desktopContentPadding,
                  ),
                  child: switch (state) {
                    ActivityLogInitial() ||
                    ActivityLogLoading() =>
                      const ShimmerTableRows(),
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
                    ActivityLogLoaded(:final entries, :final meta) => Column(
                        children: [
                          Expanded(
                            child: _ActivityLogTable(
                              entries: entries,
                              isDark: isDark,
                              l10n: l10n,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPagination(
                            meta: meta,
                            onPageChanged: cubit.goToPage,
                          ),
                          const SizedBox(
                              height: AppSizes.desktopContentPadding),
                        ],
                      ),
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final ActivityLogFilters filters;
  final List<ActivityLogUser> users;
  final ActivityLogCubit cubit;
  final bool isDark;
  final AppLocalizations l10n;

  const _FilterBar({
    required this.filters,
    required this.users,
    required this.cubit,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
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

    final hasActiveFilters = filters.userId != null ||
        filters.action != null ||
        filters.dateFrom != null ||
        filters.dateTo != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.desktopContentPadding,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          // Employee filter
          SizedBox(
            width: 200,
            child: AppSelectField<String?>(
              label: l10n.t('filterEmployee'),
              hint: l10n.t('allEmployees'),
              value: users.any((u) => u.id == filters.userId)
                  ? filters.userId
                  : null,
              options: userOptions,
              onChanged: cubit.updateUserFilter,
            ),
          ),

          // Action type filter
          SizedBox(
            width: 200,
            child: AppSelectField<String?>(
              label: l10n.t('filterAction'),
              hint: l10n.t('allActions'),
              value: filters.action,
              options: actionOptions,
              onChanged: cubit.updateActionFilter,
            ),
          ),

          // Date From picker
          _DatePickerButton(
            label: l10n.t('filterDateFrom'),
            value: filters.dateFrom,
            isDark: isDark,
            onPicked: (date) => cubit.updateDateRange(date, filters.dateTo),
            onClear: () => cubit.updateDateRange(null, filters.dateTo),
          ),

          // Date To picker
          _DatePickerButton(
            label: l10n.t('filterDateTo'),
            value: filters.dateTo,
            isDark: isDark,
            firstDate: filters.dateFrom != null
                ? DateTime.tryParse(filters.dateFrom!) ?? DateTime(2020)
                : DateTime(2020),
            onPicked: (date) => cubit.updateDateRange(filters.dateFrom, date),
            onClear: () => cubit.updateDateRange(filters.dateFrom, null),
          ),

          // Clear filters button
          if (hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg + AppSpacing.xs),
              child: TextButton.icon(
                onPressed: cubit.clearFilters,
                icon: const Icon(Icons.clear, size: AppSizes.iconSm),
                label: Text(l10n.t('clearFilters')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.mutedForeground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Date Picker Button ────────────────────────────────────────────────────────

class _DatePickerButton extends StatelessWidget {
  final String label;
  final String? value;
  final bool isDark;
  final DateTime? firstDate;
  final ValueChanged<String> onPicked;
  final VoidCallback onClear;

  const _DatePickerButton({
    required this.label,
    required this.value,
    required this.isDark,
    required this.onPicked,
    required this.onClear,
    this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final fillColor = isDark ? AppColors.darkMuted : AppColors.muted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.labelMd.copyWith(color: fg)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: 160,
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value != null
                    ? (DateTime.tryParse(value!) ?? DateTime.now())
                    : DateTime.now(),
                firstDate: firstDate ?? DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                final formatted =
                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                onPicked(formatted);
              }
            },
            borderRadius: AppRadius.brMd,
            child: Container(
              height: 42,
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
        ),
      ],
    );
  }
}

// ── Activity Log Table ────────────────────────────────────────────────────────

class _ActivityLogTable extends StatelessWidget {
  final List<ActivityLogEntry> entries;
  final bool isDark;
  final AppLocalizations l10n;

  const _ActivityLogTable({
    required this.entries,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          children: [
            // Header row
            Container(
              height: AppSizes.tableHeaderHeight,
              color: headerBg,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      l10n.t('colAction'),
                      style: AppTextStyles.tableHeader.copyWith(color: muted),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n.t('colEntity'),
                      style: AppTextStyles.tableHeader.copyWith(color: muted),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      l10n.t('colEmployee'),
                      style: AppTextStyles.tableHeader.copyWith(color: muted),
                    ),
                  ),
                  SizedBox(
                    width: 148,
                    child: Text(
                      l10n.t('colTime'),
                      style: AppTextStyles.tableHeader.copyWith(color: muted),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(
                      l10n.t('colIpAddress'),
                      style: AppTextStyles.tableHeader.copyWith(color: muted),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),

            // Data rows
            Expanded(
              child: ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: border),
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  return _ActivityLogRow(
                    entry: entry,
                    isDark: isDark,
                    fg: fg,
                    muted: muted,
                    l10n: l10n,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Table Row ─────────────────────────────────────────────────────────────────

class _ActivityLogRow extends StatelessWidget {
  final ActivityLogEntry entry;
  final bool isDark;
  final Color fg;
  final Color muted;
  final AppLocalizations l10n;

  const _ActivityLogRow({
    required this.entry,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final (badgeFg, badgeBg) = _badgeColors(entry.action);

    return Container(
      height: AppSizes.tableRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        children: [
          // Action badge (localized label)
          SizedBox(
            width: 140,
            child: StatusBadge.custom(
              label: _localizedAction(entry.action, l10n),
              color: badgeFg,
              bgColor: badgeBg,
            ),
          ),

          // Entity (type + id)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (entry.entity != null)
                  Text(
                    entry.entity!,
                    style: AppTextStyles.labelSm.copyWith(color: fg),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (entry.entityId != null)
                  Text(
                    _truncateId(entry.entityId!),
                    style: AppTextStyles.bodyXs.copyWith(color: muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (entry.entity == null && entry.entityId == null)
                  Text('—', style: AppTextStyles.bodyXs.copyWith(color: muted)),
              ],
            ),
          ),

          // Employee (avatar + name + email)
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _InitialAvatar(
                  name: entry.causer?.name ?? '?',
                  isDark: isDark,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
          ),

          // Time
          SizedBox(
            width: 148,
            child: Text(
              _fmtDateTime(entry.createdAt),
              style: AppTextStyles.tableCell.copyWith(color: muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // IP
          SizedBox(
            width: 130,
            child: Text(
              entry.ip ?? '—',
              style: AppTextStyles.numeric.copyWith(color: muted, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _truncateId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 8)}…';
  }
}

// ── Initial Avatar ────────────────────────────────────────────────────────────

class _InitialAvatar extends StatelessWidget {
  final String name;
  final bool isDark;

  const _InitialAvatar({required this.name, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: AppColors.primaryMuted,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: AppTextStyles.labelXs.copyWith(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
