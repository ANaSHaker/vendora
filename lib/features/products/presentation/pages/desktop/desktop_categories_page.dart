import 'dart:io' show Process;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/buttons/app_icon_button.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../domain/entities/product_entities.dart';
import '../../cubit/categories_cubit.dart';
import '../../cubit/categories_state.dart';
import 'widgets/category_form_dialog.dart';

// ── Tree node helper ──────────────────────────────────────────────────────────

class _TreeNode {
  final CategoryEntity cat;
  final int depth;
  final bool hasChildren;

  const _TreeNode({
    required this.cat,
    required this.depth,
    required this.hasChildren,
  });
}

// ── Page ──────────────────────────────────────────────────────────────────────

class DesktopCategoriesPage extends StatelessWidget {
  const DesktopCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CategoriesCubit(
        getCategories: getIt(),
        createCategory: getIt(),
        updateCategory: getIt(),
        deleteCategory: getIt(),
        exportCategories: getIt(),
        importCategories: getIt(),
      )..load(),
      child: const _CategoriesContent(),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _CategoriesContent extends StatefulWidget {
  const _CategoriesContent();

  @override
  State<_CategoriesContent> createState() => _CategoriesContentState();
}

class _CategoriesContentState extends State<_CategoriesContent> {
  final Set<String> _expanded = {};
  String _search = '';
  bool _importing = false;
  Map<String, dynamic>? _importResult;
  String _duplicateMode = 'skip';

  // Collect all categories from both flat and nested responses
  Map<String, CategoryEntity> _collectAll(List<CategoryEntity> cats) {
    final map = <String, CategoryEntity>{};
    void visit(CategoryEntity c) {
      map[c.id] = c;
      for (final child in c.children) { visit(child); }
    }
    for (final c in cats) { visit(c); }
    return map;
  }

  // Build parent→children lookup from the flat map
  Map<String?, List<CategoryEntity>> _childrenMap(
    Map<String, CategoryEntity> allCats,
  ) {
    final map = <String?, List<CategoryEntity>>{};
    for (final cat in allCats.values) {
      (map[cat.parentId] ??= []).add(cat);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return map;
  }

  List<_TreeNode> _buildDisplayList(List<CategoryEntity> categories) {
    final allCats = _collectAll(categories);
    final cm = _childrenMap(allCats);

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      return allCats.values
          .where((c) => c.name.toLowerCase().contains(q))
          .map((c) => _TreeNode(
                cat: c,
                depth: 0,
                hasChildren: (cm[c.id]?.isNotEmpty ?? false),
              ))
          .toList()
        ..sort((a, b) => a.cat.name.compareTo(b.cat.name));
    }

    final result = <_TreeNode>[];
    void addLevel(String? parentId, int depth) {
      for (final cat in cm[parentId] ?? []) {
        final children = cm[cat.id] ?? [];
        result.add(_TreeNode(
          cat: cat,
          depth: depth,
          hasChildren: children.isNotEmpty,
        ));
        if (_expanded.contains(cat.id) && children.isNotEmpty) {
          addLevel(cat.id, depth + 1);
        }
      }
    }

    addLevel(null, 0);
    return result;
  }

