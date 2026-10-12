import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/supplier_entities.dart';

sealed class SuppliersState extends Equatable {
  const SuppliersState();
  @override
  List<Object?> get props => [];
}

class SuppliersInitial extends SuppliersState {
  const SuppliersInitial();
}

class SuppliersLoading extends SuppliersState {
  const SuppliersLoading();
}

class SuppliersLoaded extends SuppliersState {
  final List<SupplierEntity> suppliers;
  final PaginationMeta meta;
  final String search;
  final int page;

  const SuppliersLoaded({
    required this.suppliers,
    required this.meta,
    this.search = '',
    this.page = 1,
  });

  SuppliersLoaded copyWith({
    List<SupplierEntity>? suppliers,
    PaginationMeta? meta,
    String? search,
    int? page,
  }) {
    return SuppliersLoaded(
      suppliers: suppliers ?? this.suppliers,
      meta: meta ?? this.meta,
      search: search ?? this.search,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [suppliers, meta, search, page];
}

class SuppliersError extends SuppliersState {
  final String message;
  const SuppliersError(this.message);
  @override
  List<Object?> get props => [message];
}
