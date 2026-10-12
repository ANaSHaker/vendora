import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_border_radius.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static ThemeData buildLight({Color? primary}) =>
      _buildTheme(brightness: Brightness.light, primary: primary ?? AppColors.primary);

  static ThemeData buildDark({Color? primary}) =>
      _buildTheme(brightness: Brightness.dark, primary: primary ?? AppColors.primary);

  static ThemeData _buildTheme({required Brightness brightness, required Color primary}) {
    final isDark = brightness == Brightness.dark;

    final bg       = isDark ? AppColors.darkBackground      : AppColors.background;
    final surface  = isDark ? AppColors.darkSurface         : AppColors.surface;
    final border   = isDark ? AppColors.darkBorder          : AppColors.border;
    final fg       = isDark ? AppColors.darkForeground      : AppColors.foreground;
    final mutedFg  = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final primaryLight = primary.withValues(alpha: 0.12);
    final primaryMuted = primary.withValues(alpha: 0.08);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: AppColors.white,
      primaryContainer: isDark ? AppColors.darkSurface : primaryMuted,
      onPrimaryContainer: fg,
      secondary: primaryLight,
      onSecondary: AppColors.foreground,
      secondaryContainer: isDark ? AppColors.darkMuted : primaryMuted,
      onSecondaryContainer: fg,
      error: AppColors.destructive,
      onError: AppColors.white,
      errorContainer: AppColors.destructiveLight,
      onErrorContainer: AppColors.destructive,
      surface: surface,
      onSurface: fg,
      onSurfaceVariant: mutedFg,
      outline: border,
      outlineVariant: isDark ? AppColors.darkMuted : AppColors.muted,
      shadow: AppColors.black,
      scrim: const Color(0x80000000),
      inverseSurface: isDark ? AppColors.surface : AppColors.darkSurface,
      onInverseSurface: isDark ? AppColors.foreground : AppColors.darkForeground,
      inversePrimary: isDark ? primaryLight : primary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Geist',

      // ─── AppBar ────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.h5.copyWith(color: fg),
        iconTheme: IconThemeData(color: fg, size: AppSizes.iconLg),
      ),

      // ─── Card ──────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Input / TextField ─────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkMuted : AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: AppColors.destructive),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: AppColors.destructive, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTextStyles.bodySm.copyWith(color: mutedFg),
        labelStyle: AppTextStyles.labelMd.copyWith(color: mutedFg),
        errorStyle: AppTextStyles.bodyXs.copyWith(color: AppColors.destructive),
        isDense: true,
      ),

      // ─── ElevatedButton ────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm + AppSpacing.xs,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          textStyle: AppTextStyles.buttonMd,
        ),
      ),

      // ─── OutlinedButton ────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm + AppSpacing.xs,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          textStyle: AppTextStyles.buttonMd,
        ),
      ),

      // ─── TextButton ────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          textStyle: AppTextStyles.buttonMd,
        ),
      ),

      // ─── Divider ───────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // ─── Chip ──────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.darkMuted : AppColors.muted,
        labelStyle: AppTextStyles.labelSm.copyWith(color: fg),
        side: BorderSide(color: border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brFull),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),

      // ─── Dialog ────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brXl,
          side: BorderSide(color: border),
        ),
        titleTextStyle: AppTextStyles.h5.copyWith(color: fg),
        contentTextStyle: AppTextStyles.bodySm.copyWith(color: mutedFg),
      ),

      // ─── SnackBar ──────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.foreground,
        contentTextStyle: AppTextStyles.bodySm.copyWith(
          color: isDark ? AppColors.darkForeground : AppColors.white,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        behavior: SnackBarBehavior.floating,
      ),

      // ─── Bottom Navigation Bar ─────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: mutedFg,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.labelSm,
        unselectedLabelStyle: AppTextStyles.labelSm,
      ),

      // ─── Icon ──────────────────────────────────────────────────────────
      iconTheme: IconThemeData(color: mutedFg, size: AppSizes.iconLg),
      primaryIconTheme: IconThemeData(color: primary, size: AppSizes.iconLg),

      // ─── PopupMenu ─────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
          side: BorderSide(color: border),
        ),
        textStyle: AppTextStyles.bodySm.copyWith(color: fg),
      ),

      // ─── Tooltip ───────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkForeground : AppColors.foreground,
          borderRadius: AppRadius.brSm,
        ),
        textStyle: AppTextStyles.labelSm.copyWith(
          color: isDark ? AppColors.background : AppColors.white,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      // ─── Switch ────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.white;
          return isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return isDark ? AppColors.darkMuted : AppColors.muted;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((_) => Colors.transparent),
      ),

      // ─── Checkbox ──────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
        side: BorderSide(color: border, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brXs),
      ),

      // ─── ListTile ──────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.xs,
        ),
        titleTextStyle: AppTextStyles.bodySm.copyWith(color: fg),
        subtitleTextStyle: AppTextStyles.bodyXs.copyWith(color: mutedFg),
        iconColor: mutedFg,
      ),

      // ─── Tab ───────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: fg,
        unselectedLabelColor: mutedFg,
        indicatorColor: primary,
        labelStyle: AppTextStyles.labelMd,
        unselectedLabelStyle: AppTextStyles.labelMd,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: border,
      ),

      // ─── Progress Indicator ────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primaryMuted,
      ),
    );
  }
}
