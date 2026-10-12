import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/entities/sf_entities.dart';
import '../theme/sf_inherited_theme.dart';
import '../theme/sf_theme_data.dart';

class SfProductCard extends StatelessWidget {
  final SfProduct    product;
  final String       currency;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const SfProductCard({
    super.key,
    required this.product,
    required this.currency,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final t      = StorefrontTheme.of(context);
    final radius = BorderRadius.circular(t.radius);

    Widget inner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(t.radius)),
            child: Stack(fit: StackFit.expand, children: [
              product.primaryImage != null
                  ? Image.network(
                      product.primaryImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(t),
                    )
                  : _placeholder(t),
              if (product.hasDiscount)
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(t.buttonRadius.clamp(0, 6)),
                    ),
                    child: Text(
                      '-${product.discountPercent.round()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        // Info
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: t.text, height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Text(
                  '$currency ${product.price.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: t.primary),
                ),
                if (product.hasDiscount) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$currency ${product.oldPrice!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11, decoration: TextDecoration.lineThrough,
                      color: t.textMuted,
                    ),
                  ),
                ],
              ]),
              if (onAddToCart != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: _AddBtn(onTap: onAddToCart!, theme: t),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final card = switch (t.cardStyle) {
      SfCardStyle.elevated => _elevated(inner, t, radius),
      SfCardStyle.outlined => _outlined(inner, t, radius),
      SfCardStyle.glass    => _glass(inner, t, radius),
      SfCardStyle.flat     => _flat(inner, t, radius),
    };

    return GestureDetector(onTap: onTap, child: card);
  }

  Widget _placeholder(SfThemeData t) => Container(
    color: t.surfaceHigh,
    child: Icon(Icons.image_outlined, size: 40, color: t.textSubtle),
  );

  Widget _elevated(Widget child, SfThemeData t, BorderRadius r) => Container(
    decoration: BoxDecoration(
      color: t.surface, borderRadius: r,
      boxShadow: [BoxShadow(
        color: Colors.black.withAlpha(18),
        blurRadius: 16, offset: const Offset(0, 4),
      )],
    ),
    child: child,
  );

  Widget _outlined(Widget child, SfThemeData t, BorderRadius r) => Container(
    decoration: BoxDecoration(
      borderRadius: r,
      border: Border.all(color: t.border, width: 1.5),
    ),
    child: child,
  );

  Widget _flat(Widget child, SfThemeData t, BorderRadius r) => Container(
    decoration: BoxDecoration(color: t.surface, borderRadius: r),
    child: child,
  );

  Widget _glass(Widget child, SfThemeData t, BorderRadius r) => ClipRRect(
    borderRadius: r,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          color: t.surface.withAlpha(60),
          borderRadius: r,
          border: Border.all(color: t.border.withAlpha(80)),
        ),
        child: child,
      ),
    ),
  );
}

class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  final SfThemeData theme;
  const _AddBtn({required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(theme.buttonRadius.clamp(0, 20));
    return Material(
      color: theme.primary,
      borderRadius: r,
      child: InkWell(
        onTap: onTap,
        borderRadius: r,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Icon(Icons.add_shopping_cart_rounded,
              size: 16, color: theme.primaryFg),
        ),
      ),
    );
  }
}
