import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../domain/entities/homepage_builder_entities.dart';
import '../../cubit/homepage_builder_cubit.dart';

// ── Page ──────────────────────────────────────────────────────────────────────

class DesktopHomepageBuilderPage extends StatelessWidget {
  const DesktopHomepageBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomepageBuilderCubit(
        getLayout:  getIt(),
        saveLayout: getIt(),
      )..load(),
      child: const _BuilderContent(),
    );
  }
}

// ── Main Content ──────────────────────────────────────────────────────────────

class _BuilderContent extends StatelessWidget {
  const _BuilderContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppColors.darkBackground : AppColors.background;
    final border = isDark ? AppColors.darkBorder      : AppColors.border;

    return BlocBuilder<HomepageBuilderCubit, HomepageBuilderState>(
      builder: (context, state) {
        final cubit = context.read<HomepageBuilderCubit>();

        if (state is HomepageBuilderLoading || state is HomepageBuilderInitial) {
          return ColoredBox(
            color: bg,
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: ShimmerTableRows(rows: 6),
            ),
          );
        }

        if (state is HomepageBuilderError) {
          return ColoredBox(
            color: bg,
            child: Center(
              child: AppErrorWidget(
                message: state.message,
                onRetry: cubit.load,
              ),
            ),
          );
        }

        final loaded = state as HomepageBuilderLoaded;

        return ColoredBox(
          color: bg,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left panel: section palette ─────────────────────────────
              _SectionPalette(border: border, isDark: isDark),

              // ── Center panel: canvas ────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CanvasHeader(
                      loaded: loaded,
                      cubit:  cubit,
                      border: border,
                      isDark: isDark,
                    ),
                    Expanded(
                      child: _Canvas(
                        loaded: loaded,
                        cubit:  cubit,
                        isDark: isDark,
                        border: border,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Right panel: settings ───────────────────────────────────
              _SettingsPanel(
                section: loaded.selected,
                cubit:   cubit,
                border:  border,
                isDark:  isDark,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Left: Section Palette ─────────────────────────────────────────────────────

class _SectionPalette extends StatelessWidget {
  final Color border;
  final bool isDark;
  const _SectionPalette({required this.border, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomepageBuilderCubit>();
    final l10n  = AppLocalizations.of(context);
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final fg    = isDark ? AppColors.darkForeground : AppColors.foreground;
    final cardBg= isDark ? AppColors.darkSurface : AppColors.surface;

    const types = SectionType.values;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Text(
              l10n.t('hbAddSection').toUpperCase(),
              style: AppTextStyles.labelSm.copyWith(
                color: muted,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ),
          // Cards
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.sm),
              itemCount: types.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, i) {
                final type = types[i];
                return _PaletteCard(
                  type:   type,
                  l10n:   l10n,
                  fg:     fg,
                  muted:  muted,
                  cardBg: cardBg,
                  border: border,
                  onTap:  () => cubit.addSection(type),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteCard extends StatelessWidget {
  final SectionType type;
  final AppLocalizations l10n;
  final Color fg, muted, cardBg, border;
  final VoidCallback onTap;

  const _PaletteCard({
    required this.type,
    required this.l10n,
    required this.fg,
    required this.muted,
    required this.cardBg,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: border),
          borderRadius: AppRadius.brMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_emoji(type), style: const TextStyle(fontSize: 16)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.t(_labelKey(type)),
                    style: AppTextStyles.labelSm.copyWith(color: fg),
                  ),
                ),
                Icon(Icons.add, size: 14,
                    color: AppColors.primary.withAlpha(179)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.t(_descKey(type)),
              style: AppTextStyles.caption.copyWith(color: muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _emoji(SectionType t) => switch (t) {
        SectionType.hero             => '🖼️',
        SectionType.featuredProducts => '📦',
        SectionType.categories       => '🏷️',
        SectionType.cta              => '🚀',
      };

  String _labelKey(SectionType t) => switch (t) {
        SectionType.hero             => 'hbSectionHeroLabel',
        SectionType.featuredProducts => 'hbSectionFeaturedLabel',
        SectionType.categories       => 'hbSectionCategoriesLabel',
        SectionType.cta              => 'hbSectionCtaLabel',
      };

  String _descKey(SectionType t) => switch (t) {
        SectionType.hero             => 'hbSectionHeroDesc',
        SectionType.featuredProducts => 'hbSectionFeaturedDesc',
        SectionType.categories       => 'hbSectionCategoriesDesc',
        SectionType.cta              => 'hbSectionCtaDesc',
      };
}

// ── Center: Canvas Header ─────────────────────────────────────────────────────

class _CanvasHeader extends StatelessWidget {
  final HomepageBuilderLoaded loaded;
  final HomepageBuilderCubit cubit;
  final Color border;
  final bool isDark;

  const _CanvasHeader({
    required this.loaded,
    required this.cubit,
    required this.border,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fg   = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted= isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final count = loaded.sections.length;
    final countText = count == 1
        ? l10n.t('hbSectionsCountOne')
        : l10n.t('hbSectionsCount').replaceAll('{count}', '$count');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.t('hbLayoutTitle'),
                  style: AppTextStyles.labelMd.copyWith(color: fg)),
              Text(countText,
                  style: AppTextStyles.caption.copyWith(color: muted)),
            ],
          ),
          const Spacer(),
          AppButton.primary(
            label: loaded.isSaving
                ? l10n.saving
                : loaded.savedBriefly
                    ? l10n.t('hbSaved')
                    : l10n.t('hbSaveLayout'),
            size: AppButtonSize.sm,
            leading: loaded.savedBriefly
                ? const Icon(Icons.check_circle_outline, size: 14)
                : null,
            isLoading: loaded.isSaving,
            onPressed: loaded.isSaving
                ? null
                : () async {
                    final ok = await cubit.save();
                    if (!context.mounted) return;
                    if (!ok) {
                      AppSnackbar.error(context, l10n.error);
                    }
                  },
          ),
        ],
      ),
    );
  }
}

// ── Center: Canvas ────────────────────────────────────────────────────────────

class _Canvas extends StatelessWidget {
  final HomepageBuilderLoaded loaded;
  final HomepageBuilderCubit cubit;
  final bool isDark;
  final Color border;

  const _Canvas({
    required this.loaded,
    required this.cubit,
    required this.isDark,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted= isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final fg   = isDark ? AppColors.darkForeground      : AppColors.foreground;

    if (loaded.sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: border),
                borderRadius: AppRadius.brFull,
              ),
              child: Icon(Icons.add, color: muted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.t('hbEmptyTitle'),
                style: AppTextStyles.labelMd.copyWith(color: fg)),
            const SizedBox(height: 4),
            Text(l10n.t('hbEmptyDesc'),
                style: AppTextStyles.caption.copyWith(color: muted),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: loaded.sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final section   = loaded.sections[i];
        final isFirst   = i == 0;
        final isLast    = i == loaded.sections.length - 1;
        final isSelected= loaded.selectedId == section.id;

        return _SectionCard(
          section:    section,
          isSelected: isSelected,
          isFirst:    isFirst,
          isLast:     isLast,
          cubit:      cubit,
          isDark:     isDark,
          border:     border,
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final HomepageSection section;
  final bool isSelected, isFirst, isLast, isDark;
  final HomepageBuilderCubit cubit;
  final Color border;

  const _SectionCard({
    required this.section,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.cubit,
    required this.isDark,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final fg    = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardBg= isDark ? AppColors.darkSurface : AppColors.surface;
    final accent= AppColors.primary;

    return GestureDetector(
      onTap: () => cubit.selectSection(section.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(
            color: isSelected ? accent : border,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: AppRadius.brMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.drag_indicator_rounded,
                      size: 18, color: muted),
                  const SizedBox(width: AppSpacing.xs),
                  Text(_emoji(section.type),
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.t(_labelKey(section.type)),
                            style: AppTextStyles.labelSm.copyWith(color: fg)),
                        if (section.settings['title'] is String)
                          Text(
                            section.settings['title'] as String,
                            style: AppTextStyles.caption.copyWith(color: muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Controls
                  _IconBtn(
                    icon: Icons.arrow_upward_rounded,
                    disabled: isFirst,
                    onTap: () => cubit.moveUp(section.id),
                  ),
                  _IconBtn(
                    icon: Icons.arrow_downward_rounded,
                    disabled: isLast,
                    onTap: () => cubit.moveDown(section.id),
                  ),
                  _IconBtn(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.destructive,
                    onTap: () => cubit.deleteSection(section.id),
                  ),
                ],
              ),
            ),
            // Mini preview
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: _MiniPreview(
                section: section,
                isDark:  isDark,
                border:  border,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emoji(SectionType t) => switch (t) {
        SectionType.hero             => '🖼️',
        SectionType.featuredProducts => '📦',
        SectionType.categories       => '🏷️',
        SectionType.cta              => '🚀',
      };

  String _labelKey(SectionType t) => switch (t) {
        SectionType.hero             => 'hbSectionHeroLabel',
        SectionType.featuredProducts => 'hbSectionFeaturedLabel',
        SectionType.categories       => 'hbSectionCategoriesLabel',
        SectionType.cta              => 'hbSectionCtaLabel',
      };
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool disabled;
  final VoidCallback? onTap;
  final Color? color;

  const _IconBtn({
    required this.icon,
    this.disabled = false,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted  = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    return IconButton(
      icon: Icon(icon,
          size: 16,
          color: disabled ? muted.withAlpha(77) : (color ?? muted)),
      onPressed: disabled ? null : onTap,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }
}

// ── Mini Preview ──────────────────────────────────────────────────────────────

class _MiniPreview extends StatelessWidget {
  final HomepageSection section;
  final bool isDark;
  final Color border;

  const _MiniPreview({
    required this.section,
    required this.isDark,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final s       = section.settings;
    final primary = isDark ? AppColors.primary : AppColors.primary;
    final bg      = isDark ? AppColors.darkMuted    : AppColors.muted;
    final fg      = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted   = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final card    = isDark ? AppColors.darkSurface : AppColors.surface;
    final l10n    = AppLocalizations.of(context);

    switch (section.type) {
      case SectionType.hero:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.brSm,
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s['title'] as String? ?? '',
                  style: AppTextStyles.labelSm
                      .copyWith(color: fg, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(s['subtitle'] as String? ?? '',
                  style: AppTextStyles.caption.copyWith(color: muted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: AppRadius.brFull,
                ),
                child: Text(
                  s['button_text'] as String? ?? l10n.t('hbDefaultHeroButton'),
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );

      case SectionType.featuredProducts:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.brSm,
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s['title'] as String? ?? '',
                  style: AppTextStyles.labelSm
                      .copyWith(color: fg, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: List.generate(
                  4,
                  (i) => Expanded(
                    child: Container(
                      height: 36,
                      margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: AppRadius.brXs,
                        border: Border.all(color: border),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case SectionType.categories:
        final chips = [
          l10n.t('hbDefaultCatA'),
          l10n.t('hbDefaultCatB'),
          l10n.t('hbDefaultCatC'),
        ];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.brSm,
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s['title'] as String? ?? '',
                  style: AppTextStyles.labelSm
                      .copyWith(color: fg, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: chips.map((c) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: AppRadius.brFull,
                    border: Border.all(color: border),
                  ),
                  child: Text(c,
                      style: AppTextStyles.caption.copyWith(color: fg)),
                )).toList(),
              ),
            ],
          ),
        );

      case SectionType.cta:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: primary.withAlpha(25),
            borderRadius: AppRadius.brSm,
            border: Border.all(color: primary.withAlpha(77)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s['title'] as String? ?? '',
                  style: AppTextStyles.labelSm
                      .copyWith(color: fg, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(s['description'] as String? ?? '',
                  style: AppTextStyles.caption.copyWith(color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 3),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: AppRadius.brXs,
                      border: Border.all(color: border),
                    ),
                    child: Text(
                      s['primary_button_text'] as String? ?? '',
                      style: AppTextStyles.caption.copyWith(color: fg),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.brXs,
                      border: Border.all(color: border),
                    ),
                    child: Text(
                      s['secondary_button_text'] as String? ?? '',
                      style: AppTextStyles.caption.copyWith(color: muted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }
}

// ── Right: Settings Panel ─────────────────────────────────────────────────────

class _SettingsPanel extends StatelessWidget {
  final HomepageSection? section;
  final HomepageBuilderCubit cubit;
  final Color border;
  final bool isDark;

  const _SettingsPanel({
    required this.section,
    required this.cubit,
    required this.border,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Text(
              l10n.t('hbSettings').toUpperCase(),
              style: AppTextStyles.labelSm.copyWith(
                color: muted,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ),
          // Body
          Expanded(
            child: section == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        l10n.t('hbSelectSectionHint'),
                        style: AppTextStyles.caption.copyWith(color: muted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _SectionSettings(
                    section: section!,
                    cubit:   cubit,
                    isDark:  isDark,
                    border:  border,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionSettings extends StatelessWidget {
  final HomepageSection section;
  final HomepageBuilderCubit cubit;
  final bool isDark;
  final Color border;

  const _SectionSettings({
    required this.section,
    required this.cubit,
    required this.isDark,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final fg    = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final s     = section.settings;

    void patch(Map<String, dynamic> p) => cubit.patchSettings(section.id, p);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Section type header
        Row(
          children: [
            Text(_emoji(section.type),
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              l10n.t(_labelKey(section.type)),
              style: AppTextStyles.labelMd.copyWith(color: fg),
            ),
          ],
        ),
        Divider(color: border, height: AppSpacing.lg),

        // Title (all types)
        _Field(
          label: l10n.t('hbFieldTitle'),
          muted: muted,
          child: _Input(
            value: s['title'] as String? ?? '',
            isDark: isDark,
            onChanged: (v) => patch({'title': v}),
          ),
        ),

        // Hero-specific
        if (section.type == SectionType.hero) ...[
          const SizedBox(height: AppSpacing.md),
          _Field(
            label: l10n.t('hbFieldSubtitle'),
            muted: muted,
            child: _Input(
              value: s['subtitle'] as String? ?? '',
              isDark: isDark,
              maxLines: 3,
              onChanged: (v) => patch({'subtitle': v}),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Field(
            label: l10n.t('hbFieldButtonText'),
            muted: muted,
            child: _Input(
              value: s['button_text'] as String? ?? '',
              isDark: isDark,
              onChanged: (v) => patch({'button_text': v}),
            ),
          ),
        ],

        // Featured Products-specific
        if (section.type == SectionType.featuredProducts) ...[
          const SizedBox(height: AppSpacing.md),
          _Field(
            label: l10n.t('hbFieldSubtitle'),
            muted: muted,
            child: _Input(
              value: s['subtitle'] as String? ?? '',
              isDark: isDark,
              onChanged: (v) => patch({'subtitle': v}),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Field(
            label: l10n.t('hbFieldProductsToShow'),
            muted: muted,
            child: _CountDropdown(
              value: s['count'] as int? ?? 8,
              isDark: isDark,
              border: border,
              fg: fg,
              onChanged: (v) => patch({'count': v}),
            ),
          ),
        ],

        // CTA-specific
        if (section.type == SectionType.cta) ...[
          const SizedBox(height: AppSpacing.md),
          _Field(
            label: l10n.t('hbFieldDescription'),
            muted: muted,
            child: _Input(
              value: s['description'] as String? ?? '',
              isDark: isDark,
              maxLines: 3,
              onChanged: (v) => patch({'description': v}),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Field(
            label: l10n.t('hbFieldPrimaryButton'),
            muted: muted,
            child: _Input(
              value: s['primary_button_text'] as String? ?? '',
              isDark: isDark,
              onChanged: (v) => patch({'primary_button_text': v}),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Field(
            label: l10n.t('hbFieldSecondaryButton'),
            muted: muted,
            child: _Input(
              value: s['secondary_button_text'] as String? ?? '',
              isDark: isDark,
              onChanged: (v) => patch({'secondary_button_text': v}),
            ),
          ),
        ],
      ],
    );
  }

  String _emoji(SectionType t) => switch (t) {
        SectionType.hero             => '🖼️',
        SectionType.featuredProducts => '📦',
        SectionType.categories       => '🏷️',
        SectionType.cta              => '🚀',
      };

  String _labelKey(SectionType t) => switch (t) {
        SectionType.hero             => 'hbSectionHeroLabel',
        SectionType.featuredProducts => 'hbSectionFeaturedLabel',
        SectionType.categories       => 'hbSectionCategoriesLabel',
        SectionType.cta              => 'hbSectionCtaLabel',
      };
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final Color muted;
  final Widget child;

  const _Field({
    required this.label,
    required this.muted,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(color: muted)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _Input extends StatefulWidget {
  final String value;
  final bool isDark;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _Input({
    required this.value,
    required this.isDark,
    required this.onChanged,
    this.maxLines = 1,
  });

  @override
  State<_Input> createState() => _InputState();
}

class _InputState extends State<_Input> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_Input old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
      _ctrl.selection = TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg     = isDark ? AppColors.darkMuted : AppColors.muted;
    final fg     = isDark ? AppColors.darkForeground : AppColors.foreground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return TextField(
      controller: _ctrl,
      maxLines:   widget.maxLines,
      minLines:   1,
      onChanged:  widget.onChanged,
      style:      AppTextStyles.bodySm.copyWith(color: fg),
      decoration: InputDecoration(
        filled:       true,
        fillColor:    bg,
        border: OutlineInputBorder(
          borderRadius: AppRadius.brSm,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brSm,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brSm,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        isDense: true,
      ),
    );
  }
}

class _CountDropdown extends StatelessWidget {
  final int value;
  final bool isDark;
  final Color border, fg;
  final ValueChanged<int> onChanged;

  const _CountDropdown({
    required this.value,
    required this.isDark,
    required this.border,
    required this.fg,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkMuted : AppColors.muted;
    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        filled:      true,
        fillColor:   bg,
        border: OutlineInputBorder(
          borderRadius: AppRadius.brSm,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brSm,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brSm,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        isDense: true,
      ),
      style: AppTextStyles.bodySm.copyWith(color: fg),
      dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
      items: const [4, 8, 12].map((n) => DropdownMenuItem(
        value: n,
        child: Text('$n'),
      )).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}
