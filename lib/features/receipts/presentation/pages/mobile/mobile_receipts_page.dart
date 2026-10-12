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

class MobileReceiptsPage extends StatelessWidget {
  const MobileReceiptsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReceiptCubit(
        getReceipts: getIt(),
        getReceiptById: getIt(),
        postReceipt: getIt(),
        cancelReceipt: getIt(),
      )..load(),
      child: const _MobileReceiptsContent(),
    );
  }
}

class _MobileReceiptsContent extends StatelessWidget {
  const _MobileReceiptsContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('receiptsTitle')),
      ),
      body: Column(
        children: [
          _SearchAndFilter(l10n: l10n, isDark: isDark),
          Expanded(
            child: BlocBuilder<ReceiptCubit, ReceiptState>(
              builder: (context, state) {
                if (state is ReceiptLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: ShimmerTableRows(),
                  );
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
                        icon: const Icon(Icons.receipt_long_outlined, size: 40),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => context.read<ReceiptCubit>().refresh(),
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        ...state.receipts.map(
                          (r) => _ReceiptCard(
                            receipt: r,
                            isDark: isDark,
                            l10n: l10n,
                          ),
                        ),
                        if (state.meta.lastPage > 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            child: AppPagination(
                              meta: state.meta,
                              onPageChanged: (p) =>
                                  context.read<ReceiptCubit>().goToPage(p),
                            ),
                          ),
                      ],
                    ),
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

class _SearchAndFilter extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isDark;

  const _SearchAndFilter({required this.l10n, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ReceiptCubit>().state;
    final statusFilter = state is ReceiptLoaded ? state.statusFilter : null;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    final statuses = <(String?, String)>[
      (null, l10n.t('all')),
      ('draft', l10n.t('statusDraft')),
      ('posted', l10n.t('statusPosted')),
      ('cancelled', l10n.t('statusCancelled')),
    ];

    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          AppSearchField(
            hint: l10n.t('search'),
            onChanged: (q) => context.read<ReceiptCubit>().search(q),
          ),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statuses.map((pair) {
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
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatefulWidget {
  final ReceiptEntity receipt;
  final bool isDark;
  final AppLocalizations l10n;

  const _ReceiptCard({
    required this.receipt,
    required this.isDark,
    required this.l10n,
  });

  @override
  State<_ReceiptCard> createState() => _ReceiptCardState();
}

class _ReceiptCardState extends State<_ReceiptCard> {
  bool _expanded = false;
  ReceiptEntity? _detail;
  bool _loadingDetail = false;

  Future<void> _loadDetail() async {
    if (_detail != null) return;
    setState(() => _loadingDetail = true);
    final d =
        await context.read<ReceiptCubit>().loadDetail(widget.receipt.id);
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
    final isDark = widget.isDark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final l10n = widget.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: AppRadius.brMd,
            onTap: () {
              setState(() => _expanded = !_expanded);
              if (_expanded) _loadDetail();
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.reference?.isNotEmpty == true
                              ? r.reference!
                              : '—',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _statusBadge(r.status, l10n),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (r.supplierName != null) ...[
                    Text(
                      r.supplierName!,
                      style: AppTextStyles.bodySm.copyWith(color: fg),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.warehouse_outlined,
                          size: 14, color: muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          r.warehouseName ?? '—',
                          style: AppTextStyles.bodyXs.copyWith(color: muted),
                        ),
                      ),
                      Text(
                        _fmtDate(r.createdAt),
                        style: AppTextStyles.bodyXs.copyWith(color: muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${r.itemsCount} ${l10n.t('itemsCount')}',
                        style: AppTextStyles.bodyXs.copyWith(color: muted),
                      ),
                      Text(
                        r.totalValue.toStringAsFixed(2),
                        style: AppTextStyles.numeric
                            .copyWith(color: fg, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  // Actions for draft
                  if (r.status == 'draft') ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                                Icons.check_circle_outline, size: 16),
                            label: Text(l10n.t('postReceipt')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(
                                  color: AppColors.primary.withValues(
                                      alpha: 0.5)),
                            ),
                            onPressed: () => _doAction('post'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: Text(l10n.t('cancelAction')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.destructive,
                            side: BorderSide(
                                color: AppColors.destructive.withValues(
                                    alpha: 0.5)),
                          ),
                          onPressed: () => _doAction('cancel'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: border),
            _ExpandedItems(
              receipt: _detail ?? r,
              isLoading: _loadingDetail,
              isDark: isDark,
              l10n: l10n,
              fg: fg,
              muted: muted,
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpandedItems extends StatelessWidget {
  final ReceiptEntity receipt;
  final bool isLoading;
  final bool isDark;
  final AppLocalizations l10n;
  final Color fg;
  final Color muted;

  const _ExpandedItems({
    required this.receipt,
    required this.isLoading,
    required this.isDark,
    required this.l10n,
    required this.fg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final items = receipt.items;
    if (items == null || items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(l10n.t('noItems'),
            style: AppTextStyles.bodySm.copyWith(color: muted)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding:
                const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: AppTextStyles.bodySm.copyWith(color: fg),
                      ),
                      if (item.productSku != null)
                        Text(
                          item.productSku!,
                          style:
                              AppTextStyles.bodyXs.copyWith(color: muted),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${item.qty.toStringAsFixed(item.qty == item.qty.truncate() ? 0 : 2)} × ${item.unitCost.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyXs.copyWith(color: muted),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  item.total.toStringAsFixed(2),
                  style: AppTextStyles.numeric.copyWith(color: fg),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
