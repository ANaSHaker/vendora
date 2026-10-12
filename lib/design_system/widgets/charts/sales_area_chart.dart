import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';

class SalesDayData {
  final DateTime date;
  final double amount;

  const SalesDayData({required this.date, required this.amount});
}

class SalesAreaChart extends StatefulWidget {
  final List<SalesDayData> data;
  final String currencySymbol;
  final double? height;

  const SalesAreaChart({
    super.key,
    required this.data,
    this.currencySymbol = '\$',
    this.height,
  });

  @override
  State<SalesAreaChart> createState() => _SalesAreaChartState();
}

class _SalesAreaChartState extends State<SalesAreaChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = Theme.of(context).colorScheme.primary;
    final gridColor = isDark
        ? AppColors.darkBorder
        : AppColors.border;
    final labelColor = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    if (widget.data.isEmpty) return const SizedBox.shrink();

    final spots = widget.data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.amount);
    }).toList();

    final maxY = widget.data.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxY > 0 ? maxY * 1.2 : 100.0;

    return SizedBox(
      height: widget.height ?? 240,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (widget.data.length - 1).toDouble(),
          minY: 0,
          maxY: chartMaxY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: chartMaxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: gridColor,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                interval: chartMaxY / 4,
                getTitlesWidget: (val, _) => Text(
                  AppFormatters.compact(val, symbol: widget.currencySymbol),
                  style: AppTextStyles.caption.copyWith(color: labelColor),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _labelInterval,
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= widget.data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      AppFormatters.dateShort(widget.data[idx].date),
                      style: AppTextStyles.caption.copyWith(color: labelColor),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
          ),
          lineTouchData: LineTouchData(
            touchCallback: (event, response) {
              setState(() {
                _touchedIndex = response?.lineBarSpots?.first.x.toInt();
              });
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? AppColors.darkSurface : AppColors.surface,
              getTooltipItems: (spots) => spots.map((spot) {
                final idx = spot.x.toInt();
                final d = widget.data[idx];
                return LineTooltipItem(
                  '${AppFormatters.dateShort(d.date)}\n',
                  AppTextStyles.labelSm.copyWith(color: labelColor),
                  children: [
                    TextSpan(
                      text: AppFormatters.currency(
                        d.amount,
                        symbol: widget.currencySymbol,
                      ),
                      style: AppTextStyles.labelMd.copyWith(
                        color: lineColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: lineColor,
              isStrokeCapRound: true,
              dotData: FlDotData(
                checkToShowDot: (spot, _) => spot.x.toInt() == _touchedIndex,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: lineColor,
                  strokeColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.surface,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withValues(alpha: 0.15),
                    lineColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get _labelInterval {
    final len = widget.data.length;
    if (len <= 7) return 1;
    if (len <= 14) return 2;
    if (len <= 31) return 5;
    return 7;
  }
}
