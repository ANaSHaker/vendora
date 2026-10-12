import 'dart:io' show Process;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/api/api_client.dart' show kApiBaseUrl;
import '../../../../../core/di/injection.dart';
import '../../../../../design_system/widgets/images/app_network_image.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/buttons/app_icon_button.dart';
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/product_entities.dart';
import '../../cubit/products_cubit.dart';
import '../../cubit/products_state.dart';
import 'widgets/product_form_dialog.dart';

// ── Sort ──────────────────────────────────────────────────────────────────────

enum _SortKey { name, price }

enum _SortDir { asc, desc }

// ── Page ──────────────────────────────────────────────────────────────────────

class DesktopProductsPage extends StatelessWidget {
  const DesktopProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductsCubit(
        getProducts: getIt(),
        getCategories: getIt(),
        deleteProduct: getIt(),
        updateProduct: getIt(),
        exportProducts: getIt(),
        importProducts: getIt(),
      )..load(),
      child: const _ProductsContent(),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _ProductsContent extends StatefulWidget {
  const _ProductsContent();

  @override
  State<_ProductsContent> createState() => _ProductsContentState();
}

class _ProductsContentState extends State<_ProductsContent> {
  bool _importing = false;
  Map<String, dynamic>? _importResult;
  String _duplicateMode = 'skip';

  Future<void> _onExportDone(String? path) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (path != null) {
      AppSnackbar.success(context, path);
      if (!kIsWeb) {
        try {
          await Process.run('explorer.exe', ['/select,', path]);
        } catch (_) {}
      }
    } else {
      AppSnackbar.error(context, l10n.error);
    }
  }

