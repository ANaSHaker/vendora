import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/buttons/app_icon_button.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_state.dart';
import '../../cubit/pos_cubit.dart';
import '../../cubit/pos_state.dart';
import '../desktop/widgets/pos_cart_item_row.dart';
import '../desktop/widgets/pos_discount_modal.dart';
import '../desktop/widgets/pos_order_totals.dart';
import '../desktop/widgets/pos_payment_modal.dart';
import '../desktop/widgets/pos_receipt_dialog.dart';

class MobilePosCartSheet extends StatelessWidget {
  const MobilePosCartSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<CartCubit>()),
          BlocProvider.value(value: context.read<PosCubit>()),
        ],
        child: const MobilePosCartSheet(),
      ),
    );
  }

  Future<void> _handleCheckout(
    BuildContext context,
    CartState cart,
    PosCubit posCubit,
  ) async {
    final result = await PosPaymentModal.show(context, total: cart.total);
    if (result == null || !context.mounted) return;
    await posCubit.submitOrder(
      cart: cart,
      paymentMethod: result.method,
      paymentAmount: result.amount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosCubit, PosState>(
      listenWhen: (p, c) =>
          p.lastOrder != c.lastOrder || p.submitFailure != c.submitFailure,
      listener: (context, state) {
        final l10n = AppLocalizations.of(context);
        if (state.lastOrder != null) {
          context.read<CartCubit>().clear();
          Navigator.of(context).pop();
          AppSnackbar.success(context, l10n.orderSuccess);
          if (state.autoPrint) {
            PosReceiptDialog.show(context, state.lastOrder!);
          }
        } else if (state.submitFailure != null) {
          AppSnackbar.error(context, l10n.orderFailed);
        }
      },
      child: BlocBuilder<CartCubit, CartState>(
        builder: (context, cart) {
          final cartCubit = context.read<CartCubit>();
          final posCubit = context.read<PosCubit>();

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (_, controller) => Column(
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: AppSpacing.sm),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Sheet header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Text(
                        cart.itemCount > 0
                            ? '${AppLocalizations.of(context).cart} (${cart.itemCount})'
                            : AppLocalizations.of(context).cart,
                        style: AppTextStyles.h6,
                      ),
                      const Spacer(),
                      BlocSelector<PosCubit, PosState, bool>(
                        selector: (s) => s.autoPrint,
                        builder: (context, autoPrint) {
                          final cs = Theme.of(context).colorScheme;
                          return Tooltip(
                            message: AppLocalizations.of(context).autoPrint,
                            child: InkWell(
                              onTap: () =>
                                  context.read<PosCubit>().toggleAutoPrint(),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  autoPrint
                                      ? Icons.print
                                      : Icons.print_outlined,
                                  size: 18,
                                  color: autoPrint
                                      ? cs.primary
                                      : AppColors.mutedForeground,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (cartCubit.canUndo)
                        AppIconButton(
                          icon: const Icon(Icons.undo),
                          onPressed: cartCubit.undo,
                          variant: AppButtonVariant.ghost,
                          size: AppButtonSize.sm,
                          tooltip: AppLocalizations.of(context).undo,
                        ),
                      AppIconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        variant: AppButtonVariant.ghost,
                        size: AppButtonSize.sm,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                // Items
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      return PosCartItemRow(
                        item: item,
                        onRemove: () => cartCubit.removeItem(item.productId),
                        onQuantityChanged: (q) =>
                            cartCubit.updateQuantity(item.productId, q),
                      );
                    },
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                // Totals + action
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md +
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    children: [
                      PosOrderTotals(
                        cart: cart,
                        onAddDiscount: () async {
                          final result = await PosDiscountModal.show(
                            context,
                            current: cart.discount,
                          );
                          if (result != null && context.mounted) {
                            cartCubit.setDiscount(result);
                          }
                        },
                        onClearDiscount: () => cartCubit.setDiscount(null),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      BlocBuilder<PosCubit, PosState>(
                        buildWhen: (p, c) => p.submitting != c.submitting,
                        builder: (context, posState) {
                          return AppButton.primary(
                            label:
                                '${AppLocalizations.of(context).charge} ${AppFormatters.currency(cart.total)}',
                            fullWidth: true,
                            size: AppButtonSize.lg,
                            isLoading: posState.submitting,
                            onPressed: posState.submitting
                                ? null
                                : () => _handleCheckout(
                                      context,
                                      cart,
                                      posCubit,
                                    ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
