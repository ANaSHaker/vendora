import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../domain/entities/homepage_builder_entities.dart';
import '../../cubit/homepage_builder_cubit.dart';

// ── Page ──────────────────────────────────────────────────────────────────────

class MobileHomepageBuilderPage extends StatelessWidget {
  const MobileHomepageBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomepageBuilderCubit(
        getLayout:  getIt(),
        saveLayout: getIt(),
      )..load(),
      child: const _MobileBuilderView(),
    );
  }
}

// ── View ──────────────────────────────────────────────────────────────────────

class _MobileBuilderView extends StatelessWidget {
  const _MobileBuilderView();

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final isDark= Theme.of(context).brightness == Brightness.dark;
    final bg    = isDark ? AppColors.darkBackground : AppColors.background;

    return BlocBuilder<HomepageBuilderCubit, HomepageBuilderState>(
      builder: (context, state) {
        final cubit = context.read<HomepageBuilderCubit>();

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
            title: Text(l10n.t('hbTitle'),
                style: AppTextStyles.labelMd.copyWith(
                  color: isDark ? AppColors.darkForeground : AppColors.foreground,
                )),
            actions: [
              if (state is HomepageBuilderLoaded)
                TextButton(
                  onPressed: state.isSaving
                      ? null
                      : () async {
                          final ok = await cubit.save();
                          if (!context.mounted) return;
                          if (ok) {
                            AppSnackbar.success(context, l10n.t('hbSaved'));
                          } else {
                            AppSnackbar.error(context, l10n.error);
                          }
                        },
                  child: state.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.t('hbSaveLayout'),
                          style: const TextStyle(color: AppColors.primary)),
                ),
            ],
          ),
          body: switch (state) {
            HomepageBuilderInitial() || HomepageBuilderLoading() =>
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child:   ShimmerTableRows(rows: 5),
              ),
            HomepageBuilderError(:final message) => Center(
                child: AppErrorWidget(
                  message: message,
                  onRetry: cubit.load,
                ),
              ),
            HomepageBuilderLoaded() => _MobileCanvas(
                loaded: state,
                cubit:  cubit,
                isDark: isDark,
              ),
          },
          floatingActionButton: state is HomepageBuilderLoaded
              ? FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  onPressed: () => _showAddSheet(context, cubit),
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  void _showAddSheet(BuildContext context, HomepageBuilderCubit cubit) {
    final l10n  = AppLocalizations.of(context);
    final isDark= Theme.of(context).brightness == Brightness.dark;
    final bg    = isDark ? AppColors.darkSurface : AppColors.surface;
    final border= isDark ? AppColors.darkBorder : AppColors.border;
    final fg    = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.t('hbAddSection'),
                style: AppTextStyles.labelMd.copyWith(color: fg)),
            const SizedBox(height: AppSpacing.md),
            ...SectionType.values.map((type) => ListTile(
              leading: Text(_emoji(type),
                  style: const TextStyle(fontSize: 22)),
              title: Text(l10n.t(_labelKey(type)),
                  style: AppTextStyles.labelSm.copyWith(color: fg)),
              subtitle: Text(l10n.t(_descKey(type)),
                  style: AppTextStyles.caption.copyWith(color: muted)),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.brMd,
                side: BorderSide(color: border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              onTap: () {
                Navigator.pop(context);
                cubit.addSection(type);
              },
            )).toList(),
            const SizedBox(height: AppSpacing.md),
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

// ── Mobile Canvas ─────────────────────────────────────────────────────────────

class _MobileCanvas extends StatelessWidget {
  final HomepageBuilderLoaded loaded;
  final HomepageBuilderCubit cubit;
  final bool isDark;

  const _MobileCanvas({
    required this.loaded,
    required this.cubit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final fg    = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final border= isDark ? AppColors.darkBorder : AppColors.border;

    if (loaded.sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.web_asset_outlined, size: 48, color: muted),
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
      itemBuilder: (context, i) {
        final section = loaded.sections[i];
        final isSelected = loaded.selectedId == section.id;

        return _MobileSectionCard(
          section:    section,
          isSelected: isSelected,
          isFirst:    i == 0,
          isLast:     i == loaded.sections.length - 1,
          cubit:      cubit,
          isDark:     isDark,
          border:     border,
          onTap: () {
            cubit.selectSection(section.id);
            _showSettingsSheet(context, section, cubit, isDark, border);
          },
        );
      },
    );
  }

  void _showSettingsSheet(
    BuildContext context,
    HomepageSection section,
    HomepageBuilderCubit cubit,
    bool isDark,
    Color border,
  ) {
    final l10n  = AppLocalizations.of(context);
    final bg    = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg    = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final s     = section.settings;

    void patch(Map<String, dynamic> p) => cubit.patchSettings(section.id, p);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(_emoji(section.type),
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.t(_labelKey(section.type)),
                    style: AppTextStyles.labelMd.copyWith(color: fg)),
              ]),
              Divider(color: border, height: AppSpacing.lg),

              _MobileField(
                label: l10n.t('hbFieldTitle'),
                muted: muted, isDark: isDark,
                value: s['title'] as String? ?? '',
                onChanged: (v) => patch({'title': v}),
              ),

              if (section.type == SectionType.hero) ...[
                const SizedBox(height: AppSpacing.md),
                _MobileField(
                  label: l10n.t('hbFieldSubtitle'),
                  muted: muted, isDark: isDark, maxLines: 3,
                  value: s['subtitle'] as String? ?? '',
                  onChanged: (v) => patch({'subtitle': v}),
                ),
                const SizedBox(height: AppSpacing.md),
                _MobileField(
                  label: l10n.t('hbFieldButtonText'),
                  muted: muted, isDark: isDark,
                  value: s['button_text'] as String? ?? '',
                  onChanged: (v) => patch({'button_text': v}),
                ),
              ],

              if (section.type == SectionType.featuredProducts) ...[
                const SizedBox(height: AppSpacing.md),
                _MobileField(
                  label: l10n.t('hbFieldSubtitle'),
                  muted: muted, isDark: isDark,
                  value: s['subtitle'] as String? ?? '',
                  onChanged: (v) => patch({'subtitle': v}),
                ),
              ],

              if (section.type == SectionType.cta) ...[
                const SizedBox(height: AppSpacing.md),
                _MobileField(
                  label: l10n.t('hbFieldDescription'),
                  muted: muted, isDark: isDark, maxLines: 3,
                  value: s['description'] as String? ?? '',
                  onChanged: (v) => patch({'description': v}),
                ),
                const SizedBox(height: AppSpacing.md),
                _MobileField(
                  label: l10n.t('hbFieldPrimaryButton'),
                  muted: muted, isDark: isDark,
                  value: s['primary_button_text'] as String? ?? '',
                  onChanged: (v) => patch({'primary_button_text': v}),
                ),
                const SizedBox(height: AppSpacing.md),
                _MobileField(
                  label: l10n.t('hbFieldSecondaryButton'),
                  muted: muted, isDark: isDark,
                  value: s['secondary_button_text'] as String? ?? '',
                  onChanged: (v) => patch({'secondary_button_text': v}),
                ),
              ],
            ],
          ),
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

