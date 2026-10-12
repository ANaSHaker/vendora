import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/locale_cubit.dart';
import '../../../../core/cubit/theme_cubit.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../design_system/theme/app_border_radius.dart';
import '../../../../design_system/theme/app_color_presets.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_text_styles.dart';

class ThemePickerDialog extends StatefulWidget {
  const ThemePickerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ThemeCubit>(),
        child: BlocProvider.value(
          value: context.read<LocaleCubit>(),
          child: const ThemePickerDialog(),
        ),
      ),
    );
  }

  @override
  State<ThemePickerDialog> createState() => _ThemePickerDialogState();
}

class _ThemePickerDialogState extends State<ThemePickerDialog> {
  late ThemeState _draft;

  static const _statusOptions = ['pending', 'processing', 'completed'];

  @override
  void initState() {
    super.initState();
    _draft = context.read<ThemeCubit>().state;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = _draft.mode == ThemeMode.dark;
    final isAr = AppLocalizations.of(context).isAr;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = _draft.primaryColor;

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brXl,
        side: BorderSide(color: border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─ Header ────────────────────────────────────────────────
            _Header(
              title: l10n.appearance,
              onReset: _onReset,
              onClose: () => Navigator.of(context).pop(),
              fg: fg,
              muted: muted,
              border: border,
              surface: surface,
              isAr: isAr,
            ),

            // ─ Scrollable Content ─────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live preview
                    _SectionLabel(label: l10n.livePreview, fg: fg),
                    const SizedBox(height: AppSpacing.sm),
                    _LivePreview(draft: _draft, primary: primary),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.livePreviewHint,
                      style: AppTextStyles.caption.copyWith(color: muted),
                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                    ),

                    const SizedBox(height: AppSpacing.base),

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
                      onChanged: (dark) => setState(
                          () => _draft = _draft.copyWith(
                              mode: dark ? ThemeMode.dark : ThemeMode.light)),
                    ),

                    const SizedBox(height: AppSpacing.base),

                    // Default order status
                    _SectionLabel(label: l10n.posDefaultStatus, fg: fg),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.posDefaultStatusHint,
                      style: AppTextStyles.caption.copyWith(color: muted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _StatusDropdown(
                      value: _draft.posDefaultStatus,
                      options: _statusOptions,
                      l10n: l10n,
                      surface: surface,
                      border: border,
                      fg: fg,
                      primary: primary,
                      onChanged: (v) =>
                          setState(() => _draft = _draft.copyWith(posDefaultStatus: v)),
                    ),

                    const SizedBox(height: AppSpacing.base),

                    // Primary color
                    _SectionLabel(label: l10n.primaryColor, fg: fg),
                    const SizedBox(height: AppSpacing.sm),
                    _ColorGrid(
                      selected: _draft.preset,
                      l10n: l10n,
                      fg: fg,
                      border: border,
                      surface: surface,
                      bg: bg,
                      onSelected: (p) =>
                          setState(() => _draft = _draft.copyWith(preset: p)),
                    ),

                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),

