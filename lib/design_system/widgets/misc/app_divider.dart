import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AppDivider extends StatelessWidget {
  final bool vertical;
  final double? extent;

  const AppDivider({super.key, this.vertical = false, this.extent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkBorder : AppColors.border;

    if (vertical) {
      return Container(
        width: 1,
        height: extent,
        color: color,
      );
    }
    return Divider(color: color, height: 1, thickness: 1);
  }
}
