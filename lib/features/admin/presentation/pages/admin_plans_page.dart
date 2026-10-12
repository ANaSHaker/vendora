import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../design_system/theme/app_border_radius.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_text_styles.dart';
import '../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../domain/entities/admin_plan_entity.dart';
import '../../domain/usecases/admin_usecases.dart';
import '../cubit/admin_plans_cubit.dart';
import '../cubit/admin_plans_state.dart';

class AdminPlansPage extends StatelessWidget {
  const AdminPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminPlansCubit(
        getPlans: getIt<GetAdminPlansUseCase>(),
        createPlan: getIt<CreateAdminPlanUseCase>(),
        updatePlan: getIt<UpdateAdminPlanUseCase>(),
        deletePlan: getIt<DeleteAdminPlanUseCase>(),
      )..load(),
      child: const _PlansContent(),
    );
  }
}

class _PlansContent extends StatelessWidget {
  const _PlansContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.t('adminPlans'),
                          style: AppTextStyles.h4.copyWith(color: fg)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(l10n.t('adminPlansSubtitle'),
                          style: AppTextStyles.bodySm.copyWith(color: muted)),
                    ],
                  ),
                ),
                AppButton(
                  label: l10n.t('createPlan'),
                  onPressed: () => _showPlanForm(context, null),
                  leading: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: BlocBuilder<AdminPlansCubit, AdminPlansState>(
                builder: (context, state) {
                  if (state is AdminPlansLoading) {
                    return Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: AppRadius.brLg,
                        border: Border.all(color: borderColor),
                      ),
                      child: const ShimmerTableRows(rows: 8),
                    );
                  }
                  if (state is AdminPlansError) {
                    return AppErrorWidget(
                      message: state.message,
                      onRetry: () => context.read<AdminPlansCubit>().load(),
                    );
                  }
                  if (state is AdminPlansLoaded) {
                    if (state.plans.isEmpty) {
                      return AppEmptyState(message: l10n.t('noPlans'));
                    }
                    return _PlansTable(
                      state: state,
                      l10n: l10n,
                      isDark: isDark,
                      bg: bg,
                      borderColor: borderColor,
                      fg: fg,
                      muted: muted,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanForm(BuildContext context, AdminPlanEntity? editing) {
    final cubit = context.read<AdminPlansCubit>();
    final l10n = AppLocalizations.of(context);
    AppDialog.show(
      context: context,
      title: editing != null ? l10n.t('editPlan') : l10n.t('createPlan'),
      width: 520,
      barrierDismissible: false,
      child: BlocProvider.value(
        value: cubit,
        child: _PlanFormBody(editing: editing, l10n: l10n),
      ),
    );
  }
}

// ── Table ─────────────────────────────────────────────────────────────────────

class _PlansTable extends StatelessWidget {
  final AdminPlansLoaded state;
  final AppLocalizations l10n;
  final bool isDark;
  final Color bg;
  final Color borderColor;
  final Color fg;
  final Color muted;

  const _PlansTable({
    required this.state,
    required this.l10n,
    required this.isDark,
    required this.bg,
    required this.borderColor,
    required this.fg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _PlansHeader(
              l10n: l10n,
              isDark: isDark,
              borderColor: borderColor,
              muted: muted),
          Expanded(
            child: ListView.builder(
              itemCount: state.plans.length,
              itemBuilder: (ctx, i) => _PlanRow(
                plan: state.plans[i],
                isDark: isDark,
                borderColor: borderColor,
                fg: fg,
                muted: muted,
                l10n: l10n,
                isDeleting: state.deletingId == state.plans[i].id,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlansHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isDark;
  final Color borderColor;
  final Color muted;

  const _PlansHeader({
    required this.l10n,
    required this.isDark,
    required this.borderColor,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkMuted : AppColors.muted;
    Widget cell(String key, {int flex = 2, TextAlign align = TextAlign.start}) =>
        Expanded(
          flex: flex,
          child: Text(l10n.t(key),
              textAlign: align,
              style: AppTextStyles.tableHeader.copyWith(color: muted)),
        );
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          cell('planName', flex: 4),
          cell('amount', flex: 2, align: TextAlign.end),
          cell('maxProducts', flex: 2, align: TextAlign.end),
          cell('maxUsers', flex: 2, align: TextAlign.end),
          cell('maxBranches', flex: 2, align: TextAlign.end),
          cell('statusLabel', flex: 2),
          SizedBox(
            width: 90,
            child: Text(l10n.t('actions'),
                textAlign: TextAlign.center,
                style: AppTextStyles.tableHeader.copyWith(color: muted)),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final AdminPlanEntity plan;
  final bool isDark;
  final Color borderColor;
  final Color fg;
  final Color muted;
  final AppLocalizations l10n;
  final bool isDeleting;

  const _PlanRow({
    required this.plan,
    required this.isDark,
    required this.borderColor,
    required this.fg,
    required this.muted,
    required this.l10n,
    required this.isDeleting,
  });

  @override
  Widget build(BuildContext context) {
    Widget numCell(String value, {int flex = 2}) => Expanded(
          flex: flex,
          child: Text(value,
              textAlign: TextAlign.end,
              style: AppTextStyles.numeric.copyWith(color: fg)),
        );

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Name cell — name bold, slug monospace muted, description small muted
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(plan.name,
                    style: AppTextStyles.tableCell.copyWith(
                        color: fg, fontWeight: FontWeight.w500)),
                if (plan.slug.isNotEmpty)
                  Text(plan.slug,
                      style: AppTextStyles.labelXs.copyWith(
                          color: muted, fontFamily: 'monospace')),
                if (plan.description != null && plan.description!.isNotEmpty)
                  Text(plan.description!,
                      style: AppTextStyles.labelXs.copyWith(color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          numCell(AppFormatters.currency(plan.price)),
          numCell(plan.maxProducts?.toString() ?? '∞'),
          numCell(plan.maxUsers?.toString() ?? '∞'),
          numCell(plan.maxBranches?.toString() ?? '∞'),
          Expanded(
            flex: 2,
            child: StatusBadge(
              label: plan.isActive ? l10n.t('status_active') : l10n.t('inactive'),
              color: plan.isActive ? AppColors.statusPaid : AppColors.statusPending,
              bgColor: plan.isActive
                  ? AppColors.statusPaidBg
                  : AppColors.statusPendingBg,
            ),
          ),
          SizedBox(
            width: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_rounded, size: 16, color: muted),
                  tooltip: l10n.t('edit'),
                  onPressed: () => _showEdit(context),
                ),
                if (isDeleting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: AppColors.destructive),
                    tooltip: l10n.t('deletePlan'),
                    onPressed: () => _confirmDelete(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEdit(BuildContext context) {
    final cubit = context.read<AdminPlansCubit>();
    AppDialog.show(
      context: context,
      title: l10n.t('editPlan'),
      width: 520,
      barrierDismissible: false,
      child: BlocProvider.value(
        value: cubit,
        child: _PlanFormBody(editing: plan, l10n: l10n),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<AdminPlansCubit>();
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.t('deletePlan'),
      message: l10n.t('deleteConfirm'),
      confirmLabel: l10n.t('delete'),
      isDestructive: true,
      onConfirm: () {},
    );
    if (confirmed != true) return;
    final ok = await cubit.deletePlan(plan.id);
    if (!context.mounted) return;
    if (ok) {
      AppSnackbar.success(context, l10n.t('planDeleted'));
    } else {
      AppSnackbar.error(context, l10n.t('errorSaving'));
    }
  }
}

// ── Form ──────────────────────────────────────────────────────────────────────

class _PlanFormBody extends StatefulWidget {
  final AdminPlanEntity? editing;
  final AppLocalizations l10n;

  const _PlanFormBody({this.editing, required this.l10n});

  @override
  State<_PlanFormBody> createState() => _PlanFormBodyState();
}

class _PlanFormBodyState extends State<_PlanFormBody> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _maxProducts;
  late final TextEditingController _maxUsers;
  late final TextEditingController _maxBranches;
  late final TextEditingController _description;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _name = TextEditingController(text: e?.name ?? '');
    _price = TextEditingController(
        text: e != null ? e.price.toStringAsFixed(2) : '');
    _maxProducts =
        TextEditingController(text: e?.maxProducts?.toString() ?? '');
    _maxUsers = TextEditingController(text: e?.maxUsers?.toString() ?? '');
    _maxBranches =
        TextEditingController(text: e?.maxBranches?.toString() ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _maxProducts.dispose();
    _maxUsers.dispose();
    _maxBranches.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _price.text.trim().isEmpty) {
      AppSnackbar.error(context, widget.l10n.t('fieldRequired'));
      return;
    }
    setState(() => _isSaving = true);
    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'price': double.tryParse(_price.text) ?? 0,
      'is_active': _isActive,
      if (_description.text.trim().isNotEmpty)
        'description': _description.text.trim(),
      if (_maxProducts.text.trim().isNotEmpty)
        'max_products': int.tryParse(_maxProducts.text.trim()),
      if (_maxUsers.text.trim().isNotEmpty)
        'max_users': int.tryParse(_maxUsers.text.trim()),
      if (_maxBranches.text.trim().isNotEmpty)
        'max_branches': int.tryParse(_maxBranches.text.trim()),
    };
    final cubit = context.read<AdminPlansCubit>();
    bool ok;
    if (widget.editing != null) {
      ok = await cubit.updatePlan(widget.editing!.id, data);
    } else {
      ok = await cubit.createPlan(data);
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      AppSnackbar.success(
        context,
        widget.editing != null
            ? widget.l10n.t('planUpdated')
            : widget.l10n.t('planCreated'),
      );
      Navigator.of(context).pop();
    } else {
      AppSnackbar.error(context, widget.l10n.t('errorSaving'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: _name,
            label: l10n.t('planName'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _price,
            label: l10n.t('monthlyPrice'),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _maxProducts,
                  label: l10n.t('maxProducts'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _maxUsers,
                  label: l10n.t('maxUsers'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _maxBranches,
                  label: l10n.t('maxBranches'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _description,
            label: l10n.t('labelDescription'),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Checkbox(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v ?? true),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(l10n.t('isActive'),
                  style: AppTextStyles.labelSm.copyWith(color: muted)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: l10n.cancel,
                onPressed: () => Navigator.of(context).pop(),
                variant: AppButtonVariant.ghost,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: l10n.save,
                onPressed: _isSaving ? null : _save,
                isLoading: _isSaving,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