            // ─ Footer ────────────────────────────────────────────────
            _Footer(
              onApply: _onApply,
              onCancel: () => Navigator.of(context).pop(),
              applyLabel: l10n.applyChanges,
              cancelLabel: l10n.cancel,
              primary: primary,
              border: border,
              fg: fg,
              surface: surface,
            ),
          ],
        ),
      ),
    );
  }

  void _onApply() {
    context.read<ThemeCubit>().applySettings(_draft);
    Navigator.of(context).pop();
  }

  void _onReset() {
    setState(() {
      _draft = const ThemeState();
    });
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onReset;
  final VoidCallback onClose;
  final Color fg, muted, border, surface;
  final bool isAr;

  const _Header({
    required this.title,
    required this.onReset,
    required this.onClose,
    required this.fg,
    required this.muted,
    required this.border,
    required this.surface,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          if (!isAr) ...[
            Text(title,
                style: AppTextStyles.h6.copyWith(
                    color: fg, fontWeight: FontWeight.w700)),
            const Spacer(),
          ],
          InkWell(
            onTap: onClose,
            borderRadius: AppRadius.brSm,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: AppSizes.iconMd, color: muted),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          InkWell(
            onTap: onReset,
            borderRadius: AppRadius.brSm,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.refresh_rounded, size: AppSizes.iconMd, color: muted),
            ),
          ),
          if (isAr) ...[
            const Spacer(),
            Text(title,
                style: AppTextStyles.h6.copyWith(
                    color: fg, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color fg;
  const _SectionLabel({required this.label, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.labelSm.copyWith(
        color: fg,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─── Live Preview ─────────────────────────────────────────────────────────────

class _LivePreview extends StatelessWidget {
  final ThemeState draft;
  final Color primary;

  const _LivePreview({required this.draft, required this.primary});

  @override
  Widget build(BuildContext context) {
    final isDark = draft.mode == ThemeMode.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final sidebarBg = isDark ? const Color(0xFF1A1C2E) : const Color(0xFFF8FAFC);

    return Container(
      height: 130,
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
            width: 90,
            color: sidebarBg,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 36, height: 8,
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                _PreviewNavItem(color: primary, active: true),
                const SizedBox(height: 4),
                _PreviewNavItem(color: muted, active: false),
                const SizedBox(height: 4),
                _PreviewNavItem(color: muted, active: false),
              ],
            ),
          ),
          Container(width: 1, color: border),
          // Content
          Expanded(
            child: Container(
              color: bg,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppLocalizations.of(context).signIn,
                          style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Row(children: [
                        _PreviewDot(color: muted),
                        const SizedBox(width: 4),
                        _PreviewDot(color: muted),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Stats cards
                  Row(children: [
                    _PreviewCard(
                        surface: surface, border: border, primary: primary, fg: fg),
                    const SizedBox(width: 6),
                    _PreviewCard(
                        surface: surface, border: border, primary: primary, fg: fg),
                  ]),
                  const SizedBox(height: 8),
                  // Highlighted line
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
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

class _PreviewNavItem extends StatelessWidget {
  final Color color;
  final bool active;
  const _PreviewNavItem({required this.color, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color.withValues(alpha: active ? 1 : 0.5),
                shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
              height: 5,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: active ? 0.6 : 0.3),
                  borderRadius: BorderRadius.circular(3))),
        ),
      ]),
    );
  }
}

class _PreviewDot extends StatelessWidget {
  final Color color;
  const _PreviewDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle));
  }
}

class _PreviewCard extends StatelessWidget {
  final Color surface, border, primary, fg;
  const _PreviewCard(
      {required this.surface,
      required this.border,
      required this.primary,
      required this.fg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 36,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: 5,
                width: 30,
                decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 4),
            Container(
                height: 8,
                width: 45,
                decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3))),
          ],
        ),
      ),
    );
  }
}

// ─── Mode Toggle ──────────────────────────────────────────────────────────────

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
    return Container(
      height: 44,
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
                  size: 14,
                  color: isSelected ? AppColors.white : fg.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  color: isSelected ? AppColors.white : fg.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Dropdown ──────────────────────────────────────────────────────────

class _StatusDropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final AppLocalizations l10n;
  final Color surface, border, fg, primary;
  final ValueChanged<String> onChanged;

  const _StatusDropdown({
    required this.value,
    required this.options,
    required this.l10n,
    required this.surface,
    required this.border,
    required this.fg,
    required this.primary,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: surface,
          iconEnabledColor: fg.withValues(alpha: 0.5),
          style: AppTextStyles.bodySm.copyWith(color: fg),
          items: options
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(l10n.statusLabel(s)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ─── Color Grid ───────────────────────────────────────────────────────────────

class _ColorGrid extends StatelessWidget {
  final AppColorPreset selected;
  final AppLocalizations l10n;
  final Color fg, border, surface, bg;
  final ValueChanged<AppColorPreset> onSelected;

  const _ColorGrid({
    required this.selected,
    required this.l10n,
    required this.fg,
    required this.border,
    required this.surface,
    required this.bg,
    required this.onSelected,
  });

  String _name(AppColorPreset p) => l10n.isAr ? p.nameAr : p.nameEn;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 0.85,
      children: AppColorPreset.values.map((preset) {
        final isSelected = preset == selected;
        return GestureDetector(
          onTap: () => onSelected(preset),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
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
                        child: Icon(Icons.check_rounded,
                            color: AppColors.white, size: 22),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                _name(preset),
                style: AppTextStyles.caption.copyWith(
                  color: fg.withValues(alpha: 0.7),
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final VoidCallback onApply, onCancel;
  final String applyLabel, cancelLabel;
  final Color primary, border, fg, surface;

  const _Footer({
    required this.onApply,
    required this.onCancel,
    required this.applyLabel,
    required this.cancelLabel,
    required this.primary,
    required this.border,
    required this.fg,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: border),
                foregroundColor: fg,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
              child: Text(cancelLabel),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
              child: Text(applyLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
