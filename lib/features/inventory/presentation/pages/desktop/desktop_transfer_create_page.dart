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
import '../../../domain/entities/transfer_entities.dart';
import '../../../domain/usecases/transfer_usecases.dart';

// ── Simple option models ───────────────────────────────────────────────────────

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

// ── Page ──────────────────────────────────────────────────────────────────────

class DesktopTransferCreatePage extends StatefulWidget {
  const DesktopTransferCreatePage({super.key});

  @override
  State<DesktopTransferCreatePage> createState() =>
      _DesktopTransferCreatePageState();
}

class _DesktopTransferCreatePageState
    extends State<DesktopTransferCreatePage> {
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
        client.get<Map<String, dynamic>>(
          ApiEndpoints.branches,
          queryParameters: {'per_page': 200},
        ),
        client.get<Map<String, dynamic>>(
          ApiEndpoints.warehouses,
          queryParameters: {'per_page': 200},
        ),
        client.get<Map<String, dynamic>>(
          ApiEndpoints.products,
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

    final useCase = getIt<CreateTransferUseCase>();
    final result = await useCase(TransferFormData(
      reference: _refCtrl.text.trim().isEmpty
          ? null
          : _refCtrl.text.trim(),
      fromBranchId: _fromBranchId,
      fromWarehouseId: _fromWarehouseId!,
      toBranchId: _toBranchId,
      toWarehouseId: _toWarehouseId!,
      notes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
      items: validItems,
    ));

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
      },
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
                  onPressed: () => context.go('/transfers'),
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.sm,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.t('newTransfer'),
                    style: AppTextStyles.h5.copyWith(color: fg)),
              ],
            ),
          ),

          // Body
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(
                        AppSizes.desktopContentPadding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_error != null) _ErrorBanner(message: _error!),

                            // Card
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

                                  // From section
                                  Text(
                                    l10n.t('labelFrom').toUpperCase(),
                                    style: AppTextStyles.bodyXs.copyWith(
                                      color: muted,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppSelectField<String?>(
                                          label: l10n.t('labelFromBranch'),
                                          hint: l10n.t('selectBranch'),
                                          value: _fromBranchId,
                                          options: [
                                            AppSelectOption(
                                                value: null,
                                                label: l10n.t('noBranch')),
                                            ..._branches.map((b) =>
                                                AppSelectOption(
                                                    value: b.id,
                                                    label: b.name)),
                                          ],
                                          onChanged: (v) => setState(
                                              () => _fromBranchId = v),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: AppSelectField<String?>(
                                          label:
                                              '${l10n.t("labelFromWarehouse")} *',
                                          hint: l10n.t('selectWarehouse'),
                                          value: _fromWarehouseId,
                                          options: _warehouses
                                              .where((w) =>
                                                  w.id != _toWarehouseId)
                                              .map((w) => AppSelectOption(
                                                    value: w.id,
                                                    label: w.extra != null
                                                        ? '${w.name} (${w.extra})'
                                                        : w.name,
                                                  ))
                                              .toList(),
                                          onChanged: (v) => setState(
                                              () => _fromWarehouseId = v),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // To section
                                  Text(
                                    l10n.t('labelTo').toUpperCase(),
                                    style: AppTextStyles.bodyXs.copyWith(
                                      color: muted,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppSelectField<String?>(
                                          label: l10n.t('labelToBranch'),
                                          hint: l10n.t('selectBranch'),
                                          value: _toBranchId,
                                          options: [
                                            AppSelectOption(
                                                value: null,
                                                label: l10n.t('noBranch')),
                                            ..._branches.map((b) =>
                                                AppSelectOption(
                                                    value: b.id,
                                                    label: b.name)),
                                          ],
                                          onChanged: (v) => setState(
                                              () => _toBranchId = v),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: AppSelectField<String?>(
                                          label:
                                              '${l10n.t("labelToWarehouse")} *',
                                          hint: l10n.t('selectWarehouse'),
                                          value: _toWarehouseId,
                                          options: _warehouses
                                              .where((w) =>
                                                  w.id != _fromWarehouseId)
                                              .map((w) => AppSelectOption(
                                                    value: w.id,
                                                    label: w.extra != null
                                                        ? '${w.name} (${w.extra})'
                                                        : w.name,
                                                  ))
                                              .toList(),
                                          onChanged: (v) => setState(
                                              () => _toWarehouseId = v),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // Notes
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

                            // Items card
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
                                      TextButton.icon(
                                        onPressed: () => setState(
                                            () => _items.add(_ItemRowData())),
                                        icon: const Icon(Icons.add, size: 14),
                                        label: Text(l10n.t('addItem')),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),

                                  // Items header
                                  Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkMuted
                                          : AppColors.primaryMuted,
                                      borderRadius: AppRadius.brSm,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 4,
                                            child: Text(
                                                l10n.t('colProduct'),
                                                style: AppTextStyles
                                                    .tableHeader)),
                                        SizedBox(
                                          width: 90,
                                          child: Text(l10n.t('colQty'),
                                              style:
                                                  AppTextStyles.tableHeader),
                                        ),
                                        SizedBox(
                                          width: 110,
                                          child: Text(
                                              l10n.t('colUnitCost'),
                                              style:
                                                  AppTextStyles.tableHeader),
                                        ),
                                        const SizedBox(width: 32),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),

                                  for (var i = 0;
                                      i < _items.length;
                                      i++)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: AppSpacing.sm),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child: AppSelectField<String?>(
                                              hint:
                                                  l10n.t('selectProduct'),
                                              value: _items[i].productId,
                                              options: _products
                                                  .map((p) =>
                                                      AppSelectOption(
                                                        value: p.id,
                                                        label: p.extra !=
                                                                null
                                                            ? '${p.name} (${p.extra})'
                                                            : p.name,
                                                      ))
                                                  .toList(),
                                              onChanged: (v) {
                                                final prod =
                                                    _products.where((p) =>
                                                        p.id == v).firstOrNull;
                                                setState(() {
                                                  _items[i].productId = v;
                                                  _items[i].productName =
                                                      prod?.name ?? '';
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(
                                              width: AppSpacing.sm),
                                          SizedBox(
                                            width: 90,
                                            child: AppTextField(
                                              hint: '1',
                                              controller:
                                                  _items[i].qtyCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(
                                              width: AppSpacing.sm),
                                          SizedBox(
                                            width: 110,
                                            child: AppTextField(
                                              hint: '0.00',
                                              controller:
                                                  _items[i].costCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          SizedBox(
                                            width: 28,
                                            child: _items.length > 1
                                                ? IconButton(
                                                    icon: const Icon(
                                                        Icons
                                                            .remove_circle_outline,
                                                        size: 16,
                                                        color: AppColors
                                                            .destructive),
                                                    onPressed: () =>
                                                        setState(() {
                                                      _items[i].dispose();
                                                      _items.removeAt(i);
                                                    }),
                                                    padding:
                                                        EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            // Footer actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                AppButton.outline(
                                  label: l10n.cancel,
                                  onPressed: () => context.go('/transfers'),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                AppButton.primary(
                                  label: l10n.t('createTransfer'),
                                  isLoading: _submitting,
                                  onPressed: _submitting ? null : _submit,
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
