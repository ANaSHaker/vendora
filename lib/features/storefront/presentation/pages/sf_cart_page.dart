import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/storefront_cubit.dart';
import '../theme/sf_inherited_theme.dart';
import '../theme/sf_theme_data.dart';
import '../widgets/sf_button.dart';

class SfCartPage extends StatelessWidget {
  final String slug;
  const SfCartPage({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    final t      = StorefrontTheme.of(context);
    final l10n   = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return BlocBuilder<StorefrontCubit, StorefrontState>(
      builder: (ctx, state) {
        if (state is! StorefrontLoaded) return const SizedBox.shrink();
        final loaded = state;
        final cart   = loaded.cart;
        final cubit  = ctx.read<StorefrontCubit>();

        if (cart.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(64),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shopping_bag_outlined, size: 64, color: t.textSubtle),
              const SizedBox(height: 16),
              Text(l10n.sfCartEmpty,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: t.text)),
              const SizedBox(height: 8),
              Text(l10n.sfCartEmptyHint,
                style: TextStyle(fontSize: 14, color: t.textMuted)),
              const SizedBox(height: 24),
              SfButton(
                label: l10n.sfContinueShopping,
                onPressed: () => context.go('/store/$slug/products'),
              ),
            ]),
          );
        }

        final Widget cartList = Column(
          children: cart.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(t.radius),
              border: Border.all(color: t.border),
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(t.radius / 2),
                child: item.product.primaryImage != null
                    ? Image.network(item.product.primaryImage!,
                        width: 64, height: 64, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64, height: 64, color: t.surfaceHigh))
                    : Container(width: 64, height: 64, color: t.surfaceHigh,
                        child: Icon(Icons.image_outlined, color: t.textSubtle)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.product.name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.text),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${loaded.vendor.currency} ${item.product.price.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, color: t.primary, fontWeight: FontWeight.w600)),
                ]),
              ),
              Row(children: [
                _QtyBtn(icon: Icons.remove, t: t,
                    onTap: () => cubit.updateCartQty(item.product.id, item.quantity - 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${item.quantity}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text)),
                ),
                _QtyBtn(icon: Icons.add, t: t,
                    onTap: () => cubit.updateCartQty(item.product.id, item.quantity + 1)),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: t.textMuted),
                  onPressed: () => cubit.removeFromCart(item.product.id),
                ),
              ]),
            ]),
          )).toList(),
        );

        final Widget summary = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(t.radius),
            border: Border.all(color: t.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.sfOrderSummary,
              style: TextStyle(fontSize: 16, fontWeight: t.headingWeight, color: t.text)),
            const SizedBox(height: 16),
            _SummaryRow(label: l10n.sfSubtotal,
              value: '${loaded.vendor.currency} ${loaded.cartTotal.toStringAsFixed(2)}', t: t),
            const SizedBox(height: 8),
            Divider(color: t.border),
            const SizedBox(height: 8),
            _SummaryRow(
              label: l10n.sfTotal,
              value: '${loaded.vendor.currency} ${loaded.cartTotal.toStringAsFixed(2)}',
              t: t, isBold: true,
            ),
            const SizedBox(height: 20),
            SfButton(
              label: l10n.sfCheckout,
              onPressed: () => context.go('/store/$slug/checkout'),
            ),
          ]),
        );

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 48 : 16, vertical: 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.sfCart,
              style: TextStyle(fontSize: 28, fontWeight: t.headingWeight,
                  color: t.text, letterSpacing: t.headingLetterSpacing)),
            const SizedBox(height: 24),
            if (isWide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 6, child: cartList),
                const SizedBox(width: 24),
                SizedBox(width: 300, child: summary),
              ])
            else
              Column(children: [cartList, const SizedBox(height: 20), summary]),
          ]),
        );
      },
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon; final SfThemeData t; final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.t, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: t.text),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final SfThemeData t;
  final bool isBold;
  const _SummaryRow({required this.label, required this.value,
    required this.t, this.isBold = false});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: TextStyle(fontSize: 14, color: isBold ? t.text : t.textMuted,
        fontWeight: isBold ? FontWeight.w600 : FontWeight.w400)),
    const Spacer(),
    Text(value, style: TextStyle(fontSize: 14, color: t.text,
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
  ]);
}
