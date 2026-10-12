import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/cubit/theme_cubit.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_color_presets.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';

class DesktopThemesPage extends StatefulWidget {
  const DesktopThemesPage({super.key});

  @override
  State<DesktopThemesPage> createState() => _DesktopThemesPageState();
}

class _DesktopThemesPageState extends State<DesktopThemesPage> {
  late ThemeState _draft;

  static const _statusOptions = ['pending', 'processing', 'completed'];

  @override
  void initState() {
    super.initState();
    _draft = context.read<ThemeCubit>().state;
  }

  void _apply() {
    context.read<ThemeCubit>().applySettings(_draft);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.t('settingsSaved')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _reset() => setState(() => _draft = const ThemeState());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = _draft.mode == ThemeMode.dark;
    final isAr = l10n.isAr;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = _draft.primaryColor;

    return ColoredBox(
      color: bg,
      child: Column(
        children: [
          // Header
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: border)),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.desktopContentPadding),
            child: Row(
              children: [
                Text(l10n.appearance,
                    style: AppTextStyles.h5.copyWith(color: fg)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(l10n.t('resetToDefault')),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: Text(l10n.applyChanges),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.desktopContentPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live preview
                      _SectionLabel(label: l10n.livePreview, fg: fg),
                      const SizedBox(height: AppSpacing.sm),
                      _LivePreviewFull(
                          draft: _draft, primary: primary, l10n: l10n),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.livePreviewHint,
                        style: AppTextStyles.caption.copyWith(color: muted),
                        textAlign: isAr ? TextAlign.right : TextAlign.left,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Mode toggle
                      _SectionLabel(label: l10n.mode, fg: fg),
                      const SizedBox(height: AppSpacing.sm),
                      _ModeToggle(
                        isDark: isDark,
                        primary: primary,
                        surface: surface,
                        border: border,
                        fg: fg,
                        lightLabel: l10n.light,
                        darkLabel: l10n.dark,
                        onChanged: (dark) => setState(() => _draft =
                            _draft.copyWith(
                                mode: dark
                                    ? ThemeMode.dark
                                    : ThemeMode.light)),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Default order status
                      _SectionLabel(label: l10n.posDefaultStatus, fg: fg),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.posDefaultStatusHint,
                        style: AppTextStyles.caption.copyWith(color: muted),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: AppRadius.brMd,
                          border: Border.all(color: border),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _draft.posDefaultStatus,
                            isExpanded: true,
                            dropdownColor: surface,
                            iconEnabledColor: fg.withValues(alpha: 0.5),
                            style: AppTextStyles.bodySm.copyWith(color: fg),
                            items: _statusOptions
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(l10n.statusLabel(s)),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _draft =
                                    _draft.copyWith(posDefaultStatus: v));
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Primary color
                      _SectionLabel(label: l10n.primaryColor, fg: fg),
                      const SizedBox(height: AppSpacing.sm),
                      GridView.count(
                        crossAxisCount: 6,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 0.85,
                        children: AppColorPreset.values.map((preset) {
                          final isSelected = preset == _draft.preset;
                          return GestureDetector(
                            onTap: () => setState(() =>
                                _draft = _draft.copyWith(preset: preset)),
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 150),
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: preset.swatch,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? fg : border,
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(
                                              Icons.check_rounded,
                                              color: AppColors.white,
                                              size: 22),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isAr ? preset.nameAr : preset.nameEn,
                                  style: AppTextStyles.caption.copyWith(
                                    color: fg.withValues(alpha: 0.7),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color fg;
  const _SectionLabel({required this.label, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: AppTextStyles.labelSm.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ));
  }
}

class _LivePreviewFull extends StatelessWidget {
  final ThemeState draft;
  final Color primary;
  final AppLocalizations l10n;

  const _LivePreviewFull(
      {required this.draft, required this.primary, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = draft.mode == ThemeMode.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final sidebarBg =
        isDark ? const Color(0xFF1A1C2E) : const Color(0xFFF8FAFC);

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          // Sidebar
          Container(
            width: 120,
            color: sidebarBg,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 48,
                    height: 10,
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                _NavItem(color: primary, active: true),
                const SizedBox(height: 6),
                _NavItem(color: muted, active: false),
                const SizedBox(height: 6),
                _NavItem(color: muted, active: false),
                const SizedBox(height: 6),
                _NavItem(color: muted, active: false),
              ],
            ),
          ),
          Container(width: 1, color: border),
          // Content
          Expanded(
            child: Container(
              color: bg,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(l10n.signIn,
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                      Row(children: [
                        _Dot(color: muted),
                        const SizedBox(width: 4),
                        _Dot(color: muted),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    _StatCard(
                        surface: surface,
                        border: border,
                        primary: primary,
                        fg: fg),
                    const SizedBox(width: 8),
                    _StatCard(
                        surface: surface,
                        border: border,
                        primary: primary,
                        fg: fg),
                    const SizedBox(width: 8),
                    _StatCard(
                        surface: surface,
                        border: border,
                        primary: primary,
                        fg: fg),
                  ]),
                  const SizedBox(height: 10),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final Color color;
  final bool active;
  const _NavItem({required this.color, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color.withValues(alpha: active ? 1 : 0.5),
                shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Expanded(
          child: Container(
              height: 6,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: active ? 0.6 : 0.3),
                  borderRadius: BorderRadius.circular(3))),
        ),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2), shape: BoxShape.circle));
  }
}

class _StatCard extends StatelessWidget {
  final Color surface, border, primary, fg;
  const _StatCard(
      {required this.surface,
      required this.border,
      required this.primary,
      required this.fg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: 6,
                width: 36,
                decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 5),
            Container(
                height: 10,
                width: 52,
                decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3))),
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isDark;
  final Color primary, surface, border, fg;
  final String lightLabel, darkLabel;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({
    required this.isDark,
    required this.primary,
    required this.surface,
    required this.border,
    required this.fg,
    required this.lightLabel,
    required this.darkLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            _ModeBtn(
              label: lightLabel,
              icon: Icons.light_mode_rounded,
              isSelected: !isDark,
              primary: primary,
              fg: fg,
              onTap: () => onChanged(false),
            ),
            _ModeBtn(
              label: darkLabel,
              icon: Icons.dark_mode_rounded,
              isSelected: isDark,
              primary: primary,
              fg: fg,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color primary, fg;
  final VoidCallback onTap;

  const _ModeBtn({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.primary,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? primary : Colors.transparent,
            borderRadius: AppRadius.brSm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected
                      ? AppColors.white
                      : fg.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  color: isSelected
                      ? AppColors.white
                      : fg.withValues(alpha: 0.6),
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
