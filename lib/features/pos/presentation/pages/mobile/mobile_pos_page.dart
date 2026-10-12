import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_state.dart';
import '../../cubit/pos_cubit.dart';
import '../../cubit/pos_state.dart';
import '../desktop/widgets/pos_category_tabs.dart';
import '../desktop/widgets/pos_setup_dialog.dart';
import 'mobile_pos_cart_sheet.dart';

class MobilePosPage extends StatelessWidget {
  const MobilePosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CartCubit()),
        BlocProvider(
          create: (_) => PosCubit(
            getBranches: getIt(),
            getWarehouses: getIt(),
            getProducts: getIt(),
            getCategories: getIt(),
            createOrder: getIt(),
            storage: getIt(),
          )..initialize(),
        ),
      ],
      child: const _MobilePosScaffold(),
    );
  }
}

class _MobilePosScaffold extends StatelessWidget {
  const _MobilePosScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(AppLocalizations.of(context).pointOfSale, style: AppTextStyles.h6),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: BlocBuilder<PosCubit, PosState>(
        buildWhen: (p, c) => p.isReady != c.isReady,
        builder: (context, state) {
          if (!state.isReady) return const PosSetupOverlay();
          return const _MobilePosBody();
        },
      ),
    );
  }
}

class _MobilePosBody extends StatelessWidget {
  const _MobilePosBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosCubit, PosState>(
      builder: (context, pos) {
        final posCubit = context.read<PosCubit>();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: AppSearchField(
                hint: AppLocalizations.of(context).searchProducts,
                onChanged: posCubit.search,
              ),
            ),
            if (pos.categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: PosCategoryTabs(
                  categories: pos.categories,
                  selectedCategoryId: pos.selectedCategoryId,
                  onSelect: posCubit.selectCategory,
                ),
              ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: pos.productsLoading
                  ? GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
                      ),
                      itemCount: 8,
                      itemBuilder: (_, __) => const ShimmerBox(height: 120),
                    )
                  : pos.filteredProducts.isEmpty
                      ? Builder(builder: (ctx) {
                          final l = AppLocalizations.of(ctx);
                          return AppEmptyState(
                            icon: const Icon(
                              Icons.inventory_2_outlined,
                              size: 40,
                            ),
                            message: pos.searchQuery.isNotEmpty
                                ? '${l.noProductsFound}: "${pos.searchQuery}"'
                                : l.noProductsAvailable,
                          );
                        })
                      : BlocBuilder<CartCubit, CartState>(
                          builder: (context, cart) {
                            final cartCubit = context.read<CartCubit>();
                            return GridView.builder(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: AppSpacing.sm,
                                mainAxisSpacing: AppSpacing.sm,
                              ),
                              itemCount: pos.filteredProducts.length,
                              itemBuilder: (_, i) {
                                final product = pos.filteredProducts[i];
                                final qty = cart.quantityOf(product.id);
                                return _MobileProductCard(
                                  name: product.name,
                                  price: product.price,
                                  quantity: qty,
                                  onTap: () => cartCubit.addItem(product),
                                );
                              },
                            );
                          },
                        ),
            ),
            // Cart FAB bar
            BlocBuilder<CartCubit, CartState>(
              builder: (context, cart) {
                if (cart.isEmpty) return const SizedBox.shrink();
                return _CartBar(cart: cart);
              },
            ),
          ],
        );
      },
    );
  }
}

class _MobileProductCard extends StatelessWidget {
  final String name;
  final double price;
  final double quantity;
  final VoidCallback onTap;

  const _MobileProductCard({
    required this.name,
    required this.price,
    required this.quantity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inCart = quantity > 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: inCart ? AppColors.primaryLight : AppColors.surface,
          border: Border.all(
            color: inCart ? AppColors.primary : AppColors.border,
            width: inCart ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: AppTextStyles.labelMd,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (inCart)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      quantity.toInt().toString(),
                      style: AppTextStyles.labelXs
                          .copyWith(color: AppColors.white),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              AppFormatters.currency(price),
              style: AppTextStyles.numericLg.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  final CartState cart;

  const _CartBar({required this.cart});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => MobilePosCartSheet.show(context),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.primary,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                CountBadge(count: cart.itemCount),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  AppLocalizations.of(context).cart,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  AppFormatters.currency(cart.total),
                  style: AppTextStyles.numeric.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
