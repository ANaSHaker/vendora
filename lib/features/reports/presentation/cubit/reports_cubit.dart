import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/usecases/reports_usecases.dart';
import '../../../../core/utils/file_saver.dart';
import '../../../../design_system/widgets/inputs/app_date_range_picker.dart';
import 'reports_state.dart';

// ─── Sales Report Cubit ───────────────────────────────────────────────────────

class SalesReportCubit extends Cubit<SalesReportState> {
  final GetSalesReportUseCase _getSalesReport;
  final GetSalesOrdersUseCase _getSalesOrders;
  final ExportReportUseCase _export;

  SalesReportCubit(this._getSalesReport, this._getSalesOrders, this._export)
      : super(SalesReportInitial(ReportFilters.thisMonth()));

  Future<void> load({ReportFilters? filters}) async {
    final f = filters ?? ReportFilters.thisMonth();
    emit(SalesReportLoading(f));
    try {
      final data = await _getSalesReport(
        dateFrom: f.dateFrom,
        dateTo: f.dateTo,
        branchId: f.branchId,
        paymentMethod: f.paymentMethod,
      );
      final ordersResult = await _getSalesOrders(
        page: 1,
        dateFrom: f.dateFrom,
        dateTo: f.dateTo,
        branchId: f.branchId,
        paymentMethod: f.paymentMethod,
      );
      emit(SalesReportLoaded(
        data: data,
        filters: f,
        orders: ordersResult.data,
        ordersMeta: ordersResult.meta,
      ));
    } catch (e) {
      emit(SalesReportError(message: e.toString(), filters: f));
    }
  }

  Future<void> loadOrdersPage(int page) async {
    if (state is! SalesReportLoaded) return;
    final loaded = state as SalesReportLoaded;
    emit(loaded.copyWith(ordersLoading: true));
    try {
      final result = await _getSalesOrders(
        page: page,
        dateFrom: loaded.filters.dateFrom,
        dateTo: loaded.filters.dateTo,
        branchId: loaded.filters.branchId,
        paymentMethod: loaded.filters.paymentMethod,
      );
      if (state is SalesReportLoaded) {
        emit((state as SalesReportLoaded).copyWith(
          orders: result.data,
          ordersMeta: result.meta,
          ordersLoading: false,
        ));
      }
    } catch (_) {
      if (state is SalesReportLoaded) {
        emit((state as SalesReportLoaded).copyWith(ordersLoading: false));
      }
    }
  }

  void changePreset(DateRangePreset preset) {
    final now = DateTime.now();
    final (from, to) = switch (preset) {
      DateRangePreset.today => (DateTime(now.year, now.month, now.day), now),
      DateRangePreset.thisWeek => (now.subtract(Duration(days: now.weekday - 1)), now),
      DateRangePreset.thisMonth => (DateTime(now.year, now.month, 1), now),
      DateRangePreset.custom => (_currentFilters.dateFrom, _currentFilters.dateTo),
    };
    load(filters: _currentFilters.copyWith(dateFrom: from, dateTo: to, preset: preset));
  }

  void setCustomRange(DateTime from, DateTime to) {
    load(filters: _currentFilters.copyWith(
      dateFrom: from,
      dateTo: to,
      preset: DateRangePreset.custom,
    ));
  }

  void filterByBranch(String? branchId) {
    load(filters: branchId == null
        ? _currentFilters.copyWith(clearBranch: true)
        : _currentFilters.copyWith(branchId: branchId));
  }

  void filterByPaymentMethod(String? method) {
    load(filters: method == null
        ? _currentFilters.copyWith(clearPaymentMethod: true)
        : _currentFilters.copyWith(paymentMethod: method));
  }

