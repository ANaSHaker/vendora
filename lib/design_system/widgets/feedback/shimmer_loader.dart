import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_border_radius.dart';

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkMuted : const Color(0xFFE8E8E8);
    final highlight = isDark ? AppColors.darkBorder : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: borderRadius ?? AppRadius.brMd,
        ),
      ),
    );
  }
}

class ShimmerStatCards extends StatelessWidget {
  final int count;

  const ShimmerStatCards({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        count,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < count - 1 ? AppSpacing.base : 0),
            child: const ShimmerBox(height: AppSizes.statCardHeight),
          ),
        ),
      ),
    );
  }
}

class ShimmerTableRows extends StatelessWidget {
  final int rows;

  const ShimmerTableRows({super.key, this.rows = 8});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: Column(
        children: List.generate(rows, (i) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    ShimmerBox(width: 24, height: 24),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 3,
                      child: ShimmerBox(height: 14),
                    ),
                    SizedBox(width: AppSpacing.base),
                    Expanded(
                      flex: 2,
                      child: ShimmerBox(height: 14),
                    ),
                    SizedBox(width: AppSpacing.base),
                    ShimmerBox(width: 60, height: 24, borderRadius: AppRadius.brFull),
                    SizedBox(width: AppSpacing.base),
                    ShimmerBox(width: 72, height: 28),
                  ],
                ),
              ),
              if (i < rows - 1) Divider(color: border, height: 1),
            ],
          );
        }),
      ),
    );
  }
}
