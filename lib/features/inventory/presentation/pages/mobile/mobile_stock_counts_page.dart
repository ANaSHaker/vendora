import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
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
import '../../../domain/entities/stock_count_entities.dart';
import '../../cubit/stock_count_cubit.dart';
import '../../cubit/stock_count_state.dart';

class MobileStockCountsPage extends StatelessWidget {
  const MobileStockCountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StockCountCubit(
        getStockCounts: getIt(),
        getStockCountById: getIt(),
        createStockCount: getIt(),
        postStockCount: getIt(),
        deleteStockCount: getIt(),
      )..load(),
      child: const _MobileContent(),
    );
  }
}

class _MobileContent extends StatelessWidget {
  const _MobileContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockCountCubit, StockCountState>(
      builder: (context, state) {
        final cubit = context.read<StockCountCubit>();
        final l10n = AppLocalizations.of(context);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(l10n.t('stockCounts'), style: AppTextStyles.h6),
            elevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateDialog(context, cubit, l10n),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppSearchField(
                  hint: l10n.t('searchStockCounts'),
                  onChanged: cubit.search,
                ),
              ),
              Expanded(
                child: switch (state) {
                  StockCountInitial() || StockCountLoading() =>
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      itemCount: 6,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ShimmerTableRows(),
                      ),
                    ),
                  StockCountError(:final message) => AppErrorWidget(
                      message: message,
                      onRetry: cubit.refresh,
                    ),
                  StockCountLoaded(:final counts) when counts.isEmpty =>
                    AppEmptyState(
                      icon: const Icon(Icons.inventory_2_outlined, size: 40),
                      message: l10n.t('noStockCounts'),
                    ),
                  StockCountLoaded(:final counts) => ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      itemCount: counts.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) => _StockCountCard(
                        count: counts[i],
                        l10n: l10n,
                        onPost: () =>
                            _confirmPost(context, counts[i], cubit, l10n),
                        onDelete: () =>
                            _confirmDelete(context, counts[i], cubit, l10n),
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

class _StockCountCard extends StatelessWidget {
  final StockCountEntity count;
  final AppLocalizations l10n;
  final VoidCallback onPost;
  final VoidCallback onDelete;

  const _StockCountCard({
    required this.count,
    required this.l10n,
    required this.onPost,
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

  StatusBadge _badge() => switch (count.status) {
        'posted' => StatusBadge.custom(
            label: count.status,
            color: AppColors.successForeground,
            bgColor: AppColors.successLight,
          ),
        'cancelled' => StatusBadge.custom(
            label: count.status,
            color: AppColors.destructive,
            bgColor: AppColors.destructive.withValues(alpha: 0.1),
          ),
        _ => StatusBadge.custom(
            label: count.status,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
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
                  count.reference.isNotEmpty ? count.reference : '—',
                  style: AppTextStyles.numeric
                      .copyWith(color: AppColors.foreground),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _badge(),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            count.warehouseName,
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
                _fmtDate(count.createdAt),
                style: AppTextStyles.bodyXs
                    .copyWith(color: AppColors.mutedForeground),
              ),
              const Spacer(),
              Text(
                '${count.itemsCount} items',
                style: AppTextStyles.bodyXs
                    .copyWith(color: AppColors.mutedForeground),
              ),
            ],
          ),
          if (count.status == 'draft') ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                AppButton.outline(
                  label: l10n.t('postCount'),
                  size: AppButtonSize.sm,
                  leading:
                      const Icon(Icons.check_circle_outline, size: 14),
                  onPressed: onPost,
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton.outline(
                  label: l10n.delete,
                  size: AppButtonSize.sm,
                  leading: const Icon(Icons.delete_outline, size: 14),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _showCreateDialog(
  BuildContext context,
  StockCountCubit cubit,
  AppLocalizations l10n,
) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _MobileCreateDialog(
      l10n: l10n,
      onSave: (data) async {
        final ok = await cubit.createStockCount(data);
        if (ok && context.mounted) {
          AppSnackbar.success(context, l10n.t('stockCountCreated'));
        }
        return ok;
      },
    ),
  );
}

Future<void> _confirmPost(
  BuildContext context,
  StockCountEntity count,
  StockCountCubit cubit,
  AppLocalizations l10n,
) async {
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: l10n.t('postCountTitle'),
    message: l10n.t('postCountMsg'),
    confirmLabel: l10n.t('postCount'),
    isDestructive: false,
    onConfirm: () {},
  );
  if (confirmed != true || !context.mounted) return;
  final ok = await cubit.postCount(count.id);
  if (context.mounted) {
    ok
        ? AppSnackbar.success(context, l10n.t('stockCountPosted'))
        : AppSnackbar.error(context, l10n.t('actionFailed'));
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  StockCountEntity count,
  StockCountCubit cubit,
  AppLocalizations l10n,
) async {
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: l10n.t('deleteStockCountTitle'),
    message: l10n.t('deleteStockCountMsg'),
    confirmLabel: l10n.delete,
    isDestructive: true,
    onConfirm: () {},
  );
  if (confirmed != true || !context.mounted) return;
  final ok = await cubit.deleteCount(count.id);
  if (context.mounted) {
    ok
        ? AppSnackbar.success(context, l10n.t('stockCountDeleted'))
        : AppSnackbar.error(context, l10n.t('actionFailed'));
  }
}

// ── Mobile create dialog ──────────────────────────────────────────────────────

class _MobileCreateDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final Future<bool> Function(StockCountFormData) onSave;

  const _MobileCreateDialog(
      {required this.l10n, required this.onSave});

  @override
  State<_MobileCreateDialog> createState() => _MobileCreateDialogState();
}

class _MobileCreateDialogState extends State<_MobileCreateDialog> {
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loadingWarehouses = true;
  List<_WH> _warehouses = [];
  String? _warehouseId;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    _notesCtrl.dispose();
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
    setState(() {
      _submitting = true;
      _error = null;
    });
    final data = StockCountFormData(
      reference:
          _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      warehouseId: _warehouseId!,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
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
            Text(l10n.t('newStockCount'), style: AppTextStyles.h5),
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
            AppTextField(
              label: l10n.t('labelReference'),
              hint: l10n.t('referencePlaceholder'),
              controller: _refCtrl,
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
                onChanged: (v) => setState(() => _warehouseId = v),
              ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.t('labelNotes'),
              hint: l10n.t('notesPlaceholder'),
              controller: _notesCtrl,
              maxLines: 3,
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
                  label: l10n.t('createStockCount'),
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

class _WH {
  final String id;
  final String name;
  const _WH(this.id, this.name);
}
