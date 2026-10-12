import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/reservation_entity.dart';
import '../../cubit/reservations_cubit.dart';
import '../../cubit/reservations_state.dart';

Color _surfaceOf(bool isDark) =>
    isDark ? AppColors.darkSurface : AppColors.surface;
Color _borderOf(bool isDark) =>
    isDark ? AppColors.darkBorder : AppColors.border;
Color _fgOf(bool isDark) =>
    isDark ? AppColors.darkForeground : AppColors.foreground;
Color _mutedOf(bool isDark) =>
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

(Color fg, Color bg, String label) _statusDecoration(
    String status, AppLocalizations l10n) =>
    switch (status) {
      'pending' => (
          AppColors.statusPending,
          AppColors.statusPendingBg,
          l10n.statusPending,
        ),
      'confirmed' => (
          AppColors.statusPaid,
          AppColors.statusPaidBg,
          l10n.t('statusConfirmed'),
        ),
      'completed' => (
          AppColors.statusCompleted,
          AppColors.statusCompletedBg,
          l10n.statusCompleted,
        ),
      'on_hold' => (
          AppColors.warning,
          AppColors.warningLight,
          l10n.statusOnHold,
        ),
      'cancelled' => (
          AppColors.statusCancelled,
          AppColors.statusCancelledBg,
          l10n.statusCancelled,
        ),
      'no_show' => (
          AppColors.statusDraft,
          AppColors.statusDraftBg,
          l10n.statusNoShow,
        ),
      _ => (AppColors.statusDraft, AppColors.statusDraftBg, status),
    };

class MobileReservationsPage extends StatelessWidget {
  const MobileReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReservationsCubit(
        getReservations: getIt(),
        updateStatus: getIt(),
        deleteReservation: getIt(),
      )..load(),
      child: const _MobileReservationsContent(),
    );
  }
}

class _MobileReservationsContent extends StatelessWidget {
  const _MobileReservationsContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(l10n.reservations),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      ),
      body: BlocBuilder<ReservationsCubit, ReservationsState>(
        builder: (context, state) {
          final cubit = context.read<ReservationsCubit>();
          final filters = switch (state) {
            ReservationsLoaded(:final filters) => filters,
            ReservationsLoading(:final filters) => filters,
            ReservationsError(:final filters) => filters,
            _ => const ReservationsFilters(),
          };

          return Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: AppSearchField(
                  hint: l10n.searchReservations,
                  onChanged: cubit.search,
                ),
              ),
              // KPI strip
              if (state is ReservationsLoaded)
                _MobileKpiStrip(state: state),
              // Status filter chips
              _MobileStatusFilter(
                selected: filters.status,
                onSelect: cubit.filterByStatus,
                l10n: l10n,
                isDark: isDark,
              ),
              // Body
              Expanded(
                child: _buildBody(context, state, cubit, isDark, l10n),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReservationsState state,
    ReservationsCubit cubit,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return switch (state) {
      ReservationsInitial() ||
      ReservationsLoading() =>
        ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 6,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: ShimmerBox(height: 96),
          ),
        ),
      ReservationsError(:final message, :final filters) => AppErrorWidget(
          message: message,
          onRetry: () => cubit.load(filters: filters),
        ),
      ReservationsLoaded(:final reservations)
          when reservations.isEmpty =>
        AppEmptyState(
          icon: const Icon(Icons.event_seat_outlined, size: 40),
          message: l10n.noReservationsFound,
        ),
      ReservationsLoaded(:final reservations, :final meta) => Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: reservations.length,
                itemBuilder: (ctx, i) => _MobileReservationCard(
                  reservation: reservations[i],
                  isDark: isDark,
                  cubit: cubit,
                  l10n: l10n,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: AppPagination(
                meta: meta,
                onPageChanged: cubit.loadPage,
              ),
            ),
          ],
        ),
    };
  }
}

// ─── Mobile KPI Strip ─────────────────────────────────────────────────────────

class _MobileKpiStrip extends StatelessWidget {
  final ReservationsLoaded state;
  const _MobileKpiStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int noShow = 0;
    int confirmedToday = 0;
    int pendingToday = 0;
    int upcoming = 0;

    for (final r in state.reservations) {
      final resDay = DateTime(
        r.reservationDate.year,
        r.reservationDate.month,
        r.reservationDate.day,
      );
      if (r.status == 'no_show') { noShow++; }
      if (r.status == 'confirmed' && resDay == today) { confirmedToday++; }
      if (r.status == 'pending' && resDay == today) { pendingToday++; }
      if (r.reservationDate.isAfter(now) &&
          r.status != 'cancelled' &&
          r.status != 'no_show') { upcoming++; }
    }

    final items = [
      (noShow.toString(), l10n.statusNoShow, AppColors.destructive),
      (confirmedToday.toString(), l10n.confirmedToday, AppColors.success),
      (pendingToday.toString(), l10n.pendingToday, AppColors.warning),
      (upcoming.toString(), l10n.upcomingReservations, AppColors.info),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final (value, label, color) = items[i];
          return _MiniKpiCard(
            value: value,
            label: label,
            color: color,
          );
        },
      ),
    );
  }
}

class _MiniKpiCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MiniKpiCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _surfaceOf(isDark),
        border: Border.all(color: _borderOf(isDark)),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.h5.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodyXs
                .copyWith(color: _mutedOf(isDark)),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ─── Mobile Status Filter ─────────────────────────────────────────────────────

