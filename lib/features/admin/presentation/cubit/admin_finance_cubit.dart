import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/admin_usecases.dart';
import 'admin_finance_state.dart';

class AdminFinanceCubit extends Cubit<AdminFinanceState> {
  final GetAdminFinanceSummaryUseCase _getSummary;
  final GetAdminFinanceEntriesUseCase _getEntries;
  final CreateAdminFinanceEntryUseCase _createEntry;
  final UpdateAdminFinanceEntryUseCase _updateEntry;
  final VoidAdminFinanceEntryUseCase _voidEntry;
  final GetAdminFinanceCategoriesUseCase _getCategories;
  final CreateAdminFinanceCategoryUseCase _createCategory;
  final UpdateAdminFinanceCategoryUseCase _updateCategory;

  AdminFinanceCubit({
    required GetAdminFinanceSummaryUseCase getSummary,
    required GetAdminFinanceEntriesUseCase getEntries,
    required CreateAdminFinanceEntryUseCase createEntry,
    required UpdateAdminFinanceEntryUseCase updateEntry,
    required VoidAdminFinanceEntryUseCase voidEntry,
    required GetAdminFinanceCategoriesUseCase getCategories,
    required CreateAdminFinanceCategoryUseCase createCategory,
    required UpdateAdminFinanceCategoryUseCase updateCategory,
  })  : _getSummary = getSummary,
        _getEntries = getEntries,
        _createEntry = createEntry,
        _updateEntry = updateEntry,
        _voidEntry = voidEntry,
        _getCategories = getCategories,
        _createCategory = createCategory,
        _updateCategory = updateCategory,
        super(const AdminFinanceInitial());

  Future<void> load() async {
    emit(const AdminFinanceLoading());
    await _fetchAll();
  }

  Future<void> _fetchAll({
    String tab = 'all',
    String dateFrom = '',
    String dateTo = '',
    String categoryFilter = '',
    String statusFilter = '',
    String search = '',
  }) async {
    final summaryRes = await _getSummary(
      from: dateFrom.isNotEmpty ? dateFrom : null,
      to: dateTo.isNotEmpty ? dateTo : null,
    );
    if (summaryRes.isLeft()) {
      emit(AdminFinanceError(summaryRes.fold((f) => f.message, (_) => '')));
      return;
    }

    final entriesRes = await _getEntries(
      type: tab == 'all' ? null : tab,
      from: dateFrom.isNotEmpty ? dateFrom : null,
      to: dateTo.isNotEmpty ? dateTo : null,
      categoryId: categoryFilter.isNotEmpty ? categoryFilter : null,
      status: statusFilter.isNotEmpty ? statusFilter : null,
      search: search.isNotEmpty ? search : null,
    );
    if (entriesRes.isLeft()) {
      emit(AdminFinanceError(entriesRes.fold((f) => f.message, (_) => '')));
      return;
    }

    final catsRes = await _getCategories();
    if (catsRes.isLeft()) {
      emit(AdminFinanceError(catsRes.fold((f) => f.message, (_) => '')));
      return;
    }

    final summary = summaryRes.getOrElse(() => throw Exception());
    final entries = entriesRes.getOrElse(() => throw Exception());
    final categories = catsRes.getOrElse(() => throw Exception());

    emit(AdminFinanceLoaded(
      summary: summary,
      entries: entries,
      categories: categories,
      tab: tab,
      dateFrom: dateFrom,
      dateTo: dateTo,
      categoryFilter: categoryFilter,
      statusFilter: statusFilter,
      search: search,
    ));
  }

  Future<void> setTab(String tab) async {
    final s = state;
    if (s is! AdminFinanceLoaded) return;
    emit(s.copyWith(tab: tab, categoryFilter: '', search: ''));
    if (tab != 'categories') {
      await _reloadEntries(tab: tab);
    }
  }

  Future<void> applyFilters({
    String? dateFrom,
    String? dateTo,
    String? categoryFilter,
    String? statusFilter,
    String? search,
  }) async {
    final s = state;
    if (s is! AdminFinanceLoaded) return;
    final newFrom = dateFrom ?? s.dateFrom;
    final newTo = dateTo ?? s.dateTo;
    final newCat = categoryFilter ?? s.categoryFilter;
    final newStatus = statusFilter ?? s.statusFilter;
    final newSearch = search ?? s.search;
    emit(s.copyWith(
      dateFrom: newFrom,
      dateTo: newTo,
      categoryFilter: newCat,
      statusFilter: newStatus,
      search: newSearch,
    ));
    await _reloadEntries(
      tab: s.tab,
      dateFrom: newFrom,
      dateTo: newTo,
      categoryFilter: newCat,
      statusFilter: newStatus,
      search: newSearch,
    );
  }

