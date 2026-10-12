import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/receipt_entity.dart';

abstract class ReceiptState extends Equatable {
  const ReceiptState();

  @override
  List<Object?> get props => [];
}

class ReceiptInitial extends ReceiptState {
  const ReceiptInitial();
}

class ReceiptLoading extends ReceiptState {
  const ReceiptLoading();
}

class ReceiptLoaded extends ReceiptState {
  final List<ReceiptEntity> receipts;
  final PaginationMeta meta;
  final String? statusFilter;
  final String? search;
  final int page;

  const ReceiptLoaded({
    required this.receipts,
    required this.meta,
    this.statusFilter,
    this.search,
    this.page = 1,
  });

  ReceiptLoaded copyWith({
    List<ReceiptEntity>? receipts,
    PaginationMeta? meta,
    String? statusFilter,
    String? search,
    int? page,
  }) =>
      ReceiptLoaded(
        receipts: receipts ?? this.receipts,
        meta: meta ?? this.meta,
        statusFilter: statusFilter ?? this.statusFilter,
        search: search ?? this.search,
        page: page ?? this.page,
      );

  @override
  List<Object?> get props =>
      [receipts, meta, statusFilter, search, page];
}

class ReceiptError extends ReceiptState {
  final String message;
  const ReceiptError(this.message);

  @override
  List<Object?> get props => [message];
}