class _MobileStatusFilter extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;
  final AppLocalizations l10n;
  final bool isDark;

  const _MobileStatusFilter({
    required this.selected,
    required this.onSelect,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      (null, l10n.all),
      ('pending', l10n.statusPending),
      ('confirmed', l10n.t('statusConfirmed')),
      ('completed', l10n.statusCompleted),
      ('on_hold', l10n.statusOnHold),
      ('cancelled', l10n.statusCancelled),
      ('no_show', l10n.statusNoShow),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, i) {
          final (statusVal, label) = statuses[i];
          final isActive = selected == statusVal;
          final cs = Theme.of(context).colorScheme;

          return GestureDetector(
            onTap: () =>
                onSelect(isActive && statusVal != null ? null : statusVal),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? cs.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: isActive ? cs.primary : _borderOf(isDark),
                ),
                borderRadius: AppRadius.brFull,
              ),
              child: Text(
                label,
                style: AppTextStyles.labelXs.copyWith(
                  color: isActive ? cs.primary : _mutedOf(isDark),
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Mobile Reservation Card ──────────────────────────────────────────────────

class _MobileReservationCard extends StatelessWidget {
  final ReservationEntity reservation;
  final bool isDark;
  final ReservationsCubit cubit;
  final AppLocalizations l10n;

  const _MobileReservationCard({
    required this.reservation,
    required this.isDark,
    required this.cubit,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final surface = _surfaceOf(isDark);
    final border = _borderOf(isDark);
    final fg = _fgOf(isDark);
    final muted = _mutedOf(isDark);
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMM yyyy');
    final (statusColor, statusBg, statusLabel) =
        _statusDecoration(reservation.status, l10n);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Reference badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Text(
                    reservation.reference,
                    style: AppTextStyles.labelXs.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                StatusBadge.custom(
                  label: statusLabel,
                  color: statusColor,
                  bgColor: statusBg,
                ),
                const SizedBox(width: AppSpacing.xs),
                _MobileActionMenu(
                  reservation: reservation,
                  cubit: cubit,
                  l10n: l10n,
                  muted: muted,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Customer name
            Text(
              reservation.customerName,
              style: AppTextStyles.labelMd.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (reservation.customerPhone != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 12, color: muted),
                  const SizedBox(width: 4),
                  Text(
                    reservation.customerPhone!,
                    style: AppTextStyles.bodySm.copyWith(color: muted),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            // Date + Time
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 12, color: muted),
                const SizedBox(width: 4),
                Text(
                  dateFmt.format(reservation.reservationDate.toLocal()),
                  style: AppTextStyles.bodySm.copyWith(color: muted),
                ),
                if (reservation.timeFrom != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.access_time_rounded, size: 12, color: muted),
                  const SizedBox(width: 4),
                  Text(
                    reservation.timeFrom!,
                    style: AppTextStyles.bodySm.copyWith(color: muted),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // Party size + table
            Row(
              children: [
                Icon(Icons.people_outline_rounded, size: 12, color: muted),
                const SizedBox(width: 4),
                Text(
                  '${reservation.partySize}',
                  style: AppTextStyles.bodySm.copyWith(color: muted),
                ),
                if (reservation.tableName != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.table_restaurant_rounded,
                      size: 12, color: muted),
                  const SizedBox(width: 4),
                  Text(
                    reservation.tableName!,
                    style: AppTextStyles.bodySm.copyWith(color: muted),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileActionMenu extends StatelessWidget {
  final ReservationEntity reservation;
  final ReservationsCubit cubit;
  final AppLocalizations l10n;
  final Color muted;

  const _MobileActionMenu({
    required this.reservation,
    required this.cubit,
    required this.l10n,
    required this.muted,
  });

  static const Map<String, List<String>> _validNext = {
    'pending':   ['confirmed', 'on_hold', 'no_show', 'cancelled'],
    'confirmed': ['completed', 'no_show', 'cancelled'],
    'on_hold':   ['confirmed', 'cancelled'],
    'no_show':   [],
    'completed': [],
    'cancelled': [],
  };

  bool _canDo(String target) =>
      (_validNext[reservation.status] ?? []).contains(target);

  @override
  Widget build(BuildContext context) {
    final hasActions = _canDo('confirmed') || _canDo('completed') ||
        _canDo('no_show') || _canDo('cancelled');

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 16, color: muted),
      onSelected: (value) => _handleAction(context, value),
      itemBuilder: (_) => [
        if (_canDo('confirmed'))
          PopupMenuItem(
            value: 'confirm',
            child: Text(l10n.confirmReservation),
          ),
        if (_canDo('completed'))
          PopupMenuItem(
            value: 'complete',
            child: Text(l10n.completeReservation),
          ),
        if (_canDo('no_show'))
          PopupMenuItem(
            value: 'no_show',
            child: Text(l10n.markNoShow),
          ),
        if (_canDo('cancelled'))
          PopupMenuItem(
            value: 'cancel',
            child: Text(l10n.cancelReservation),
          ),
        if (hasActions) const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            l10n.delete,
            style: const TextStyle(color: AppColors.destructive),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    if (action == 'delete') {
      final err = await cubit.deleteReservation(reservation.id);
      if (!context.mounted) return;
      if (err == null) {
        AppSnackbar.success(context, l10n.success);
      } else {
        AppSnackbar.error(context, err);
      }
      return;
    }

    final statusMap = {
      'confirm': 'confirmed',
      'complete': 'completed',
      'cancel': 'cancelled',
      'no_show': 'no_show',
    };
    final newStatus = statusMap[action];
    if (newStatus == null) return;

    final err = await cubit.updateStatus(reservation.id, newStatus);
    if (!context.mounted) return;
    if (err == null) {
      AppSnackbar.success(context, l10n.success);
    } else {
      AppSnackbar.error(context, err);
    }
  }
}
