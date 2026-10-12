import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../core/utils/formatters.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../../design_system/widgets/inputs/app_text_field.dart';

class PosPaymentResult {
  final String method;
  final double amount;
  const PosPaymentResult({required this.method, required this.amount});
}

class PosPaymentModal extends StatefulWidget {
  final double total;

  const PosPaymentModal({super.key, required this.total});

  static Future<PosPaymentResult?> show(
    BuildContext context, {
    required double total,
  }) {
    return showDialog<PosPaymentResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PosPaymentModal(total: total),
    );
  }

  @override
  State<PosPaymentModal> createState() => _PosPaymentModalState();
}

class _PosPaymentModalState extends State<PosPaymentModal> {
  String _method = 'cash';
  late final TextEditingController _ctrl;
  String? _error;

  static const _methodKeys = [
    ('cash', Icons.payments_outlined),
    ('card', Icons.credit_card),
    ('bank_transfer', Icons.account_balance_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.total.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _entered => double.tryParse(_ctrl.text.trim()) ?? 0;
  double get _change => (_entered - widget.total).clamp(0.0, double.infinity);

  String _methodLabel(String key, AppLocalizations l10n) => switch (key) {
    'cash'          => l10n.cash,
    'card'          => l10n.card,
    _               => l10n.bankTransfer,
  };

  void _confirm(AppLocalizations l10n) {
    final amount = double.tryParse(_ctrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = l10n.enterValidAmount);
      return;
    }
    if (amount < widget.total) {
      setState(() => _error = l10n.amountLessThanTotal);
      return;
    }
    Navigator.of(context).pop(PosPaymentResult(method: _method, amount: amount));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final editableHasFocus =
              FocusManager.instance.primaryFocus?.context?.widget is EditableText;

          // 1/2/3 switch method only when amount field not focused
          if (!editableHasFocus) {
            if (event.logicalKey == LogicalKeyboardKey.digit1 ||
                event.logicalKey == LogicalKeyboardKey.numpad1) {
              setState(() => _method = 'cash');
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.digit2 ||
                event.logicalKey == LogicalKeyboardKey.numpad2) {
              setState(() => _method = 'card');
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.digit3 ||
                event.logicalKey == LogicalKeyboardKey.numpad3) {
              setState(() => _method = 'bank_transfer');
              return KeyEventResult.handled;
            }
          }

          // Enter to confirm
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            _confirm(l10n);
            return KeyEventResult.handled;
          }

          // Escape to cancel
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.payment, style: AppTextStyles.h5),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.totalDue, style: AppTextStyles.bodySm),
                  Text(
                    AppFormatters.currency(widget.total),
                    style: AppTextStyles.numericXl.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.paymentMethod, style: AppTextStyles.labelSm),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: _methodKeys.map((m) {
                  final (key, icon) = m;
                  final isActive = _method == key;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: GestureDetector(
                        onTap: () => setState(() => _method = key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isActive ? cs.primary : surfaceColor,
                            border: Border.all(
                              color: isActive ? cs.primary : AppColors.border,
                            ),
                            borderRadius: AppRadius.brSm,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                icon,
                                size: 20,
                                color: isActive
                                    ? AppColors.white
                                    : AppColors.mutedForeground,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _methodLabel(key, l10n),
                                style: AppTextStyles.labelXs.copyWith(
                                  color: isActive
                                      ? AppColors.white
                                      : AppColors.foreground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _ctrl,
                label: l10n.amountTendered,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                errorText: _error,
                autofocus: true,
                onChanged: (_) => setState(() => _error = null),
              ),
              if (_entered >= widget.total) ...[
                const SizedBox(height: AppSpacing.sm),
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.cashChange,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          AppFormatters.currency(_change),
                          style: AppTextStyles.numeric.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      label: l10n.cancel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton.primary(
                      label: '${l10n.charge} ${AppFormatters.currency(widget.total)}',
                      onPressed: () => _confirm(l10n),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
        ),
    );
  }
}
