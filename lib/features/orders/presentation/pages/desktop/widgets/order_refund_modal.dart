import 'package:flutter/material.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../../core/utils/formatters.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../domain/entities/order_entity.dart';
import '../../../cubit/orders_cubit.dart';

class OrderRefundModal extends StatefulWidget {
  final OrderEntity order;
  final OrdersCubit cubit;

  const OrderRefundModal({
    super.key,
    required this.order,
    required this.cubit,
  });

  static Future<bool> show(
    BuildContext context, {
    required OrderEntity order,
    required OrdersCubit cubit,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrderRefundModal(order: order, cubit: cubit),
    );
    return result ?? false;
  }

  @override
  State<OrderRefundModal> createState() => _OrderRefundModalState();
}

class _RefundLine {
  final OrderItemEntity item;
  bool selected;
  int qty;

  _RefundLine({required this.item, this.selected = true, required this.qty});
}

class _OrderRefundModalState extends State<OrderRefundModal> {
  late final List<_RefundLine> _lines;
  String _paymentMethod = 'cash';
  final _reasonController = TextEditingController();
  bool _submitting = false;
  bool _reasonError = false;
  bool _itemsError = false;

  @override
  void initState() {
    super.initState();
    _lines = widget.order.items
        .map((item) => _RefundLine(item: item, selected: true, qty: item.quantity))
        .toList();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  double get _refundTotal => _lines
      .where((l) => l.selected)
      .fold(0.0, (sum, l) => sum + l.item.unitPrice * l.qty);

  List<_RefundLine> get _selectedLines => _lines.where((l) => l.selected).toList();

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    final hasItems = _selectedLines.isNotEmpty;
    final hasReason = reason.isNotEmpty;

    if (!hasItems || !hasReason) {
      setState(() {
        _itemsError = !hasItems;
        _reasonError = !hasReason;
      });
      return;
    }

    setState(() => _submitting = true);
    final ok = await widget.cubit.refundOrder(
      widget.order.id,
      reason: reason,
      paymentMethod: _paymentMethod,
      items: _selectedLines
          .map((l) => {'order_item_id': l.item.id, 'quantity': l.qty})
          .toList(),
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _submitting = false);
      AppSnackbar.error(context, AppLocalizations.of(context).error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final mutedBg = isDark ? AppColors.darkMuted : AppColors.muted;

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.confirmRefund,
                          style: AppTextStyles.h6.copyWith(color: fg),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.order.reference,
                          style: AppTextStyles.bodyXs.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: muted),
                    onPressed:
                        _submitting ? null : () => Navigator.of(context).pop(false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),

            // ── Scrollable body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Items section
                    Text(
                      l10n.refundItems,
                      style: AppTextStyles.labelSm.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_itemsError) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.noItemsSelected,
                        style: AppTextStyles.bodyXs
                            .copyWith(color: AppColors.destructive),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: mutedBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _itemsError ? AppColors.destructive : border,
                        ),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < _lines.length; i++) ...[
                            if (i > 0) Divider(height: 1, color: border),
                            _ItemRow(
                              line: _lines[i],
                              isDark: isDark,
                              fg: fg,
                              muted: muted,
                              onToggle: (v) => setState(() {
                                _lines[i].selected = v;
                                if (_itemsError && _selectedLines.isNotEmpty) {
                                  _itemsError = false;
                                }
                              }),
                              onDecrement: () => setState(() {
                                if (_lines[i].qty > 1) _lines[i].qty--;
                              }),
                              onIncrement: () => setState(() {
                                if (_lines[i].qty < _lines[i].item.quantity) {
                                  _lines[i].qty++;
                                }
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Estimated refund
                    if (_selectedLines.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.estimatedRefund,
                              style: AppTextStyles.labelSm.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              AppFormatters.currency(_refundTotal),
                              style: AppTextStyles.numericLg.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // Payment method
                    Text(
                      l10n.selectPaymentMethod,
                      style: AppTextStyles.labelSm.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _MethodButtons(
                      selected: _paymentMethod,
                      onChanged: (m) => setState(() => _paymentMethod = m),
                      isDark: isDark,
                      fg: fg,
                      border: border,
                      l10n: l10n,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Reason
                    Text(
                      l10n.refundReason,
                      style: AppTextStyles.labelSm.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _reasonController,
                      autofocus: true,
                      maxLines: 3,
                      style: AppTextStyles.bodySm.copyWith(color: fg),
                      decoration: InputDecoration(
                        hintText: l10n.refundReasonHint,
                        hintStyle: AppTextStyles.bodySm.copyWith(color: muted),
                        filled: true,
                        fillColor: mutedBg,
                        errorText:
                            _reasonError ? l10n.reasonRequired : null,
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.destructive),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.destructive, width: 2),
                        ),
                      ),
                      onChanged: (_) {
                        if (_reasonError) setState(() => _reasonError = false);
                      },
                    ),
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: border),

            // ── Footer ──
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.outline(
                    label: l10n.cancel,
                    onPressed:
                        _submitting ? null : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton.destructive(
                    label: _selectedLines.isEmpty
                        ? l10n.confirmRefund
                        : '${l10n.confirmRefund}  ${AppFormatters.currency(_refundTotal)}',
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item Row ──────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final _RefundLine line;
  final bool isDark;
  final Color fg;
  final Color muted;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _ItemRow({
    required this.line,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.onToggle,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      child: Row(
        children: [
          Checkbox(
            value: line.selected,
            onChanged: (v) => onToggle(v ?? false),
            activeColor: primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.item.productName,
                  style: AppTextStyles.labelSm.copyWith(color: fg),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppFormatters.currency(line.item.unitPrice),
                  style: AppTextStyles.bodyXs.copyWith(color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Qty stepper
          if (line.selected) ...[
            _StepperButton(
              icon: Icons.remove,
              onPressed: line.qty > 1 ? onDecrement : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2),
              child: Text(
                '${line.qty}',
                style: AppTextStyles.labelSm.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _StepperButton(
              icon: Icons.add,
              onPressed: line.qty < line.item.quantity ? onIncrement : null,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '/${line.item.quantity}',
              style: AppTextStyles.bodyXs.copyWith(color: muted),
            ),
          ] else
            Text(
              '×${line.item.quantity}',
              style: AppTextStyles.bodyXs.copyWith(color: muted),
            ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepperButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return SizedBox(
      width: 28,
      height: 28,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: onPressed != null ? border : border.withAlpha(80)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Icon(icon, size: 14),
      ),
    );
  }
}

// ── Payment Method Buttons ───────────────────────────────────────────────────

class _MethodButtons extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final bool isDark;
  final Color fg;
  final Color border;
  final AppLocalizations l10n;

  const _MethodButtons({
    required this.selected,
    required this.onChanged,
    required this.isDark,
    required this.fg,
    required this.border,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final methods = [
      ('cash', l10n.cash, Icons.payments_outlined),
      ('card', l10n.card, Icons.credit_card_outlined),
      ('wallet', l10n.wallet, Icons.account_balance_wallet_outlined),
      ('other', l10n.other, Icons.more_horiz_rounded),
    ];

    return Row(
      children: [
        for (final (value, label, icon) in methods) ...[
          Expanded(
            child: _MethodButton(
              value: value,
              label: label,
              icon: icon,
              isSelected: selected == value,
              onTap: () => onChanged(value),
              isDark: isDark,
              fg: fg,
              border: border,
              context: context,
            ),
          ),
          if (value != 'other') const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _MethodButton extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color fg;
  final Color border;
  final BuildContext context;

  const _MethodButton({
    required this.value,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.fg,
    required this.border,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg = isSelected
        ? primary.withAlpha(20)
        : (isDark ? AppColors.darkMuted : AppColors.muted);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primary : border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? primary : fg,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodyXs.copyWith(
                color: isSelected ? primary : fg,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
