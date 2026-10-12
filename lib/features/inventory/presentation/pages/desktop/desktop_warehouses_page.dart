import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/buttons/app_icon_button.dart';
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/inventory_entities.dart';
import '../../../domain/entities/warehouse_entities.dart';
import '../../../domain/usecases/inventory_usecases.dart';
import '../../../domain/usecases/warehouse_usecases.dart';
import '../../cubit/warehouse_cubit.dart';
import '../../cubit/warehouse_state.dart';

class DesktopWarehousesPage extends StatelessWidget {
  const DesktopWarehousesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WarehouseCubit(
        getWarehouses: getIt<GetManagedWarehousesUseCase>(),
        createWarehouse: getIt<CreateWarehouseUseCase>(),
        updateWarehouse: getIt<UpdateWarehouseUseCase>(),
        deleteWarehouse: getIt<DeleteWarehouseUseCase>(),
        setDefaultWarehouse: getIt<SetDefaultWarehouseUseCase>(),
        getBranches: getIt<GetInventoryBranchOptionsUseCase>(),
      )..load(),
      child: const _WarehousesContent(),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

// React warehouseTypes.ts color mapping
Color _typeColor(String type) => switch (type) {
      'main' => AppColors.primary,
      'transit' => AppColors.primary,
      'damaged' => AppColors.destructive,
      'returns' => AppColors.mutedForeground,
      _ => AppColors.foreground,
    };

Color _typeBg(String type) => switch (type) {
      'main' => AppColors.primaryMuted,
      'transit' => AppColors.primaryMuted,
      _ => AppColors.muted,
    };

String _typeLabel(AppLocalizations l10n, String type) => switch (type) {
      'main' => l10n.t('warehouseTypeMain'),
      'retail' => l10n.t('warehouseTypeRetail'),
      'kitchen' => l10n.t('warehouseTypeKitchen'),
      'freezer' => l10n.t('warehouseTypeFreezer'),
      'damaged' => l10n.t('warehouseTypeDamaged'),
      'transit' => l10n.t('warehouseTypeTransit'),
      'returns' => l10n.t('warehouseTypeReturns'),
      _ => type,
    };

IconData _typeIcon(String type) => switch (type) {
      'main' => Icons.home_work_rounded,
      'retail' => Icons.store_rounded,
      'kitchen' => Icons.restaurant_rounded,
      'freezer' => Icons.ac_unit_rounded,
      'damaged' => Icons.warning_amber_rounded,
      'transit' => Icons.local_shipping_rounded,
      'returns' => Icons.replay_rounded,
      _ => Icons.warehouse_rounded,
    };

Future<void> _showWarehouseForm(
  BuildContext context,
  WarehouseCubit cubit,
  AppLocalizations l10n,
  List<InventoryBranchOptionEntity> branches, {
  WarehouseEntity? editing,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _WarehouseFormDialog(
      editing: editing,
      l10n: l10n,
      branches: branches,
      onSave: (data) async {
        final ok = editing != null
            ? await cubit.updateWarehouse(editing.id, data)
            : await cubit.createWarehouse(data);
        if (ok && context.mounted) {
          AppSnackbar.success(
            context,
            editing != null
                ? l10n.t('warehouseUpdated')
                : l10n.t('warehouseCreated'),
          );
        }
        return ok;
      },
    ),
  );
}

Future<void> _confirmDeleteWarehouse(
  BuildContext context,
  WarehouseEntity warehouse,
  WarehouseCubit cubit,
  AppLocalizations l10n,
) async {
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: l10n.t('deleteWarehouseTitle'),
    message: l10n.t('deleteWarehouseMsg').replaceAll('{name}', warehouse.name),
    confirmLabel: l10n.delete,
    isDestructive: true,
    onConfirm: () {},
  );
  if (confirmed != true || !context.mounted) return;
  final ok = await cubit.deleteWarehouse(warehouse.id);
  if (context.mounted) {
    if (ok) {
      AppSnackbar.success(context, l10n.t('warehouseDeleted'));
    } else {
      AppSnackbar.error(context, l10n.t('warehouseDeleteFailed'));
    }
  }
}

// ── Page Content ──────────────────────────────────────────────────────────────

