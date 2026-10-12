import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/buttons/app_icon_button.dart';
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/transfer_entities.dart';
import '../../cubit/transfer_cubit.dart';
import '../../cubit/transfer_state.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

StatusBadge _transferStatusBadge(String status, AppLocalizations l10n) {
  final label = switch (status) {
    'draft' => l10n.t('statusDraft'),
    'approved' => l10n.t('statusApproved'),
    'in_transit' => l10n.t('statusInTransit'),
    'received' => l10n.t('statusReceived'),
    'cancelled' => l10n.t('statusCancelled'),
    _ => status,
  };
  return switch (status) {
    'approved' => StatusBadge.custom(
        label: label,
        color: AppColors.primary,
        bgColor: AppColors.primaryMuted,
      ),
    'in_transit' => StatusBadge.custom(
        label: label,
        color: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFEF3C7),
      ),
    'received' => StatusBadge.custom(
        label: label,
        color: AppColors.primary,
        bgColor: AppColors.primaryMuted,
      ),
    'cancelled' => StatusBadge.custom(
        label: label,
        color: AppColors.destructive,
        bgColor: AppColors.destructive.withValues(alpha: 0.1),
      ),
    _ => StatusBadge.custom(
        label: label,
        color: AppColors.mutedForeground,
        bgColor: AppColors.muted,
      ),
  };
}

// ── Page ──────────────────────────────────────────────────────────────────────