  Future<void> _reloadEntries({
    required String tab,
    String dateFrom = '',
    String dateTo = '',
    String categoryFilter = '',
    String statusFilter = '',
    String search = '',
  }) async {
    if (tab == 'categories') return;
    final s = state;
    if (s is! AdminFinanceLoaded) return;
    final entriesRes = await _getEntries(
      type: tab == 'all' ? null : tab,
      from: dateFrom.isNotEmpty ? dateFrom : null,
      to: dateTo.isNotEmpty ? dateTo : null,
      categoryId: categoryFilter.isNotEmpty ? categoryFilter : null,
      status: statusFilter.isNotEmpty ? statusFilter : null,
      search: search.isNotEmpty ? search : null,
    );
    entriesRes.fold(
      (f) => emit(s.copyWith(saveError: f.message)),
      (entries) => emit(s.copyWith(entries: entries)),
    );
  }

  Future<void> _reloadSummary() async {
    final s = state;
    if (s is! AdminFinanceLoaded) return;
    final res = await _getSummary(
      from: s.dateFrom.isNotEmpty ? s.dateFrom : null,
      to: s.dateTo.isNotEmpty ? s.dateTo : null,
    );
    res.fold((_) {}, (summary) => emit(s.copyWith(summary: summary)));
  }

  Future<bool> saveEntry({
    String? id,
    required Map<String, dynamic> data,
  }) async {
    final s = state;
    if (s is! AdminFinanceLoaded) return false;
    if (s.isSaving) return false;
    emit(s.copyWith(isSaving: true, saveSuccess: false, clearSaveError: true));
    final res = id != null
        ? await _updateEntry(id, data)
        : await _createEntry(data);
    return res.fold(
      (f) {
        emit(s.copyWith(isSaving: false, saveError: f.message));
        return false;
      },
      (_) async {
        await _reloadEntries(
          tab: s.tab,
          dateFrom: s.dateFrom,
          dateTo: s.dateTo,
          categoryFilter: s.categoryFilter,
          statusFilter: s.statusFilter,
          search: s.search,
        );
        await _reloadSummary();
        final ns = state;
        if (ns is AdminFinanceLoaded) {
          emit(ns.copyWith(isSaving: false, saveSuccess: true));
        }
        return true;
      },
    );
  }

  Future<bool> voidEntry(String id) async {
    final s = state;
    if (s is! AdminFinanceLoaded) return false;
    final res = await _voidEntry(id);
    return res.fold(
      (f) {
        emit(s.copyWith(saveError: f.message));
        return false;
      },
      (_) async {
        await _reloadEntries(
          tab: s.tab,
          dateFrom: s.dateFrom,
          dateTo: s.dateTo,
          categoryFilter: s.categoryFilter,
          statusFilter: s.statusFilter,
          search: s.search,
        );
        await _reloadSummary();
        return true;
      },
    );
  }

  Future<bool> saveCategory({
    String? id,
    required Map<String, dynamic> data,
  }) async {
    final s = state;
    if (s is! AdminFinanceLoaded) return false;
    if (s.isSaving) return false;
    emit(s.copyWith(isSaving: true, saveSuccess: false, clearSaveError: true));
    final res = id != null
        ? await _updateCategory(id, data)
        : await _createCategory(data);
    return res.fold(
      (f) {
        emit(s.copyWith(isSaving: false, saveError: f.message));
        return false;
      },
      (_) async {
        final catsRes = await _getCategories();
        catsRes.fold((_) {}, (cats) {
          final ns = state;
          if (ns is AdminFinanceLoaded) {
            emit(ns.copyWith(
              isSaving: false,
              saveSuccess: true,
              categories: cats,
            ));
          }
        });
        return true;
      },
    );
  }

  void clearSaveStatus() {
    final s = state;
    if (s is AdminFinanceLoaded) {
      emit(s.copyWith(saveSuccess: false, clearSaveError: true));
    }
  }
}