  Future<String?> exportFile(String endpoint) async {
    try {
      final f = _currentFilters;
      final dateFmt = DateFormat('yyyy-MM-dd', 'en_US');
      final params = <String, dynamic>{
        'date_from': dateFmt.format(f.dateFrom),
        'date_to': dateFmt.format(f.dateTo),
        if (f.branchId != null) 'branch_id': f.branchId,
        if (f.paymentMethod != null) 'payment_method': f.paymentMethod,
      };
      final bytes = await _export(endpoint, params);
      return _saveFile(bytes, endpoint);
    } catch (e) {
      debugPrint('[Export:Sales] exportFile failed: $e');
      rethrow;
    }
  }

  ReportFilters get _currentFilters => switch (state) {
        SalesReportLoaded(:final filters) => filters,
        SalesReportLoading(:final filters) => filters,
        SalesReportError(:final filters) => filters,
        SalesReportInitial(:final filters) => filters,
      };
}

// ─── Inventory Report Cubit ───────────────────────────────────────────────────

class InventoryReportCubit extends Cubit<InventoryReportState> {
  final GetInventoryTabReportUseCase _getReport;
  final ExportReportUseCase _export;

  InventoryReportCubit(this._getReport, this._export)
      : super(InventoryReportInitial(ReportFilters.thisMonth()));

  Future<void> load({ReportFilters? filters, InventoryReportTab? tab}) async {
    final f = filters ?? ReportFilters.thisMonth();
    final t = tab ?? _currentTab;
    emit(InventoryReportLoading(f, activeTab: t));
    try {
      final data = await _getReport(
        branchId: f.branchId,
        warehouseId: f.warehouseId,
        productId: f.productId,
        movementType: f.movementType,
        dateFrom: f.dateFrom,
        dateTo: f.dateTo,
      );
      emit(InventoryReportLoaded(data: data, filters: f, activeTab: t));
    } catch (e) {
      emit(InventoryReportError(message: e.toString(), filters: f));
    }
  }

  void switchTab(InventoryReportTab tab) {
    if (state is InventoryReportLoaded) {
      emit((state as InventoryReportLoaded).copyWith(activeTab: tab));
    }
  }

  void changePreset(DateRangePreset preset) {
    final now = DateTime.now();
    final (from, to) = switch (preset) {
      DateRangePreset.today => (DateTime(now.year, now.month, now.day), now),
      DateRangePreset.thisWeek => (now.subtract(Duration(days: now.weekday - 1)), now),
      DateRangePreset.thisMonth => (DateTime(now.year, now.month, 1), now),
      DateRangePreset.custom => (_currentFilters.dateFrom, _currentFilters.dateTo),
    };
    load(filters: _currentFilters.copyWith(dateFrom: from, dateTo: to, preset: preset));
  }

  void setCustomRange(DateTime from, DateTime to) {
    load(filters: _currentFilters.copyWith(
      dateFrom: from, dateTo: to, preset: DateRangePreset.custom,
    ));
  }

  void filterByWarehouse(String? warehouseId) {
    load(filters: warehouseId == null
        ? _currentFilters.copyWith(clearWarehouse: true)
        : _currentFilters.copyWith(warehouseId: warehouseId));
  }

  void filterByMovementType(String? type) {
    load(filters: type == null
        ? _currentFilters.copyWith(clearMovementType: true)
        : _currentFilters.copyWith(movementType: type));
  }

  Future<String?> exportFile(String endpoint) async {
    try {
      final f = _currentFilters;
      final dateFmt = DateFormat('yyyy-MM-dd', 'en_US');
      final bytes = await _export(endpoint, {
        'date_from': dateFmt.format(f.dateFrom),
        'date_to': dateFmt.format(f.dateTo),
        if (f.warehouseId != null) 'warehouse_id': f.warehouseId,
      });
      return _saveFile(bytes, endpoint);
    } catch (e) {
      debugPrint('[Export:Inventory] exportFile failed: $e');
      rethrow;
    }
  }

  InventoryReportTab get _currentTab => state is InventoryReportLoaded
      ? (state as InventoryReportLoaded).activeTab
      : InventoryReportTab.stock;

  ReportFilters get _currentFilters => switch (state) {
        InventoryReportLoaded(:final filters) => filters,
        InventoryReportLoading(:final filters) => filters,
        InventoryReportError(:final filters) => filters,
        InventoryReportInitial(:final filters) => filters,
      };
}

