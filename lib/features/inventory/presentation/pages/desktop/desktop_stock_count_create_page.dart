import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/buttons/app_icon_button.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../domain/entities/stock_count_entities.dart';
import '../../../domain/usecases/stock_count_usecases.dart';

// ── Option models ─────────────────────────────────────────────────────────────

class _Opt {
  final String id;
  final String name;
  final String? extra;
  const _Opt(this.id, this.name, [this.extra]);
}

// ── Inventory item from stock endpoint ────────────────────────────────────────

class _StockItem {
  final String productId;
  final String productName;
  final String? productSku;
  final String? productUnit;
  final double systemQty;
  final TextEditingController countedCtrl;

  _StockItem({
    required this.productId,
    required this.productName,
    this.productSku,
    this.productUnit,
    required this.systemQty,
  }) : countedCtrl = TextEditingController(
            text: systemQty.toStringAsFixed(
                systemQty == systemQty.truncate() ? 0 : 2));

  double get countedQty =>
      double.tryParse(countedCtrl.text.trim()) ?? systemQty;

  double get varianceQty => countedQty - systemQty;

  void dispose() => countedCtrl.dispose();
}

// ── Page ──────────────────────────────────────────────────────────────────────

class DesktopStockCountCreatePage extends StatefulWidget {
  const DesktopStockCountCreatePage({super.key});

  @override
  State<DesktopStockCountCreatePage> createState() =>
      _DesktopStockCountCreatePageState();
}

