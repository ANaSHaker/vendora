import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/transfer_entities.dart';

sealed class TransferState extends Equatable {
  const TransferState();
  @override
  List<Object?> get props => [];
}

class TransferInitial extends TransferState {
  const TransferInitial();
}

class TransferLoading extends TransferState {
  const TransferLoading();
}

class TransferLoaded extends TransferState {
  final List<TransferEntity> transfers;
  final PaginationMeta meta;
  final String search;
  final String? statusFilter;
  final int page;

  const TransferLoaded({
    required this.transfers,
    required this.meta,
    this.search = '',
    this.statusFilter,
    this.page = 1,
  });

  TransferLoaded copyWith({
    List<TransferEntity>? transfers,
    PaginationMeta? meta,
    String? search,
    String? Function()? statusFilter,
    int? page,
  }) {
    return TransferLoaded(
      transfers: transfers ?? this.transfers,
      meta: meta ?? this.meta,
      search: search ?? this.search,
      statusFilter:
          statusFilter != null ? statusFilter() : this.statusFilter,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [transfers, meta, search, statusFilter, page];
}

class TransferError extends TransferState {
  final String message;
  const TransferError(this.message);
  @override
  List<Object?> get props => [message];
}
