import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/receipt_entity.dart';
import '../../cubit/receipt_cubit.dart';
import '../../cubit/receipt_state.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final dt = DateTime.parse(iso);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

StatusBadge _statusBadge(String status, AppLocalizations l10n) {
  final label = switch (status) {
    'draft' => l10n.t('statusDraft'),
    'posted' => l10n.t('statusPosted'),
    'cancelled' => l10n.t('statusCancelled'),
    _ => status,
  };
  return switch (status) {
    'posted' => StatusBadge.custom(
        label: label,
        color: AppColors.primary,
        bgColor: AppColors.primaryMuted),
    'cancelled' => StatusBadge.custom(
        label: label,
        color: AppColors.destructive,
        bgColor: AppColors.destructive.withValues(alpha: 0.1)),
    _ => StatusBadge.custom(
        label: label,
        color: AppColors.mutedForeground,
        bgColor: AppColors.muted),
  };
}

// ── Page ──────────────────────────────────────────────────────────────────────

class DesktopReceiptsPage extends StatelessWidget {
  const DesktopReceiptsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReceiptCubit(
        getReceipts: getIt(),
        getReceiptById: getIt(),
        postReceipt: getIt(),
        cancelReceipt: getIt(),
      )..load(),
      child: const _DesktopReceiptsContent(),
    );
  }
}

class _DesktopReceiptsContent extends StatelessWidget {
  const _DesktopReceiptsContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final headerBg =
        isDark ? AppColors.darkMuted : AppColors.primaryMuted;

    return ColoredBox(
      color: bg,
      child: Column(
        children: [
          // Page header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.desktopContentPadding,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.t('receiptsTitle'),
                        style: AppTextStyles.h5.copyWith(color: fg)),
                    Text(l10n.t('receiptsSubtitle'),
                        style: AppTextStyles.bodySm.copyWith(color: muted)),
                  ],
                ),
              ],
            ),
          ),

          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.desktopContentPadding,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: _FilterBar(l10n: l10n, isDark: isDark, muted: muted),
          ),

          // Table
          Expanded(
            child: BlocBuilder<ReceiptCubit, ReceiptState>(
              builder: (context, state) {
                if (state is ReceiptLoading) {
                  return const ShimmerTableRows();
                }
                if (state is ReceiptError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: () => context.read<ReceiptCubit>().refresh(),
                  );
                }
                if (state is ReceiptLoaded) {
                  if (state.receipts.isEmpty) {
                    return Center(
                      child: AppEmptyState(
                        message: l10n.t('noReceipts'),
                        icon: const Icon(
                            Icons.receipt_long_outlined, size: 40),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      // Table header
                      Container(
                        height: AppSizes.tableHeaderHeight,
                        color: headerBg,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.desktopContentPadding),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 160,
                              child: Text(l10n.t('labelReference'),
                                  style: AppTextStyles.tableHeader),
                            ),
                            Expanded(
                              child: Text(l10n.t('labelSupplier'),
                                  style: AppTextStyles.tableHeader),
                            ),
                            SizedBox(
                              width: 160,
                              child: Text(l10n.t('colWarehouse'),
                                  style: AppTextStyles.tableHeader),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(l10n.t('colCreated'),
                                  style: AppTextStyles.tableHeader),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(l10n.t('colTotal'),
                                  style: AppTextStyles.tableHeader,
                                  textAlign: TextAlign.end),
                            ),
                            SizedBox(
                              width: 110,
                              child: Text(l10n.t('colStatus'),
                                  style: AppTextStyles.tableHeader),
                            ),
                            const SizedBox(width: 80),
                          ],
                        ),
                      ),

                      // Rows
                      Expanded(
                        child: ListView.separated(
                          itemCount: state.receipts.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: border),
                          itemBuilder: (context, i) {
                            final r = state.receipts[i];
                            return _ReceiptRow(
                              receipt: r,
                              isDark: isDark,
                              l10n: l10n,
                              fg: fg,
                              muted: muted,
                              border: border,
                            );
                          },
                        ),
                      ),

                      // Pagination
                      if (state.meta.lastPage > 1)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: AppPagination(
                            meta: state.meta,
                            onPageChanged: (p) =>
                                context.read<ReceiptCubit>().goToPage(p),
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
    );
  }
}

