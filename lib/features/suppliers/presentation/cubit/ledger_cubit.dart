import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/supplier_entities.dart';
import '../../domain/usecases/ledger_usecases.dart';
import '../../domain/usecases/suppliers_usecases.dart';
import 'ledger_state.dart';

class LedgerCubit extends Cubit<LedgerState> {
  final GetSupplierLedgerUseCase _getLedger;
  final GetSuppliersUseCase _getSuppliers;
  final ExportSupplierLedgerUseCase? _exportLedger;

  LedgerCubit({
    required GetSupplierLedgerUseCase getLedger,
    required GetSuppliersUseCase getSuppliers,
    ExportSupplierLedgerUseCase? exportLedger,
  })  : _getLedger = getLedger,
        _getSuppliers = getSuppliers,
        _exportLedger = exportLedger,
        super(const LedgerInitial());

  // Load supplier list then immediately load global ledger data
  Future<void> init() async {
    await loadSupplierList();
    await load();
  }

  Future<void> loadSupplierList() async {
    final result = await _getSuppliers(perPage: 100);
    if (isClosed) return;
    result.fold(
      (_) {},
      (paginated) {
        final s = state;
        if (s is LedgerInitial) {
          emit(LedgerInitial(supplierList: paginated.data));
        } else if (s is LedgerLoaded) {
          emit(s.copyWith(supplierList: paginated.data));
        } else if (s is LedgerLoading) {
          emit(LedgerLoading(supplierList: paginated.data));
        } else if (s is LedgerError) {
          emit(LedgerError(s.message, supplierList: paginated.data));
        }
      },
    );
  }

  Future<void> load({
    String? supplierId,
    String? type,
    String dateFrom = '',
    String dateTo = '',
    int page = 1,
  }) async {
    final currentSupplierList = _getSupplierList();
    emit(LedgerLoading(supplierList: currentSupplierList));
    final result = await _getLedger(
      supplierId: supplierId,
      type: type,
      dateFrom: dateFrom.isNotEmpty ? dateFrom : null,
      dateTo: dateTo.isNotEmpty ? dateTo : null,
      page: page,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(LedgerError(failure.message,
          supplierList: currentSupplierList)),
      (data) => emit(LedgerLoaded(
        entries: data.entries,
        meta: data.meta,
        summary: data.summary,
        supplierId: supplierId,
        supplierList: currentSupplierList,
        type: type,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: page,
      )),
    );
  }

  Future<void> setSupplier(String? id) async {
    final s = state;
    final type = s is LedgerLoaded ? s.type : null;
    final dateFrom = s is LedgerLoaded ? s.dateFrom : '';
    final dateTo = s is LedgerLoaded ? s.dateTo : '';
    await load(
      supplierId: (id == null || id.isEmpty) ? null : id,
      type: type,
      dateFrom: dateFrom,
      dateTo: dateTo,
      page: 1,
    );
  }

  Future<void> setType(String? type) async {
    final s = state;
    if (s is LedgerLoaded) {
      await load(
        supplierId: s.supplierId,
        type: (type == null || type.isEmpty) ? null : type,
        dateFrom: s.dateFrom,
        dateTo: s.dateTo,
        page: 1,
      );
    }
  }

  Future<void> setDates(String dateFrom, String dateTo) async {
    final s = state;
    if (s is LedgerLoaded) {
      await load(
        supplierId: s.supplierId,
        type: s.type,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: 1,
      );
    }
  }

  Future<void> goToPage(int page) async {
    final s = state;
    if (s is LedgerLoaded) {
      await load(
        supplierId: s.supplierId,
        type: s.type,
        dateFrom: s.dateFrom,
        dateTo: s.dateTo,
        page: page,
      );
    }
  }

  Future<void> refresh() async {
    final s = state;
    if (s is LedgerLoaded) {
      await load(
        supplierId: s.supplierId,
        type: s.type,
        dateFrom: s.dateFrom,
        dateTo: s.dateTo,
        page: s.page,
      );
    } else {
      await load();
    }
  }

  Future<List<int>?> exportLedger() async {
    final export = _exportLedger;
    if (export == null) return null;
    final s = state;
    final supplierId = s is LedgerLoaded ? s.supplierId : null;
    final type       = s is LedgerLoaded ? s.type       : null;
    final dateFrom   = s is LedgerLoaded ? s.dateFrom   : '';
    final dateTo     = s is LedgerLoaded ? s.dateTo     : '';
    final result = await export(
      supplierId: supplierId,
      type: type,
      dateFrom: dateFrom.isNotEmpty ? dateFrom : null,
      dateTo: dateTo.isNotEmpty ? dateTo : null,
    );
    return result.fold(
      (failure) {
        debugPrint('[LedgerCubit.exportLedger] failed: ${failure.message}');
        return null;
      },
      (bytes) => bytes,
    );
  }

  List<SupplierEntity> _getSupplierList() {
    final s = state;
    return switch (s) {
      LedgerInitial(:final supplierList) => supplierList,
      LedgerLoading(:final supplierList) => supplierList,
      LedgerLoaded(:final supplierList) => supplierList,
      LedgerError(:final supplierList) => supplierList,
    };
  }
}
