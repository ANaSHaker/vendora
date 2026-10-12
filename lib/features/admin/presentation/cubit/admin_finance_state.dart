import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_finance_entity.dart';
import '../../../../core/api/api_response.dart';

abstract class AdminFinanceState extends Equatable {
  const AdminFinanceState();
  @override
  List<Object?> get props => [];
}

class AdminFinanceInitial extends AdminFinanceState {
  const AdminFinanceInitial();
}

class AdminFinanceLoading extends AdminFinanceState {
  const AdminFinanceLoading();
}

class AdminFinanceLoaded extends AdminFinanceState {
  final AdminFinanceSummaryEntity summary;
  final PaginatedResponse<AdminFinanceEntryEntity> entries;
  final List<AdminFinanceCategoryEntity> categories;
  final String tab; // 'all' | 'revenue' | 'expense' | 'categories'
  final String dateFrom;
  final String dateTo;
  final String categoryFilter;
  final String statusFilter;
  final String search;
  final bool isSaving;
  final bool saveSuccess;
  final String? saveError;

  const AdminFinanceLoaded({
    required this.summary,
    required this.entries,
    required this.categories,
    this.tab = 'all',
    this.dateFrom = '',
    this.dateTo = '',
    this.categoryFilter = '',
    this.statusFilter = '',
    this.search = '',
    this.isSaving = false,
    this.saveSuccess = false,
    this.saveError,
  });

  AdminFinanceLoaded copyWith({
    AdminFinanceSummaryEntity? summary,
    PaginatedResponse<AdminFinanceEntryEntity>? entries,
    List<AdminFinanceCategoryEntity>? categories,
    String? tab,
    String? dateFrom,
    String? dateTo,
    String? categoryFilter,
    String? statusFilter,
    String? search,
    bool? isSaving,
    bool? saveSuccess,
    String? saveError,
    bool clearSaveError = false,
  }) {
    return AdminFinanceLoaded(
      summary: summary ?? this.summary,
      entries: entries ?? this.entries,
      categories: categories ?? this.categories,
      tab: tab ?? this.tab,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      search: search ?? this.search,
      isSaving: isSaving ?? this.isSaving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
    );
  }

  @override
  List<Object?> get props => [
        summary, entries, categories, tab,
        dateFrom, dateTo, categoryFilter, statusFilter, search,
        isSaving, saveSuccess, saveError,
      ];
}

class AdminFinanceError extends AdminFinanceState {
  final String message;
  const AdminFinanceError(this.message);
  @override
  List<Object?> get props => [message];
}
