import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/di/injection.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../core/utils/formatters.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../../design_system/widgets/buttons/app_icon_button.dart';
import '../../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../domain/entities/pos_entities.dart';
import '../../../../domain/usecases/pos_usecases.dart';
import '../../../cubit/cart_cubit.dart';
import '../../../cubit/cart_state.dart';
import '../../../cubit/pos_cubit.dart';
import '../../../cubit/pos_state.dart';
import 'pos_cart_item_row.dart';
import 'pos_discount_modal.dart';
import 'pos_order_totals.dart';
import 'pos_payment_modal.dart';
import 'pos_receipt_dialog.dart';

class PosRightPanel extends StatelessWidget {
  const PosRightPanel({super.key});

  Future<void> handleCheckout(BuildContext context, CartState cart, PosCubit posCubit) async {
    if (cart.isEmpty) return;
    final result = await PosPaymentModal.show(context, total: cart.total);
    if (result == null || !context.mounted) return;
    await posCubit.submitOrder(
      cart: cart,
      paymentMethod: result.method,
      paymentAmount: result.amount,
    );
  }

  Future<void> _handleAddDiscount(
    BuildContext context,
    CartCubit cartCubit,
    CartState cart,
  ) async {
    final result = await PosDiscountModal.show(context, current: cart.discount);
    if (!context.mounted) return;
    if (result != null) cartCubit.setDiscount(result);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosCubit, PosState>(
      listenWhen: (p, c) =>
          p.lastOrder != c.lastOrder || p.submitFailure != c.submitFailure,
      listener: (context, state) {
        if (state.lastOrder != null) {
          context.read<CartCubit>().clear();
          if (state.autoPrint) {
            PosReceiptDialog.show(context, state.lastOrder!);
          }
        } else if (state.submitFailure != null) {
          AppSnackbar.error(context, AppLocalizations.of(context).orderFailed);
        }
      },
      child: BlocBuilder<PosCubit, PosState>(
        buildWhen: (p, c) =>
            p.lastOrder != c.lastOrder || p.submitting != c.submitting,
        builder: (context, posState) {
          // Show success screen when order is done
          if (posState.lastOrder != null) {
            return _PosSuccessScreen(
              order: posState.lastOrder!,
              onNewOrder: () => context.read<PosCubit>().clearLastOrder(),
            );
          }

          return BlocBuilder<CartCubit, CartState>(
            builder: (context, cart) {
              final cartCubit = context.read<CartCubit>();
              final posCubit = context.read<PosCubit>();

              return ColoredBox(
                color: AppColors.surface,
                child: Column(
                  children: [
                    _PanelHeader(
                      itemCount: cart.itemCount,
                      canUndo: cartCubit.canUndo,
                      onUndo: cartCubit.undo,
                      onClear: cart.isEmpty ? null : cartCubit.clear,
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _CustomerSelector(
                        cart: cart,
                        cartCubit: cartCubit,
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    // Order note
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: _OrderNoteField(
                        note: cart.note,
                        onChanged: cartCubit.setNote,
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    Expanded(
                      child: cart.isEmpty
                          ? Builder(
                              builder: (ctx) {
                                final l = AppLocalizations.of(ctx);
                                return AppEmptyState(
                                  icon: const Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 40),
                                  message: l.emptyCart,
                                  subtitle: l.addItems,
                                );
                              },
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              itemCount: cart.items.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: AppColors.border),
                              itemBuilder: (_, i) {
                                final item = cart.items[i];
                                return PosCartItemRow(
                                  item: item,
                                  onRemove: () =>
                                      cartCubit.removeItem(item.productId),
                                  onQuantityChanged: (q) => cartCubit
                                      .updateQuantity(item.productId, q),
                                );
                              },
                            ),
                    ),
                    if (cart.isNotEmpty) ...[
                      const Divider(height: 1, color: AppColors.border),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            PosOrderTotals(
                              cart: cart,
                              onAddDiscount: () =>
                                  _handleAddDiscount(context, cartCubit, cart),
                              onClearDiscount: () =>
                                  cartCubit.setDiscount(null),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            BlocBuilder<PosCubit, PosState>(
                              buildWhen: (p, c) =>
                                  p.submitting != c.submitting,
                              builder: (context, ps) {
                                return AppButton.primary(
                                  label:
                                      '${AppLocalizations.of(context).charge} ${AppFormatters.currency(cart.total)}',
                                  fullWidth: true,
                                  size: AppButtonSize.lg,
                                  isLoading: ps.submitting,
                                  onPressed: ps.submitting
                                      ? null
                                      : () => handleCheckout(
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
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Success Screen ──────────────────────────────────────────────────────────

class _PosSuccessScreen extends StatelessWidget {
  final PosOrderEntity order;
  final VoidCallback onNewOrder;

  const _PosSuccessScreen({
    required this.order,
    required this.onNewOrder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final cashPayment = order.payments.firstWhere(
      (p) => p.method == 'cash',
      orElse: () => const PosPaymentResultEntity(method: '', amount: 0),
    );
    final showChange = order.change > 0 && cashPayment.method == 'cash';

    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Checkmark circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 36,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.orderComplete,
                style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                order.reference,
                style: AppTextStyles.labelSm.copyWith(
                  color: cs.primary,
                  fontFamily: AppTextStyles.numeric.fontFamily,
                ),
              ),
              if (showChange) ...[
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: AppRadius.brLg,
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.cashChange,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppFormatters.currency(order.change),
                        style: AppTextStyles.numericXl.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      label: l10n.printReceipt,
                      leading: const Icon(Icons.print_outlined, size: 16),
                      onPressed: () => PosReceiptDialog.show(context, order),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton.primary(
                      label: l10n.newOrder,
                      leading: const Icon(Icons.add_rounded, size: 16),
                      onPressed: onNewOrder,
                    ),
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

// ─── Panel Header ────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  final int itemCount;
  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback? onClear;

  const _PanelHeader({
    required this.itemCount,
    required this.canUndo,
    required this.onUndo,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            itemCount > 0 ? '${l10n.cart} ($itemCount)' : l10n.cart,
            style: AppTextStyles.h6,
          ),
          const Spacer(),
          BlocSelector<PosCubit, PosState, bool>(
            selector: (s) => s.autoPrint,
            builder: (context, autoPrint) => Tooltip(
              message: l10n.autoPrint,
              child: GestureDetector(
                onTap: () => context.read<PosCubit>().toggleAutoPrint(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: autoPrint
                          ? cs.primary.withValues(alpha: 0.12)
                          : AppColors.transparent,
                      borderRadius: AppRadius.brMd,
                      border: Border.all(
                        color: autoPrint
                            ? cs.primary.withValues(alpha: 0.4)
                            : cs.outline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          autoPrint
                              ? Icons.print_rounded
                              : Icons.print_outlined,
                          size: 14,
                          color: autoPrint
                              ? cs.primary
                              : AppColors.mutedForeground,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.autoPrint,
                          style: AppTextStyles.labelXs.copyWith(
                            color: autoPrint
                                ? cs.primary
                                : AppColors.mutedForeground,
                            fontWeight: autoPrint
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (canUndo)
            AppIconButton(
              icon: const Icon(Icons.undo_rounded),
              onPressed: onUndo,
              size: AppButtonSize.sm,
              tooltip: l10n.undo,
            ),
          if (onClear != null) ...[
            const SizedBox(width: AppSpacing.xs),
            AppIconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: onClear,
              variant: AppButtonVariant.destructive,
              size: AppButtonSize.sm,
              tooltip: l10n.clearCart,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Order Note Field ────────────────────────────────────────────────────────

class _OrderNoteField extends StatefulWidget {
  final String note;
  final ValueChanged<String> onChanged;

  const _OrderNoteField({required this.note, required this.onChanged});

  @override
  State<_OrderNoteField> createState() => _OrderNoteFieldState();
}

class _OrderNoteFieldState extends State<_OrderNoteField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.note);
  }

  @override
  void didUpdateWidget(_OrderNoteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller when cart is cleared
    if (widget.note.isEmpty && _ctrl.text.isNotEmpty) {
      _ctrl.clear();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: _ctrl,
      maxLines: 2,
      minLines: 1,
      onChanged: widget.onChanged,
      style: AppTextStyles.bodyXs.copyWith(
        color: isDark ? AppColors.darkForeground : AppColors.foreground,
      ),
      decoration: InputDecoration(
        hintText: l10n.orderNoteHint,
        hintStyle: AppTextStyles.bodyXs.copyWith(
          color: AppColors.mutedForeground,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Icon(
            Icons.notes_rounded,
            size: 16,
            color: AppColors.mutedForeground,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
        filled: true,
        fillColor: isDark ? AppColors.darkMuted : AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        isDense: true,
      ),
    );
  }
}

// ─── Customer Selector ───────────────────────────────────────────────────────

class _CustomerSelector extends StatefulWidget {
  final CartState cart;
  final CartCubit cartCubit;

  const _CustomerSelector({required this.cart, required this.cartCubit});

  @override
  State<_CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends State<_CustomerSelector> {
  final _searchUseCase = getIt<SearchPosCustomersUseCase>();
  final _createUseCase = getIt<CreatePosCustomerUseCase>();
  final TextEditingController _ctrl = TextEditingController();
  Timer? _debounce;

  bool _showSearch = false;
  bool _loading = false;
  bool _creating = false;
  List<PosCustomerEntity> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final result = await _searchUseCase(query.trim());
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _loading = false;
        _results = [];
      }),
      (customers) => setState(() {
        _loading = false;
        _results = customers;
      }),
    );
  }

  void _selectCustomer(PosCustomerEntity customer) {
    widget.cartCubit.setCustomer(customer);
    _closeSearch();
  }

  Future<void> _createNewCustomer() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _creating = true);
    final result = await _createUseCase(name: name);
    if (!mounted) return;
    setState(() => _creating = false);
    result.fold(
      (_) {},
      (customer) {
        widget.cartCubit.setCustomer(customer);
        _closeSearch();
      },
    );
  }

  void _closeSearch() {
    _debounce?.cancel();
    setState(() {
      _showSearch = false;
      _loading = false;
      _creating = false;
      _results = [];
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Customer selected ──────────────────────────────────────────────────
    if (widget.cart.customer != null) {
      return _SelectedCustomerRow(
        customer: widget.cart.customer!,
        onRemove: () => widget.cartCubit.setCustomer(null),
      );
    }

    // ── Search open ────────────────────────────────────────────────────────
    if (_showSearch) {
      final query = _ctrl.text.trim();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSearchField(
            controller: _ctrl,
            hint: l10n.searchCustomer,
            onChanged: _onSearchChanged,
            onClear: _closeSearch,
          ),
          if (_loading)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: cs.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          // Results dropdown
          if (_results.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _results.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (_, i) {
                  final c = _results[i];
                  return InkWell(
                    onTap: () => _selectCustomer(c),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor:
                                cs.primary.withValues(alpha: 0.1),
                            child: Text(
                              c.name.isNotEmpty
                                  ? c.name[0].toUpperCase()
                                  : '?',
                              style: AppTextStyles.labelXs
                                  .copyWith(color: cs.primary),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: AppTextStyles.labelSm),
                                if (c.phone != null)
                                  Text(c.phone!,
                                      style: AppTextStyles.bodyXs.copyWith(
                                          color: AppColors.mutedForeground)),
                              ],
                            ),
                          ),
                          Icon(Icons.keyboard_return_rounded,
                              size: 14, color: cs.primary),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          // Create customer button — shows whenever there's text typed
          if (query.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _CreateCustomerButton(
              name: query,
              isLoading: _creating,
              onTap: _creating ? null : _createNewCustomer,
            ),
          ],
        ],
      );
    }

    // ── Default: always-visible customer button ────────────────────────────
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        _showSearch = true;
      }),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.person_search_outlined,
                  size: 15,
                  color: cs.primary.withValues(alpha: 0.7)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.addCustomer,
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.mutedForeground),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 15, color: AppColors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Selected customer row ────────────────────────────────────────────────────

class _SelectedCustomerRow extends StatelessWidget {
  final PosCustomerEntity customer;
  final VoidCallback onRemove;

  const _SelectedCustomerRow(
      {required this.customer, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: cs.primary.withValues(alpha: 0.15),
            child: Text(
              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
              style: AppTextStyles.labelSm.copyWith(color: cs.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name,
                    style: AppTextStyles.labelSm,
                    overflow: TextOverflow.ellipsis),
                if (customer.phone != null)
                  Text(customer.phone!,
                      style: AppTextStyles.bodyXs
                          .copyWith(color: AppColors.mutedForeground)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Icon(Icons.close_rounded,
                  size: 15, color: AppColors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Create customer button ───────────────────────────────────────────────────

class _CreateCustomerButton extends StatelessWidget {
  final String name;
  final bool isLoading;
  final VoidCallback? onTap;

  const _CreateCustomerButton({
    required this.name,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: isLoading ? 0.04 : 0.08),
            border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                )
              else
                Icon(Icons.person_add_outlined, size: 14, color: cs.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${l10n.createCustomer}: "$name"',
                  style: AppTextStyles.labelSm.copyWith(color: cs.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
