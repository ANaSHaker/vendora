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
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../domain/entities/stock_count_entities.dart';
import '../../../domain/usecases/stock_count_usecases.dart';

class _Opt {
  final String id;
  final String name;
  final String? extra;
  const _Opt(this.id, this.name, [this.extra]);
}

class _StockItem {
  final String productId;
  final String productName;
  final String? productSku;
  final double systemQty;
  final TextEditingController countedCtrl;

  _StockItem({
    required this.productId,
    required this.productName,
    this.productSku,
    required this.systemQty,
  }) : countedCtrl = TextEditingController(
            text: systemQty.toStringAsFixed(
                systemQty == systemQty.truncate() ? 0 : 2));

  double get countedQty =>
      double.tryParse(countedCtrl.text.trim()) ?? systemQty;
  double get varianceQty => countedQty - systemQty;

  void dispose() => countedCtrl.dispose();
}

class MobileStockCountCreatePage extends StatefulWidget {
  const MobileStockCountCreatePage({super.key});

  @override
  State<MobileStockCountCreatePage> createState() =>
      _MobileStockCountCreatePageState();
}

class _MobileStockCountCreatePageState
    extends State<MobileStockCountCreatePage> {
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
        client.get<Map<String, dynamic>>(ApiEndpoints.branches,
            queryParameters: {'per_page': 200}),
        client.get<Map<String, dynamic>>(ApiEndpoints.warehouses,
            queryParameters: {'per_page': 200}),
      ]);
      if (!mounted) return;

      List<_Opt> parse(dynamic res, String nameField, [String? extraField]) {
        final data = res.data as Map<String, dynamic>;
        final list =
            (data['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        return list
            .map((m) => _Opt(
                  m['id']?.toString() ?? '',
                  m[nameField] as String? ?? '',
                  extraField != null ? m[extraField] as String? : null,
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
        queryParameters: {'warehouse_id': warehouseId, 'per_page': 500},
      );
      if (!mounted) return;
      final data = res.data as Map<String, dynamic>;
      final list =
          (data['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      final items = list.map((m) {
        final product = m['product'] as Map<String, dynamic>?;
        final qty = (m['qty'] as num?)?.toDouble() ??
            (m['quantity'] as num?)?.toDouble() ??
            0.0;
        return _StockItem(
          productId:
              (product?['id'] ?? m['product_id'])?.toString() ?? '',
          productName: product?['name'] as String? ??
              m['product_name'] as String? ??
              '',
          productSku: product?['sku'] as String?,
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
    final result = await getIt<CreateStockCountUseCase>()(StockCountFormData(
      reference:
          _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      branchId: _branchId,
      warehouseId: _warehouseId!,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
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
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('newStockCount')),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/stock-counts'),
        ),
      ),
      body: _loadingOptions
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) _ErrorBanner(message: _error!),

                  // Settings card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: surface,
                      border: Border.all(color: border),
                      borderRadius: AppRadius.brMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.t('labelBasicInfo'),
                            style:
                                AppTextStyles.labelMd.copyWith(color: fg)),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: l10n.t('labelReference'),
                          hint: l10n.t('referencePlaceholder'),
                          controller: _refCtrl,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppSelectField<String?>(
                          label: l10n.t('labelBranch'),
                          hint: l10n.t('selectBranch'),
                          value: _branchId,
                          options: [
                            AppSelectOption(
                                value: null, label: l10n.t('noBranch')),
                            ..._branches.map((b) =>
                                AppSelectOption(value: b.id, label: b.name)),
                          ],
                          onChanged: (v) =>
                              setState(() => _branchId = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppSelectField<String?>(
                          label: '${l10n.t("labelWarehouse")} *',
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
                            setState(() => _warehouseId = v);
                            if (v != null) _loadStockItems(v);
                          },
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

                  const SizedBox(height: AppSpacing.md),

                  // Stock items card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: surface,
                      border: Border.all(color: border),
                      borderRadius: AppRadius.brMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(l10n.t('labelItems'),
                                style: AppTextStyles.labelMd
                                    .copyWith(color: fg)),
                            if (_stockItems.isNotEmpty) ...[
                              const Spacer(),
                              Text(
                                '${_stockItems.length} ${l10n.t("itemsCount")}',
                                style: AppTextStyles.bodySm
                                    .copyWith(color: muted),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_warehouseId == null)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.muted,
                              borderRadius: AppRadius.brSm,
                            ),
                            child: Center(
                              child: Text(
                                l10n.t('selectWarehouseFirst'),
                                style: AppTextStyles.bodySm
                                    .copyWith(color: muted),
                              ),
                            ),
                          )
                        else if (_loadingStock)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.xl),
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else if (_stockItems.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.muted,
                              borderRadius: AppRadius.brSm,
                            ),
                            child: Center(
                              child: Text(
                                l10n.t('noStockItems'),
                                style: AppTextStyles.bodySm
                                    .copyWith(color: muted),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: _stockItems.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: border),
                            itemBuilder: (ctx, i) {
                              final item = _stockItems[i];
                              return _MobileStockItemRow(
                                item: item,
                                fg: fg,
                                muted: muted,
                                border: border,
                                onChanged: (_) => setState(() {}),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Row(
                    children: [
                      Expanded(
                        child: AppButton.outline(
                          label: l10n.cancel,
                          onPressed: () => context.go('/stock-counts'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton.primary(
                          label: l10n.t('createStockCount'),
                          isLoading: _submitting,
                          onPressed: _submitting ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }
}

class _MobileStockItemRow extends StatelessWidget {
  final _StockItem item;
  final Color fg;
  final Color muted;
  final Color border;
  final ValueChanged<String> onChanged;

  const _MobileStockItemRow({
    required this.item,
    required this.fg,
    required this.muted,
    required this.border,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final variance = item.varianceQty;
    final isGain = variance > 0;
    final isLoss = variance < 0;
    final varianceColor = isGain
        ? AppColors.successForeground
        : isLoss
            ? AppColors.destructive
            : muted;

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: AppTextStyles.labelSm.copyWith(color: fg),
                    overflow: TextOverflow.ellipsis),
                if (item.productSku != null)
                  Text(item.productSku!,
                      style:
                          AppTextStyles.bodyXs.copyWith(color: muted)),
                Text(
                  'System: ${item.systemQty.toStringAsFixed(item.systemQty == item.systemQty.truncate() ? 0 : 2)}',
                  style: AppTextStyles.bodyXs.copyWith(color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 80,
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
              const SizedBox(height: 2),
              Text(
                (isGain ? '+' : '') +
                    variance.toStringAsFixed(
                        variance == variance.truncate() ? 0 : 2),
                style: AppTextStyles.bodyXs
                    .copyWith(color: varianceColor),
              ),
            ],
          ),
        ],
      ),
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
            child: Text(message,
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }
}
