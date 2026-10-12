import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/inventory_entities.dart';
import '../../domain/entities/warehouse_entities.dart';

sealed class WarehouseState extends Equatable {
  const WarehouseState();
  @override
  List<Object?> get props => [];
}

class WarehouseInitial extends WarehouseState {
  const WarehouseInitial();
}

class WarehouseLoading extends WarehouseState {
  const WarehouseLoading();
}

class WarehouseLoaded extends WarehouseState {
  final List<WarehouseEntity> warehouses;
  final PaginationMeta meta;
  final String search;
  final String? branchId;
  final int page;
  final List<InventoryBranchOptionEntity> branches;
  final bool loadingBranches;

  const WarehouseLoaded({
    required this.warehouses,
    required this.meta,
    this.search = '',
    this.branchId,
    this.page = 1,
    this.branches = const [],
    this.loadingBranches = false,
  });

  WarehouseLoaded copyWith({
    List<WarehouseEntity>? warehouses,
    PaginationMeta? meta,
    String? search,
    String? Function()? branchId,
    int? page,
    List<InventoryBranchOptionEntity>? branches,
    bool? loadingBranches,
  }) {
    return WarehouseLoaded(
      warehouses: warehouses ?? this.warehouses,
      meta: meta ?? this.meta,
      search: search ?? this.search,
      branchId: branchId != null ? branchId() : this.branchId,
      page: page ?? this.page,
      branches: branches ?? this.branches,
      loadingBranches: loadingBranches ?? this.loadingBranches,
    );
  }

  @override
  List<Object?> get props =>
      [warehouses, meta, search, branchId, page, branches, loadingBranches];
}

class WarehouseError extends WarehouseState {
  final String message;
  const WarehouseError(this.message);
  @override
  List<Object?> get props => [message];
}
