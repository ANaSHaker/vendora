import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';

class BookingInlineCalendar extends StatefulWidget {
  final String selected;
  final void Function(String date) onSelect;
  final List<String> closedDates;
  final int maxFutureDays;
  final Color primaryColor;
  final void Function(int year, int month)? onMonthChanged;

  const BookingInlineCalendar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.closedDates,
    required this.maxFutureDays,
    required this.primaryColor,
    this.onMonthChanged,
  });

  @override
  State<BookingInlineCalendar> createState() => _BookingInlineCalendarState();
}

class _BookingInlineCalendarState extends State<BookingInlineCalendar> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final init = widget.selected.isNotEmpty
        ? DateTime.tryParse('${widget.selected}T00:00:00') ?? DateTime.now()
        : DateTime.now();
    _year  = init.year;
    _month = init.month;
  }

  @override
  void didUpdateWidget(BookingInlineCalendar old) {
    super.didUpdateWidget(old);
    if (widget.selected.isNotEmpty && widget.selected != old.selected) {
      final d = DateTime.tryParse('${widget.selected}T00:00:00');
      if (d != null) {
        setState(() { _year = d.year; _month = d.month; });
      }
    }
  }

  void _prev() {
    setState(() {
      if (_month == 1) { _year--; _month = 12; } else _month--;
    });
    widget.onMonthChanged?.call(_year, _month);
  }

  void _next() {
    setState(() {
      if (_month == 12) { _year++; _month = 1; } else _month++;
    });
    widget.onMonthChanged?.call(_year, _month);
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? AppColors.darkSurface    : AppColors.surface;
    final border   = isDark ? AppColors.darkBorder     : AppColors.border;
    final fg       = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted    = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary  = widget.primaryColor;

    final today     = _todayStr();
    final maxDate   = _maxDateStr(widget.maxFutureDays);
    final closedSet = widget.closedDates.toSet();

    final firstWeekday = DateTime(_year, _month, 1).weekday % 7; // 0=Sun
    final daysInMonth  = DateTime(_year, _month + 1, 0).day;
    final locale       = Localizations.localeOf(context).languageCode;
    final monthLabel   = DateFormat('MMMM yyyy', locale).format(DateTime(_year, _month));
    final dayNames     = _weekDayNames(locale);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                _NavBtn(icon: Icons.chevron_left_rounded, onTap: _prev, fg: muted),
                Expanded(
                  child: Text(monthLabel, textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(color: fg, fontWeight: FontWeight.w700)),
                ),
                _NavBtn(icon: Icons.chevron_right_rounded, onTap: _next, fg: muted),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          // Day headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
            child: Row(
              children: dayNames.map((d) => Expanded(
                child: Text(d, textAlign: TextAlign.center,
                  style: AppTextStyles.labelSm.copyWith(color: muted, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ),
          // Days grid — fixed 34px cell height via mainAxisExtent
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.sm),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                mainAxisExtent: 34,
              ),
              itemCount: firstWeekday + daysInMonth,
              itemBuilder: (_, index) {
                if (index < firstWeekday) return const SizedBox.shrink();
                final day     = index - firstWeekday + 1;
                final dateStr = '$_year-${_month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                final isPast     = dateStr.compareTo(today) < 0;
                final isTooFar   = dateStr.compareTo(maxDate) > 0;
                final isClosed   = closedSet.contains(dateStr);
                final isDisabled = isPast || isTooFar || isClosed;
                final isToday    = dateStr == today;
                final isSelected = dateStr == widget.selected;

                return _DayCell(
                  day: day,
                  isSelected: isSelected,
                  isToday: isToday,
                  isDisabled: isDisabled,
                  primaryColor: primary,
                  fg: fg,
                  muted: muted,
                  onTap: isDisabled ? null : () => widget.onSelect(dateStr),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _maxDateStr(int days) {
    final max = DateTime.now().add(Duration(days: days));
    return '${max.year}-${max.month.toString().padLeft(2, '0')}-${max.day.toString().padLeft(2, '0')}';
  }

  List<String> _weekDayNames(String locale) {
    final base = DateTime(2024, 1, 7); // known Sunday
    return List.generate(7, (i) {
      final d = base.add(Duration(days: i));
      return DateFormat('EEE', locale).format(d).substring(0, 2);
    });
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color fg;
  const _NavBtn({required this.icon, required this.onTap, required this.fg});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32, height: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: fg),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool isDisabled;
  final Color primaryColor;
  final Color fg;
  final Color muted;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day, required this.isSelected, required this.isToday,
    required this.isDisabled, required this.primaryColor,
    required this.fg, required this.muted, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? bg;
    Color textColor;
    Border? border;

    if (isSelected) {
      bg = primaryColor;
      textColor = Colors.white;
    } else if (isToday && !isDisabled) {
      bg = null;
      border = Border.all(color: primaryColor.withValues(alpha: 0.7), width: 1.5);
      textColor = primaryColor;
    } else if (isDisabled) {
      textColor = muted.withValues(alpha: 0.35);
    } else {
      textColor = fg;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: border,
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
              decoration: isDisabled ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }
}
