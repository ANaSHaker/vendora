import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/api/api_client.dart';
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
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../domain/entities/adjustment_entities.dart';
import '../../cubit/adjustment_cubit.dart';
import '../../cubit/adjustment_state.dart';

class MobileAdjustmentsPage extends StatelessWidget {
  const MobileAdjustmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdjustmentCubit(
        getAdjustments: getIt(),
        getAdjustmentById: getIt(),
        createAdjustment: getIt(),
        updateAdjustment: getIt(),
        approveAdjustment: getIt(),
        postAdjustment: getIt(),
        cancelAdjustment: getIt(),
        deleteAdjustment: getIt(),
      )..load(),
      child: const _MobileContent(),
    );
  }
}

class _MobileContent extends StatelessWidget {
  const _MobileContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdjustmentCubit, AdjustmentState>(
      builder: (context, state) {
        final cubit = context.read<AdjustmentCubit>();
        final l10n = AppLocalizations.of(context);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(l10n.t('adjustments'), style: AppTextStyles.h6),
            elevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showFormDialog(context, cubit, l10n),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: switch (state) {
            AdjustmentInitial() || AdjustmentLoading() => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: 6,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ShimmerTableRows(),
                ),
              ),
            AdjustmentError(:final message) => AppErrorWidget(
                message: message,
                onRetry: cubit.refresh,
              ),
            AdjustmentLoaded(:final adjustments) when adjustments.isEmpty =>
              AppEmptyState(
                icon: const Icon(Icons.tune_outlined, size: 40),
                message: l10n.t('noAdjustments'),
              ),
            AdjustmentLoaded(:final adjustments) => ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: adjustments.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final a = adjustments[i];
                  return _AdjustmentCard(
                    adjustment: a,
                    l10n: l10n,
                    onEdit: () =>
                        _showFormDialog(context, cubit, l10n, editing: a),
                    onApprove: () =>
                        _confirmAction(context, cubit, l10n, a, 'approve'),
                    onPost: () =>
                        _confirmAction(context, cubit, l10n, a, 'post'),
                    onCancel: () =>
                        _confirmAction(context, cubit, l10n, a, 'cancel'),
                    onDelete: () =>
                        _confirmAction(context, cubit, l10n, a, 'delete'),
                  );
                },
              ),
          },
        );
      },
    );
  }
}

class _AdjustmentCard extends StatelessWidget {
  final AdjustmentEntity adjustment;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onApprove;
  final VoidCallback onPost;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _AdjustmentCard({
    required this.adjustment,
    required this.l10n,
    required this.onEdit,
    required this.onApprove,
    required this.onPost,
    required this.onCancel,
    required this.onDelete,
  });

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  StatusBadge _typeBadge() => switch (adjustment.adjustmentType) {
        'adjustment_out' => StatusBadge.custom(
            label: adjustment.adjustmentType,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
          ),
        'damaged' => StatusBadge.custom(
            label: adjustment.adjustmentType,
            color: AppColors.destructive,
            bgColor: AppColors.destructive.withValues(alpha: 0.1),
          ),
        _ => StatusBadge.custom(
            label: adjustment.adjustmentType,
            color: AppColors.primary,
            bgColor: AppColors.primaryMuted,
          ),
      };