class _WarehousesContent extends StatelessWidget {
  const _WarehousesContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WarehouseCubit, WarehouseState>(
      builder: (context, state) {
        final cubit = context.read<WarehouseCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted =
            isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

        final branches = state is WarehouseLoaded
            ? state.branches
            : <InventoryBranchOptionEntity>[];
        final currentBranchId =
            state is WarehouseLoaded ? state.branchId : null;
        final hasFilters = state is WarehouseLoaded &&
            (state.search.isNotEmpty || state.branchId != null);

        return ColoredBox(
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    // Icon box
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.warehouse_rounded,
                          size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('warehousesTitle'),
                          style: AppTextStyles.h4.copyWith(color: fg),
                        ),
                        Text(
                          l10n.t('warehousesSubtitle'),
                          style: AppTextStyles.bodySm.copyWith(color: muted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    AppButton.primary(
                      label: l10n.t('newWarehouse'),
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.add, size: 16),
                      onPressed: () =>
                          _showWarehouseForm(context, cubit, l10n, branches),
                    ),
                  ],
                ),
              ),

              // ── Filters ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.desktopContentPadding),
                child: Row(
                  children: [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: AppSearchField(
                          hint: l10n.t('searchWarehouses'),
                          onChanged: cubit.search,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 200,
                      child: AppSelectField<String>(
                        hint: l10n.t('allBranches'),
                        value: currentBranchId != null &&
                                branches.any((b) => b.id == currentBranchId)
                            ? currentBranchId
                            : null,
                        options: [
                          AppSelectOption(
                              value: '', label: l10n.t('allBranches')),
                          ...branches.map((b) =>
                              AppSelectOption(value: b.id, label: b.name)),
                        ],
                        onChanged: (v) =>
                            cubit.setBranch(v?.isEmpty ?? true ? null : v),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (hasFilters)
                      TextButton(
                        onPressed: () {
                          cubit.setBranch(null);
                          cubit.search('');
                        },
                        child: Text(
                          l10n.t('clearFilters'),
                          style: AppTextStyles.bodyXs.copyWith(
                            color: muted,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Table ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.desktopContentPadding),
                  child: switch (state) {
                    WarehouseInitial() || WarehouseLoading() =>
                      const ShimmerTableRows(),
                    WarehouseError(:final message) => AppErrorWidget(
                        message: message, onRetry: cubit.refresh),
                    WarehouseLoaded(:final warehouses) when warehouses.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(Icons.warehouse_outlined, size: 40),
                        message: hasFilters
                            ? l10n.t('noWarehouses')
                            : l10n.t('noWarehouses'),
                        subtitle: hasFilters
                            ? null
                            : l10n.t('addFirstWarehouse'),
                        action: hasFilters
                            ? null
                            : AppButton.primary(
                                label: l10n.t('newWarehouse'),
                                onPressed: () => _showWarehouseForm(
                                    context, cubit, l10n, branches),
                              ),
                      ),
                    WarehouseLoaded(:final warehouses, :final meta) => Column(
                        children: [
                          Expanded(
                            child: _WarehousesTable(
                              warehouses: warehouses,
                              isDark: isDark,
                              l10n: l10n,
                              onEdit: (w) => _showWarehouseForm(
                                  context, cubit, l10n, branches, editing: w),
                              onDelete: (w) => _confirmDeleteWarehouse(
                                  context, w, cubit, l10n),
                              onSetDefault: (w) async {
                                final ok = await cubit.setDefault(w.id);
                                if (context.mounted) {
                                  if (ok) {
                                    AppSnackbar.success(context,
                                        l10n.t('warehouseSetDefaultDone'));
                                  } else {
                                    AppSnackbar.error(context,
                                        l10n.t('warehouseSetDefaultFailed'));
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPagination(
                              meta: meta, onPageChanged: cubit.goToPage),
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

// ── Warehouses Table ──────────────────────────────────────────────────────────

class _WarehousesTable extends StatelessWidget {
  final List<WarehouseEntity> warehouses;
  final bool isDark;
  final AppLocalizations l10n;
  final void Function(WarehouseEntity) onEdit;
  final void Function(WarehouseEntity) onDelete;
  final void Function(WarehouseEntity) onSetDefault;

  const _WarehousesTable({
    required this.warehouses,
    required this.isDark,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
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
            // Header — React order: Code, Name, Branch, Type, Status, Default, Actions
            Container(
              height: AppSizes.tableHeaderHeight,
              color: headerBg,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(l10n.t('colCode'),
                        style: AppTextStyles.tableHeader,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(l10n.t('colName'),
                        style: AppTextStyles.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(l10n.t('colBranch'),
                        style: AppTextStyles.tableHeader),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(l10n.t('colType'),
                        style: AppTextStyles.tableHeader,
                        overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(l10n.t('colStatus'),
                        style: AppTextStyles.tableHeader,
                        overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(l10n.t('colDefault'),
                        style: AppTextStyles.tableHeader,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 72),
                ],
              ),
            ),
            Divider(height: 1, color: border),
            // Rows
            Expanded(
              child: ListView.separated(
                itemCount: warehouses.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: border),
                itemBuilder: (context, i) {
                  final w = warehouses[i];
                  return _WarehouseRow(
                    warehouse: w,
                    fg: fg,
                    muted: muted,
                    l10n: l10n,
                    onEdit: () => onEdit(w),
                    onDelete: () => onDelete(w),
                    onSetDefault: w.isDefault ? null : () => onSetDefault(w),
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

class _WarehouseRow extends StatelessWidget {
  final WarehouseEntity warehouse;
  final Color fg;
  final Color muted;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  const _WarehouseRow({
    required this.warehouse,
    required this.fg,
    required this.muted,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.tableRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          // Code — monospace muted (React: font-mono text-muted-foreground)
          SizedBox(
            width: 100,
            child: Text(
              warehouse.code,
              style: AppTextStyles.numeric.copyWith(
                color: muted,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Name — bold (React: font-semibold text-text)
          Expanded(
            flex: 3,
            child: Text(
              warehouse.name,
              style: AppTextStyles.labelSm.copyWith(
                  color: fg, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Branch
          Expanded(
            flex: 2,
            child: Text(
              warehouse.branchName ?? '—',
              style: AppTextStyles.tableCell.copyWith(color: muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Type badge (React colors)
          SizedBox(
            width: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: _typeBg(warehouse.type),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_typeIcon(warehouse.type),
                      size: 12, color: _typeColor(warehouse.type)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _typeLabel(l10n, warehouse.type),
                      style: AppTextStyles.bodyXs.copyWith(
                        color: _typeColor(warehouse.type),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Status — icon + text (React: CheckCircle/XCircle + Active/Inactive)
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Icon(
                  warehouse.isActive
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  size: 14,
                  color: warehouse.isActive
                      ? AppColors.primary
                      : AppColors.mutedForeground,
                ),
                const SizedBox(width: 4),
                Text(
                  warehouse.isActive ? l10n.active : l10n.inactive,
                  style: AppTextStyles.bodyXs.copyWith(
                    color: warehouse.isActive
                        ? AppColors.primary
                        : AppColors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Default — star+text when default, text button when not
          SizedBox(
            width: 120,
            child: warehouse.isDefault
                ? Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        l10n.t('defaultLabel'),
                        style: AppTextStyles.bodyXs.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: onSetDefault,
                    child: Text(
                      l10n.t('warehouseDefault'),
                      style: AppTextStyles.bodyXs.copyWith(
                        color: muted,
                        decoration: onSetDefault != null
                            ? TextDecoration.underline
                            : null,
                      ),
                    ),
                  ),
          ),
          // Actions (hover reveal in React — always show in Flutter)
          SizedBox(
            width: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppIconButton(
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  onPressed: onEdit,
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.sm,
                  tooltip: l10n.edit,
                ),
                AppIconButton(
                  icon: const Icon(Icons.delete_outline, size: 14),
                  onPressed: onDelete,
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
  }
}

// ── Warehouse Form Dialog ─────────────────────────────────────────────────────

class _WarehouseFormDialog extends StatefulWidget {
  final WarehouseEntity? editing;
  final AppLocalizations l10n;
  final List<InventoryBranchOptionEntity> branches;
  final Future<bool> Function(WarehouseFormData) onSave;

  const _WarehouseFormDialog({
    this.editing,
    required this.l10n,
    required this.branches,
    required this.onSave,
  });

  @override
  State<_WarehouseFormDialog> createState() => _WarehouseFormDialogState();
}

class _WarehouseFormDialogState extends State<_WarehouseFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _notesCtrl;
  late String _type;
  late bool _isActive;
  late bool _isDefault;
  String? _branchId;
  bool _submitting = false;
  String? _error;


  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _type = e?.type ?? 'main';
    _isActive = e?.isActive ?? true;
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = widget.l10n;
    final isEditing = widget.editing != null;

    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.t('nameRequired'));
      return;
    }
    if (_codeCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.t('codeRequired'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final data = WarehouseFormData(
      name: _nameCtrl.text.trim(),
      code: _codeCtrl.text.trim().toUpperCase(),
      type: _type,
      isActive: _isActive,
      isDefault: _isDefault,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      branchId: isEditing ? null : _branchId,
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
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.md, 0),
              child: Row(
                children: [
                  Text(
                    isEditing
                        ? l10n.t('editWarehouse')
                        : l10n.t('newWarehouse'),
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

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: AppRadius.brSm,
                          border: Border.all(
                              color: AppColors.destructive
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 14, color: AppColors.destructive),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(_error!,
                                  style: AppTextStyles.bodySm
                                      .copyWith(color: AppColors.destructive)),
                            ),
                          ],
                        ),
                      ),

                    // Branch (create only)
                    if (!isEditing && widget.branches.isNotEmpty) ...[
                      AppSelectField<String>(
                        label: '${l10n.t("labelBranch")} *',
                        hint: l10n.t('allBranches'),
                        value: _branchId,
                        options: widget.branches
                            .map((b) =>
                                AppSelectOption(value: b.id, label: b.name))
                            .toList(),
                        onChanged: (v) => setState(() => _branchId = v),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Branch lock notice (edit)
                    if (isEditing) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMuted,
                          borderRadius: AppRadius.brSm,
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(l10n.t('branchCannotChange'),
                                  style: AppTextStyles.bodySm
                                      .copyWith(color: AppColors.primary)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Code (2/5) + Name (3/5) row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppTextField(
                            label: '${l10n.t("labelCode")} *',
                            hint: l10n.t('warehouseCodePlaceholder'),
                            controller: _codeCtrl,
                            onChanged: (v) {
                              final upper =
                                  v.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\-_]'), '');
                              if (upper != v) {
                                _codeCtrl.value = _codeCtrl.value.copyWith(
                                  text: upper,
                                  selection: TextSelection.collapsed(
                                      offset: upper.length),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 3,
                          child: AppTextField(
                            label: '${l10n.t("labelName")} *',
                            hint: l10n.t('warehouseNamePlaceholder'),
                            controller: _nameCtrl,
                            autofocus: !isEditing,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Type grid (4 columns, 2 rows like React)
                    Text('${l10n.t("labelType")} *',
                        style: AppTextStyles.labelMd),
                    const SizedBox(height: AppSpacing.xs),
                    _TypeGrid(
                      selected: _type,
                      l10n: l10n,
                      onSelect: (t) => setState(() => _type = t),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Notes + char counter
                    AppTextField(
                      label: l10n.t('labelNotes'),
                      hint: l10n.t('notesPlaceholder'),
                      controller: _notesCtrl,
                      maxLines: 3,
                      onChanged: (_) => setState(() {}),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        '${_notesCtrl.text.length}/500',
                        style: AppTextStyles.bodyXs.copyWith(
                            color: AppColors.mutedForeground),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Active + Default toggles (horizontal, same line like React)
                    Row(
                      children: [
                        _ToggleItem(
                          label: l10n.t('isActive'),
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        _ToggleItem(
                          label: l10n.t('isDefault'),
                          value: _isDefault,
                          onChanged: (v) => setState(() => _isDefault = v),
                        ),
                      ],
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
                        : l10n.t('createWarehouse'),
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

// ── Type Grid (matches React 4-column grid) ───────────────────────────────────

class _TypeGrid extends StatelessWidget {
  final String selected;
  final AppLocalizations l10n;
  final ValueChanged<String> onSelect;

  static const _types = [
    'main', 'retail', 'kitchen', 'freezer', 'damaged', 'transit', 'returns',
  ];

  const _TypeGrid(
      {required this.selected, required this.l10n, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: _types.map((type) {
        final isSelected = selected == type;
        return InkWell(
          onTap: () => onSelect(type),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: isSelected ? _typeBg(type) : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.border.withValues(alpha: 0.6),
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _typeIcon(type),
                  size: 13,
                  color: isSelected
                      ? _typeColor(type)
                      : AppColors.mutedForeground,
                ),
                const SizedBox(width: 5),
                Text(
                  _typeLabel(l10n, type),
                  style: AppTextStyles.bodyXs.copyWith(
                    color: isSelected
                        ? _typeColor(type)
                        : AppColors.mutedForeground,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Toggle Item (horizontal layout like React) ────────────────────────────────

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.labelMd),
      ],
    );
  }
}
