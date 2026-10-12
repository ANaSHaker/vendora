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
import '../../../domain/entities/transfer_entities.dart';
import '../../../domain/usecases/transfer_usecases.dart';

class _Opt {
  final String id;
  final String name;
  final String? extra;
  const _Opt(this.id, this.name, [this.extra]);
}

class _ItemRowData {
  String? productId;
  String productName = '';
  final qtyCtrl = TextEditingController();
  final costCtrl = TextEditingController();
  void dispose() {
    qtyCtrl.dispose();
    costCtrl.dispose();
  }
}

class MobileTransferCreatePage extends StatefulWidget {
  const MobileTransferCreatePage({super.key});

  @override
  State<MobileTransferCreatePage> createState() =>
      _MobileTransferCreatePageState();
}

class _MobileTransferCreatePageState extends State<MobileTransferCreatePage> {
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _loading = true;
  List<_Opt> _branches = [];
  List<_Opt> _warehouses = [];
  List<_Opt> _products = [];

  String? _fromBranchId;
  String? _fromWarehouseId;
  String? _toBranchId;
  String? _toWarehouseId;

  final List<_ItemRowData> _items = [];
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _items.add(_ItemRowData());
    _loadOptions();
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

  Future<void> _loadOptions() async {
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
      if (!mounted) return;

      List<_Opt> parse(dynamic res, String nameField, [String? extra]) {
        final data = res.data as Map<String, dynamic>;
        final list =
            (data['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        return list
            .map((m) => _Opt(m['id']?.toString() ?? '',
                m[nameField] as String? ?? '',
                extra != null ? m[extra] as String? : null))
            .toList();
      }

      setState(() {
        _branches = parse(results[0], 'name');
        _warehouses = parse(results[1], 'name', 'code');
        _products = parse(results[2], 'name', 'sku');
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_fromWarehouseId == null || _toWarehouseId == null) {
      setState(() => _error = l10n.t('warehouseRequired'));
      return;
    }
    if (_fromWarehouseId == _toWarehouseId) {
      setState(() => _error = l10n.t('warehouseSameError'));
      return;
    }
    final validItems = _items
        .where((r) => r.productId != null)
        .map((r) => TransferItemInput(
              productId: r.productId!,
              productName: r.productName,
              qty: double.tryParse(r.qtyCtrl.text.trim()) ?? 1,
              unitCost: double.tryParse(r.costCtrl.text.trim()) ?? 0,
            ))
        .toList();
    if (validItems.isEmpty) {
      setState(() => _error = l10n.t('itemsRequired'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await getIt<CreateTransferUseCase>()(TransferFormData(
      reference:
          _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      fromBranchId: _fromBranchId,
      fromWarehouseId: _fromWarehouseId!,
      toBranchId: _toBranchId,
      toWarehouseId: _toWarehouseId!,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      items: validItems,
    ));
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _submitting = false;
        _error = failure.message;
      }),
      (_) {
        AppSnackbar.success(context, l10n.t('transferCreated'));
        context.go('/transfers');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('newTransfer')),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/transfers'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) _ErrorBanner(message: _error!),

                  // Basic info card
                  _SectionCard(
                    title: l10n.t('labelBasicInfo'),
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: l10n.t('labelReference'),
                          hint: l10n.t('referencePlaceholder'),
                          controller: _refCtrl,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SectionLabel(
                            label: l10n.t('labelFrom').toUpperCase(),
                            color: muted),
                        const SizedBox(height: AppSpacing.sm),
                        AppSelectField<String?>(
                          label: l10n.t('labelFromBranch'),
                          hint: l10n.t('selectBranch'),
                          value: _fromBranchId,
                          options: [
                            AppSelectOption(
                                value: null, label: l10n.t('noBranch')),
                            ..._branches.map((b) =>
                                AppSelectOption(value: b.id, label: b.name)),
                          ],
                          onChanged: (v) =>
                              setState(() => _fromBranchId = v),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppSelectField<String?>(
                          label: '${l10n.t("labelFromWarehouse")} *',
                          hint: l10n.t('selectWarehouse'),
                          value: _fromWarehouseId,
                          options: _warehouses
                              .where((w) => w.id != _toWarehouseId)
                              .map((w) => AppSelectOption(
                                    value: w.id,
                                    label: w.extra != null
                                        ? '${w.name} (${w.extra})'
                                        : w.name,
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _fromWarehouseId = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SectionLabel(
                            label: l10n.t('labelTo').toUpperCase(),
                            color: muted),
                        const SizedBox(height: AppSpacing.sm),
                        AppSelectField<String?>(
                          label: l10n.t('labelToBranch'),
                          hint: l10n.t('selectBranch'),
                          value: _toBranchId,
                          options: [
                            AppSelectOption(
                                value: null, label: l10n.t('noBranch')),
                            ..._branches.map((b) =>
                                AppSelectOption(value: b.id, label: b.name)),
                          ],
                          onChanged: (v) =>
                              setState(() => _toBranchId = v),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppSelectField<String?>(
                          label: '${l10n.t("labelToWarehouse")} *',
                          hint: l10n.t('selectWarehouse'),
                          value: _toWarehouseId,
                          options: _warehouses
                              .where((w) => w.id != _fromWarehouseId)
                              .map((w) => AppSelectOption(
                                    value: w.id,
                                    label: w.extra != null
                                        ? '${w.name} (${w.extra})'
                                        : w.name,
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _toWarehouseId = v),
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

                  // Items card
                  _SectionCard(
                    title: l10n.t('labelItems'),
                    isDark: isDark,
                    trailing: TextButton.icon(
                      onPressed: () =>
                          setState(() => _items.add(_ItemRowData())),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l10n.t('addItem')),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < _items.length; i++)
                          _MobileItemRow(
                            index: i,
                            item: _items[i],
                            products: _products,
                            showRemove: _items.length > 1,
                            l10n: l10n,
                            onRemove: () => setState(() {
                              _items[i].dispose();
                              _items.removeAt(i);
                            }),
                            onProductChanged: (v) {
                              final prod = _products
                                  .where((p) => p.id == v)
                                  .firstOrNull;
                              setState(() {
                                _items[i].productId = v;
                                _items[i].productName = prod?.name ?? '';
                              });
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
                          onPressed: () => context.go('/transfers'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton.primary(
                          label: l10n.t('createTransfer'),
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

class _MobileItemRow extends StatelessWidget {
  final int index;
  final _ItemRowData item;
  final List<_Opt> products;
  final bool showRemove;
  final AppLocalizations l10n;
  final VoidCallback onRemove;
  final ValueChanged<String?> onProductChanged;

  const _MobileItemRow({
    required this.index,
    required this.item,
    required this.products,
    required this.showRemove,
    required this.l10n,
    required this.onRemove,
    required this.onProductChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: AppRadius.brSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${l10n.t("item")} ${index + 1}',
                  style: AppTextStyles.labelSm),
              const Spacer(),
              if (showRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close,
                      size: 16, color: AppColors.destructive),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSelectField<String?>(
            hint: l10n.t('selectProduct'),
            value: item.productId,
            options: products
                .map((p) => AppSelectOption(
                      value: p.id,
                      label: p.extra != null
                          ? '${p.name} (${p.extra})'
                          : p.name,
                    ))
                .toList(),
            onChanged: onProductChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: l10n.t('colQty'),
                  hint: '1',
                  controller: item.qtyCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: l10n.t('colUnitCost'),
                  hint: '0.00',
                  controller: item.costCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool isDark;

  const _SectionCard({
    required this.title,
    required this.child,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Container(
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
              Text(title,
                  style: AppTextStyles.labelMd.copyWith(color: fg)),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: AppTextStyles.bodyXs.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ));
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
        border: Border.all(
            color: AppColors.destructive.withValues(alpha: 0.3)),
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
