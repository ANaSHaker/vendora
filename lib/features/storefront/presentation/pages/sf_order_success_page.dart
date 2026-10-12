import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../theme/sf_inherited_theme.dart';
import '../widgets/sf_button.dart';

class SfOrderSuccessPage extends StatelessWidget {
  final String slug;
  final String? reference;
  final double? total;
  const SfOrderSuccessPage({super.key, required this.slug,
    this.reference, this.total});

  @override
  Widget build(BuildContext context) {
    final t    = StorefrontTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: Colors.green, size: 48),
          ),
          const SizedBox(height: 24),
          Text(l10n.sfOrderSuccess,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: t.headingWeight,
                color: t.text, letterSpacing: t.headingLetterSpacing)),
          const SizedBox(height: 12),
          if (reference != null)
            Text('${l10n.sfOrderRef}: $reference',
              style: TextStyle(fontSize: 16, color: t.textMuted)),
          if (total != null) ...[
            const SizedBox(height: 8),
            Text('${l10n.sfTotal}: ${total!.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.primary)),
          ],
          const SizedBox(height: 32),
          Row(mainAxisSize: MainAxisSize.min, children: [
            SfButton(
              label: l10n.sfOrderTracking,
              onPressed: reference != null
                  ? () => context.go('/store/$slug/track/$reference')
                  : null,
              outlined: true, small: true,
            ),
            const SizedBox(width: 12),
            SfButton(
              label: l10n.sfContinueShopping,
              onPressed: () => context.go('/store/$slug/products'),
              small: true,
            ),
          ]),
        ]),
      ),
    );
  }
}