  Future<void> _showImport(BuildContext context, ProductsCubit cubit) async {
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
      AppSnackbar.error(
        context,
        AppLocalizations.of(context).t('categoryImportFailed'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        final cubit = context.read<ProductsCubit>();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final muted =
            isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

        final categories = state is ProductsLoaded
            ? state.categories
            : <CategoryEntity>[];
        final filters = switch (state) {
          ProductsLoaded(:final filters) => filters,
          ProductsLoading(:final filters) => filters,
          ProductsError(:final filters) => filters,
          _ => const ProductsFilters(),
        };

        return ColoredBox(
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.products,
                          style: AppTextStyles.h4.copyWith(color: fg),
                        ),
                        if (state is ProductsLoaded)
                          Text(
                            l10n.t('productCount')
                                .replaceAll('{count}', '${state.meta.total}'),
                            style: AppTextStyles.bodySm
                                .copyWith(color: muted),
                          ),
                      ],
                    ),
                    const Spacer(),
                    // Duplicate mode — always visible
                    _DuplicateModeDropdown(
                      value: _duplicateMode,
                      isDark: isDark,
                      onChanged: (v) =>
                          setState(() => _duplicateMode = v ?? 'skip'),
                      l10n: l10n,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton.outline(
                      label: l10n.downloadTemplate,
                      size: AppButtonSize.sm,
                      leading:
                          const Icon(Icons.download_outlined, size: 14),
                      onPressed: () async {
                        final path =
                            await cubit.exportFile(template: true);
                        await _onExportDone(path);
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton.outline(
                      label: l10n.exportFile,
                      size: AppButtonSize.sm,
                      leading:
                          const Icon(Icons.upload_file_outlined, size: 14),
                      onPressed: () async {
                        final path = await cubit.exportFile();
                        await _onExportDone(path);
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton.outline(
                      label: l10n.uploadFile,
                      size: AppButtonSize.sm,
                      isLoading: _importing,
                      leading: const Icon(Icons.upload_outlined, size: 14),
                      onPressed: _importing
                          ? null
                          : () => _showImport(context, cubit),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton.primary(
                      label: l10n.addProduct,
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.add, size: 16),
                      onPressed: () => ProductFormDialog.show(
                        context,
                        categories: categories,
                        onSaved: cubit.onProductSaved,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Filters bar ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.desktopContentPadding,
                ),
                child: _FiltersBar(
                  filters: filters,
                  categories: categories,
                  cubit: cubit,
                  l10n: l10n,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Import result banner ───────────────────────────────────
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

              // ── Table ──────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.desktopContentPadding,
                  ),
                  child: switch (state) {
                    ProductsInitial() || ProductsLoading() =>
                      const ShimmerTableRows(),
                    ProductsError(:final message, :final filters) =>
                      AppErrorWidget(
                        message: message,
                        onRetry: () => cubit.load(filters: filters),
                      ),
                    ProductsLoaded(:final products, :final filters)
                        when products.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(
                            Icons.inventory_2_outlined, size: 40),
                        message: filters.search.isNotEmpty
                            ? '${l10n.noProductsFound}: "${filters.search}"'
                            : l10n.noProductsYet,
                        subtitle: filters.search.isEmpty
                            ? l10n.noProductsYetAction
                            : null,
                        action: AppButton.primary(
                          label: l10n.addProduct,
                          onPressed: () => ProductFormDialog.show(
                            context,
                            categories: categories,
                            onSaved: cubit.onProductSaved,
                          ),
                        ),
                      ),
                    ProductsLoaded(:final products, :final meta) => Column(
                        children: [
                          Expanded(
                            child: _ProductsTable(
                              products: products,
                              categories: categories,
                              cubit: cubit,
                              isDark: isDark,
                              l10n: l10n,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPagination(
                            meta: meta,
                            onPageChanged: cubit.goToPage,
                          ),
                          const SizedBox(
                              height: AppSizes.desktopContentPadding),
                        ],
                      ),
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Filters bar ───────────────────────────────────────────────────────────────

class _FiltersBar extends StatelessWidget {
  final ProductsFilters filters;
  final List<CategoryEntity> categories;
  final ProductsCubit cubit;
  final AppLocalizations l10n;

  const _FiltersBar({
    required this.filters,
    required this.categories,
    required this.cubit,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 260,
          child: AppSearchField(
            hint: l10n.searchByNameOrSku,
            onChanged: cubit.search,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 180,
          child: AppSelectField<String>(
            hint: l10n.allCategories,
            value: filters.categoryId,
            options: categories
                .map((c) => AppSelectOption(value: c.id, label: c.name))
                .toList(),
            onChanged: cubit.filterByCategory,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 160,
          child: AppSelectField<String>(
            hint: l10n.allStatuses,
            value: filters.isActive == null
                ? 'all'
                : filters.isActive!
                    ? 'active'
                    : 'inactive',
            options: [
              AppSelectOption(value: 'all', label: l10n.filterAll),
              AppSelectOption(value: 'active', label: l10n.filterActive),
              AppSelectOption(value: 'inactive', label: l10n.filterInactive),
            ],
            onChanged: (v) => cubit.filterByStatus(
              (v == null || v == 'all') ? null : v == 'active',
            ),
          ),
        ),
      ],
    );
  }
}

// ── Products table ────────────────────────────────────────────────────────────

class _ProductsTable extends StatefulWidget {
  final List<ProductEntity> products;
  final List<CategoryEntity> categories;
  final ProductsCubit cubit;
  final bool isDark;
  final AppLocalizations l10n;

  const _ProductsTable({
    required this.products,
    required this.categories,
    required this.cubit,
    required this.isDark,
    required this.l10n,
  });

  @override
  State<_ProductsTable> createState() => _ProductsTableState();
}

class _ProductsTableState extends State<_ProductsTable> {
  _SortKey _sortKey = _SortKey.name;
  _SortDir _sortDir = _SortDir.asc;
  int? _cursor;

  List<ProductEntity> get _sorted {
    final list = List<ProductEntity>.from(widget.products);
    final dir = _sortDir == _SortDir.asc ? 1 : -1;
    list.sort((a, b) {
      switch (_sortKey) {
        case _SortKey.name:
          return a.name.compareTo(b.name) * dir;
        case _SortKey.price:
          return (a.price - b.price).sign.toInt() * dir;
      }
    });
    return list;
  }

  void _toggleSort(_SortKey key) {
    setState(() {
      if (_sortKey == key) {
        _sortDir =
            _sortDir == _SortDir.asc ? _SortDir.desc : _SortDir.asc;
      } else {
        _sortKey = key;
        _sortDir = _SortDir.asc;
      }
      _cursor = null;
    });
  }

  Future<void> _confirmDelete(
      BuildContext context, ProductEntity product) async {
    final l10n = widget.l10n;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.deleteProduct,
      message:
          '${l10n.deleteProduct} "${product.name}"? ${l10n.t('confirmRefundMessage')}',
      confirmLabel: l10n.delete,
      isDestructive: true,
      onConfirm: () {},
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await widget.cubit.deleteProduct(product.id);
    if (context.mounted) {
      ok
          ? AppSnackbar.success(context, l10n.productDeleted)
          : AppSnackbar.error(context, l10n.productDeleteFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted;
    final surface =
        widget.isDark ? AppColors.darkSurface : AppColors.surface;
    final border =
        widget.isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg =
        widget.isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final fg =
        widget.isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = widget.isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return Focus(
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          setState(() => _cursor =
              ((_cursor ?? -1) + 1).clamp(0, sorted.length - 1));
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() => _cursor =
              ((_cursor ?? sorted.length) - 1).clamp(0, sorted.length - 1));
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.enter &&
            _cursor != null) {
          final product = sorted[_cursor!];
          ProductFormDialog.show(
            context,
            editing: product,
            categories: widget.categories,
            onSaved: widget.cubit.onProductSaved,
          );
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          setState(() => _cursor = null);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                height: AppSizes.tableHeaderHeight,
                color: headerBg,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    // Offset matching thumbnail (36) + gap (8) in data rows
                    const SizedBox(width: 44),
                    _SortableHeaderCell(
                      label: widget.l10n.colName,
                      flex: 3,
                      sortKey: _SortKey.name,
                      activeSortKey: _sortKey,
                      sortDir: _sortDir,
                      onSort: _toggleSort,
                    ),
                    _HeaderCell(widget.l10n.colCategory, flex: 2),
                    SizedBox(
                      width: 90,
                      child: Text(
                        widget.l10n.colShowInStore,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.base),
                    _HeaderCell(widget.l10n.colUnit, flex: 1),
                    _SortableHeaderCell(
                      label: widget.l10n.colPrice,
                      flex: 1,
                      sortKey: _SortKey.price,
                      activeSortKey: _sortKey,
                      sortDir: _sortDir,
                      onSort: _toggleSort,
                      textAlign: TextAlign.right,
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        widget.l10n.colStatus,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 72),
                  ],
                ),
              ),
              Divider(height: 1, color: border),
              // ── Rows ────────────────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: border),
                  itemBuilder: (context, i) {
                    final product = sorted[i];
                    return _ProductRow(
                      key: ValueKey(product.id),
                      product: product,
                      fg: fg,
                      muted: muted,
                      isDark: widget.isDark,
                      isCursor: _cursor == i,
                      l10n: widget.l10n,
                      onEdit: () {
                        setState(() => _cursor = i);
                        ProductFormDialog.show(
                          context,
                          editing: product,
                          categories: widget.categories,
                          onSaved: widget.cubit.onProductSaved,
                        );
                      },
                      onDelete: () => _confirmDelete(context, product),
                      onToggleOnline: (v) =>
                          widget.cubit.toggleOnline(product.id, v),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;

  const _HeaderCell(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label, style: AppTextStyles.tableHeader),
    );
  }
}

class _SortableHeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final _SortKey sortKey;
  final _SortKey activeSortKey;
  final _SortDir sortDir;
  final void Function(_SortKey) onSort;
  final TextAlign textAlign;

  const _SortableHeaderCell({
    required this.label,
    required this.flex,
    required this.sortKey,
    required this.activeSortKey,
    required this.sortDir,
    required this.onSort,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = sortKey == activeSortKey;
    // Price header is absolute-right (TextAlign.right in data).
    // All other headers use directional start (= right in RTL, left in LTR),
    // matching the natural text alignment of data cells.
    final AlignmentGeometry alignment = textAlign == TextAlign.right
        ? Alignment.centerRight
        : AlignmentDirectional.centerStart;

    return Expanded(
      flex: flex,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onSort(sortKey),
          child: Align(
            alignment: alignment,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTextStyles.tableHeader),
                if (isActive) ...[
                  const SizedBox(width: 2),
                  Icon(
                    sortDir == _SortDir.asc
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 14,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Product row ───────────────────────────────────────────────────────────────

class _ProductRow extends StatefulWidget {
  final ProductEntity product;
  final Color fg;
  final Color muted;
  final bool isDark;
  final bool isCursor;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleOnline;

  const _ProductRow({
    super.key,
    required this.product,
    required this.fg,
    required this.muted,
    required this.isDark,
    this.isCursor = false,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleOnline,
  });

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverBg = widget.isDark
        ? AppColors.darkMuted.withValues(alpha: 0.6)
        : AppColors.primaryMuted.withValues(alpha: 0.5);
    final cursorBg =
        widget.isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final showActions = _hovered || widget.isCursor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onEdit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: AppSizes.tableRowHeight,
          color: widget.isCursor
              ? cursorBg
              : (_hovered ? hoverBg : Colors.transparent),
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              // Thumbnail
              _ProductThumbnail(
                imageUrl: widget.product.imageUrl,
                isDark: widget.isDark,
              ),
              const SizedBox(width: AppSpacing.sm),
              // Name + has_options badge + sku below
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.product.name,
                            style: AppTextStyles.labelSm
                                .copyWith(color: widget.fg),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.product.hasOptions) ...[
                          const SizedBox(width: 4),
                          const _OptionsBadge(),
                        ],
                      ],
                    ),
                    if (widget.product.sku != null)
                      Text(
                        widget.product.sku!,
                        style: AppTextStyles.bodyXs
                            .copyWith(color: widget.muted),
                      ),
                  ],
                ),
              ),
              // Category
              Expanded(
                flex: 2,
                child: Text(
                  widget.product.categoryName ?? '—',
                  style:
                      AppTextStyles.tableCell.copyWith(color: widget.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Show In Store — inline online toggle
              SizedBox(
                width: 90,
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // absorb tap — checkbox handles its own
                    child: Checkbox(
                      value: widget.product.isOnline,
                      onChanged: (v) => widget.onToggleOnline(v ?? false),
                      activeColor: AppColors.primary,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              // Unit
              Expanded(
                child: Text(
                  widget.product.unit ?? '—',
                  style:
                      AppTextStyles.tableCell.copyWith(color: widget.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Price
              Expanded(
                child: Text(
                  AppFormatters.currency(widget.product.price),
                  style: AppTextStyles.numeric.copyWith(color: widget.fg),
                  textAlign: TextAlign.right,
                ),
              ),
              // Status — dot + text (matching Vue)
              SizedBox(
                width: 80,
                child: Center(
                  child: _StatusDot(
                    active: widget.product.isActive,
                    fg: widget.fg,
                    muted: widget.muted,
                    l10n: widget.l10n,
                  ),
                ),
              ),
              // Actions — hover-only
              SizedBox(
                width: 72,
                child: AnimatedOpacity(
                  opacity: showActions ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 120),
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
      ),
    );
  }
}

// ── Product thumbnail ─────────────────────────────────────────────────────────

class _ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final bool isDark;

  const _ProductThumbnail({this.imageUrl, required this.isDark});

  static String? _resolve(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '$kApiBaseUrl${raw.startsWith('/') ? '' : '/'}$raw';
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkMuted : AppColors.muted;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final url = _resolve(imageUrl);

    if (url != null) {
      return AppNetworkImage(
        url: url,
        width: 36,
        height: 36,
        borderRadius: 6,
        fallbackColor: bg,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 36,
        height: 36,
        child: ColoredBox(
          color: bg,
          child: Center(
            child: Icon(Icons.inventory_2_outlined, size: 16, color: muted),
          ),
        ),
      ),
    );
  }
}

// ── Status dot (Vue-style: dot + text, no background) ────────────────────────

class _StatusDot extends StatelessWidget {
  final bool active;
  final Color fg;
  final Color muted;
  final AppLocalizations l10n;

  const _StatusDot({
    required this.active,
    required this.fg,
    required this.muted,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.primary : muted,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          active ? l10n.active : l10n.inactive,
          style: AppTextStyles.bodyXs.copyWith(
            color: active ? fg : muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Options badge ─────────────────────────────────────────────────────────────

class _OptionsBadge extends StatelessWidget {
  const _OptionsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryMuted,
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tune_rounded,
              size: 8, color: AppColors.primary),
          const SizedBox(width: 2),
          Text(
            AppLocalizations.of(context).t('optionsBadge'),
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
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
    final errors =
        (result['errors'] as List?)?.cast<String>() ?? <String>[];
    final summary = l10n.importCounts
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
                  l10n.importSummary,
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.successForeground),
                ),
                Text(
                  summary,
                  style: AppTextStyles.bodyXs
                      .copyWith(color: AppColors.successForeground),
                ),
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
                              child: Text(e,
                                  style: AppTextStyles.bodyXs.copyWith(
                                      color: AppColors.destructive)),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.successForeground,
            ),
            onPressed: onDismiss,
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
}

// ── Duplicate mode dropdown — always visible in toolbar ───────────────────────

class _DuplicateModeDropdown extends StatelessWidget {
  final String value;
  final bool isDark;
  final ValueChanged<String?> onChanged;
  final AppLocalizations l10n;

  const _DuplicateModeDropdown({
    required this.value,
    required this.isDark,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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
          onChanged: onChanged,
        ),
      ),
    );
  }
}