class _FilterBar extends StatefulWidget {
  final AppLocalizations l10n;
  final bool isDark;
  final Color muted;

  const _FilterBar(
      {required this.l10n, required this.isDark, required this.muted});

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<ReceiptCubit>().state;
    final statusFilter =
        state is ReceiptLoaded ? state.statusFilter : null;

    final statuses = <(String?, String)>[
      (null, widget.l10n.t('all')),
      ('draft', widget.l10n.t('statusDraft')),
      ('posted', widget.l10n.t('statusPosted')),
      ('cancelled', widget.l10n.t('statusCancelled')),
    ];

    return Row(
      children: [
        SizedBox(
          width: 280,
          child: AppSearchField(
            hint: widget.l10n.t('search'),
            onChanged: (q) => context.read<ReceiptCubit>().search(q),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        ...statuses.map((pair) {
          final isSelected = statusFilter == pair.$1;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: FilterChip(
              label: Text(pair.$2),
              selected: isSelected,
              onSelected: (_) =>
                  context.read<ReceiptCubit>().filterByStatus(pair.$1),
            ),
          );
        }),
      ],
    );
  }
}

class _ReceiptRow extends StatefulWidget {
  final ReceiptEntity receipt;
  final bool isDark;
  final AppLocalizations l10n;
  final Color fg;
  final Color muted;
  final Color border;

  const _ReceiptRow({
    required this.receipt,
    required this.isDark,
    required this.l10n,
    required this.fg,
    required this.muted,
    required this.border,
  });

  @override
  State<_ReceiptRow> createState() => _ReceiptRowState();
}

class _ReceiptRowState extends State<_ReceiptRow> {
  bool _hovering = false;
  bool _expanded = false;
  ReceiptEntity? _detail;
  bool _loadingDetail = false;

  Future<void> _loadDetail() async {
    if (_detail != null) return;
    setState(() => _loadingDetail = true);
    final d = await context.read<ReceiptCubit>().loadDetail(widget.receipt.id);
    if (mounted) {
      setState(() {
        _detail = d;
        _loadingDetail = false;
      });
    }
  }

  Future<void> _doAction(String action) async {
    final l10n = widget.l10n;
    final (title, msg, label, isDestructive) = switch (action) {
      'post' => (
          l10n.t('postReceiptTitle'),
          l10n.t('postReceiptMsg'),
          l10n.t('postReceipt'),
          false
        ),
      _ => (
          l10n.t('cancelReceiptTitle'),
          l10n.t('cancelReceiptMsg'),
          l10n.t('cancelAction'),
          true
        ),
    };
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: title,
      message: msg,
      confirmLabel: label,
      isDestructive: isDestructive,
      onConfirm: () {},
    );
    if (confirmed != true || !mounted) return;

