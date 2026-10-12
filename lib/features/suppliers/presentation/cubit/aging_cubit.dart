import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/aging_entities.dart';
import '../../domain/entities/supplier_entities.dart';
import '../../domain/usecases/aging_usecases.dart';
import '../../domain/usecases/suppliers_usecases.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class AgingState extends Equatable {
  const AgingState();
  @override
  List<Object?> get props => [];
}

class AgingInitial extends AgingState {
  final List<SupplierEntity> supplierList;
  const AgingInitial({this.supplierList = const []});
  @override
  List<Object?> get props => [supplierList];
}

class AgingLoading extends AgingState {
  final List<SupplierEntity> supplierList;
  const AgingLoading({this.supplierList = const []});
  @override
  List<Object?> get props => [supplierList];
}

class AgingLoaded extends AgingState {
  final List<AgingRowEntity> rows;
  final AgingTotals totals;
  final List<SupplierEntity> supplierList;
  final String? supplierId;
  final String asOf;

  AgingLoaded({
    required this.rows,
    required this.supplierList,
    this.supplierId,
    this.asOf = '',
  }) : totals = AgingTotals.fromRows(rows);

  @override
  List<Object?> get props => [rows, totals, supplierList, supplierId, asOf];
}

class AgingError extends AgingState {
  final String message;
  final List<SupplierEntity> supplierList;
  const AgingError(this.message, {this.supplierList = const []});
  @override
  List<Object?> get props => [message, supplierList];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class AgingCubit extends Cubit<AgingState> {
  final GetSupplierAgingUseCase _getAging;
  final ExportSupplierAgingUseCase _exportAging;
  final GetSuppliersUseCase _getSuppliers;

  AgingCubit({
    required GetSupplierAgingUseCase getAging,
    required ExportSupplierAgingUseCase exportAging,
    required GetSuppliersUseCase getSuppliers,
  })  : _getAging = getAging,
        _exportAging = exportAging,
        _getSuppliers = getSuppliers,
        super(const AgingInitial());

  Future<void> init() async {
    await _loadSupplierList();
    await load();
  }

  Future<void> _loadSupplierList() async {
    final result = await _getSuppliers(perPage: 100);
    if (isClosed) return;
    result.fold((_) {}, (paginated) {
      final s = state;
      if (s is AgingInitial) {
        emit(AgingInitial(supplierList: paginated.data));
      } else if (s is AgingLoaded) {
        emit(AgingLoaded(
          rows: s.rows,
          supplierList: paginated.data,
          supplierId: s.supplierId,
          asOf: s.asOf,
        ));
      } else if (s is AgingLoading) {
        emit(AgingLoading(supplierList: paginated.data));
      } else if (s is AgingError) {
        emit(AgingError(s.message, supplierList: paginated.data));
      }
    });
  }

  Future<void> load({String? supplierId, String asOf = ''}) async {
    final currentList = _supplierList;
    emit(AgingLoading(supplierList: currentList));
    final result = await _getAging(
      supplierId: supplierId,
      asOf: asOf.isNotEmpty ? asOf : null,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(AgingError(failure.message, supplierList: currentList)),
      (rows) => emit(AgingLoaded(
        rows: rows,
        supplierList: currentList,
        supplierId: supplierId,
        asOf: asOf,
      )),
    );
  }

  Future<void> setSupplier(String? id) async {
    final s = state;
    final asOf = s is AgingLoaded ? s.asOf : '';
    await load(supplierId: id, asOf: asOf);
  }

  Future<void> setAsOf(String asOf) async {
    final s = state;
    final id = s is AgingLoaded ? s.supplierId : null;
    await load(supplierId: id, asOf: asOf);
  }

  Future<List<int>?> exportAging() async {
    final s = state;
    final supplierId = s is AgingLoaded ? s.supplierId : null;
    final asOf       = s is AgingLoaded ? s.asOf       : '';
    final result = await _exportAging(
      supplierId: supplierId,
      asOf: asOf.isNotEmpty ? asOf : null,
    );
    return result.fold(
      (failure) {
        debugPrint('[AgingCubit.exportAging] failed: ${failure.message}');
        return null;
      },
      (bytes) => bytes,
    );
  }

  List<SupplierEntity> get _supplierList => switch (state) {
        AgingInitial(:final supplierList)  => supplierList,
        AgingLoading(:final supplierList)  => supplierList,
        AgingLoaded(:final supplierList)   => supplierList,
        AgingError(:final supplierList)    => supplierList,
      };
}
