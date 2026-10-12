import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../cubit/cart_cubit.dart';
import '../../../cubit/cart_state.dart';
import '../../../cubit/pos_cubit.dart';
import '../../../cubit/pos_state.dart';
import '../../../../services/pos_sound_service.dart';
import 'pos_category_tabs.dart';
import 'pos_product_card.dart';
import 'pos_shortcuts_bar.dart';

class PosLeftPanel extends StatelessWidget {
  final FocusNode? searchFocusNode;
  const PosLeftPanel({super.key, this.searchFocusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosCubit, PosState>(
      builder: (context, pos) {
        final posCubit = context.read<PosCubit>();
        return ColoredBox(
          color: AppColors.background,
          child: Column(
            children: [
              // Search + categories bar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: AppSearchField(
                  hint: AppLocalizations.of(context).searchByNameOrSku,
                  onChanged: posCubit.search,
                  focusNode: searchFocusNode,
                ),
              ),
              if (pos.categories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: PosCategoryTabs(
                    categories: pos.categories,
                    selectedCategoryId: pos.selectedCategoryId,
                    onSelect: posCubit.selectCategory,
                  ),
                ),
              const Divider(height: 1, color: AppColors.border),
              // Product grid
              Expanded(
                child: pos.productsLoading
                    ? const _ProductGridShimmer()
                    : pos.filteredProducts.isEmpty
                        ? Builder(
                            builder: (ctx) {
                              final l10n = AppLocalizations.of(ctx);
                              return AppEmptyState(
                                icon: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 40,
                                ),
                                message: pos.searchQuery.isNotEmpty
                                    ? '${l10n.noProductsFound}: "${pos.searchQuery}"'
                                    : l10n.noProductsAvailable,
                              );
                            },
                          )
                        : BlocBuilder<CartCubit, CartState>(
                            builder: (context, cart) {
                              final cartCubit = context.read<CartCubit>();
                              final outOfStockLabel =
                                  AppLocalizations.of(context).outOfStock;
                              return GridView.builder(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: AppSpacing.xs,
                                  mainAxisSpacing: AppSpacing.xs,
                                  childAspectRatio: 1.25,
                                ),
                                itemCount: pos.filteredProducts.length,
                                itemBuilder: (_, i) {
                                  final product = pos.filteredProducts[i];
                                  return PosProductCard(
                                    product: product,
                                    quantity: cart.quantityOf(product.id),
                                    outOfStockLabel: outOfStockLabel,
                                    onTap: () {
                                      cartCubit.addItem(product);
                                      PosSoundService.addItem();
                                    },
                                  );
                                },
                              );
                            },
                          ),
              ),
              const PosShortcutsBar(),
            ],
          ),
        );
      },
    );
  }
}

class _ProductGridShimmer extends StatelessWidget {
  const _ProductGridShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: AppSpacing.xs,
        mainAxisSpacing: AppSpacing.xs,
        childAspectRatio: 1.25,
      ),
      itemCount: 20,
      itemBuilder: (_, __) => LayoutBuilder(
        builder: (_, constraints) =>
            ShimmerBox(height: constraints.maxHeight),
      ),
    );
  }
}
