import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_border_radius.dart';
import '../feedback/app_loading.dart';
import '../feedback/app_empty_state.dart';

class AppTableColumn {
  final String label;
  final double? width;
  final ColumnSize size;
  final bool numeric;
  final bool sortable;

  const AppTableColumn({
    required this.label,
    this.width,
    this.size = ColumnSize.M,
    this.numeric = false,
    this.sortable = false,
  });
}

class AppDataTable<T> extends StatelessWidget {
  final List<AppTableColumn> columns;
  final List<T> rows;
  final DataRow2 Function(T item, int index) rowBuilder;
  final bool isLoading;
  final String emptyMessage;
  final String? emptySubtitle;
  final Widget? emptyAction;
  final int? sortColumnIndex;
  final bool sortAscending;
  final DataColumnSortCallback? onSort;
  final double minWidth;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.rowBuilder,
    this.isLoading = false,
    this.emptyMessage = 'No data found',
    this.emptySubtitle,
    this.emptyAction,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.minWidth = 600,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.muted;
    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    if (isLoading) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: borderColor),
        ),
        child: const AppLoadingInline(height: 300),
      );
    }

    if (rows.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl4),
        child: AppEmptyState(
          message: emptyMessage,
          subtitle: emptySubtitle,
          action: emptyAction,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: DataTable2(
        minWidth: minWidth,
        columnSpacing: AppSpacing.base,
        horizontalMargin: AppSpacing.base,
        headingRowHeight: AppSizes.tableHeaderHeight,
        dataRowHeight: AppSizes.tableRowHeight,
        dividerThickness: 1,
        headingRowColor: WidgetStateProperty.all(headerBg),
        border: TableBorder(
          horizontalInside: BorderSide(color: borderColor),
        ),
        sortColumnIndex: sortColumnIndex,
        sortAscending: sortAscending,
        columns: columns
            .map(
              (col) => DataColumn2(
                label: Text(
                  col.label.toUpperCase(),
                  style: AppTextStyles.tableHeader.copyWith(color: muted),
                ),
                size: col.size,
                fixedWidth: col.width,
                numeric: col.numeric,
                onSort: col.sortable ? onSort : null,
              ),
            )
            .toList(),
        rows: rows
            .asMap()
            .entries
            .map((e) => rowBuilder(e.value, e.key))
            .toList(),
      ),
    );
  }
}

DataCell appCell(
  String text, {
  TextStyle? style,
  bool isDark = false,
  Color? color,
}) {
  final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
  return DataCell(
    Text(
      text,
      style: (style ?? AppTextStyles.tableCell).copyWith(
        color: color ?? fg,
      ),
      overflow: TextOverflow.ellipsis,
    ),
  );
}

DataCell appCellWidget(Widget child) => DataCell(child);
