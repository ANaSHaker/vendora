import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
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
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/adjustment_entities.dart';
import '../../cubit/adjustment_cubit.dart';
import '../../cubit/adjustment_state.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

StatusBadge _typeBadge(String type, AppLocalizations l10n) {
  final label = switch (type) {
    'adjustment_in' => l10n.t('adjustmentIn'),
    'adjustment_out' => l10n.t('adjustmentOut'),
    'damaged' => l10n.t('damaged'),
    'stock_count' => l10n.t('adjustmentType_stock_count'),
    _ => type,
  };
  return StatusBadge.custom(
    label: label,
    color: AppColors.mutedForeground,
    bgColor: AppColors.muted,
  );
}

StatusBadge _statusBadge(String status, AppLocalizations l10n) {
  final label = switch (status) {
    'draft' => l10n.t('statusDraft'),
    'approved' => l10n.t('statusApproved'),
    'posted' => l10n.t('statusPosted'),
    'cancelled' => l10n.t('statusCancelled'),
    _ => status,
  };
  return switch (status) {
    'approved' => StatusBadge.custom(
        label: label,
        color: AppColors.primary,
        bgColor: AppColors.primaryMuted,
      ),
    'posted' => StatusBadge.custom(
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

class DesktopAdjustmentsPage extends StatelessWidget {
  const DesktopAdjustmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdjustmentCubit(
        getAdjustments: getIt(),
        getAdjustmentById: getIt(),
        createAdjustment: getIt(),
        updateAdjustment: getIt(),
        approveAdjustment: getIt(),
        postAdjustment: getIt(),
        cancelAdjustment: getIt(),
        deleteAdjustment: getIt(),
      )..load(),
      child: const _AdjustmentsContent(),
    );
  }
}

class _AdjustmentsContent extends StatelessWidget {
  const _AdjustmentsContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdjustmentCubit, AdjustmentState>(
      builder: (context, state) {
        final cubit = context.read<AdjustmentCubit>();
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
                          l10n.t('adjustments'),
                          style: AppTextStyles.h4.copyWith(color: fg),
                        ),
                        if (state is AdjustmentLoaded)
                          Text(
                            '${state.meta.total} ${l10n.t("adjustmentsTotal")}',
                            style: AppTextStyles.bodySm.copyWith(color: muted),
                          ),
                      ],
                    ),
                    const Spacer(),
                    AppButton.primary(
                      label: l10n.t('newAdjustment'),
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.add, size: 16),
                      onPressed: () =>
                          _showFormDialog(context, cubit, l10n),
                    ),
                  ],
                ),
              ),

              // Filters row
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.desktopContentPadding),
                child: _FiltersRow(
                  statusFilter: state is AdjustmentLoaded
                      ? state.statusFilter
                      : null,
                  typeFilter: state is AdjustmentLoaded
                      ? state.typeFilter
                      : null,
                  onStatusChanged: cubit.filterByStatus,
                  onTypeChanged: cubit.filterByType,
                  isDark: isDark,
                  l10n: l10n,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Table
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.desktopContentPadding),
                  child: switch (state) {
                    AdjustmentInitial() || AdjustmentLoading() =>
                      const ShimmerTableRows(),
                    AdjustmentError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: cubit.refresh,
                      ),
                    AdjustmentLoaded(:final adjustments)
                        when adjustments.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(Icons.tune_outlined, size: 40),
                        message: l10n.t('noAdjustments'),
                        action: AppButton.primary(
                          label: l10n.t('newAdjustment'),
                          onPressed: () =>
                              _showFormDialog(context, cubit, l10n),
                        ),
                      ),
                    AdjustmentLoaded(
                      :final adjustments,
                      :final meta,
                    ) =>
                      Column(
                        children: [
                          Expanded(
                            child: _AdjustmentsTable(
                              adjustments: adjustments,
                              isDark: isDark,
                              l10n: l10n,
                              onView: (a) =>
                                  _showViewDialog(context, cubit, l10n, a),
                              onEdit: (a) =>
                                  _showFormDialog(context, cubit, l10n, editing: a),
                              onApprove: (a) => _confirmAction(
                                context, cubit, l10n,
                                l10n.t('approveAdjustmentTitle'),
                                l10n.t('approveAdjustmentMsg'),
                                l10n.t('approve'),
                                false,
                                () => cubit.approveAdjustment(a.id),
                              ),
                              onPost: (a) => _confirmAction(
                                context, cubit, l10n,
                                l10n.t('postAdjustmentTitle'),
                                l10n.t('postAdjustmentMsg'),
                                l10n.t('post'),
                                false,
                                () => cubit.postAdjustment(a.id),
                              ),
                              onCancel: (a) => _confirmAction(
                                context, cubit, l10n,
                                l10n.t('cancelAdjustmentTitle'),
                                l10n.t('cancelAdjustmentMsg'),
                                l10n.cancel,
                                true,
                                () => cubit.cancelAdjustment(a.id),
                              ),
                              onDelete: (a) => _confirmAction(
                                context, cubit, l10n,
                                l10n.t('deleteAdjustmentTitle'),
                                l10n.t('deleteAdjustmentMsg'),
                                l10n.delete,
                                true,
                                () => cubit.deleteAdjustment(a.id),
                              ),
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

// ── Filters row ───────────────────────────────────────────────────────────────

class _FiltersRow extends StatelessWidget {
  final String? statusFilter;
  final String? typeFilter;
  final void Function(String?) onStatusChanged;
  final void Function(String?) onTypeChanged;
  final bool isDark;
  final AppLocalizations l10n;

  const _FiltersRow({
    required this.statusFilter,
    required this.typeFilter,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      (null, l10n.t('all')),
      ('draft', l10n.t('statusDraft')),
      ('approved', l10n.t('statusApproved')),
      ('posted', l10n.t('statusPosted')),
      ('cancelled', l10n.t('statusCancelled')),
    ];
    final types = [
      (null, l10n.t('all')),
      ('adjustment_in', l10n.t('adjustmentIn')),
      ('adjustment_out', l10n.t('adjustmentOut')),
      ('damaged', l10n.t('damaged')),
      ('stock_count', l10n.t('adjustmentType_stock_count')),
    ];

    return Row(
      children: [
        SizedBox(
          width: 180,
          child: AppSelectField<String?>(
            label: l10n.t('colStatus'),
            hint: l10n.t('colStatus'),
            value: statusFilter,
            options: statuses
                .map((t) => AppSelectOption(value: t.$1, label: t.$2))
                .toList(),
            onChanged: onStatusChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 180,
          child: AppSelectField<String?>(
            label: l10n.t('adjustmentType'),
            hint: l10n.t('adjustmentType'),
            value: typeFilter,
            options: types
                .map((t) => AppSelectOption(value: t.$1, label: t.$2))
                .toList(),
            onChanged: onTypeChanged,
          ),
        ),
      ],
    );
  }
}

// ── Table ─────────────────────────────────────────────────────────────────────

class _AdjustmentsTable extends StatelessWidget {
  final List<AdjustmentEntity> adjustments;
  final bool isDark;
  final AppLocalizations l10n;
  final void Function(AdjustmentEntity) onView;
  final void Function(AdjustmentEntity) onEdit;
  final void Function(AdjustmentEntity) onApprove;
  final void Function(AdjustmentEntity) onPost;
  final void Function(AdjustmentEntity) onCancel;
  final void Function(AdjustmentEntity) onDelete;

  const _AdjustmentsTable({
    required this.adjustments,
    required this.isDark,
    required this.l10n,
    required this.onView,
    required this.onEdit,
    required this.onApprove,
    required this.onPost,
    required this.onCancel,
    required this.onDelete,
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
            Container(
              height: AppSizes.tableHeaderHeight,
              color: headerBg,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Text(l10n.t('colReference'),
                          style: AppTextStyles.tableHeader)),
                  Expanded(
                      child: Text(l10n.t('colType'),
                          style: AppTextStyles.tableHeader)),
                  Expanded(
                      child: Text(l10n.t('colBranch'),
                          style: AppTextStyles.tableHeader)),
                  SizedBox(
                    width: 100,
                    child: Text(l10n.t('colDate'),
                        style: AppTextStyles.tableHeader),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(l10n.t('colStatus'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    width: 140,
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
                itemCount: adjustments.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: border),
                itemBuilder: (context, i) {
                  final a = adjustments[i];
                  return Container(
                    height: AppSizes.tableRowHeight,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            a.reference?.isNotEmpty == true
                                ? a.reference!
                                : '—',
                            style:
                                AppTextStyles.numeric.copyWith(color: fg),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: _typeBadge(a.adjustmentType, l10n),
                        ),
                        Expanded(
                          child: Text(
                            a.branchName ?? '—',
                            style:
                                AppTextStyles.tableCell.copyWith(color: fg),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            _fmtDate(a.date),
                            style:
                                AppTextStyles.tableCell.copyWith(color: muted),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child:
                              Center(child: _statusBadge(a.status, l10n)),
                        ),
                        SizedBox(
                          width: 140,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (a.status != 'cancelled') ...[
                                AppIconButton(
                                  icon: const Icon(Icons.visibility_outlined,
                                      size: 14),
                                  onPressed: () => onView(a),
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  tooltip: l10n.t('viewAdjustment'),
                                ),
                              ],
                              if (a.status == 'draft') ...[
                                AppIconButton(
                                  icon: const Icon(
                                      Icons.thumb_up_outlined,
                                      size: 14),
                                  onPressed: () => onApprove(a),
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  tooltip: l10n.t('approve'),
                                ),
                                AppIconButton(
                                  icon: const Icon(Icons.cancel_outlined,
                                      size: 14),
                                  onPressed: () => onCancel(a),
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  tooltip: l10n.cancel,
                                ),
                                AppIconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 14),
                                  onPressed: () => onDelete(a),
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  tooltip: l10n.delete,
                                ),
                              ] else if (a.status == 'approved') ...[
                                AppIconButton(
                                  icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 14),
                                  onPressed: () => onPost(a),
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  tooltip: l10n.t('post'),
                                ),
                                AppIconButton(
                                  icon: const Icon(Icons.cancel_outlined,
                                      size: 14),
                                  onPressed: () => onCancel(a),
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  tooltip: l10n.cancel,
                                ),
                              ],
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

// ── Confirm action ────────────────────────────────────────────────────────────

Future<void> _confirmAction(
  BuildContext context,
  AdjustmentCubit cubit,
  AppLocalizations l10n,
  String title,
  String message,
  String confirmLabel,
  bool isDestructive,
  Future<bool> Function() action,
) async {
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    isDestructive: isDestructive,
    onConfirm: () {},
  );
  if (confirmed != true || !context.mounted) return;
  final ok = await action();
  if (context.mounted) {
    ok
        ? AppSnackbar.success(context, l10n.t('actionSuccess'))
        : AppSnackbar.error(context, l10n.t('actionFailed'));
  }
}

// ── View dialog ───────────────────────────────────────────────────────────────

Future<void> _showViewDialog(
  BuildContext context,
  AdjustmentCubit cubit,
  AppLocalizations l10n,
  AdjustmentEntity adjustment,
) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _AdjustmentViewDialog(
      adjustment: adjustment,
      cubit: cubit,
      l10n: l10n,
    ),
  );
}

class _AdjustmentViewDialog extends StatefulWidget {
  final AdjustmentEntity adjustment;
  final AdjustmentCubit cubit;
  final AppLocalizations l10n;

  const _AdjustmentViewDialog({
    required this.adjustment,
    required this.cubit,
    required this.l10n,
  });

  @override
  State<_AdjustmentViewDialog> createState() =>
      _AdjustmentViewDialogState();
}

class _AdjustmentViewDialogState extends State<_AdjustmentViewDialog> {
  AdjustmentEntity? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final detail = await widget.cubit.loadDetail(widget.adjustment.id);
    if (mounted) {
      setState(() {
        _detail = detail ?? widget.adjustment;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final a = _detail ?? widget.adjustment;
    final isPosted = a.status == 'posted';

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      child: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.md, 0),
              child: Row(
                children: [
                  Text(l10n.t('adjustmentDetail'),
                      style: AppTextStyles.h5),
                  const SizedBox(width: AppSpacing.sm),
                  _statusBadge(a.status, l10n),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const Divider(height: AppSpacing.lg, color: AppColors.border),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info grid
                      Wrap(
                        spacing: AppSpacing.xl,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _InfoChip(
                              label: l10n.t('labelReference'),
                              value: a.reference?.isNotEmpty == true
                                  ? a.reference!
                                  : '—'),
                          _InfoChip(
                              label: l10n.t('colBranch'),
                              value: a.branchName ?? '—'),
                          _InfoChip(
                              label: l10n.t('labelWarehouse'),
                              value: a.warehouseName ?? '—'),
                          _InfoChip(
                              label: l10n.t('adjustmentType'),
                              value: _typeLabel(a.adjustmentType, l10n)),
                          _InfoChip(
                              label: l10n.t('labelDate'),
                              value: _fmtDate(a.date)),
                        ],
                      ),

                      if (a.items != null && a.items!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(l10n.t('labelItems'),
                            style: AppTextStyles.labelMd),
                        const SizedBox(height: AppSpacing.sm),
                        _ItemsTable(
                          items: a.items!,
                          isPosted: isPosted,
                          l10n: l10n,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.outline(
                    label: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type, AppLocalizations l10n) => switch (type) {
        'adjustment_in' => l10n.t('adjustmentIn'),
        'adjustment_out' => l10n.t('adjustmentOut'),
        'damaged' => l10n.t('damaged'),
        'stock_count' => l10n.t('adjustmentType_stock_count'),
        _ => type,
      };
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.bodyXs
                .copyWith(color: muted, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.labelSm.copyWith(color: fg)),
      ],
    );
  }
}

class _ItemsTable extends StatelessWidget {
  final List<AdjustmentItemEntity> items;
  final bool isPosted;
  final AppLocalizations l10n;

  const _ItemsTable({
    required this.items,
    required this.isPosted,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: AppRadius.brSm,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brSm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 36,
              color: headerBg,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text(l10n.t('labelProductName'),
                          style: AppTextStyles.tableHeader)),
                  if (isPosted) ...[
                    SizedBox(
                      width: 80,
                      child: Text(l10n.t('colQtyBefore'),
                          style: AppTextStyles.tableHeader,
                          textAlign: TextAlign.end),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(l10n.t('colQtyAfter'),
                          style: AppTextStyles.tableHeader,
                          textAlign: TextAlign.end),
                    ),
                  ],
                  SizedBox(
                    width: 80,
                    child: Text(l10n.t('labelQty'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                ],
              ),
            ),
            for (final item in items) ...[
              Divider(height: 1, color: border),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.productName,
                              style:
                                  AppTextStyles.tableCell.copyWith(color: fg),
                              overflow: TextOverflow.ellipsis),
                          if (item.productSku != null)
                            Text(item.productSku!,
                                style: AppTextStyles.bodyXs
                                    .copyWith(color: muted)),
                        ],
                      ),
                    ),
                    if (isPosted) ...[
                      SizedBox(
                        width: 80,
                        child: Text(
                          item.quantityBefore?.toStringAsFixed(2) ?? '—',
                          style: AppTextStyles.numeric.copyWith(color: muted),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          item.quantityAfter?.toStringAsFixed(2) ?? '—',
                          style: AppTextStyles.numeric.copyWith(color: fg),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                    SizedBox(
                      width: 80,
                      child: Text(
                        item.qty.toStringAsFixed(2),
                        style: AppTextStyles.numeric.copyWith(color: fg),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Form dialog ───────────────────────────────────────────────────────────────

Future<void> _showFormDialog(
  BuildContext context,
  AdjustmentCubit cubit,
  AppLocalizations l10n, {
  AdjustmentEntity? editing,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AdjustmentFormDialog(
      editing: editing,
      l10n: l10n,
      onSave: (data) async {
        final ok = editing != null
            ? await cubit.updateAdjustment(editing.id, data)
            : await cubit.createAdjustment(data);
        if (ok && context.mounted) {
          AppSnackbar.success(
            context,
            editing != null
                ? l10n.t('adjustmentUpdated')
                : l10n.t('adjustmentCreated'),
          );
        }
        return ok;
      },
    ),
  );
}

class _AdjustmentFormDialog extends StatefulWidget {
  final AdjustmentEntity? editing;
  final AppLocalizations l10n;
  final Future<bool> Function(AdjustmentFormData) onSave;

  const _AdjustmentFormDialog({
    this.editing,
    required this.l10n,
    required this.onSave,
  });

  @override
  State<_AdjustmentFormDialog> createState() => _AdjustmentFormDialogState();
}

class _AdjustmentFormDialogState extends State<_AdjustmentFormDialog> {
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late String _type;
  late String _date;
  String? _branchId;
  String? _warehouseId;
  bool _loadingData = true;
  List<_DropdownItem> _branches = [];
  List<_DropdownItem> _warehouses = [];
  List<_DropdownItem> _products = [];
  final List<_ItemRowData> _items = [];
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _type = e?.adjustmentType ?? 'adjustment_in';
    _date = e?.date ?? _todayStr();
    _refCtrl.text = e?.reference ?? '';
    _notesCtrl.text = e?.notes ?? '';
    _items.add(_ItemRowData());
    _loadData();
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    _notesCtrl.dispose();
    for (final r in _items) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final client = getIt<ApiClient>();
      final results = await Future.wait([
        client.get<Map<String, dynamic>>(ApiEndpoints.branches,
            queryParameters: {'per_page': 200}),
        client.get<Map<String, dynamic>>(ApiEndpoints.warehouses,
            queryParameters: {'per_page': 200}),
        client.get<Map<String, dynamic>>(ApiEndpoints.products,
            queryParameters: {'per_page': 200}),
      ]);

      final branchData = results[0].data as Map<String, dynamic>;
      final warehouseData = results[1].data as Map<String, dynamic>;
      final productData = results[2].data as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _branches = ((branchData['data'] as List<dynamic>?) ?? [])
              .cast<Map<String, dynamic>>()
              .map((b) => _DropdownItem(b['id']?.toString() ?? '', b['name'] as String? ?? ''))
              .toList();
          _warehouses = ((warehouseData['data'] as List<dynamic>?) ?? [])
              .cast<Map<String, dynamic>>()
              .map((w) => _DropdownItem(w['id']?.toString() ?? '', w['name'] as String? ?? ''))
              .toList();
          _products = ((productData['data'] as List<dynamic>?) ?? [])
              .cast<Map<String, dynamic>>()
              .map((p) => _DropdownItem(
                    p['id']?.toString() ?? '',
                    '${p['name'] ?? ''}${p['sku'] != null ? ' (${p['sku']})' : ''}',
                  ))
              .toList();
          _loadingData = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  Future<void> _submit() async {
    if (_warehouseId == null) {
      setState(() => _error = widget.l10n.t('warehouseRequired'));
      return;
    }
    final validItems = _items
        .where((r) => r.productId != null)
        .map((r) => AdjustmentItemInput(
              productId: r.productId!,
              productName: r.productName ?? '',
              qty: double.tryParse(r.qtyCtrl.text.trim()) ?? 0,
              note: r.noteCtrl.text.trim().isEmpty
                  ? null
                  : r.noteCtrl.text.trim(),
            ))
        .toList();
    if (validItems.isEmpty) {
      setState(() => _error = widget.l10n.t('itemsRequired'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final data = AdjustmentFormData(
      adjustmentType: _type,
      branchId: _branchId,
      warehouseId: _warehouseId!,
      reference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      date: _date,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      items: validItems,
    );
    final ok = await widget.onSave(data);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _submitting = false;
        _error = widget.l10n.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isEditing = widget.editing != null;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      child: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.md, 0),
              child: Row(
                children: [
                  Text(
                    isEditing
                        ? l10n.t('editAdjustment')
                        : l10n.t('newAdjustment'),
                    style: AppTextStyles.h5,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const Divider(height: AppSpacing.lg, color: AppColors.border),

            if (_loadingData)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) _ErrorBanner(message: _error!),

                      // Type & Branch row
                      Row(
                        children: [
                          Expanded(
                            child: AppSelectField<String>(
                              label: '${l10n.t("adjustmentType")} *',
                              hint: l10n.t('selectType'),
                              value: _type,
                              options: [
                                AppSelectOption(
                                    value: 'adjustment_in',
                                    label: l10n.t('adjustmentIn')),
                                AppSelectOption(
                                    value: 'adjustment_out',
                                    label: l10n.t('adjustmentOut')),
                                AppSelectOption(
                                    value: 'damaged',
                                    label: l10n.t('damaged')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _type = v ?? 'adjustment_in'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppSelectField<String?>(
                              label: l10n.t('labelBranch'),
                              hint: l10n.t('selectBranch'),
                              value: _branchId,
                              options: [
                                AppSelectOption(
                                    value: null,
                                    label: l10n.t('all')),
                                ..._branches.map((b) =>
                                    AppSelectOption(value: b.id, label: b.name)),
                              ],
                              onChanged: (v) =>
                                  setState(() => _branchId = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Warehouse (full width)
                      AppSelectField<String?>(
                        label: '${l10n.t("labelWarehouse")} *',
                        hint: l10n.t('selectWarehouse'),
                        value: _warehouseId,
                        options: _warehouses
                            .map((w) =>
                                AppSelectOption(value: w.id, label: w.name))
                            .toList(),
                        onChanged: (v) => setState(() => _warehouseId = v),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Reference & Date
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: l10n.t('labelReference'),
                              hint: l10n.t('referencePlaceholder'),
                              controller: _refCtrl,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppTextField(
                              label: l10n.t('labelDate'),
                              hint: 'YYYY-MM-DD',
                              controller:
                                  TextEditingController(text: _date),
                              onChanged: (v) => _date = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      AppTextField(
                        label: l10n.t('labelNotes'),
                        hint: l10n.t('notesPlaceholder'),
                        controller: _notesCtrl,
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Items
                      Row(
                        children: [
                          Text(l10n.t('labelItems'),
                              style: AppTextStyles.labelMd),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _items.add(_ItemRowData())),
                            icon: const Icon(Icons.add, size: 14),
                            label: Text(l10n.t('addItem')),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      for (var i = 0; i < _items.length; i++)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                flex: 3,
                                child: AppSelectField<String?>(
                                  label: i == 0
                                      ? l10n.t('labelProductName')
                                      : null,
                                  hint: l10n.t('selectProduct'),
                                  value: _items[i].productId,
                                  options: _products
                                      .map((p) => AppSelectOption(
                                          value: p.id, label: p.name))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      _items[i].productId = v;
                                      _items[i].productName =
                                          v == null
                                              ? null
                                              : _products
                                                  .firstWhere(
                                                      (p) => p.id == v,
                                                      orElse: () =>
                                                          _DropdownItem('', ''))
                                                  .name;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: AppTextField(
                                  label: i == 0
                                      ? l10n.t('labelQty')
                                      : null,
                                  hint: '0',
                                  controller: _items[i].qtyCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              if (_items.length > 1)
                                Padding(
                                  padding: EdgeInsets.only(
                                      bottom: i == 0
                                          ? AppSpacing.xs
                                          : 0),
                                  child: IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 18,
                                        color: AppColors.destructive),
                                    onPressed: () => setState(() {
                                      _items[i].dispose();
                                      _items.removeAt(i);
                                    }),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.outline(
                    label: l10n.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton.primary(
                    label: isEditing
                        ? l10n.saveChanges
                        : l10n.t('createAdjustment'),
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
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

// ── Internal data models ──────────────────────────────────────────────────────

class _ItemRowData {
  String? productId;
  String? productName;
  final qtyCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  void dispose() {
    qtyCtrl.dispose();
    noteCtrl.dispose();
  }
}

class _DropdownItem {
  final String id;
  final String name;
  const _DropdownItem(this.id, this.name);
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: AppRadius.brSm,
        border:
            Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 14, color: AppColors.destructive),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
  }
}