  Future<void> _onExportDone(BuildContext ctx, String? path, AppLocalizations l10n) async {
    if (!ctx.mounted) return;
    if (path != null) {
      AppSnackbar.success(ctx, path);
      if (!kIsWeb) {
        try { await Process.run('explorer.exe', ['/select,', path]); } catch (_) {}
      }
    } else {
      AppSnackbar.error(ctx, l10n.error);
    }
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  Future<void> _showImport(BuildContext context, CategoriesCubit cubit) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    if (!context.mounted) return;

    setState(() => _importing = true);
    final bytes = result.files.single.bytes!;
    final name = result.files.single.name;
    final data = await cubit.importFile(
      bytes.toList(),
      name,
      duplicateMode: _duplicateMode,
    );
    if (!mounted) return;
    setState(() {
      _importing = false;
      _importResult = data;
    });
    if (data == null && context.mounted) {
      AppSnackbar.error(context, AppLocalizations.of(context).categoryImportFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        final cubit = context.read<CategoriesCubit>();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final surface = isDark ? AppColors.darkSurface : AppColors.surface;
        final border = isDark ? AppColors.darkBorder : AppColors.border;
        final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

        final allCats = state is CategoriesLoaded ? state.categories : <CategoryEntity>[];
        final nodes = _buildDisplayList(allCats);
        final allCatsFlat = _collectAll(allCats);
        final totalCount = allCatsFlat.length;

        return ColoredBox(
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.categories,
                          style: AppTextStyles.h4.copyWith(color: fg),
                        ),
                        if (state is CategoriesLoaded)
                          Text(
                            _search.isNotEmpty
                                ? l10n.categoryMatchingCount
                                    .replaceAll('{count}', '${nodes.length}')
                                : l10n.categoryTotal
                                    .replaceAll('{count}', '$totalCount'),
                            style: AppTextStyles.bodySm.copyWith(color: muted),
                          ),
                      ],
                    ),
                    const Spacer(),
                    // Duplicate mode selector
                    _DuplicateModeDropdown(
                      value: _duplicateMode,
                      isDark: isDark,
                      l10n: l10n,
                      onChanged: (v) => setState(() => _duplicateMode = v),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Import/Export toolbar
                    AppButton.outline(
                      label: l10n.downloadTemplate,
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.download_outlined, size: 14),
                      onPressed: () async {
                        final ctx = context;
                        final path = await cubit.exportFile(template: true);
                        if (!ctx.mounted) return;
                        await _onExportDone(ctx, path, l10n);
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton.outline(
                      label: l10n.exportFile,
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.upload_file_outlined, size: 14),
                      onPressed: () async {
                        final ctx = context;
                        final path = await cubit.exportFile();
                        if (!ctx.mounted) return;
                        await _onExportDone(ctx, path, l10n);
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton.outline(
                      label: l10n.uploadFile,
                      size: AppButtonSize.sm,
                      isLoading: _importing,
                      leading: const Icon(Icons.upload_outlined, size: 14),
                      onPressed:
                          _importing ? null : () => _showImport(context, cubit),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton.primary(
                      label: l10n.addCategory,
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.add, size: 16),
                      onPressed: () => CategoryFormDialog.show(
                        context,
                        allCategories: allCats,
                        onSubmit: cubit.createCategory,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search bar ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.desktopContentPadding,
                ),
                child: SizedBox(
                  width: 320,
                  child: AppSearchField(
                    hint: l10n.searchCategories,
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Import result banner ──────────────────────────────────────
              if (_importResult != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.desktopContentPadding,
                    0,
                    AppSizes.desktopContentPadding,
                    AppSpacing.md,
                  ),
                  child: _ImportResultBanner(
                    result: _importResult!,
                    l10n: l10n,
                    isDark: isDark,
                    onDismiss: () => setState(() => _importResult = null),
                  ),
                ),

              // ── Table ─────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.desktopContentPadding,
                    0,
                    AppSizes.desktopContentPadding,
                    0,
                  ),
                  child: switch (state) {
                    CategoriesInitial() || CategoriesLoading() =>
                      const ShimmerTableRows(rows: 6),
                    CategoriesError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: cubit.load,
                      ),
                    CategoriesLoaded(:final categories) when categories.isEmpty =>
                      AppEmptyState(
                        icon:
                            const Icon(Icons.folder_outlined, size: 40),
                        message: l10n.noCategoriesYet,
                        action: AppButton.primary(
                          label: l10n.addCategory,
                          onPressed: () => CategoryFormDialog.show(
                            context,
                            allCategories: categories,
                            onSubmit: cubit.createCategory,
                          ),
                        ),
                      ),
                    CategoriesLoaded() => _CategoriesTable(
                        nodes: nodes,
                        allCats: allCats,
                        expanded: _expanded,
                        cubit: cubit,
                        isDark: isDark,
                        surface: surface,
                        border: border,
                        fg: fg,
                        muted: muted,
                        l10n: l10n,
                        onToggleExpand: _toggleExpand,
                      ),
                  },
                ),
              ),

              // ── Footer ────────────────────────────────────────────────────
              if (state is CategoriesLoaded && totalCount > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.desktopContentPadding,
                    vertical: AppSpacing.md,
                  ),
                  child: Text(
                    l10n.categoryTotal.replaceAll('{count}', '$totalCount'),
                    style: AppTextStyles.bodyXs.copyWith(color: muted),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Table ─────────────────────────────────────────────────────────────────────

class _CategoriesTable extends StatelessWidget {
  final List<_TreeNode> nodes;
  final List<CategoryEntity> allCats;
  final Set<String> expanded;
  final CategoriesCubit cubit;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color fg;
  final Color muted;
  final AppLocalizations l10n;
  final void Function(String id) onToggleExpand;

  const _CategoriesTable({
    required this.nodes,
    required this.allCats,
    required this.expanded,
    required this.cubit,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.fg,
    required this.muted,
    required this.l10n,
    required this.onToggleExpand,
  });

  Future<void> _confirmDelete(BuildContext context, CategoryEntity cat) async {
    await _DeleteCategoryDialog.show(
      context,
      category: cat,
      onDelete: () => cubit.deleteCategory(cat.id),
      onDeleted: () {
        if (context.mounted) {
          AppSnackbar.success(context, l10n.categoryDeleted);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              height: AppSizes.tableHeaderHeight,
              color: headerBg,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  const SizedBox(width: 24), // expand icon space
                  Expanded(
                    flex: 4,
                    child: Text(l10n.colName, style: AppTextStyles.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(l10n.colParent, style: AppTextStyles.tableHeader),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      l10n.colProducts,
                      style: AppTextStyles.tableHeader,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      l10n.colOrder,
                      style: AppTextStyles.tableHeader,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 88,
                    child: Text(
                      l10n.colStatus,
                      style: AppTextStyles.tableHeader,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 72), // actions
                ],
              ),
            ),
            Divider(height: 1, color: border),
            // ── Rows ────────────────────────────────────────────────────────
            Expanded(
              child: nodes.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noData,
                        style: AppTextStyles.bodySm.copyWith(color: muted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: nodes.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: border),
                      itemBuilder: (context, i) {
                        final node = nodes[i];
                        return _CategoryRow(
                          node: node,
                          isExpanded: expanded.contains(node.cat.id),
                          isDark: isDark,
                          border: border,
                          fg: fg,
                          muted: muted,
                          l10n: l10n,
                          onToggle: () => onToggleExpand(node.cat.id),
                          onEdit: () => CategoryFormDialog.show(
                            context,
                            editing: node.cat,
                            allCategories: allCats,
                            onSubmit: (data) =>
                                cubit.updateCategory(node.cat.id, data),
                          ),
                          onDelete: () => _confirmDelete(context, node.cat),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category row ──────────────────────────────────────────────────────────────

class _CategoryRow extends StatefulWidget {
  final _TreeNode node;
  final bool isExpanded;
  final bool isDark;
  final Color border;
  final Color fg;
  final Color muted;
  final AppLocalizations l10n;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryRow({
    required this.node,
    required this.isExpanded,
    required this.isDark,
    required this.border,
    required this.fg,
    required this.muted,
    required this.l10n,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final cat = node.cat;
    final indentWidth = node.depth * 20.0;
    final folderColor = node.depth == 0 ? AppColors.primary : widget.muted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: AppSizes.tableRowHeight,
        color: _hovered
            ? (widget.isDark
                ? AppColors.darkMuted.withValues(alpha: 0.5)
                : AppColors.primaryMuted.withValues(alpha: 0.4))
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            // Expand/collapse toggle
            SizedBox(
              width: 24,
              child: node.hasChildren
                  ? InkWell(
                      onTap: widget.onToggle,
                      borderRadius: BorderRadius.circular(4),
                      child: Icon(
                        widget.isExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_right_rounded,
                        size: 18,
                        color: widget.muted,
                      ),
                    )
                  : null,
            ),
            // Name cell with indentation
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  SizedBox(width: indentWidth),
                  Icon(
                    widget.isExpanded && node.hasChildren
                        ? Icons.folder_open_outlined
                        : Icons.folder_outlined,
                    size: 16,
                    color: folderColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: AppTextStyles.labelSm.copyWith(color: widget.fg),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Parent
            Expanded(
              flex: 2,
              child: Text(
                cat.parentName ?? '—',
                style: AppTextStyles.tableCell.copyWith(color: widget.muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Products count
            SizedBox(
              width: 72,
              child: Text(
                '${cat.productCount}',
                style: AppTextStyles.numeric.copyWith(
                  color: cat.productCount > 0 ? widget.fg : widget.muted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Sort order
            SizedBox(
              width: 64,
              child: Text(
                '${cat.sortOrder}',
                style: AppTextStyles.numeric.copyWith(color: widget.muted),
                textAlign: TextAlign.center,
              ),
            ),
            // Status badge
            SizedBox(
              width: 88,
              child: Center(
                child: _StatusBadge(isActive: cat.isActive, l10n: widget.l10n),
              ),
            ),
            // Actions — visible only on hover
            SizedBox(
              width: 72,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _hovered ? 1.0 : 0.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppIconButton(
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      onPressed: widget.onEdit,
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.sm,
                      tooltip: widget.l10n.edit,
                    ),
                    AppIconButton(
                      icon: const Icon(Icons.delete_outline, size: 14),
                      onPressed: widget.onDelete,
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.sm,
                      tooltip: widget.l10n.delete,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final AppLocalizations l10n;

  const _StatusBadge({required this.isActive, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = isActive ? AppColors.primary : AppColors.mutedForeground;
    final bgColor = isActive
        ? AppColors.primaryMuted
        : (isDark ? AppColors.darkMuted : AppColors.muted);
    final textColor = isActive ? AppColors.primary : AppColors.mutedForeground;
    final borderColor = isActive
        ? AppColors.primary.withValues(alpha: 0.35)
        : AppColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? l10n.active : l10n.inactive,
            style: AppTextStyles.labelXs.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}

// ── Import result banner ──────────────────────────────────────────────────────

class _ImportResultBanner extends StatelessWidget {
  final Map<String, dynamic> result;
  final AppLocalizations l10n;
  final bool isDark;
  final VoidCallback onDismiss;

  const _ImportResultBanner({
    required this.result,
    required this.l10n,
    required this.isDark,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final created = result['created'] ?? 0;
    final updated = result['updated'] ?? 0;
    final skipped = result['skipped'] ?? 0;
    final failed = result['failed'] ?? 0;
    final errors = (result['errors'] as List?)?.cast<String>() ?? <String>[];
    final summary = l10n.categoryImportCounts
        .replaceAll('{created}', '$created')
        .replaceAll('{updated}', '$updated')
        .replaceAll('{skipped}', '$skipped')
        .replaceAll('{failed}', '$failed');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkMuted : AppColors.successLight,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.success,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: AppColors.successForeground,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.categoryImportSummary,
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.successForeground),
                ),
                Text(
                  summary,
                  style: AppTextStyles.bodyXs
                      .copyWith(color: AppColors.successForeground),
                ),
                if (errors.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  ...errors.take(10).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ',
                              style: AppTextStyles.bodyXs.copyWith(
                                  color: AppColors.destructive)),
                          Expanded(
                            child: Text(
                              e,
                              style: AppTextStyles.bodyXs
                                  .copyWith(color: AppColors.destructive),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16,
                color: AppColors.successForeground),
            onPressed: onDismiss,
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
}

// ── Duplicate mode dropdown ───────────────────────────────────────────────────

class _DuplicateModeDropdown extends StatelessWidget {
  final String value;
  final bool isDark;
  final AppLocalizations l10n;
  final ValueChanged<String> onChanged;

  const _DuplicateModeDropdown({
    required this.value,
    required this.isDark,
    required this.l10n,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: AppTextStyles.bodyXs.copyWith(color: fg),
          dropdownColor: bg,
          borderRadius: BorderRadius.circular(8),
          items: [
            DropdownMenuItem(
              value: 'skip',
              child: Text(l10n.duplicateSkip,
                  style: AppTextStyles.bodyXs.copyWith(color: fg)),
            ),
            DropdownMenuItem(
              value: 'update',
              child: Text(l10n.duplicateUpdate,
                  style: AppTextStyles.bodyXs.copyWith(color: fg)),
            ),
          ],
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

// ── Delete category dialog ────────────────────────────────────────────────────

class _DeleteCategoryDialog extends StatefulWidget {
  final CategoryEntity category;
  final Future<bool> Function() onDelete;
  final VoidCallback onDeleted;

  const _DeleteCategoryDialog({
    required this.category,
    required this.onDelete,
    required this.onDeleted,
  });

  static Future<void> show(
    BuildContext context, {
    required CategoryEntity category,
    required Future<bool> Function() onDelete,
    required VoidCallback onDeleted,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteCategoryDialog(
        category: category,
        onDelete: onDelete,
        onDeleted: onDeleted,
      ),
    );
  }

  @override
  State<_DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<_DeleteCategoryDialog> {
  bool _deleting = false;
  bool _failed = false;

  Future<void> _doDelete() async {
    setState(() { _deleting = true; _failed = false; });
    final ok = await widget.onDelete();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      widget.onDeleted();
    } else {
      setState(() { _deleting = false; _failed = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    final cat = widget.category;
    final hasProducts = cat.productCount > 0;
    final hasChildren = cat.children.isNotEmpty;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deleteCategory,
                  style: AppTextStyles.h5.copyWith(color: fg)),
              const SizedBox(height: AppSpacing.xs),
              // Confirm message with category name bolded
              Text.rich(
                TextSpan(
                  style: AppTextStyles.bodySm.copyWith(color: muted),
                  children: [
                    TextSpan(text: '${l10n.confirmDelete} '),
                    TextSpan(
                      text: '"${cat.name}"',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: fg),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
              ),

              // Warning: has products → can't delete
              if (hasProducts) ...[
                const SizedBox(height: AppSpacing.sm),
                _InfoBox(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.destructive,
                  text: l10n.categoryHasProducts
                      .replaceAll('{name}', cat.name)
                      .replaceAll('{count}', '${cat.productCount}'),
                ),
              ],

              // Info: children will move to top level
              if (!hasProducts && hasChildren) ...[
                const SizedBox(height: AppSpacing.sm),
                _InfoBox(
                  icon: Icons.info_outline_rounded,
                  color: AppColors.primary,
                  text: l10n.categoryChildrenMoved,
                ),
              ],

              // API error
              if (_failed) ...[
                const SizedBox(height: AppSpacing.sm),
                _InfoBox(
                  icon: Icons.error_outline_rounded,
                  color: AppColors.destructive,
                  text: l10n.categoryDeleteFailed,
                ),
              ],

              const SizedBox(height: AppSpacing.xl),
              Divider(height: 1, color: border),
              const SizedBox(height: AppSpacing.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.outline(
                    label: l10n.cancel,
                    onPressed: _deleting ? null : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton.destructive(
                    label: l10n.delete,
                    isLoading: _deleting,
                    // Disabled when category has products
                    onPressed: hasProducts || _deleting ? null : _doDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info box (reusable inline alert) ─────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoBox({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodyXs.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
