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
import '../../../../../design_system/widgets/buttons/app_icon_button.dart';
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../domain/entities/stock_count_entities.dart';
import '../../../domain/usecases/stock_count_usecases.dart';

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

class DesktopStockCountDetailPage extends StatefulWidget {
  final String id;

  const DesktopStockCountDetailPage({super.key, required this.id});

  @override
  State<DesktopStockCountDetailPage> createState() =>
      _DesktopStockCountDetailPageState();
}

class _DesktopStockCountDetailPageState
    extends State<DesktopStockCountDetailPage> {
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
    final result =
        await getIt<GetStockCountByIdUseCase>()(widget.id);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;

    return ColoredBox(
      color: bg,
      child: Column(
        children: [
          // Page header
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: border)),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.desktopContentPadding),
            child: Row(
              children: [
                AppIconButton(
                  icon: const Icon(Icons.arrow_back, size: 18),
                  onPressed: () => context.go('/stock-counts'),
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.sm,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.t('stockCountDetail'),
                    style: AppTextStyles.h5.copyWith(color: fg)),
                if (_count != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  _statusBadge(_count!.status, l10n),
                ],
                const Spacer(),
                if (_actionLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (_count != null &&
                    !_actionLoading &&
                    _count!.status == 'draft') ...[
                  AppButton.primary(
                    label: l10n.t('postCount'),
                    size: AppButtonSize.sm,
                    leading: const Icon(
                        Icons.check_circle_outline, size: 14),
                    onPressed: _doPost,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton.destructive(
                    label: l10n.delete,
                    size: AppButtonSize.sm,
                    leading:
                        const Icon(Icons.delete_outline, size: 14),
                    onPressed: _doDelete,
                  ),
                ],
              ],
            ),
          ),

          // Body
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
                : _errorMsg != null
                    ? AppErrorWidget(
                        message: _errorMsg!, onRetry: _load)
                    : _count == null
                        ? const SizedBox.shrink()
                        : _StockCountDetailBody(
                            count: _count!,
                            isDark: isDark,
                            l10n: l10n,
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Detail body ───────────────────────────────────────────────────────────────

class _StockCountDetailBody extends StatelessWidget {
  final StockCountEntity count;
  final bool isDark;
  final AppLocalizations l10n;

  const _StockCountDetailBody({
    required this.count,
    required this.isDark,
    required this.l10n,
  });

  bool get _hasStockMovedAfterCount {
    if (count.lastMovementAt == null) return false;
    try {
      final lastMove = DateTime.parse(count.lastMovementAt!);
      final created = DateTime.parse(count.createdAt);
      return lastMove.isAfter(created);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = count.items ?? [];
    final gainItems = items.where((i) => i.varianceQty > 0);
    final lossItems = items.where((i) => i.varianceQty < 0);
    final totalGain =
        gainItems.fold<double>(0, (s, i) => s + i.varianceQty);
    final totalLoss =
        lossItems.fold<double>(0, (s, i) => s + i.varianceQty.abs());
    final totalVarianceValue = items.fold<double>(
        0, (s, i) => s + (i.varianceQty * (i.unitCost ?? 0)));

    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(AppSizes.desktopContentPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning bar
              if (_hasStockMovedAfterCount) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: AppRadius.brMd,
                    border: Border.all(
                        color: const Color(0xFFF59E0B)
                            .withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_outlined,
                          color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.t('stockCountWarning'),
                          style: AppTextStyles.bodySm.copyWith(
                              color: const Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

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
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _SummaryCard(
                        label: l10n.t('totalLossQty'),
                        value: '-${totalLoss.toStringAsFixed(totalLoss == totalLoss.truncate() ? 0 : 2)}',
                        color: AppColors.destructive,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
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
                const SizedBox(height: AppSpacing.lg),
              ],

              // Info card
              _InfoCard(count: count, isDark: isDark, l10n: l10n),
              const SizedBox(height: AppSpacing.lg),

              // Items table
              if (items.isNotEmpty)
                _ItemsTable(
                    count: count,
                    isDark: isDark,
                    l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
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
          Text(label,
              style: AppTextStyles.bodyXs.copyWith(color: muted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h5
                .copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final StockCountEntity count;
  final bool isDark;
  final AppLocalizations l10n;

  const _InfoCard({
    required this.count,
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _InfoItem(
                label: l10n.t('labelReference'),
                value: count.reference.isNotEmpty ? count.reference : '—',
                fg: fg,
                muted: muted,
              ),
              _InfoItem(
                label: l10n.t('colWarehouse'),
                value: count.warehouseName,
                fg: fg,
                muted: muted,
              ),
              _InfoItem(
                label: l10n.t('labelBranch'),
                value: count.branchName ?? '—',
                fg: fg,
                muted: muted,
              ),
              _InfoItem(
                label: l10n.t('colCreated'),
                value: _fmtDate(count.createdAt),
                fg: fg,
                muted: muted,
              ),
              if (count.postedAt != null)
                _InfoItem(
                  label: l10n.t('postedAt'),
                  value: _fmtDate(count.postedAt),
                  fg: fg,
                  muted: muted,
                ),
            ],
          ),
          if (count.notes != null && count.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(color: border),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.t('labelNotes').toUpperCase(),
              style: AppTextStyles.bodyXs.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(count.notes!,
                style: AppTextStyles.bodySm.copyWith(color: fg)),
          ],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color fg;
  final Color muted;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.fg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodyXs.copyWith(color: muted)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.labelSm.copyWith(color: fg)),
        ],
      ),
    );
  }
}

// ── Items table ───────────────────────────────────────────────────────────────

class _ItemsTable extends StatelessWidget {
  final StockCountEntity count;
  final bool isDark;
  final AppLocalizations l10n;

  const _ItemsTable({
    required this.count,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg =
        isDark ? AppColors.darkMuted : AppColors.primaryMuted;
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
      child: ClipRRect(
        borderRadius: AppRadius.brMd,
        child: Column(
          children: [
            // Card header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: border))),
              child: Row(
                children: [
                  Text(l10n.t('labelItems'),
                      style: AppTextStyles.labelMd.copyWith(color: fg)),
                  const Spacer(),
                  Text(
                    '${items.length} ${l10n.t("itemsCount")}',
                    style: AppTextStyles.bodySm.copyWith(color: muted),
                  ),
                ],
              ),
            ),

            // Table header
            Container(
              height: AppSizes.tableHeaderHeight,
              color: headerBg,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text(l10n.t('colProduct'),
                          style: AppTextStyles.tableHeader)),
                  SizedBox(
                    width: 90,
                    child: Text(l10n.t('colSystemQty'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(l10n.t('colCountedQty'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(l10n.t('colVariance'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(l10n.t('colVarianceValue'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),

            // Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: border),
              itemBuilder: (_, i) {
                final item = items[i];
                final variance = item.varianceQty;
                final varianceValue =
                    variance * (item.unitCost ?? 0);
                final isGain = variance > 0;
                final isLoss = variance < 0;
                final varColor = isGain
                    ? AppColors.successForeground
                    : isLoss
                        ? AppColors.destructive
                        : muted;

                return Container(
                  height: AppSizes.tableRowHeight,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(item.productName,
                                style: AppTextStyles.tableCell
                                    .copyWith(color: fg),
                                overflow: TextOverflow.ellipsis),
                            if (item.productSku != null)
                              Text(item.productSku!,
                                  style: AppTextStyles.bodyXs
                                      .copyWith(color: muted),
                                  overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          item.systemQty.toStringAsFixed(
                              item.systemQty ==
                                      item.systemQty.truncate()
                                  ? 0
                                  : 2),
                          style: AppTextStyles.numeric
                              .copyWith(color: muted),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          item.countedQty.toStringAsFixed(
                              item.countedQty ==
                                      item.countedQty.truncate()
                                  ? 0
                                  : 2),
                          style: AppTextStyles.numeric
                              .copyWith(color: fg),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          (isGain ? '+' : '') +
                              variance.toStringAsFixed(
                                  variance ==
                                          variance.truncate()
                                      ? 0
                                      : 2),
                          style: AppTextStyles.numeric
                              .copyWith(color: varColor),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text(
                          (varianceValue >= 0 ? '+' : '') +
                              varianceValue.toStringAsFixed(2),
                          style: AppTextStyles.numeric.copyWith(
                              color: varColor,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
