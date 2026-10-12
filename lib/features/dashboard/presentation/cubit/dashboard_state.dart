import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/dashboard_entities.dart';

enum DashboardPeriodFilter { today, week, month, custom }

class DashboardFilters extends Equatable {
  final DashboardPeriodFilter period;
  final String? branchId;
  final DateTime? customFrom;
  final DateTime? customTo;

  const DashboardFilters({
    required this.period,
    this.branchId,
    this.customFrom,
    this.customTo,
  });

  DateTime get dateFrom {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (period) {
      DashboardPeriodFilter.today =>
        today.subtract(const Duration(days: 1)),
      DashboardPeriodFilter.week =>
        today.subtract(const Duration(days: 7)),
      DashboardPeriodFilter.month =>
        today.subtract(const Duration(days: 30)),
      DashboardPeriodFilter.custom =>
        customFrom ?? today.subtract(const Duration(days: 30)),
    };
  }

  DateTime get dateTo {
    final now = DateTime.now();
    if (period == DashboardPeriodFilter.custom && customTo != null) {
      return DateTime(customTo!.year, customTo!.month, customTo!.day);
    }
    return DateTime(now.year, now.month, now.day);
  }

  /// Short label shown under each chip: "May 11" / "May 5 – 11" / "1 – 11 مايو"
  /// [locale] should be the BCP-47 language code: 'ar', 'en', 'fr', 'de', 'it'.
  String chipDateLabelFor(String locale) {
    final from = dateFrom;
    final to = dateTo;
    final sameDay = from.year == to.year &&
        from.month == to.month &&
        from.day == to.day;
    try {
      if (sameDay) return DateFormat.MMMd(locale).format(from);
      if (from.year == to.year && from.month == to.month) {
        // Same-month range: show day numbers + abbreviated month once.
        // Arabic is RTL: "5 – 11 مايو"; Latin scripts: "May 5 – 11"
        final monthAbbr = DateFormat('MMM', locale).format(from);
        if (locale == 'ar') {
          return '${from.day} – ${to.day} $monthAbbr';
        }
        return '$monthAbbr ${from.day} – ${to.day}';
      }
      // Cross-month range
      return '${DateFormat.MMMd(locale).format(from)} – ${DateFormat.MMMd(locale).format(to)}';
    } catch (_) {
      // Fallback to English if the locale's data isn't loaded
      if (sameDay) return DateFormat.MMMd('en').format(from);
      if (from.month == to.month) {
        return '${DateFormat('MMM', 'en').format(from)} ${from.day} – ${to.day}';
      }
      return '${DateFormat.MMMd('en').format(from)} – ${DateFormat.MMMd('en').format(to)}';
    }
  }

  DashboardFilters copyWith({
    DashboardPeriodFilter? period,
    String? branchId,
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    final newPeriod = period ?? this.period;
    final isCustom = newPeriod == DashboardPeriodFilter.custom;
    return DashboardFilters(
      period: newPeriod,
      branchId: branchId ?? this.branchId,
      customFrom: isCustom ? (customFrom ?? this.customFrom) : null,
      customTo: isCustom ? (customTo ?? this.customTo) : null,
    );
  }

  @override
  List<Object?> get props => [period, branchId, customFrom, customTo];
}

abstract class DashboardState extends Equatable {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();

  @override
  List<Object?> get props => [];
}

class DashboardLoading extends DashboardState {
  final DashboardFilters filters;

  const DashboardLoading({required this.filters});

  @override
  List<Object?> get props => [filters];
}

class DashboardLoaded extends DashboardState {
  final DashboardDataEntity data;
  final DashboardFilters filters;

  const DashboardLoaded({required this.data, required this.filters});

  @override
  List<Object?> get props => [data, filters];
}

class DashboardError extends DashboardState {
  final String message;
  final DashboardFilters filters;

  const DashboardError({required this.message, required this.filters});

  @override
  List<Object?> get props => [message, filters];
}
