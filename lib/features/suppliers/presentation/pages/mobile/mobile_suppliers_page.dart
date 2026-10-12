import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/formatters.dart';
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
import '../../../domain/entities/supplier_entities.dart';
import '../../../domain/usecases/suppliers_usecases.dart';
import '../../cubit/suppliers_cubit.dart';
import '../../cubit/suppliers_state.dart';
import '../desktop/supplier_payment_dialog.dart';
import 'mobile_supplier_form_sheet.dart';

class MobileSuppliersPage extends StatelessWidget {
  const MobileSuppliersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SuppliersCubit(
        getSuppliers: getIt<GetSuppliersUseCase>(),
        createSupplier: getIt<CreateSupplierUseCase>(),
        updateSupplier: getIt<UpdateSupplierUseCase>(),
        deleteSupplier: getIt<DeleteSupplierUseCase>(),
      )..load(),
      child: const _MobileSuppliersContent(),
    );
  }
}

class _MobileSuppliersContent extends StatelessWidget {
  const _MobileSuppliersContent();

  Future<void> _showForm(BuildContext context, SuppliersCubit cubit,
      AppLocalizations l10n,
      {SupplierEntity? editing}) async {
    await showMobileSupplierForm(context, cubit, l10n, editing: editing);
  }

  Future<void> _confirmDelete(BuildContext context, SupplierEntity supplier,
      SuppliersCubit cubit, AppLocalizations l10n) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.t('delete_supplier_title'),
      message:
          l10n.t('delete_supplier_msg').replaceAll('{name}', supplier.name),
      confirmLabel: l10n.delete,
      isDestructive: true,
      onConfirm: () {},
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await cubit.deleteSupplier(supplier.id);
    if (context.mounted) {
      if (ok) {
        AppSnackbar.success(context, l10n.t('supplier_deleted'));
      } else {
        AppSnackbar.error(context, l10n.t('supplier_delete_failed'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      builder: (context, state) {
        final cubit = context.read<SuppliersCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.background,
          appBar: AppBar(
            backgroundColor:
                isDark ? AppColors.darkSurface : AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(
              l10n.t('suppliers'),
              style: AppTextStyles.h6.copyWith(
                  color: isDark
                      ? AppColors.darkForeground
                      : AppColors.foreground),
            ),
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                  height: 1,
                  color:
                      isDark ? AppColors.darkBorder : AppColors.border),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showForm(context, cubit, l10n),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppSearchField(
                  hint: l10n.t('search_suppliers'),
                  onChanged: cubit.search,
                ),
              ),
              Expanded(
                child: switch (state) {
                  SuppliersInitial() ||
                  SuppliersLoading() =>
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      itemCount: 8,
                      itemBuilder: (_, __) => const Padding(
                        padding:
                            EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ShimmerBox(height: 96),
                      ),
                    ),
                  SuppliersError(:final message) => AppErrorWidget(
                      message: message,
                      onRetry: cubit.refresh,
                    ),
                  SuppliersLoaded(:final suppliers)
                      when suppliers.isEmpty =>
                    AppEmptyState(
                      icon:
                          const Icon(Icons.store_outlined, size: 40),
                      message: l10n.t('no_suppliers'),
                      action: AppButton.primary(
                        label: l10n.t('new_supplier'),
                        onPressed: () =>
                            _showForm(context, cubit, l10n),
                      ),
                    ),
                  SuppliersLoaded(:final suppliers) =>
                    RefreshIndicator(
                      onRefresh: () async => cubit.refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        itemCount: suppliers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final s = suppliers[i];
                          return _SupplierCard(
                            supplier: s,
                            isDark: isDark,
                            l10n: l10n,
                            onEdit: () =>
                                _showForm(context, cubit, l10n,
                                    editing: s),
                            onDelete: () => _confirmDelete(
                                context, s, cubit, l10n),
                            onPayment: () => showSupplierPaymentDialog(
                              context,
                              supplier: s,
                              l10n: l10n,
                            ),
                          );
                        },
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

// ── Supplier Card ──────────────────────────────────────────────────────────────

class _SupplierCard extends StatelessWidget {
  final SupplierEntity supplier;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPayment;

  const _SupplierCard({
    required this.supplier,
    required this.isDark,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
    required this.onPayment,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    supplier.name,
                    style: AppTextStyles.labelMd.copyWith(color: fg),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                supplier.isActive
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
              ],
            ),
            if (supplier.phone != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 12, color: muted),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    supplier.phone!,
                    style: AppTextStyles.bodySm.copyWith(color: muted),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('opening_balance_label'),
                        style:
                            AppTextStyles.bodyXs.copyWith(color: muted),
                      ),
                      Text(
                        AppFormatters.currency(supplier.openingBalance),
                        style:
                            AppTextStyles.numeric.copyWith(color: fg),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.payments_outlined,
                      size: 18, color: AppColors.primary),
                  onPressed: onPayment,
                  tooltip: l10n.supplierRecordPayment,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18, color: muted),
                  onPressed: onEdit,
                  tooltip: l10n.edit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18,
                      color: AppColors.destructive),
                  onPressed: onDelete,
                  tooltip: l10n.delete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