    final cubit = context.read<ReceiptCubit>();
    final ok = action == 'post'
        ? await cubit.postReceipt(widget.receipt.id)
        : await cubit.cancelReceipt(widget.receipt.id);
    if (mounted) {
      ok
          ? AppSnackbar.success(context, l10n.t('actionSuccess'))
          : AppSnackbar.error(context, l10n.t('actionFailed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.receipt;
    final hoverBg = widget.isDark
        ? AppColors.darkMuted.withValues(alpha: 0.4)
        : AppColors.primaryMuted.withValues(alpha: 0.3);

    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: () {
              setState(() => _expanded = !_expanded);
              if (!_expanded) _loadDetail();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: AppSizes.tableRowHeight,
              color: _hovering ? hoverBg : Colors.transparent,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.desktopContentPadding),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(
                      r.reference?.isNotEmpty == true
                          ? r.reference!
                          : '—',
                      style: AppTextStyles.tableCell
                          .copyWith(color: AppColors.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.supplierName ?? '—',
                      style: AppTextStyles.tableCell
                          .copyWith(color: widget.fg),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: Text(
                      r.warehouseName ?? '—',
                      style: AppTextStyles.tableCell
                          .copyWith(color: widget.muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(_fmtDate(r.createdAt),
                        style: AppTextStyles.tableCell
                            .copyWith(color: widget.muted)),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      r.totalValue.toStringAsFixed(2),
                      style: AppTextStyles.numeric
                          .copyWith(color: widget.fg),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: _statusBadge(r.status, widget.l10n),
                  ),
                  SizedBox(
                    width: 80,
                    child: r.status == 'draft'
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                    Icons.check_circle_outline,
                                    size: 16),
                                color: AppColors.primary,
                                onPressed: () => _doAction('post'),
                                tooltip: widget.l10n.t('postReceipt'),
                                constraints:
                                    const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined,
                                    size: 16),
                                color: AppColors.destructive,
                                onPressed: () => _doAction('cancel'),
                                tooltip:
                                    widget.l10n.t('cancelAction'),
                                constraints:
                                    const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Expandable detail row
        if (_expanded)
          _ExpandedDetail(
            receipt: _detail ?? r,
            isLoading: _loadingDetail,
            isDark: widget.isDark,
            l10n: widget.l10n,
            fg: widget.fg,
            muted: widget.muted,
            border: widget.border,
          ),
      ],
    );
  }
}

class _ExpandedDetail extends StatelessWidget {
  final ReceiptEntity receipt;
  final bool isLoading;
  final bool isDark;
  final AppLocalizations l10n;
  final Color fg;
  final Color muted;
  final Color border;

  const _ExpandedDetail({
    required this.receipt,
    required this.isLoading,
    required this.isDark,
    required this.l10n,
    required this.fg,
    required this.muted,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.darkMuted : AppColors.muted;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: border)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : (receipt.items == null || receipt.items!.isEmpty)
              ? Center(
                  child: Text(l10n.t('noItems'),
                      style: AppTextStyles.bodySm.copyWith(color: muted)))
              : _ItemsTable(
                  items: receipt.items!,
                  isDark: isDark,
                  l10n: l10n,
                  fg: fg,
                  muted: muted,
                  border: border),
    );
  }
}

class _ItemsTable extends StatelessWidget {
  final List<ReceiptItemEntity> items;
  final bool isDark;
  final AppLocalizations l10n;
  final Color fg;
  final Color muted;
  final Color border;

  const _ItemsTable({
    required this.items,
    required this.isDark,
    required this.l10n,
    required this.fg,
    required this.muted,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Column(
        children: [
          // Header
          Container(
            height: 32,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.primaryMuted,
              borderRadius: AppRadius.brSm,
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text(l10n.t('colProduct'),
                        style: AppTextStyles.tableHeader)),
                SizedBox(
                    width: 80,
                    child: Text(l10n.t('colQty'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end)),
                SizedBox(
                    width: 110,
                    child: Text(l10n.t('colUnitCost'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end)),
                SizedBox(
                    width: 110,
                    child: Text(l10n.t('colTotal'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 4, horizontal: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                  SizedBox(
                    width: 80,
                    child: Text(
                      item.qty.toStringAsFixed(
                          item.qty == item.qty.truncate() ? 0 : 2),
                      style: AppTextStyles.numeric.copyWith(color: fg),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      item.unitCost.toStringAsFixed(2),
                      style:
                          AppTextStyles.numeric.copyWith(color: muted),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      item.total.toStringAsFixed(2),
                      style: AppTextStyles.numeric.copyWith(color: fg),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
