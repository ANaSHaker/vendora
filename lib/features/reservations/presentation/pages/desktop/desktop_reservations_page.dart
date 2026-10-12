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
import '../../../../../design_system/widgets/inputs/app_date_range_picker.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/reservation_entity.dart';
import '../../cubit/reservations_cubit.dart';
import '../../cubit/reservations_state.dart';

// ─── Color helpers ────────────────────────────────────────────────────────────
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
      'seated' => (
          const Color(0xFFA855F7),
          const Color(0x1AA855F7),
          l10n.t('statusSeated'),
        ),
      'completed' => (
          AppColors.statusCompleted,
          AppColors.statusCompletedBg,
          l10n.statusCompleted,
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

class DesktopReservationsPage extends StatelessWidget {
  const DesktopReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReservationsCubit(
        getReservations: getIt(),
        updateStatus: getIt(),
        deleteReservation: getIt(),
      )..load(),
      child: const _ReservationsContent(),
    );
  }
}

class _ReservationsContent extends StatefulWidget {
  const _ReservationsContent();

  @override
  State<_ReservationsContent> createState() => _ReservationsContentState();
}

class _ReservationsContentState extends State<_ReservationsContent> {
  ReservationEntity? _selected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReservationsCubit, ReservationsState>(
      builder: (context, state) {
        final cubit = context.read<ReservationsCubit>();
        final filters = switch (state) {
          ReservationsLoaded(:final filters) => filters,
          ReservationsLoading(:final filters) => filters,
          ReservationsError(:final filters) => filters,
          _ => const ReservationsFilters(),
        };

        // Keep selected in sync when list refreshes
        if (_selected != null && state is ReservationsLoaded) {
          final found = state.reservations.where((r) => r.id == _selected!.id);
          if (found.isNotEmpty) _selected = found.first;
        }

        return ColoredBox(
          color: AppColors.background,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReservationsHeader(filters: filters, cubit: cubit),
                    _KpiSummaryRow(state: state),
                    _FilterBar(filters: filters, cubit: cubit),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.desktopContentPadding,
                        ),
                        child: _buildBody(context, state, cubit),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selected != null)
                _DetailPanel(
                  reservation: _selected!,
                  cubit: cubit,
                  onClose: () => setState(() => _selected = null),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReservationsState state,
    ReservationsCubit cubit,
  ) {
    return switch (state) {
      ReservationsInitial() ||
      ReservationsLoading() =>
        const ShimmerTableRows(),
      ReservationsError(:final message, :final filters) => AppErrorWidget(
          message: message,
          onRetry: () => cubit.load(filters: filters),
        ),
      ReservationsLoaded(:final reservations)
          when reservations.isEmpty =>
        AppEmptyState(
          icon: const Icon(Icons.event_seat_outlined, size: 40),
          message: AppLocalizations.of(context).noReservationsFound,
        ),
      ReservationsLoaded(:final reservations, :final meta) => Column(
          children: [
            Expanded(
              child: _ReservationsTable(
                reservations: reservations,
                selectedId: _selected?.id,
                cubit: cubit,
                onSelect: (r) => setState(() =>
                    _selected = _selected?.id == r.id ? null : r),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppPagination(meta: meta, onPageChanged: cubit.loadPage),
            const SizedBox(height: AppSizes.desktopContentPadding),
          ],
        ),
    };
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ReservationsHeader extends StatelessWidget {
  final ReservationsFilters filters;
  final ReservationsCubit cubit;

  const _ReservationsHeader({required this.filters, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = _fgOf(isDark);
    final muted = _mutedOf(isDark);
    final state = context.watch<ReservationsCubit>().state;
    final total =
        state is ReservationsLoaded ? state.meta.total : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.desktopContentPadding,
        AppSizes.desktopContentPadding,
        AppSizes.desktopContentPadding,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.reservations,
                  style: AppTextStyles.h4.copyWith(color: fg)),
              Text(
                l10n.reservationSubtitle,
                style: AppTextStyles.bodySm.copyWith(color: muted),
              ),
              if (total != null)
                Text(
                  '$total ${l10n.results}',
                  style: AppTextStyles.bodyXs.copyWith(color: muted),
                ),
            ],
          ),
          const Spacer(),
          AppDateRangePicker(
            startDate: filters.dateFrom,
            endDate: filters.dateTo,
            activePreset: filters.preset,
            onPresetChanged: cubit.changePreset,
            onCustomRange: (from, to) => cubit.setCustomRange(from, to),
          ),
        ],
      ),
    );
  }
}