class _DesktopStockCountCreatePageState
    extends State<DesktopStockCountCreatePage> {
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _loadingOptions = true;
  bool _loadingStock = false;
  List<_Opt> _branches = [];
  List<_Opt> _warehouses = [];

  String? _branchId;
  String? _warehouseId;

  List<_StockItem> _stockItems = [];
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    _notesCtrl.dispose();
    for (final item in _stockItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final client = getIt<ApiClient>();
      final results = await Future.wait([
        client.get<Map<String, dynamic>>(
          ApiEndpoints.branches,
          queryParameters: {'per_page': 200},
        ),
        client.get<Map<String, dynamic>>(
          ApiEndpoints.warehouses,
          queryParameters: {'per_page': 200},
        ),
      ]);

      if (!mounted) return;

      List<_Opt> parse(dynamic res, String nameField,
          [String? extraField]) {
        final data = res.data as Map<String, dynamic>;
        final list = (data['data'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        return list
            .map((m) => _Opt(
                  m['id']?.toString() ?? '',
                  m[nameField] as String? ?? '',
                  extraField != null
                      ? m[extraField] as String?
                      : null,
                ))
            .toList();
      }

      setState(() {
        _branches = parse(results[0], 'name');
        _warehouses = parse(results[1], 'name', 'code');
        _loadingOptions = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  Future<void> _loadStockItems(String warehouseId) async {
    for (final item in _stockItems) {
      item.dispose();
    }
    setState(() {
      _loadingStock = true;
      _stockItems = [];
    });

    try {
      final client = getIt<ApiClient>();
      final res = await client.get<Map<String, dynamic>>(
        ApiEndpoints.inventoryStock,
        queryParameters: {
          'warehouse_id': warehouseId,
          'per_page': 500,
        },
      );
      if (!mounted) return;

      final data = res.data as Map<String, dynamic>;
      final list = (data['data'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      final items = list.map((m) {
        final product = m['product'] as Map<String, dynamic>?;
        final qty = (m['qty'] as num?)?.toDouble() ??
            (m['quantity'] as num?)?.toDouble() ??
            0.0;
        return _StockItem(
          productId: (product?['id'] ?? m['product_id'])?.toString() ?? '',
          productName:
              product?['name'] as String? ?? m['product_name'] as String? ?? '',
          productSku: product?['sku'] as String?,
          productUnit: product?['unit'] as String?,
          systemQty: qty,
        );
      }).where((i) => i.productId.isNotEmpty).toList();

      setState(() {
        _stockItems = items;
        _loadingStock = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingStock = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);

    if (_warehouseId == null) {
      setState(() => _error = l10n.t('warehouseRequired'));
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final items = _stockItems
        .map((s) => StockCountItemInput(
              productId: s.productId,
              countedQty: s.countedQty,
            ))
        .toList();

    final useCase = getIt<CreateStockCountUseCase>();
    final result = await useCase(StockCountFormData(
      reference: _refCtrl.text.trim().isEmpty
          ? null
          : _refCtrl.text.trim(),
      branchId: _branchId,
      warehouseId: _warehouseId!,
      notes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
      items: items,
    ));

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _submitting = false;
        _error = failure.message;
      }),
      (_) {
        AppSnackbar.success(context, l10n.t('stockCountCreated'));
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
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
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
                Text(l10n.t('newStockCount'),
                    style: AppTextStyles.h5.copyWith(color: fg)),
              ],
            ),
          ),

          // Body
          Expanded(
            child: _loadingOptions
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(
                        AppSizes.desktopContentPadding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 900),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_error != null)
                              _ErrorBanner(message: _error!),

                            // Settings card
                            _Card(
                              isDark: isDark,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.t('labelBasicInfo'),
                                      style: AppTextStyles.labelMd
                                          .copyWith(color: fg)),
                                  const SizedBox(height: AppSpacing.md),

                                  // Reference
                                  AppTextField(
                                    label: l10n.t('labelReference'),
                                    hint: l10n.t('referencePlaceholder'),
                                    controller: _refCtrl,
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppSelectField<String?>(
                                          label: l10n.t('labelBranch'),
                                          hint: l10n.t('selectBranch'),
                                          value: _branchId,
                                          options: [
                                            AppSelectOption(
                                                value: null,
                                                label: l10n.t('noBranch')),
                                            ..._branches.map((b) =>
                                                AppSelectOption(
                                                    value: b.id,
                                                    label: b.name)),
                                          ],
                                          onChanged: (v) =>
                                              setState(() => _branchId = v),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: AppSelectField<String?>(
                                          label:
                                              '${l10n.t("labelWarehouse")} *',
                                          hint: l10n.t('selectWarehouse'),
                                          value: _warehouseId,
                                          options: _warehouses
                                              .map((w) => AppSelectOption(
                                                    value: w.id,
                                                    label: w.extra != null
                                                        ? '${w.name} (${w.extra})'
                                                        : w.name,
                                                  ))
                                              .toList(),
                                          onChanged: (v) {
                                            setState(() =>
                                                _warehouseId = v);
                                            if (v != null) {
                                              _loadStockItems(v);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  AppTextField(
                                    label: l10n.t('labelNotes'),
                                    hint: l10n.t('notesPlaceholder'),
                                    controller: _notesCtrl,
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            // Stock items card
                            _Card(
                              isDark: isDark,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(l10n.t('labelItems'),
                                          style: AppTextStyles.labelMd
                                              .copyWith(color: fg)),
                                      const Spacer(),
                                      if (_stockItems.isNotEmpty)
                                        Text(
                                          '${_stockItems.length} ${l10n.t("itemsCount")}',
                                          style: AppTextStyles.bodySm
                                              .copyWith(color: muted),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  if (_warehouseId == null)
                                    Container(
                                      padding: const EdgeInsets.all(
                                          AppSpacing.lg),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkMuted
                                            : AppColors.muted,
                                        borderRadius: AppRadius.brSm,
                                      ),
                                      child: Center(
                                        child: Text(
                                          l10n.t('selectWarehouseFirst'),
                                          style:
                                              AppTextStyles.bodySm.copyWith(
                                                  color: muted),
                                        ),
                                      ),
                                    )
                                  else if (_loadingStock)
                                    const Center(
                                      child: Padding(
                                        padding:
                                            EdgeInsets.all(AppSpacing.xl),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    )
                                  else if (_stockItems.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(
                                          AppSpacing.lg),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkMuted
                                            : AppColors.muted,
                                        borderRadius: AppRadius.brSm,
                                      ),
                                      child: Center(
                                        child: Text(
                                          l10n.t('noStockItems'),
                                          style:
                                              AppTextStyles.bodySm.copyWith(
                                                  color: muted),
                                        ),
                                      ),
                                    )
                                  else
                                    _StockItemsTable(
                                      items: _stockItems,
                                      isDark: isDark,
                                      l10n: l10n,
                                      fg: fg,
                                      muted: muted,
                                      border: border,
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            // Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                AppButton.outline(
                                  label: l10n.cancel,
                                  onPressed: () =>
                                      context.go('/stock-counts'),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                AppButton.primary(
                                  label: l10n.t('createStockCount'),
                                  isLoading: _submitting,
                                  onPressed:
                                      _submitting ? null : _submit,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Stock items table ─────────────────────────────────────────────────────────

class _StockItemsTable extends StatefulWidget {
  final List<_StockItem> items;
  final bool isDark;
  final AppLocalizations l10n;
  final Color fg;
  final Color muted;
  final Color border;

  const _StockItemsTable({
    required this.items,
    required this.isDark,
    required this.l10n,
    required this.fg,
    required this.muted,
    required this.border,
  });

  @override
  State<_StockItemsTable> createState() => _StockItemsTableState();
}

class _StockItemsTableState extends State<_StockItemsTable> {
  @override
  Widget build(BuildContext context) {
    final headerBg = widget.isDark
        ? AppColors.darkMuted
        : AppColors.primaryMuted;

    return Column(
      children: [
        // Table header
        Container(
          height: 36,
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: headerBg,
            borderRadius: AppRadius.brSm,
          ),
          child: Row(
            children: [
              Expanded(
                  flex: 3,
                  child: Text(widget.l10n.t('colProduct'),
                      style: AppTextStyles.tableHeader)),
              SizedBox(
                width: 90,
                child: Text(widget.l10n.t('colSystemQty'),
                    style: AppTextStyles.tableHeader,
                    textAlign: TextAlign.end),
              ),
              SizedBox(
                width: 110,
                child: Text(widget.l10n.t('colCountedQty'),
                    style: AppTextStyles.tableHeader,
                    textAlign: TextAlign.center),
              ),
              SizedBox(
                width: 90,
                child: Text(widget.l10n.t('colVariance'),
                    style: AppTextStyles.tableHeader,
                    textAlign: TextAlign.end),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.items.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: widget.border),
          itemBuilder: (_, i) {
            final item = widget.items[i];
            return _StockItemRow(
              item: item,
              isDark: widget.isDark,
              fg: widget.fg,
              muted: widget.muted,
              l10n: widget.l10n,
              onChanged: (_) => setState(() {}),
            );
          },
        ),
      ],
    );
  }
}

class _StockItemRow extends StatelessWidget {
  final _StockItem item;
  final bool isDark;
  final Color fg;
  final Color muted;
  final AppLocalizations l10n;
  final ValueChanged<String> onChanged;

  const _StockItemRow({
    required this.item,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.l10n,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final variance = item.varianceQty;
    final isGain = variance > 0;
    final isLoss = variance < 0;
    final varianceColor = isGain
        ? AppColors.successForeground
        : isLoss
            ? AppColors.destructive
            : muted;

    return SizedBox(
      height: AppSizes.tableRowHeight,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.productName,
                    style: AppTextStyles.tableCell.copyWith(color: fg),
                    overflow: TextOverflow.ellipsis),
                if (item.productSku != null)
                  Text(item.productSku!,
                      style:
                          AppTextStyles.bodyXs.copyWith(color: muted),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              item.systemQty.toStringAsFixed(
                  item.systemQty == item.systemQty.truncate() ? 0 : 2),
              style: AppTextStyles.numeric.copyWith(color: muted),
              textAlign: TextAlign.end,
            ),
          ),
          SizedBox(
            width: 110,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs, vertical: 4),
              child: TextField(
                controller: item.countedCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: AppTextStyles.numeric.copyWith(color: fg),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.brSm,
                    borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.brSm,
                    borderSide:
                        const BorderSide(color: AppColors.primary),
                  ),
                ),
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              (isGain ? '+' : '') +
                  variance.toStringAsFixed(
                      variance == variance.truncate() ? 0 : 2),
              style: AppTextStyles.numeric
                  .copyWith(color: varianceColor),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: child,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.08),
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
