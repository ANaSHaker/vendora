import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../domain/entities/product_entities.dart';
import '../../cubit/categories_cubit.dart';
import '../../cubit/categories_state.dart';
import '../desktop/widgets/category_form_dialog.dart';

class MobileCategoriesPage extends StatelessWidget {
  const MobileCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CategoriesCubit(
        getCategories: getIt(),
        createCategory: getIt(),
        updateCategory: getIt(),
        deleteCategory: getIt(),
        exportCategories: getIt(),
        importCategories: getIt(),
      )..load(),
      child: const _MobileCategoriesContent(),
    );
  }
}

class _MobileCategoriesContent extends StatelessWidget {
  const _MobileCategoriesContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        final cubit = context.read<CategoriesCubit>();
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: const Text('Categories', style: AppTextStyles.h6),
            elevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => CategoryFormDialog.show(
              context,
              allCategories: state is CategoriesLoaded ? state.categories : [],
              onSubmit: cubit.createCategory,
            ),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: AppColors.white),
          ),
          body: switch (state) {
            CategoriesInitial() ||
            CategoriesLoading() =>
              ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: 6,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ShimmerBox(height: 60),
                ),
              ),
            CategoriesError(:final message) => AppErrorWidget(
                message: message,
                onRetry: cubit.load,
              ),
            CategoriesLoaded(:final categories) when categories.isEmpty =>
              AppEmptyState(
                icon: const Icon(Icons.category_outlined, size: 40),
                message: 'No categories yet',
                action: AppButton.primary(
                  label: 'Add Category',
                  onPressed: () => CategoryFormDialog.show(
                    context,
                    allCategories: const [],
                    onSubmit: cubit.createCategory,
                  ),
                ),
              ),
            CategoriesLoaded(:final categories) => RefreshIndicator(
                onRefresh: () async => cubit.load(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl * 4,
                  ),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, i) => _CategoryCard(
                    category: categories[i],
                    cubit: cubit,
                  ),
                ),
              ),
          },
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryEntity category;
  final CategoriesCubit cubit;

  const _CategoryCard({required this.category, required this.cubit});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Category',
      message: 'Delete "${category.name}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
      onConfirm: () {},
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await cubit.deleteCategory(category.id);
    if (context.mounted) {
      if (ok) {
        AppSnackbar.success(context, 'Category deleted');
      } else {
        AppSnackbar.error(context, 'Failed to delete');
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: AppTextStyles.labelMd),
                  if (category.parentName != null)
                    Text(
                      'Parent: ${category.parentName}',
                      style: AppTextStyles.bodyXs
                          .copyWith(color: AppColors.mutedForeground),
                    ),
                  Text(
                    '${category.productCount} products',
                    style: AppTextStyles.bodyXs
                        .copyWith(color: AppColors.mutedForeground),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => CategoryFormDialog.show(
                context,
                editing: category,
                allCategories: const [],
                onSubmit: (data) => cubit.updateCategory(category.id, data),
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
      ),
    );
  }
}
