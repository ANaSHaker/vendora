import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';

enum AvatarSize { xs, sm, md, lg, xl }

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final AvatarSize size;
  final Color? bgColor;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AvatarSize.md,
    this.bgColor,
  });

  double get _dimension => switch (size) {
        AvatarSize.xs => 24,
        AvatarSize.sm => 32,
        AvatarSize.md => 40,
        AvatarSize.lg => 48,
        AvatarSize.xl => 64,
      };

  double get _fontSize => switch (size) {
        AvatarSize.xs => 10,
        AvatarSize.sm => 12,
        AvatarSize.md => 14,
        AvatarSize.lg => 16,
        AvatarSize.xl => 22,
      };

  @override
  Widget build(BuildContext context) {
    final bg = bgColor ?? AppColors.primaryMuted;
    final dim = _dimension;

    return ClipOval(
      child: SizedBox(
        width: dim,
        height: dim,
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _InitialsAvatar(
                  name: name,
                  bg: bg,
                  fontSize: _fontSize,
                ),
              )
            : _InitialsAvatar(name: name, bg: bg, fontSize: _fontSize),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String? name;
  final Color bg;
  final double fontSize;

  const _InitialsAvatar({
    required this.name,
    required this.bg,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name != null ? AppFormatters.initials(name!) : '?';

    return Container(
      color: bg,
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.labelSm.copyWith(
            fontSize: fontSize,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
