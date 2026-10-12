import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/storefront_cubit.dart';
import '../theme/sf_inherited_theme.dart';
import '../theme/sf_theme_data.dart';

class SfContactPage extends StatelessWidget {
  const SfContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t      = StorefrontTheme.of(context);
    final l10n   = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return BlocBuilder<StorefrontCubit, StorefrontState>(
      builder: (_, state) {
        if (state is! StorefrontLoaded) return const SizedBox.shrink();
        final vendor = state.vendor;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 120 : 24, vertical: 48),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.sfContactTitle,
              style: TextStyle(fontSize: 32, fontWeight: t.headingWeight,
                  color: t.text, letterSpacing: t.headingLetterSpacing)),
            const SizedBox(height: 32),
            if (vendor.contactEmail != null)
              _ContactCard(
                icon: Icons.mail_outline_rounded,
                title: l10n.sfCustomerEmail,
                value: vendor.contactEmail!, t: t,
              ),
            if (vendor.contactPhone != null) ...[
              const SizedBox(height: 12),
              _ContactCard(
                icon: Icons.phone_outlined,
                title: l10n.sfCustomerPhone,
                value: vendor.contactPhone!, t: t,
              ),
            ],
            if (vendor.contactAddress != null) ...[
              const SizedBox(height: 12),
              _ContactCard(
                icon: Icons.location_on_outlined,
                title: l10n.sfDeliveryAddress,
                value: vendor.contactAddress!, t: t,
              ),
            ],
          ]),
        );
      },
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final SfThemeData t;
  const _ContactCard({required this.icon, required this.title,
    required this.value, required this.t});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: t.surface,
      borderRadius: BorderRadius.circular(t.radius),
      border: Border.all(color: t.border),
    ),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: t.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(t.radius / 2),
        ),
        child: Icon(icon, color: t.primary, size: 20),
      ),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 12, color: t.textMuted,
            fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, color: t.text, fontWeight: FontWeight.w500)),
      ]),
    ]),
  );
}