class _MobileSectionCard extends StatelessWidget {
  final HomepageSection section;
  final bool isSelected, isFirst, isLast, isDark;
  final HomepageBuilderCubit cubit;
  final Color border;
  final VoidCallback onTap;

  const _MobileSectionCard({
    required this.section,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.cubit,
    required this.isDark,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final fg    = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardBg= isDark ? AppColors.darkSurface : AppColors.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(
            color: isSelected ? AppColors.primary : border,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: AppRadius.brMd,
        ),
        child: Row(
          children: [
            Text(_emoji(section.type),
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.sm),
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
            // Up / Down / Delete
            if (!isFirst)
              _SmallIconBtn(
                icon: Icons.arrow_upward_rounded,
                color: muted,
                onTap: () => cubit.moveUp(section.id),
              ),
            if (!isLast)
              _SmallIconBtn(
                icon: Icons.arrow_downward_rounded,
                color: muted,
                onTap: () => cubit.moveDown(section.id),
              ),
            _SmallIconBtn(
              icon: Icons.delete_outline_rounded,
              color: AppColors.destructive,
              onTap: () => cubit.deleteSection(section.id),
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

class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallIconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, size: 16, color: color),
        onPressed: onTap,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      );
}

class _MobileField extends StatefulWidget {
  final String label, value;
  final Color muted;
  final bool isDark;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _MobileField({
    required this.label,
    required this.value,
    required this.muted,
    required this.isDark,
    required this.onChanged,
    this.maxLines = 1,
  });

  @override
  State<_MobileField> createState() => _MobileFieldState();
}

class _MobileFieldState extends State<_MobileField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: AppTextStyles.caption.copyWith(color: widget.muted)),
        const SizedBox(height: 4),
        TextField(
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
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
