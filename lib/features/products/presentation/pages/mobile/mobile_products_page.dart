import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
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
import '../../../domain/entities/product_entities.dart';
import '../../cubit/products_cubit.dart';
import '../../cubit/products_state.dart';
import '../desktop/widgets/product_form_dialog.dart';

class MobileProductsPage extends StatelessWidget {
  const MobileProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductsCubit(
        getProducts: getIt(),
        getCategories: getIt(),
        deleteProduct: getIt(),
        updateProduct: getIt(),
        exportProducts: getIt(),
        importProducts: getIt(),
      )..load(),
      child: const _MobileProductsContent(),
    );
  }
}

class _MobileProductsContent extends StatelessWidget {
  const _MobileProductsContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        final cubit = context.read<ProductsCubit>();
        final categories =
            state is ProductsLoaded ? state.categories : <CategoryEntity>[];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: const Text('Products', style: AppTextStyles.h6),
            elevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => ProductFormDialog.show(
              context,
              categories: categories,
              onSaved: cubit.onProductSaved,
            ),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: AppColors.white),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppSearchField(
                  hint: 'Search products...',
                  onChanged: cubit.search,
                ),
              ),
              Expanded(
                child: switch (state) {
                  ProductsInitial() ||
                  ProductsLoading() =>
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      itemCount: 8,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ShimmerBox(height: 72),
                      ),
                    ),
                  ProductsError(:final message, :final filters) =>
                    AppErrorWidget(
                      message: message,
                      onRetry: () => cubit.load(filters: filters),
                    ),
                  ProductsLoaded(:final products) when products.isEmpty =>
                    AppEmptyState(
                      icon: const Icon(Icons.inventory_2_outlined, size: 40),
                      message: 'No products found',
                      action: AppButton.primary(
                        label: 'Add Product',
                        onPressed: () => ProductFormDialog.show(
                          context,
                          categories: categories,
                          onSaved: cubit.onProductSaved,
                        ),
                      ),
                    ),
                  ProductsLoaded(:final products) => RefreshIndicator(
                      onRefresh: () async => cubit.refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.xl * 4,
                        ),
                        itemCount: products.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, i) {
                          return _MobileProductCard(
                            product: products[i],
                            categories: categories,
                            cubit: cubit,
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

class _MobileProductCard extends StatelessWidget {
  final ProductEntity product;
  final List<CategoryEntity> categories;
  final ProductsCubit cubit;

  const _MobileProductCard({
    required this.product,
    required this.categories,
    required this.cubit,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Product',
      message: 'Delete "${product.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
      onConfirm: () {},
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await cubit.deleteProduct(product.id);
    if (context.mounted) {
      if (ok) {
        AppSnackbar.success(context, 'Product deleted');
      } else {
        AppSnackbar.error(context, 'Failed to delete product');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
                  Text(product.name, style: AppTextStyles.labelMd),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (product.sku != null) ...[
                        Text(
                          product.sku!,
                          style: AppTextStyles.bodyXs
                              .copyWith(color: AppColors.mutedForeground),
                        ),
                        const Text(' · ',
                            style: TextStyle(color: AppColors.mutedForeground)),
                      ],
                      if (product.categoryName != null)
                        Text(
                          product.categoryName!,
                          style: AppTextStyles.bodyXs
                              .copyWith(color: AppColors.mutedForeground),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        AppFormatters.currency(product.price),
                        style: AppTextStyles.numeric.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      product.isActive
                          ? StatusBadge.custom(
                              label: 'Active',
                              color: AppColors.successForeground,
                              bgColor: AppColors.successLight,
                            )
                          : StatusBadge.custom(
                              label: 'Inactive',
                              color: AppColors.mutedForeground,
                              bgColor: AppColors.muted,
                            ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => ProductFormDialog.show(
                    context,
                    editing: product,
                    categories: categories,
                    onSaved: cubit.onProductSaved,
                  ),
                  color: AppColors.mutedForeground,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _confirmDelete(context),
                  color: AppColors.destructive,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
