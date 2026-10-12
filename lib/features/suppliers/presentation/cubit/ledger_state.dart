import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/ledger_entities.dart';
import '../../domain/entities/supplier_entities.dart';

sealed class LedgerState extends Equatable {
  const LedgerState();
  @override
  List<Object?> get props => [];
}

class LedgerInitial extends LedgerState {
  final List<SupplierEntity> supplierList;
  const LedgerInitial({this.supplierList = const []});
  @override
  List<Object?> get props => [supplierList];
}

class LedgerLoading extends LedgerState {
  final List<SupplierEntity> supplierList;
  const LedgerLoading({this.supplierList = const []});
  @override
  List<Object?> get props => [supplierList];
}

class LedgerLoaded extends LedgerState {
  final List<LedgerEntryEntity> entries;
  final PaginationMeta meta;
  final LedgerSummary summary;
  final String? supplierId;
  final List<SupplierEntity> supplierList;
  final String? type;
  final String dateFrom;
  final String dateTo;
  final int page;

  const LedgerLoaded({
    required this.entries,
    required this.meta,
    required this.summary,
    this.supplierId,
    this.supplierList = const [],
    this.type,
    this.dateFrom = '',
    this.dateTo = '',
    this.page = 1,
  });

  LedgerLoaded copyWith({
    List<LedgerEntryEntity>? entries,
    PaginationMeta? meta,
    LedgerSummary? summary,
    String? Function()? supplierId,
    List<SupplierEntity>? supplierList,
    String? Function()? type,
    String? dateFrom,
    String? dateTo,
    int? page,
  }) {
    return LedgerLoaded(
      entries: entries ?? this.entries,
      meta: meta ?? this.meta,
      summary: summary ?? this.summary,
      supplierId: supplierId != null ? supplierId() : this.supplierId,
      supplierList: supplierList ?? this.supplierList,
      type: type != null ? type() : this.type,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props =>
      [entries, meta, summary, supplierId, supplierList, type, dateFrom, dateTo, page];
}

class LedgerError extends LedgerState {
  final String message;
  final List<SupplierEntity> supplierList;
  const LedgerError(this.message, {this.supplierList = const []});
  @override
  List<Object?> get props => [message, supplierList];
}
