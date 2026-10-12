import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../design_system/theme/app_border_radius.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_text_styles.dart';
import '../../../../design_system/widgets/feedback/app_snackbar.dart';

class BookingLinkCard extends StatelessWidget {
  final LocalStorage localStorage;

  const BookingLinkCard({super.key, required this.localStorage});

  String? get _slug => localStorage.trackingSlug;

  // Derives the origin from the running app's URL so the link works
  // automatically on localhost, staging, and production without any config.
  String get _bookingUrl {
    String origin;
    const configured = String.fromEnvironment('APP_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) {
      origin = configured;
    } else {
      final base = Uri.base.origin;
      origin = base.startsWith('http') ? base : '';
    }
    return '$origin/#/book/${_slug ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    final slug = _slug;
    if (slug == null || slug.isEmpty) return const SizedBox.shrink();

    final l10n   = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder  : AppColors.border;
    final fg     = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted  = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cs     = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.xl),
                topRight: Radius.circular(AppRadius.xl),
              ),
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.link_rounded, size: 16, color: cs.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.t('bookingLinkTitle'),
                        style: AppTextStyles.bodySm.copyWith(color: fg, fontWeight: FontWeight.w700)),
                      Text(l10n.t('bookingLinkSubtitle'),
                        style: AppTextStyles.labelSm.copyWith(color: muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // URL display
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                    borderRadius: AppRadius.brLg,
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.public_rounded, size: 14, color: muted),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          _bookingUrl,
                          style: AppTextStyles.labelSm.copyWith(
                            color: fg,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Action buttons row
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.copy_rounded,
                        label: l10n.t('bookingLinkCopy'),
                        color: cs.primary,
                        bg: cs.primary.withOpacity(0.08),
                        border: cs.primary.withOpacity(0.2),
                        onTap: () => _copyLink(context, l10n),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.qr_code_2_rounded,
                        label: l10n.t('bookingLinkQr'),
                        color: isDark ? AppColors.darkForeground : AppColors.foreground,
                        bg: isDark ? AppColors.darkMuted : AppColors.muted,
                        border: border,
                        onTap: () => _showQr(context, l10n),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.open_in_new_rounded,
                        label: l10n.t('bookingLinkOpen'),
                        color: isDark ? AppColors.darkForeground : AppColors.foreground,
                        bg: isDark ? AppColors.darkMuted : AppColors.muted,
                        border: border,
                        onTap: () => _openLink(context, l10n),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyLink(BuildContext context, AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: _bookingUrl));
    if (!context.mounted) return;
    AppSnackbar.success(context, l10n.t('bookingLinkCopied'));
  }

  void _showQr(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg     = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted  = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.t('bookingQrTitle'),
                      style: AppTextStyles.h5.copyWith(color: fg, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(_),
                    icon: Icon(Icons.close_rounded, color: muted),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.brXl,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16)],
                ),
                child: QrImageView(
                  data: _bookingUrl,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(_bookingUrl,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSm.copyWith(color: muted, fontFamily: 'monospace'),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _bookingUrl));
                    Navigator.pop(_);
                    AppSnackbar.success(context, l10n.t('bookingLinkCopied'));
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(l10n.t('bookingLinkCopy')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLink(BuildContext context, AppLocalizations l10n) async {
    final uri = Uri.parse(_bookingUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      AppSnackbar.error(context, l10n.t('bookingLinkOpenFailed'));
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, bg, border;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon, required this.label, required this.color,
    required this.bg, required this.border, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 3),
            Text(label, style: AppTextStyles.labelSm.copyWith(color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
