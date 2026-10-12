import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../domain/entities/stock_count_entities.dart';
import '../../../domain/usecases/stock_count_usecases.dart';

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

class MobileStockCountDetailPage extends StatefulWidget {
  final String id;
  const MobileStockCountDetailPage({super.key, required this.id});

  @override
  State<MobileStockCountDetailPage> createState() =>
      _MobileStockCountDetailPageState();
}

class _MobileStockCountDetailPageState
    extends State<MobileStockCountDetailPage> {
  StockCountEntity? _count;
  bool _loading = true;
  String? _errorMsg;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    final result = await getIt<GetStockCountByIdUseCase>()(widget.id);
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _errorMsg = f.message;
        _loading = false;
      }),
      (c) => setState(() {
        _count = c;
        _loading = false;
      }),
    );
  }

  Future<void> _doPost() async {
    final l10n = AppLocalizations.of(context);
    final c = _count;
    if (c == null) return;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.t('postCountTitle'),
      message: l10n.t('postCountMsg'),
      confirmLabel: l10n.t('postCount'),
      isDestructive: false,
      onConfirm: () {},
    );
    if (confirmed != true || !mounted) return;
    setState(() => _actionLoading = true);
    final result = await getIt<PostStockCountUseCase>()(c.id);
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() => _actionLoading = false);
        AppSnackbar.error(context, l10n.t('actionFailed'));
      },
      (updated) {
        setState(() {
          _count = updated;
          _actionLoading = false;
        });
        AppSnackbar.success(context, l10n.t('stockCountPosted'));
      },
    );
  }

  Future<void> _doDelete() async {
    final l10n = AppLocalizations.of(context);
    final c = _count;
    if (c == null) return;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.t('deleteStockCountTitle'),
      message: l10n.t('deleteStockCountMsg'),
      confirmLabel: l10n.delete,
      isDestructive: true,
      onConfirm: () {},
    );
    if (confirmed != true || !mounted) return;
    setState(() => _actionLoading = true);
    final result = await getIt<DeleteStockCountUseCase>()(c.id);
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() => _actionLoading = false);
        AppSnackbar.error(context, l10n.t('actionFailed'));
      },
      (_) {
        AppSnackbar.success(context, l10n.t('stockCountDeleted'));
        context.go('/stock-counts');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('stockCountDetail')),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/stock-counts'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _errorMsg != null
              ? AppErrorWidget(message: _errorMsg!, onRetry: _load)
              : _count == null
                  ? const SizedBox.shrink()
                  : _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final c = _count!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = c.items ?? [];
    final gainItems = items.where((i) => i.varianceQty > 0);
    final lossItems = items.where((i) => i.varianceQty < 0);
    final totalGain =
        gainItems.fold<double>(0, (s, i) => s + i.varianceQty);
    final totalLoss =
        lossItems.fold<double>(0, (s, i) => s + i.varianceQty.abs());
    final totalVarianceValue = items.fold<double>(
        0, (s, i) => s + (i.varianceQty * (i.unitCost ?? 0)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + actions
          Row(
            children: [
              _statusBadge(c.status, l10n),
              const Spacer(),
              if (_actionLoading)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          if (!_actionLoading && c.status == 'draft') ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton.primary(
                    label: l10n.t('postCount'),
                    size: AppButtonSize.sm,
                    leading:
                        const Icon(Icons.check_circle_outline, size: 14),
                    onPressed: _doPost,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton.destructive(
                    label: l10n.delete,
                    size: AppButtonSize.sm,
                    leading:
                        const Icon(Icons.delete_outline, size: 14),
                    onPressed: _doDelete,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Summary cards
          if (items.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: l10n.t('totalGainQty'),
                    value: '+${totalGain.toStringAsFixed(totalGain == totalGain.truncate() ? 0 : 2)}',
                    color: AppColors.successForeground,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SummaryCard(
                    label: l10n.t('totalLossQty'),
                    value: '-${totalLoss.toStringAsFixed(totalLoss == totalLoss.truncate() ? 0 : 2)}',
                    color: AppColors.destructive,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SummaryCard(
                    label: l10n.t('totalVarianceValue'),
                    value: (totalVarianceValue >= 0 ? '+' : '') +
                        totalVarianceValue.toStringAsFixed(2),
                    color: totalVarianceValue >= 0
                        ? AppColors.successForeground
                        : AppColors.destructive,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Info card
          _InfoCard(count: c, isDark: isDark, l10n: l10n),
          const SizedBox(height: AppSpacing.md),

          // Items
          if (items.isNotEmpty)
            _ItemsCard(count: c, isDark: isDark, l10n: l10n),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodyXs
                  .copyWith(color: muted, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.labelMd
                  .copyWith(color: color, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final StockCountEntity count;
  final bool isDark;
  final AppLocalizations l10n;

  const _InfoCard(
      {required this.count, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('labelDetails').toUpperCase(),
            style: AppTextStyles.bodyXs.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
              label: l10n.t('labelReference'),
              value: count.reference.isNotEmpty ? count.reference : '—',
              fg: fg,
              muted: muted),
          _InfoRow(
              label: l10n.t('colWarehouse'),
              value: count.warehouseName,
              fg: fg,
              muted: muted),
          _InfoRow(
              label: l10n.t('labelBranch'),
              value: count.branchName ?? '—',
              fg: fg,
              muted: muted),
          _InfoRow(
              label: l10n.t('colCreated'),
              value: _fmtDate(count.createdAt),
              fg: fg,
              muted: muted),
          if (count.postedAt != null)
            _InfoRow(
                label: l10n.t('postedAt'),
                value: _fmtDate(count.postedAt),
                fg: fg,
                muted: muted),
          if (count.notes != null && count.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(color: border),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.t('labelNotes').toUpperCase(),
                style: AppTextStyles.bodyXs.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            const SizedBox(height: AppSpacing.xs),
            Text(count.notes!,
                style: AppTextStyles.bodySm.copyWith(color: fg)),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color fg;
  final Color muted;
  const _InfoRow(
      {required this.label,
      required this.value,
      required this.fg,
      required this.muted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.bodyXs.copyWith(color: muted)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.labelSm.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final StockCountEntity count;
  final bool isDark;
  final AppLocalizations l10n;

  const _ItemsCard(
      {required this.count, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final items = count.items!;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Text(l10n.t('labelItems'),
                    style: AppTextStyles.labelMd.copyWith(color: fg)),
                const Spacer(),
                Text('${items.length} ${l10n.t("itemsCount")}',
                    style:
                        AppTextStyles.bodySm.copyWith(color: muted)),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: border),
            itemBuilder: (_, i) {
              final item = items[i];
              final variance = item.varianceQty;
              final varianceValue = variance * (item.unitCost ?? 0);
              final isGain = variance > 0;
              final isLoss = variance < 0;
              final varColor = isGain
                  ? AppColors.successForeground
                  : isLoss
                      ? AppColors.destructive
                      : muted;

              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName,
                              style: AppTextStyles.labelSm
                                  .copyWith(color: fg),
                              overflow: TextOverflow.ellipsis),
                          if (item.productSku != null)
                            Text(item.productSku!,
                                style: AppTextStyles.bodyXs
                                    .copyWith(color: muted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.systemQty.toStringAsFixed(item.systemQty == item.systemQty.truncate() ? 0 : 2)} → ${item.countedQty.toStringAsFixed(item.countedQty == item.countedQty.truncate() ? 0 : 2)}',
                          style: AppTextStyles.bodyXs
                              .copyWith(color: muted),
                        ),
                        Text(
                          (isGain ? '+' : '') +
                              variance.toStringAsFixed(
                                  variance == variance.truncate()
                                      ? 0
                                      : 2),
                          style: AppTextStyles.labelSm
                              .copyWith(color: varColor),
                        ),
                        if (varianceValue != 0)
                          Text(
                            (varianceValue >= 0 ? '+' : '') +
                                varianceValue.toStringAsFixed(2),
                            style: AppTextStyles.bodyXs.copyWith(
                                color: varColor,
                                fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
