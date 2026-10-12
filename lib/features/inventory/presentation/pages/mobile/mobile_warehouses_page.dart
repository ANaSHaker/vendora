import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../domain/entities/inventory_entities.dart';
import '../../../domain/entities/warehouse_entities.dart';
import '../../../domain/usecases/inventory_usecases.dart';
import '../../../domain/usecases/warehouse_usecases.dart';
import '../../cubit/warehouse_cubit.dart';
import '../../cubit/warehouse_state.dart';

class MobileWarehousesPage extends StatelessWidget {
  const MobileWarehousesPage({super.key});

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
      child: const _MobileWarehousesContent(),
    );
  }
}

class _MobileWarehousesContent extends StatelessWidget {
  const _MobileWarehousesContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WarehouseCubit, WarehouseState>(
      builder: (context, state) {
        final cubit = context.read<WarehouseCubit>();
        final l10n = AppLocalizations.of(context);
        final branches =
            state is WarehouseLoaded ? state.branches : <InventoryBranchOptionEntity>[];
        final currentBranchId =
            state is WarehouseLoaded ? state.branchId : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(l10n.t('warehousesTitle'), style: AppTextStyles.h6),
            elevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
                _showWarehouseForm(context, cubit, l10n, branches),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                child: AppSearchField(
                  hint: l10n.t('searchWarehouses'),
                  onChanged: cubit.search,
                ),
              ),
              if (branches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
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
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: switch (state) {
                  WarehouseInitial() || WarehouseLoading() =>
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      itemCount: 8,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ShimmerBox(height: 96),
                      ),
                    ),
                  WarehouseError(:final message) => AppErrorWidget(
                      message: message,
                      onRetry: cubit.refresh,
                    ),
                  WarehouseLoaded(:final warehouses)
                      when warehouses.isEmpty =>
                    AppEmptyState(
                      icon: const Icon(Icons.warehouse_outlined, size: 40),
                      message: l10n.t('noWarehouses'),
                      action: AppButton.primary(
                        label: l10n.t('newWarehouse'),
                        onPressed: () => _showWarehouseForm(
                            context, cubit, l10n, branches),
                      ),
                    ),
                  WarehouseLoaded(:final warehouses) =>
                    RefreshIndicator(
                      onRefresh: () async => cubit.refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.xl * 4,
                        ),
                        itemCount: warehouses.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, i) => _MobileWarehouseCard(
                          warehouse: warehouses[i],
                          cubit: cubit,
                          l10n: l10n,
                          branches: branches,
                        ),
                      ),
                    ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileWarehouseCard extends StatelessWidget {
  final WarehouseEntity warehouse;
  final WarehouseCubit cubit;
  final AppLocalizations l10n;
  final List<InventoryBranchOptionEntity> branches;

  const _MobileWarehouseCard({
    required this.warehouse,
    required this.cubit,
    required this.l10n,
    required this.branches,
  });

  Color _typeBadgeColor(String type) => switch (type) {
        'main' => AppColors.primary,
        'retail' => AppColors.success,
        'kitchen' => const Color(0xFFF59E0B),
        'freezer' => const Color(0xFF3B82F6),
        'damaged' => AppColors.destructive,
        'transit' => AppColors.mutedForeground,
        'returns' => const Color(0xFFF97316),
        _ => AppColors.mutedForeground,
      };

  Color _typeBadgeBg(String type) => switch (type) {
        'main' => AppColors.primaryMuted,
        'retail' => AppColors.successLight,
        'kitchen' => const Color(0xFFFEF3C7),
        'freezer' => const Color(0xFFEFF6FF),
        'damaged' => AppColors.destructiveLight,
        'transit' => AppColors.muted,
        'returns' => const Color(0xFFFFF7ED),
        _ => AppColors.muted,
      };

  String _typeLabel(String type) => switch (type) {
        'main' => l10n.t('warehouseTypeMain'),
        'retail' => l10n.t('warehouseTypeRetail'),
        'kitchen' => l10n.t('warehouseTypeKitchen'),
        'freezer' => l10n.t('warehouseTypeFreezer'),
        'damaged' => l10n.t('warehouseTypeDamaged'),
        'transit' => l10n.t('warehouseTypeTransit'),
        'returns' => l10n.t('warehouseTypeReturns'),
        _ => type,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showWarehouseForm(context, cubit, l10n, branches,
          editing: warehouse),
      borderRadius: AppRadius.brMd,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: AppRadius.brMd,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            warehouse.name,
                            style: AppTextStyles.labelMd,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (warehouse.isDefault)
                          const Icon(Icons.star_rounded,
                              size: 16, color: Color(0xFFF59E0B)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          warehouse.code,
                          style: AppTextStyles.bodyXs.copyWith(
                            color: AppColors.mutedForeground,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatusBadge.custom(
                          label: _typeLabel(warehouse.type),
                          color: _typeBadgeColor(warehouse.type),
                          bgColor: _typeBadgeBg(warehouse.type),
                        ),
                      ],
                    ),
                    if (warehouse.branchName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        warehouse.branchName!,
                        style: AppTextStyles.bodyXs
                            .copyWith(color: AppColors.mutedForeground),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  warehouse.isActive
                      ? StatusBadge.custom(
                          label: l10n.active,
                          color: AppColors.successForeground,
                          bgColor: AppColors.successLight,
                        )
                      : StatusBadge.custom(
                          label: l10n.inactive,
                          color: AppColors.mutedForeground,
                          bgColor: AppColors.muted,
                        ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      // Set default icon (if not already default)
                      if (!warehouse.isDefault)
                        IconButton(
                          icon: const Icon(Icons.star_outline_rounded, size: 18),
                          onPressed: () async {
                            final ok = await cubit.setDefault(warehouse.id);
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
                          color: AppColors.mutedForeground,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                          tooltip: l10n.t('warehouseDefault'),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _showWarehouseForm(
                            context, cubit, l10n, branches,
                            editing: warehouse),
                        color: AppColors.mutedForeground,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () =>
                            _confirmDelete(context, cubit, warehouse, l10n),
                        color: AppColors.destructive,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Form ──────────────────────────────────────────────────────────────────────

void _showWarehouseForm(
  BuildContext context,
  WarehouseCubit cubit,
  AppLocalizations l10n,
  List<InventoryBranchOptionEntity> branches, {
  WarehouseEntity? editing,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _WarehouseFormSheet(
          editing: editing, l10n: l10n, branches: branches),
    ),
  );
}

class _WarehouseFormSheet extends StatefulWidget {
  final WarehouseEntity? editing;
  final AppLocalizations l10n;
  final List<InventoryBranchOptionEntity> branches;

  const _WarehouseFormSheet({
    this.editing,
    required this.l10n,
    required this.branches,
  });

  @override
  State<_WarehouseFormSheet> createState() => _WarehouseFormSheetState();
}

class _WarehouseFormSheetState extends State<_WarehouseFormSheet> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'main';
  bool _isActive = true;
  bool _isDefault = false;
  String? _branchId;
  bool _saving = false;
  String? _nameError;

  static const _warehouseTypes = [
    'main', 'retail', 'kitchen', 'freezer', 'damaged', 'transit', 'returns',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _codeCtrl.text = e.code;
      _notesCtrl.text = e.notes ?? '';
      _type = e.type;
      _isActive = e.isActive;
      _isDefault = e.isDefault;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _typeLabel(String type) {
    final l10n = widget.l10n;
    return switch (type) {
      'main' => l10n.t('warehouseTypeMain'),
      'retail' => l10n.t('warehouseTypeRetail'),
      'kitchen' => l10n.t('warehouseTypeKitchen'),
      'freezer' => l10n.t('warehouseTypeFreezer'),
      'damaged' => l10n.t('warehouseTypeDamaged'),
      'transit' => l10n.t('warehouseTypeTransit'),
      'returns' => l10n.t('warehouseTypeReturns'),
      _ => type,
    };
  }

  Future<void> _submit() async {
    final l10n = widget.l10n;
    final isEditing = widget.editing != null;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l10n.t('nameRequired'));
      return;
    }
    setState(() {
      _saving = true;
      _nameError = null;
    });

    final data = WarehouseFormData(
      name: name,
      code: _codeCtrl.text.trim().toUpperCase(),
      type: _type,
      isActive: _isActive,
      isDefault: _isDefault,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      branchId: isEditing ? null : _branchId,
    );

    final cubit = context.read<WarehouseCubit>();
    final bool ok;
    if (isEditing) {
      ok = await cubit.updateWarehouse(widget.editing!.id, data);
    } else {
      ok = await cubit.createWarehouse(data);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
      AppSnackbar.success(
        context,
        isEditing ? l10n.t('warehouseUpdated') : l10n.t('warehouseCreated'),
      );
    } else {
      AppSnackbar.error(context, l10n.t('warehouseSaveFailed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isEditing = widget.editing != null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.brSm,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.sm, AppSpacing.sm),
            child: Row(
              children: [
                Text(
                  isEditing ? l10n.t('editWarehouse') : l10n.t('newWarehouse'),
                  style: AppTextStyles.h6,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branch dropdown — create only
                if (!isEditing && widget.branches.isNotEmpty) ...[
                  AppSelectField<String>(
                    label: '${l10n.t("labelBranch")} *',
                    hint: l10n.t('allBranches'),
                    value: _branchId,
                    options: widget.branches
                        .map((b) => AppSelectOption(value: b.id, label: b.name))
                        .toList(),
                    onChanged: (v) => setState(() => _branchId = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                // Branch lock notice — edit only
                if (isEditing) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            l10n.t('branchCannotChange'),
                            style: AppTextStyles.bodyXs
                                .copyWith(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppTextField(
                  label: '${l10n.t("labelName")} *',
                  hint: l10n.t('warehouseNamePlaceholder'),
                  controller: _nameCtrl,
                  errorText: _nameError,
                  onChanged: (_) {
                    if (_nameError != null) {
                      setState(() => _nameError = null);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: '${l10n.t("labelCode")} *',
                  hint: l10n.t('warehouseCodePlaceholder'),
                  controller: _codeCtrl,
                  onChanged: (v) {
                    final upper = v.toUpperCase();
                    if (upper != v) {
                      _codeCtrl.value = _codeCtrl.value.copyWith(
                        text: upper,
                        selection:
                            TextSelection.collapsed(offset: upper.length),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppSelectField<String>(
                  label: '${l10n.t("labelType")} *',
                  value: _type,
                  options: _warehouseTypes
                      .map((t) =>
                          AppSelectOption(value: t, label: _typeLabel(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.t('labelNotes'),
                  hint: l10n.t('notesPlaceholder'),
                  controller: _notesCtrl,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.t('isActive'),
                              style: AppTextStyles.labelSm),
                          Text(
                            l10n.t('isActiveHint'),
                            style: AppTextStyles.bodyXs.copyWith(
                                color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeTrackColor: AppColors.primary,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.t('isDefault'),
                              style: AppTextStyles.labelSm),
                          Text(
                            l10n.t('isDefaultHint'),
                            style: AppTextStyles.bodyXs.copyWith(
                                color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isDefault,
                      onChanged: (v) => setState(() => _isDefault = v),
                      activeTrackColor: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.primary(
                    label: _saving
                        ? l10n.t('saving')
                        : (isEditing
                            ? l10n.saveChanges
                            : l10n.t('createWarehouse')),
                    onPressed: _saving ? null : _submit,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confirm Delete ────────────────────────────────────────────────────────────

void _confirmDelete(
  BuildContext context,
  WarehouseCubit cubit,
  WarehouseEntity warehouse,
  AppLocalizations l10n,
) async {
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: l10n.t('deleteWarehouseTitle'),
    message: l10n
        .t('deleteWarehouseMsg')
        .replaceAll('{name}', warehouse.name),
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