// ─── KPI Summary Row ──────────────────────────────────────────────────────────

class _KpiSummaryRow extends StatelessWidget {
  final ReservationsState state;
  const _KpiSummaryRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int noShow = 0;
    int confirmedToday = 0;
    int pendingToday = 0;
    int upcoming = 0;
    int total = 0;

    if (state is ReservationsLoaded) {
      final loaded = state as ReservationsLoaded;
      total = loaded.meta.total;
      for (final r in loaded.reservations) {
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
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.desktopContentPadding,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: _KpiCard(
              label: l10n.statusNoShow,
              value: noShow.toString(),
              icon: Icons.person_off_rounded,
              color: AppColors.statusCancelled,
              bg: AppColors.statusCancelledBg,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _KpiCard(
              label: l10n.confirmedToday,
              value: confirmedToday.toString(),
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.statusPaid,
              bg: AppColors.statusPaidBg,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _KpiCard(
              label: l10n.pendingToday,
              value: pendingToday.toString(),
              icon: Icons.pending_outlined,
              color: AppColors.warning,
              bg: AppColors.warningLight,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _KpiCard(
              label: l10n.upcomingReservations,
              value: upcoming.toString(),
              icon: Icons.upcoming_rounded,
              color: AppColors.info,
              bg: AppColors.infoLight,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _KpiCard(
              label: l10n.totalReservations,
              value: total.toString(),
              icon: Icons.event_seat_rounded,
              color: AppColors.primary,
              bg: AppColors.primaryMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = _surfaceOf(isDark);
    final border = _borderOf(isDark);
    final fg = _fgOf(isDark);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brLg,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.h4.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.bodyXs.copyWith(
                    color: _mutedOf(isDark),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final ReservationsFilters filters;
  final ReservationsCubit cubit;

  const _FilterBar({required this.filters, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = _borderOf(isDark);
    final cs = Theme.of(context).colorScheme;

    final hasFilters = filters.status != null ||
        filters.dateFrom != null ||
        filters.branchId != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.desktopContentPadding,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 300,
                child: AppSearchField(
                  hint: l10n.searchReservations,
                  onChanged: cubit.search,
                ),
              ),
              const Spacer(),
              if (hasFilters)
                GestureDetector(
                  onTap: () => cubit.load(),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Text(
                      l10n.reset,
                      style: AppTextStyles.bodySm.copyWith(
                        color: cs.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _StatusFilterTabs(
            selected: filters.status,
            onSelect: cubit.filterByStatus,
            l10n: l10n,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _StatusFilterTabs extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;
  final AppLocalizations l10n;
  final bool isDark;

  const _StatusFilterTabs({
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
      ('seated', l10n.t('statusSeated')),
      ('completed', l10n.statusCompleted),
      ('cancelled', l10n.statusCancelled),
      ('no_show', l10n.statusNoShow),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((s) {
          final isActive = selected == s.$1;
          return _StatusTab(
            label: s.$2,
            isActive: isActive,
            onTap: () => onSelect(isActive && s.$1 != null ? null : s.$1),
            isDark: isDark,
            status: s.$1,
          );
        }).toList(),
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;
  final String? status;

  const _StatusTab({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isDark,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final border = _borderOf(isDark);
    final cs = Theme.of(context).colorScheme;

    Color activeColor;
    Color activeBg;
    if (status == null) {
      activeColor = cs.primary;
      activeBg = cs.primary.withValues(alpha: 0.1);
    } else {
      final l10n = AppLocalizations.of(context);
      final (fg, bg, _) = _statusDecoration(status!, l10n);
      activeColor = fg;
      activeBg = bg;
    }

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            border: Border.all(color: isActive ? activeColor : border),
            borderRadius: AppRadius.brFull,
          ),
          child: Text(
            label,
            style: AppTextStyles.labelXs.copyWith(
              color: isActive ? activeColor : _mutedOf(isDark),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Table ────────────────────────────────────────────────────────────────────

const List<int> _flexes = [2, 2, 2, 2, 2, 1, 2];

class _ReservationsTable extends StatelessWidget {
  final List<ReservationEntity> reservations;
  final String? selectedId;
  final ReservationsCubit cubit;
  final ValueChanged<ReservationEntity> onSelect;

  const _ReservationsTable({
    required this.reservations,
    required this.cubit,
    required this.onSelect,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = _surfaceOf(isDark);
    final border = _borderOf(isDark);
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brLg,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brLg,
        child: Column(
          children: [
            _TableHeader(isDark: isDark, headerBg: headerBg),
            Divider(height: 1, color: border),
            Expanded(
              child: ListView.separated(
                itemCount: reservations.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: border),
                itemBuilder: (ctx, i) => _ReservationRow(
                  reservation: reservations[i],
                  isDark: isDark,
                  isSelected: selectedId == reservations[i].id,
                  cubit: cubit,
                  onTap: () => onSelect(reservations[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final bool isDark;
  final Color headerBg;

  const _TableHeader({required this.isDark, required this.headerBg});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 44,
      color: headerBg,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: _flexes[0],
            child: Text(l10n.reference, style: AppTextStyles.tableHeader),
          ),
          Expanded(
            flex: _flexes[1],
            child: Text(l10n.customer, style: AppTextStyles.tableHeader),
          ),
          Expanded(
            flex: _flexes[2],
            child: Text(l10n.t('phone'), style: AppTextStyles.tableHeader),
          ),
          Expanded(
            flex: _flexes[3],
            child: Text(l10n.reservationDate,
                style: AppTextStyles.tableHeader),
          ),
          Expanded(
            flex: _flexes[4],
            child: Text(l10n.reservationTime,
                style: AppTextStyles.tableHeader),
          ),
          Expanded(
            flex: _flexes[5],
            child:
                Text(l10n.reservationTable, style: AppTextStyles.tableHeader),
          ),
          Expanded(
            flex: _flexes[6],
            child:
                Text(l10n.orderStatus, style: AppTextStyles.tableHeader),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _ReservationRow extends StatelessWidget {
  final ReservationEntity reservation;
  final bool isDark;
  final bool isSelected;
  final ReservationsCubit cubit;
  final VoidCallback onTap;

  const _ReservationRow({
    required this.reservation,
    required this.isDark,
    required this.cubit,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = _mutedOf(isDark);
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMM yyyy');

    final (statusColor, statusBg, statusLabel) =
        _statusDecoration(reservation.status, l10n);

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ColoredBox(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            // Reference
            Expanded(
              flex: _flexes[0],
              child: Text(
                reservation.reference,
                style: AppTextStyles.labelSm.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Customer
            Expanded(
              flex: _flexes[1],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reservation.customerName,
                    style: AppTextStyles.tableCell,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (reservation.customerEmail != null)
                    Text(
                      reservation.customerEmail!,
                      style:
                          AppTextStyles.bodyXs.copyWith(color: muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Phone
            Expanded(
              flex: _flexes[2],
              child: Text(
                reservation.customerPhone ?? '—',
                style: AppTextStyles.tableCell.copyWith(color: muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Date
            Expanded(
              flex: _flexes[3],
              child: Text(
                dateFmt.format(reservation.reservationDate.toLocal()),
                style: AppTextStyles.tableCell.copyWith(color: muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Time
            Expanded(
              flex: _flexes[4],
              child: Text(
                reservation.timeFrom != null
                    ? '${reservation.timeFrom}'
                        '${reservation.timeTo != null ? ' - ${reservation.timeTo}' : ''}'
                    : '—',
                style: AppTextStyles.tableCell.copyWith(color: muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Table
            Expanded(
              flex: _flexes[5],
              child: Text(
                reservation.tableName ?? '—',
                style: AppTextStyles.tableCell,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Status
            Expanded(
              flex: _flexes[6],
              child: StatusBadge.custom(
                label: statusLabel,
                color: statusColor,
                bgColor: statusBg,
              ),
            ),
            // Actions
            SizedBox(
              width: 40,
              child: _ActionMenu(
                reservation: reservation,
                cubit: cubit,
                l10n: l10n,
              ),
            ),
          ],
        ),
      ),
    )));
  }
}

class _ActionMenu extends StatelessWidget {
  final ReservationEntity reservation;
  final ReservationsCubit cubit;
  final AppLocalizations l10n;

  const _ActionMenu({
    required this.reservation,
    required this.cubit,
    required this.l10n,
  });

  // Matches web ALLOWED_TRANSITIONS
  static const Map<String, List<String>> _validNext = {
    'pending':   ['confirmed', 'cancelled'],
    'confirmed': ['seated', 'no_show', 'cancelled'],
    'seated':    ['completed', 'cancelled'],
    'no_show':   [],
    'completed': [],
    'cancelled': [],
  };

  bool _canDo(String target) =>
      (_validNext[reservation.status] ?? []).contains(target);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = _mutedOf(isDark);
    final hasActions = _canDo('confirmed') || _canDo('seated') ||
        _canDo('completed') || _canDo('no_show') || _canDo('cancelled');

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 18, color: muted),
      onSelected: (value) => _handleAction(context, value),
      itemBuilder: (_) => [
        if (_canDo('confirmed'))
          PopupMenuItem(
            value: 'confirm',
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 16, color: AppColors.statusPaid),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.confirmReservation),
              ],
            ),
          ),
        if (_canDo('seated'))
          PopupMenuItem(
            value: 'seat',
            child: Row(
              children: [
                const Icon(Icons.event_seat_rounded,
                    size: 16, color: Color(0xFFA855F7)),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.t('seatGuest')),
              ],
            ),
          ),
        if (_canDo('completed'))
          PopupMenuItem(
            value: 'complete',
            child: Row(
              children: [
                const Icon(Icons.done_all_rounded,
                    size: 16, color: AppColors.statusCompleted),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.completeReservation),
              ],
            ),
          ),
        if (_canDo('no_show'))
          PopupMenuItem(
            value: 'no_show',
            child: Row(
              children: [
                const Icon(Icons.person_off_rounded,
                    size: 16, color: AppColors.statusDraft),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.markNoShow),
              ],
            ),
          ),
        if (_canDo('cancelled'))
          PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined,
                    size: 16, color: AppColors.statusCancelled),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.cancelReservation),
              ],
            ),
          ),
        if (hasActions) const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 16, color: AppColors.destructive),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.delete,
                style: const TextStyle(color: AppColors.destructive),
              ),
            ],
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
      'seat':    'seated',
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

// ─── Detail Side Panel ────────────────────────────────────────────────────────

class _DetailPanel extends StatefulWidget {
  final ReservationEntity reservation;
  final ReservationsCubit cubit;
  final VoidCallback onClose;

  static const Map<String, List<String>> _validNext = {
    'pending':   ['confirmed', 'cancelled'],
    'confirmed': ['seated', 'no_show', 'cancelled'],
    'seated':    ['completed', 'cancelled'],
    'no_show':   [],
    'completed': [],
    'cancelled': [],
  };

  const _DetailPanel({
    required this.reservation,
    required this.cubit,
    required this.onClose,
  });

  @override
  State<_DetailPanel> createState() => _DetailPanelState();
}

class _DetailPanelState extends State<_DetailPanel> {
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController();
  }

  @override
  void didUpdateWidget(_DetailPanel old) {
    super.didUpdateWidget(old);
    if (old.reservation.id != widget.reservation.id) {
      _notesCtrl.clear();
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reservation = widget.reservation;
    final cubit = widget.cubit;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = _surfaceOf(isDark);
    final border = _borderOf(isDark);
    final fg = _fgOf(isDark);
    final muted = _mutedOf(isDark);
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('EEE, dd MMM yyyy', 'ar');
    final timeFmt = DateFormat('hh:mm a', 'ar');
    final (statusColor, statusBg, statusLabel) =
        _statusDecoration(reservation.status, l10n);

    final nextStatuses = _DetailPanel._validNext[reservation.status] ?? [];

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: surface,
        border: Border(left: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reservation.customerName,
                        style: AppTextStyles.labelLg.copyWith(color: fg),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: muted,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 13, color: muted),
                    const SizedBox(width: 4),
                    Text(
                      dateFmt.format(reservation.reservationDate.toLocal()),
                      style: AppTextStyles.bodyXs.copyWith(color: muted),
                    ),
                    if (reservation.timeFrom != null) ...[
                      Text('  ·  ',
                          style: AppTextStyles.bodyXs.copyWith(color: muted)),
                      Icon(Icons.access_time_rounded,
                          size: 13, color: muted),
                      const SizedBox(width: 4),
                      Text(
                        reservation.timeFrom!,
                        style: AppTextStyles.bodyXs.copyWith(color: muted),
                      ),
                    ],
                    Text('  ·  ',
                        style: AppTextStyles.bodyXs.copyWith(color: muted)),
                    Icon(Icons.people_outline_rounded,
                        size: 13, color: muted),
                    const SizedBox(width: 4),
                    Text(
                      '${reservation.partySize}',
                      style: AppTextStyles.bodyXs.copyWith(color: muted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      reservation.reference,
                      style: AppTextStyles.labelXs.copyWith(color: cs.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _StatusChip(
                        label: statusLabel,
                        fg: statusColor,
                        bg: statusBg),
                  ],
                ),
              ],
            ),
          ),

          // ── Scrollable body ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer info
                  _SectionLabel(l10n.t('customerInfo'), muted: muted),
                  _InfoCard(isDark: isDark, rows: [
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: l10n.customer,
                      value: reservation.customerName,
                      fg: fg, muted: muted, cs: cs,
                    ),
                    if (reservation.customerPhone != null)
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: l10n.t('phone'),
                        value: reservation.customerPhone!,
                        fg: fg, muted: muted, cs: cs,
                      ),
                    if (reservation.customerEmail != null)
                      _InfoRow(
                        icon: Icons.mail_outline_rounded,
                        label: l10n.t('email'),
                        value: reservation.customerEmail!,
                        fg: fg, muted: muted, cs: cs,
                      ),
                    if (reservation.source != null)
                      _InfoRow(
                        icon: Icons.language_rounded,
                        label: l10n.source,
                        value: reservation.source!,
                        fg: fg, muted: muted, cs: cs,
                      ),
                  ]),

                  const SizedBox(height: AppSpacing.md),

                  // Reservation details
                  _SectionLabel(l10n.t('reservationDetails'), muted: muted),
                  _InfoCard(isDark: isDark, rows: [
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.reservationDate,
                      value: dateFmt.format(
                          reservation.reservationDate.toLocal()),
                      fg: fg, muted: muted, cs: cs,
                    ),
                    if (reservation.timeFrom != null)
                      _InfoRow(
                        icon: Icons.access_time_rounded,
                        label: l10n.reservationTime,
                        value: reservation.timeFrom!,
                        fg: fg, muted: muted, cs: cs,
                      ),
                    _InfoRow(
                      icon: Icons.people_outline_rounded,
                      label: l10n.guests,
                      value: '${reservation.partySize}',
                      fg: fg, muted: muted, cs: cs,
                    ),
                    if (reservation.tableName != null)
                      _InfoRow(
                        icon: Icons.table_restaurant_outlined,
                        label: l10n.reservationTable,
                        value: reservation.tableName!,
                        fg: fg, muted: muted, cs: cs,
                      ),
                    if (reservation.branchName != null)
                      _InfoRow(
                        icon: Icons.store_outlined,
                        label: l10n.branch,
                        value: reservation.branchName!,
                        fg: fg, muted: muted, cs: cs,
                      ),
                    _InfoRow(
                      icon: Icons.schedule_rounded,
                      label: l10n.dateCreated,
                      value: timeFmt.format(reservation.createdAt.toLocal()),
                      fg: fg, muted: muted, cs: cs,
                    ),
                  ]),

                  // Special request
                  if (reservation.notes != null &&
                      reservation.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _SectionLabel(l10n.t('specialRequest'), muted: muted),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0x0AF59E0B),
                        border:
                            Border.all(color: const Color(0x4DF59E0B)),
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Text(
                          reservation.notes!,
                          style:
                              AppTextStyles.bodySm.copyWith(color: fg),
                        ),
                      ),
                    ),
                  ],

                  // Timeline
                  const SizedBox(height: AppSpacing.md),
                  _SectionLabel(l10n.timeline, muted: muted),
                  _TimelineEntry(
                    label: l10n.bookingCreated,
                    time: timeFmt.format(reservation.createdAt.toLocal()),
                    date: DateFormat('dd MMM', 'ar')
                        .format(reservation.createdAt.toLocal()),
                    color: cs.primary,
                    isFirst: true,
                    isLast: true,
                    fg: fg,
                    muted: muted,
                  ),

                  // Internal notes
                  const SizedBox(height: AppSpacing.md),
                  _SectionLabel(l10n.internalNotes, muted: muted),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _surfaceOf(isDark),
                      border: Border.all(color: border),
                      borderRadius: AppRadius.brMd,
                    ),
                    child: TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      style:
                          AppTextStyles.bodySm.copyWith(color: fg),
                      decoration: InputDecoration(
                        hintText: l10n.addInternalNote,
                        hintStyle: AppTextStyles.bodySm
                            .copyWith(color: muted),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.all(AppSpacing.sm),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Quick actions footer ───────────────────────────────────────────
          if (nextStatuses.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('quickActions'),
                    style: AppTextStyles.labelXs.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: nextStatuses.map((s) {
                      final (sfg, sbg, slabel) =
                          _statusDecoration(s, l10n);
                      return _QuickActionButton(
                        label: slabel,
                        color: sfg,
                        bg: sbg,
                        onTap: () async {
                          final err = await cubit.updateStatus(
                              reservation.id, s);
                          if (!context.mounted) return;
                          if (err == null) {
                            AppSnackbar.success(context, l10n.success);
                          } else {
                            AppSnackbar.error(context, err);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Timeline Entry ───────────────────────────────────────────────────────────

class _TimelineEntry extends StatelessWidget {
  final String label;
  final String time;
  final String date;
  final Color color;
  final bool isFirst;
  final bool isLast;
  final Color fg;
  final Color muted;

  const _TimelineEntry({
    required this.label,
    required this.time,
    required this.date,
    required this.color,
    required this.isFirst,
    required this.isLast,
    required this.fg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                    width: 2, height: 32, color: muted.withValues(alpha: 0.3)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        AppTextStyles.labelSm.copyWith(color: fg)),
                const SizedBox(height: 2),
                Text('$date  ·  $time',
                    style: AppTextStyles.bodyXs.copyWith(color: muted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Status Chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;

  const _StatusChip(
      {required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brFull,
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style:
              AppTextStyles.labelXs.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color muted;
  const _SectionLabel(this.text, {required this.muted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.labelXs.copyWith(
            color: muted, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> rows;

  const _InfoCard({required this.isDark, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _surfaceOf(isDark),
        border: Border.all(color: _borderOf(isDark)),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        children: rows
            .asMap()
            .entries
            .map((e) => Column(
                  children: [
                    e.value,
                    if (e.key < rows.length - 1)
                      Divider(height: 1, color: _borderOf(isDark)),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color fg;
  final Color muted;
  final ColorScheme cs;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.fg,
    required this.muted,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 15, color: cs.primary),
          const SizedBox(width: AppSpacing.sm),
          Text('$label: ',
              style: AppTextStyles.bodySm.copyWith(color: muted)),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySm.copyWith(color: fg),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: AppRadius.brMd,
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
                color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