  StatusBadge _statusBadge() => switch (adjustment.status) {
        'approved' => StatusBadge.custom(
            label: adjustment.status,
            color: AppColors.primary,
            bgColor: AppColors.primaryMuted,
          ),
        'posted' => StatusBadge.custom(
            label: adjustment.status,
            color: AppColors.successForeground,
            bgColor: AppColors.successLight,
          ),
        'cancelled' => StatusBadge.custom(
            label: adjustment.status,
            color: AppColors.destructive,
            bgColor: AppColors.destructive.withValues(alpha: 0.1),
          ),
        _ => StatusBadge.custom(
            label: adjustment.status,
            color: AppColors.mutedForeground,
            bgColor: AppColors.muted,
          ),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  adjustment.reference?.isNotEmpty == true
                      ? adjustment.reference!
                      : '—',
                  style: AppTextStyles.numeric
                      .copyWith(color: AppColors.foreground),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _typeBadge(),
              const SizedBox(width: AppSpacing.xs),
              _statusBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (adjustment.warehouseName != null)
            Text(
              adjustment.warehouseName!,
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.mutedForeground),
            ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 12, color: AppColors.mutedForeground),
              const SizedBox(width: 4),
              Text(
                _fmtDate(adjustment.date),
                style: AppTextStyles.bodyXs
                    .copyWith(color: AppColors.mutedForeground),
              ),
              const Spacer(),
              Text(
                '${adjustment.itemsCount} items',
                style: AppTextStyles.bodyXs
                    .copyWith(color: AppColors.mutedForeground),
              ),
            ],
          ),
          if (adjustment.status == 'draft' ||
              adjustment.status == 'approved') ...[
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (adjustment.status == 'draft') ...[
                    AppButton.outline(
                      label: l10n.edit,
                      size: AppButtonSize.sm,
                      onPressed: onEdit,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppButton.outline(
                      label: l10n.t('approve'),
                      size: AppButtonSize.sm,
                      onPressed: onApprove,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ] else ...[
                    AppButton.outline(
                      label: l10n.t('post'),
                      size: AppButtonSize.sm,
                      onPressed: onPost,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  AppButton.outline(
                    label: l10n.cancel,
                    size: AppButtonSize.sm,
                    onPressed: onCancel,
                  ),
                  if (adjustment.status == 'draft') ...[
                    const SizedBox(width: AppSpacing.xs),
                    AppButton.outline(
                      label: l10n.delete,
                      size: AppButtonSize.sm,
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _showFormDialog(
  BuildContext context,
  AdjustmentCubit cubit,
  AppLocalizations l10n, {
  AdjustmentEntity? editing,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AdjFormDialog(
      editing: editing,
      l10n: l10n,
      onSave: (data) async {
        final ok = editing != null
            ? await cubit.updateAdjustment(editing.id, data)
            : await cubit.createAdjustment(data);
        if (ok && context.mounted) {
          AppSnackbar.success(
            context,
            editing != null
                ? l10n.t('adjustmentUpdated')
                : l10n.t('adjustmentCreated'),
          );
        }
        return ok;
      },
    ),
  );
}

Future<void> _confirmAction(
  BuildContext context,
  AdjustmentCubit cubit,
  AppLocalizations l10n,
  AdjustmentEntity a,
  String action,
) async {
  final (title, msg, label, destructive) = switch (action) {
    'approve' => (
        l10n.t('approveAdjustmentTitle'),
        l10n.t('approveAdjustmentMsg'),
        l10n.t('approve'),
        false
      ),
    'post' => (
        l10n.t('postAdjustmentTitle'),
        l10n.t('postAdjustmentMsg'),
        l10n.t('post'),
        false
      ),
    'cancel' => (
        l10n.t('cancelAdjustmentTitle'),
        l10n.t('cancelAdjustmentMsg'),
        l10n.cancel,
        true
      ),
    _ => (
        l10n.t('deleteAdjustmentTitle'),
        l10n.t('deleteAdjustmentMsg'),
        l10n.delete,
        true
      ),
  };

  final confirmed = await ConfirmDialog.show(
    context: context,
    title: title,
    message: msg,
    confirmLabel: label,
    isDestructive: destructive,
    onConfirm: () {},
  );
  if (confirmed != true || !context.mounted) return;

  final ok = await switch (action) {
    'approve' => cubit.approveAdjustment(a.id),
    'post' => cubit.postAdjustment(a.id),
    'cancel' => cubit.cancelAdjustment(a.id),
    _ => cubit.deleteAdjustment(a.id),
  };

  if (context.mounted) {
    ok
        ? AppSnackbar.success(context, l10n.t('actionSuccess'))
        : AppSnackbar.error(context, l10n.t('actionFailed'));
  }
}

// ── Form dialog ───────────────────────────────────────────────────────────────

class _AdjFormDialog extends StatefulWidget {
  final AdjustmentEntity? editing;
  final AppLocalizations l10n;
  final Future<bool> Function(AdjustmentFormData) onSave;

  const _AdjFormDialog(
      {this.editing, required this.l10n, required this.onSave});

  @override
  State<_AdjFormDialog> createState() => _AdjFormDialogState();
}

class _AdjFormDialogState extends State<_AdjFormDialog> {
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  late String _type;
  String? _warehouseId;
  bool _loadingWarehouses = true;
  List<_WH> _warehouses = [];
  final List<_ItemRow> _items = [];
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _type = e?.adjustmentType ?? 'adjustment_in';
    _refCtrl.text = e?.reference ?? '';
    _notesCtrl.text = e?.notes ?? '';
    _dateCtrl.text = e?.date ?? _todayStr();
    _items.add(_ItemRow());
    _loadWarehouses();
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    for (final r in _items) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _loadWarehouses() async {
    try {
      final client = getIt<ApiClient>();
      // ignore: avoid_dynamic_calls
      final res = await client.get<Map<String, dynamic>>(
        '/api/warehouses',
        queryParameters: {'per_page': 200},
      );
      final data = res.data as Map<String, dynamic>;
      final list = (data['data'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _warehouses = list
              .map((w) =>
                  _WH(w['id']?.toString() ?? '', w['name'] as String? ?? ''))
              .toList();
          _loadingWarehouses = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingWarehouses = false);
    }
  }

  Future<void> _submit() async {
    if (_warehouseId == null) {
      setState(() => _error = widget.l10n.t('warehouseRequired'));
      return;
    }
    final validItems = _items
        .where((r) => r.nameCtrl.text.trim().isNotEmpty)
        .map((r) => AdjustmentItemInput(
              productId: '',
              productName: r.nameCtrl.text.trim(),
              qty: double.tryParse(r.qtyCtrl.text.trim()) ?? 0,
            ))
        .toList();
    if (validItems.isEmpty) {
      setState(() => _error = widget.l10n.t('itemsRequired'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final data = AdjustmentFormData(
      adjustmentType: _type,
      warehouseId: _warehouseId!,
      reference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      date: _dateCtrl.text.trim().isEmpty ? _todayStr() : _dateCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      items: validItems,
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
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editing != null
                  ? l10n.t('editAdjustment')
                  : l10n.t('newAdjustment'),
              style: AppTextStyles.h5,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: AppRadius.brSm,
                ),
                child: Text(_error!,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.destructive)),
              ),
            AppSelectField<String>(
              label: '${l10n.t("labelType")} *',
              hint: l10n.t('selectType'),
              value: _type,
              options: const [
                AppSelectOption(
                    value: 'adjustment_in', label: 'Adjustment In'),
                AppSelectOption(
                    value: 'adjustment_out', label: 'Adjustment Out'),
                AppSelectOption(value: 'damaged', label: 'Damaged'),
              ],
              onChanged: (v) =>
                  setState(() => _type = v ?? 'adjustment_in'),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_loadingWarehouses)
              const Center(
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              AppSelectField<String>(
                label: '${l10n.t("labelWarehouse")} *',
                hint: l10n.t('selectWarehouse'),
                value: _warehouseId,
                options: _warehouses
                    .map((w) =>
                        AppSelectOption(value: w.id, label: w.name))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _warehouseId = v),
              ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.t('labelDate'),
              hint: 'YYYY-MM-DD',
              controller: _dateCtrl,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.t('labelNotes'),
              hint: l10n.t('notesPlaceholder'),
              controller: _notesCtrl,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(l10n.t('labelItems'), style: AppTextStyles.labelMd),
                const Spacer(),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _items.add(_ItemRow())),
                  icon: const Icon(Icons.add, size: 14),
                  label: Text(l10n.t('addItem')),
                ),
              ],
            ),
            for (var i = 0; i < _items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppTextField(
                        hint: l10n.t('productNamePlaceholder'),
                        controller: _items[i].nameCtrl,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppTextField(
                        hint: '0',
                        controller: _items[i].qtyCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    if (_items.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            size: 18, color: AppColors.destructive),
                        onPressed: () => setState(() {
                          _items[i].dispose();
                          _items.removeAt(i);
                        }),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.outline(
                  label: l10n.cancel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton.primary(
                  label: widget.editing != null
                      ? l10n.saveChanges
                      : l10n.t('createAdjustment'),
                  isLoading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow {
  final nameCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
  }
}

class _WH {
  final String id;
  final String name;
  const _WH(this.id, this.name);
}