class DesktopTransfersPage extends StatelessWidget {
  const DesktopTransfersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransferCubit(
        getTransfers: getIt(),
        createTransfer: getIt(),
        approveTransfer: getIt(),
        postTransfer: getIt(),
        receiveTransfer: getIt(),
        deleteTransfer: getIt(),
      )..load(),
      child: const _TransfersContent(),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _TransfersContent extends StatelessWidget {
  const _TransfersContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransferCubit, TransferState>(
      builder: (context, state) {
        final cubit = context.read<TransferCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted =
            isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

        return ColoredBox(
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('transfers'),
                          style: AppTextStyles.h4.copyWith(color: fg),
                        ),
                        if (state is TransferLoaded)
                          Text(
                            '${state.meta.total} ${l10n.t("transfersTotal")}',
                            style:
                                AppTextStyles.bodySm.copyWith(color: muted),
                          ),
                      ],
                    ),
                    const Spacer(),
                    AppButton.primary(
                      label: l10n.t('newTransfer'),
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.add, size: 16),
                      onPressed: () => context.go('/transfers/create'),
                    ),
                  ],
                ),
              ),

              // Toolbar
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.desktopContentPadding),
                child: Row(
                  children: [
                    SizedBox(
                      width: 280,
                      child: AppSearchField(
                        hint: l10n.t('searchTransfers'),
                        onChanged: cubit.search,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 180,
                      child: AppSelectField<String?>(
                        hint: l10n.t('allStatuses'),
                        value: state is TransferLoaded
                            ? state.statusFilter
                            : null,
                        options: [
                          AppSelectOption(
                              value: null, label: l10n.t('allStatuses')),
                          AppSelectOption(
                              value: 'draft', label: l10n.t('statusDraft')),
                          AppSelectOption(
                              value: 'approved',
                              label: l10n.t('statusApproved')),
                          AppSelectOption(
                              value: 'in_transit',
                              label: l10n.t('statusInTransit')),
                          AppSelectOption(
                              value: 'received',
                              label: l10n.t('statusReceived')),
                          AppSelectOption(
                              value: 'cancelled',
                              label: l10n.t('statusCancelled')),
                        ],
                        onChanged: cubit.filterByStatus,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Table
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.desktopContentPadding),
                  child: switch (state) {
                    TransferInitial() || TransferLoading() =>
                      const ShimmerTableRows(),
                    TransferError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: cubit.refresh,
                      ),
                    TransferLoaded(:final transfers)
                        when transfers.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(Icons.swap_horiz_outlined, size: 40),
                        message: l10n.t('noTransfers'),
                        action: AppButton.primary(
                          label: l10n.t('newTransfer'),
                          onPressed: () => context.go('/transfers/create'),
                        ),
                      ),
                    TransferLoaded(:final transfers, :final meta) =>
                      Column(
                        children: [
                          Expanded(
                            child: _TransfersTable(
                              transfers: transfers,
                              isDark: isDark,
                              l10n: l10n,
                              onApprove: (t) => _confirmWorkflow(
                                  context, cubit, l10n, t, 'approve'),
                              onShip: (t) => _confirmWorkflow(
                                  context, cubit, l10n, t, 'ship'),
                              onReceive: (t) => _confirmWorkflow(
                                  context, cubit, l10n, t, 'receive'),
                              onDelete: (t) => _confirmWorkflow(
                                  context, cubit, l10n, t, 'delete'),
                              onView: (t) =>
                                  context.go('/transfers/${t.id}'),
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

// ── Table ─────────────────────────────────────────────────────────────────────

class _TransfersTable extends StatelessWidget {
  final List<TransferEntity> transfers;
  final bool isDark;
  final AppLocalizations l10n;
  final void Function(TransferEntity) onApprove;
  final void Function(TransferEntity) onShip;
  final void Function(TransferEntity) onReceive;
  final void Function(TransferEntity) onDelete;
  final void Function(TransferEntity) onView;

  const _TransfersTable({
    required this.transfers,
    required this.isDark,
    required this.l10n,
    required this.onApprove,
    required this.onShip,
    required this.onReceive,
    required this.onDelete,
    required this.onView,
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            // Header
            Container(
              height: AppSizes.tableHeaderHeight,
              color: headerBg,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Text(l10n.t('colReference'),
                          style: AppTextStyles.tableHeader)),
                  Expanded(
                      flex: 3,
                      child: Text(
                          '${l10n.t("colFrom")} → ${l10n.t("colTo")}',
                          style: AppTextStyles.tableHeader)),
                  SizedBox(
                    width: 110,
                    child: Text(l10n.t('colStatus'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(l10n.t('colCreated'),
                        style: AppTextStyles.tableHeader),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(l10n.t('colActions'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),

            Expanded(
              child: ListView.separated(
                itemCount: transfers.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: border),
                itemBuilder: (context, i) {
                  final t = transfers[i];
                  return Container(
                    height: AppSizes.tableRowHeight,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        // Reference
                        Expanded(
                          flex: 2,
                          child: Text(
                            t.reference?.isNotEmpty == true
                                ? t.reference!
                                : '—',
                            style:
                                AppTextStyles.numeric.copyWith(color: fg),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // From → To
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  t.fromWarehouseName,
                                  style: AppTextStyles.tableCell
                                      .copyWith(color: fg),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs),
                                child: Icon(Icons.arrow_forward,
                                    size: 12, color: muted),
                              ),
                              Flexible(
                                child: Text(
                                  t.toWarehouseName,
                                  style: AppTextStyles.tableCell
                                      .copyWith(color: fg),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status
                        SizedBox(
                          width: 110,
                          child: Center(
                            child: _transferStatusBadge(t.status, l10n),
                          ),
                        ),
                        // Date
                        SizedBox(
                          width: 100,
                          child: Text(
                            _fmtDate(t.createdAt),
                            style: AppTextStyles.tableCell
                                .copyWith(color: muted),
                          ),
                        ),
                        // Actions
                        SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppIconButton(
                                icon: const Icon(Icons.visibility_outlined,
                                    size: 14),
                                onPressed: () => onView(t),
                                variant: AppButtonVariant.ghost,
                                size: AppButtonSize.sm,
                                tooltip: l10n.t('viewDetail'),
                              ),
                              if (t.status == 'draft')
                                AppIconButton(
                                  icon: const Icon(
                                      Icons.thumb_up_outlined,
                                      size: 14),
                                  onPressed: () => onApprove(t),
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  tooltip: l10n.t('approve'),
                                ),
                              if (t.status == 'approved')
                                AppIconButton(
                                  icon: const Icon(
                                      Icons.local_shipping_outlined,
                                      size: 14),
                                  onPressed: () => onShip(t),
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  tooltip: l10n.t('ship'),
                                ),
                              if (t.status == 'in_transit')
                                AppIconButton(
                                  icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 14),
                                  onPressed: () => onReceive(t),
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  tooltip: l10n.t('receive'),
                                ),
                              if (t.status == 'draft')
                                AppIconButton(
                                  icon: const Icon(
                                      Icons.delete_outline,
                                      size: 14),
                                  onPressed: () => onDelete(t),
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  tooltip: l10n.delete,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

// ── Workflow confirm ──────────────────────────────────────────────────────────

Future<void> _confirmWorkflow(
  BuildContext context,
  TransferCubit cubit,
  AppLocalizations l10n,
  TransferEntity t,
  String action,
) async {
  final (title, msg, label, destructive) = switch (action) {
    'approve' => (
        l10n.t('approveTransferTitle'),
        l10n.t('approveTransferMsg'),
        l10n.t('approve'),
        false
      ),
    'ship' => (
        l10n.t('shipTransferTitle'),
        l10n.t('shipTransferMsg'),
        l10n.t('ship'),
        false
      ),
    'receive' => (
        l10n.t('receiveTransferTitle'),
        l10n.t('receiveTransferMsg'),
        l10n.t('receive'),
        false
      ),
    _ => (
        l10n.t('deleteTransferTitle'),
        l10n.t('deleteTransferMsg'),
        l10n.delete,
        true
      ),
  };

  final confirmed = await ConfirmDialog.show(
    context: context,
    title: title,
    message: msg,
    confirmLabel: label,
    isDestructive: destructive,
    onConfirm: () {},
  );
  if (confirmed != true || !context.mounted) return;

  final ok = await switch (action) {
    'approve' => cubit.approveTransfer(t.id),
    'ship' => cubit.shipTransfer(t.id),
    'receive' => cubit.receiveTransfer(t.id),
    _ => cubit.deleteTransfer(t.id),
  };

  if (context.mounted) {
    ok
        ? AppSnackbar.success(context, l10n.t('actionSuccess'))
        : AppSnackbar.error(context, l10n.t('actionFailed'));
  }
}
