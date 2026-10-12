import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/storefront_cubit.dart';
import '../theme/sf_inherited_theme.dart';
import '../theme/sf_theme_data.dart';

class SfAboutPage extends StatelessWidget {
  const SfAboutPage({super.key});

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
            Text(l10n.sfAboutTitle,
              style: TextStyle(fontSize: 32, fontWeight: t.headingWeight,
                  color: t.text, letterSpacing: t.headingLetterSpacing)),
            if (vendor.aboutTitle != null) ...[
              const SizedBox(height: 12),
              Text(vendor.aboutTitle!,
                style: TextStyle(fontSize: 20, color: t.textMuted, height: 1.5)),
            ],
            if (vendor.aboutContent != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(t.radius),
                  border: Border.all(color: t.border),
                ),
                child: Text(vendor.aboutContent!,
                  style: TextStyle(fontSize: 15, color: t.textMuted, height: 1.8)),
              ),
            ],
            const SizedBox(height: 32),
            if (vendor.instagramUrl != null || vendor.twitterUrl != null ||
                vendor.facebookUrl != null)
              Row(children: [
                if (vendor.instagramUrl != null)
                  _SocialBtn(label: 'Instagram', icon: Icons.camera_alt_outlined, t: t),
                if (vendor.twitterUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: _SocialBtn(label: 'Twitter', icon: Icons.alternate_email, t: t),
                  ),
                if (vendor.facebookUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: _SocialBtn(label: 'Facebook', icon: Icons.facebook_rounded, t: t),
                  ),
              ]),
          ]),
        );
      },
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final SfThemeData t;
  const _SocialBtn({required this.label, required this.icon, required this.t});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () {},
    icon: Icon(icon, size: 16, color: t.primary),
    label: Text(label, style: TextStyle(color: t.primary, fontSize: 13)),
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: t.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.buttonRadius)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
  );
}