// ─── Financial Report Cubit ───────────────────────────────────────────────────

class FinancialReportCubit extends Cubit<FinancialReportState> {
  final GetFinancialReportUseCase _getReport;
  final ExportReportUseCase _export;

  FinancialReportCubit(this._getReport, this._export)
      : super(FinancialReportInitial(ReportFilters.thisMonth()));

  Future<void> load({ReportFilters? filters}) async {
    final f = filters ?? ReportFilters.thisMonth();
    emit(FinancialReportLoading(f));
    try {
      final data = await _getReport(
        dateFrom: f.dateFrom,
        dateTo: f.dateTo,
        branchId: f.branchId,
        warehouseId: f.warehouseId,
        productId: f.productId,
      );
      emit(FinancialReportLoaded(data: data, filters: f));
    } catch (e) {
      emit(FinancialReportError(message: e.toString(), filters: f));
    }
  }

  void changePreset(DateRangePreset preset) {
    final now = DateTime.now();
    final (from, to) = switch (preset) {
      DateRangePreset.today => (DateTime(now.year, now.month, now.day), now),
      DateRangePreset.thisWeek => (now.subtract(Duration(days: now.weekday - 1)), now),
      DateRangePreset.thisMonth => (DateTime(now.year, now.month, 1), now),
      DateRangePreset.custom => (_currentFilters.dateFrom, _currentFilters.dateTo),
    };
    load(filters: _currentFilters.copyWith(dateFrom: from, dateTo: to, preset: preset));
  }

  void setCustomRange(DateTime from, DateTime to) {
    load(filters: _currentFilters.copyWith(
      dateFrom: from, dateTo: to, preset: DateRangePreset.custom,
    ));
  }

  void filterByBranch(String? branchId) {
    load(filters: branchId == null
        ? _currentFilters.copyWith(clearBranch: true)
        : _currentFilters.copyWith(branchId: branchId));
  }

  void filterByWarehouse(String? warehouseId) {
    load(filters: warehouseId == null
        ? _currentFilters.copyWith(clearWarehouse: true)
        : _currentFilters.copyWith(warehouseId: warehouseId));
  }

  void filterByProduct(String? productId) {
    load(filters: productId == null
        ? _currentFilters.copyWith(clearProduct: true)
        : _currentFilters.copyWith(productId: productId));
  }

  void switchTab(FinancialReportTab tab) {
    if (state is FinancialReportLoaded) {
      emit((state as FinancialReportLoaded).copyWith(activeTab: tab));
    }
  }

  Future<String?> exportFile(String endpoint) async {
    try {
      final f = _currentFilters;
      final dateFmt = DateFormat('yyyy-MM-dd', 'en_US');
      final bytes = await _export(endpoint, {
        'date_from': dateFmt.format(f.dateFrom),
        'date_to': dateFmt.format(f.dateTo),
        if (f.branchId != null) 'branch_id': f.branchId,
        if (f.warehouseId != null) 'warehouse_id': f.warehouseId,
        if (f.productId != null) 'product_id': f.productId,
      });
      return _saveFile(bytes, endpoint);
    } catch (e) {
      debugPrint('[Export:Financial] exportFile failed: $e');
      rethrow;
    }
  }

  ReportFilters get _currentFilters => switch (state) {
        FinancialReportLoaded(:final filters) => filters,
        FinancialReportLoading(:final filters) => filters,
        FinancialReportError(:final filters) => filters,
        FinancialReportInitial(:final filters) => filters,
      };
}

// ─── Shared Export Helper ─────────────────────────────────────────────────────

Future<String?> _saveFile(List<int> bytes, String endpoint) async {
  if (bytes.isEmpty) return null;
  final ext = endpoint.contains('pdf') ? 'pdf' : 'xlsx';
  final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final name = '${endpoint.split('/').last}_$ts.$ext';
  return saveExportFile(bytes, name);
}
