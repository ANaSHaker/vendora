import 'package:flutter/material.dart';
import '../../../../../../core/utils/formatters.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../domain/entities/pos_entities.dart';

class PosProductCard extends StatelessWidget {
  final PosProductEntity product;
  final double quantity;
  final String outOfStockLabel;
  final VoidCallback onTap;

  const PosProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.outOfStockLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inCart = quantity > 0;
    final oos = product.isOutOfStock;

    final cardColor = oos
        ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
        : inCart
            ? cs.primary.withValues(alpha: 0.07)
            : cs.surface;

    final borderColor = oos
        ? cs.outlineVariant.withValues(alpha: 0.4)
        : inCart
            ? cs.primary
            : cs.outlineVariant;

    final accentColor = oos
        ? cs.outlineVariant.withValues(alpha: 0.35)
        : inCart
            ? cs.primary
            : cs.primary.withValues(alpha: 0.2);

    return MouseRegion(
      cursor: oos ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: oos ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: cardColor,
            border: Border.all(
              color: borderColor,
              width: inCart && !oos ? 1.5 : 1.0,
            ),
            borderRadius: AppRadius.brMd,
            boxShadow: inCart && !oos
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Accent top bar ──
                  Container(height: 3, color: accentColor),

                  // ── Content ──
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(7, 6, 7, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Product name — 2 lines max, bold, full width
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: oos
                                  ? cs.onSurface.withValues(alpha: 0.35)
                                  : cs.onSurface,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // ── Bottom: price + OOS indicator ──
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (oos)
                                // OOS pill — BELOW name, never overlaps
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.destructive
                                        .withValues(alpha: 0.1),
                                    borderRadius: AppRadius.brXs,
                                    border: Border.all(
                                      color: AppColors.destructive
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Text(
                                    outOfStockLabel,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.destructive
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    // Price
                                    Expanded(
                                      child: Text(
                                        AppFormatters.currency(product.price),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: cs.primary,
                                          height: 1.1,
                                          fontFamily:
                                              AppTextStyles.numeric.fontFamily,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Stock count (if tracked + low)
                                    if (product.trackStock &&
                                        product.availableQty != null &&
                                        product.availableQty! <= 5)
                                      _LowStockDot(qty: product.availableQty!),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Cart qty badge — top-right, only when in cart ──
              if (inCart && !oos)
                Positioned(
                  top: 7,
                  right: 5,
                  child: _QtyBadge(quantity: quantity, color: cs.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cart quantity badge ─────────────────────────────────────────────────────

class _QtyBadge extends StatelessWidget {
  final double quantity;
  final Color color;

  const _QtyBadge({required this.quantity, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(1);

    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.brFull,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── Low stock dot (≤5 units) ────────────────────────────────────────────────

class _LowStockDot extends StatelessWidget {
  final double qty;
  const _LowStockDot({required this.qty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: AppRadius.brXs,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.warning.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
