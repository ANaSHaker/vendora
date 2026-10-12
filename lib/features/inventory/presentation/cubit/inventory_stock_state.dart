import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/inventory_entities.dart';

sealed class InventoryStockState extends Equatable {
  const InventoryStockState();
  @override
  List<Object?> get props => [];
}

class InventoryStockInitial extends InventoryStockState {
  const InventoryStockInitial();
}

class InventoryStockLoading extends InventoryStockState {
  const InventoryStockLoading();
}

class InventoryStockLoaded extends InventoryStockState {
  final List<InventoryBalanceEntity> balances;
  final PaginationMeta meta;
  final String search;
  final String? branchId;
  final String? warehouseId;
  final List<InventoryBranchOptionEntity> branches;
  final List<WarehouseOptionEntity> warehouses;
  final bool isRefreshing;

  const InventoryStockLoaded({
    required this.balances,
    required this.meta,
    this.search = '',
    this.branchId,
    this.warehouseId,
    this.branches = const <InventoryBranchOptionEntity>[],
    this.warehouses = const <WarehouseOptionEntity>[],
    this.isRefreshing = false,
  });

  InventoryStockLoaded copyWith({
    List<InventoryBalanceEntity>? balances,
    PaginationMeta? meta,
    String? search,
    String? Function()? branchId,
    String? Function()? warehouseId,
    List<InventoryBranchOptionEntity>? branches,
    List<WarehouseOptionEntity>? warehouses,
    bool? isRefreshing,
  }) {
    return InventoryStockLoaded(
      balances: balances ?? this.balances,
      meta: meta ?? this.meta,
      search: search ?? this.search,
      branchId: branchId != null ? branchId() : this.branchId,
      warehouseId: warehouseId != null ? warehouseId() : this.warehouseId,
      branches: branches ?? this.branches,
      warehouses: warehouses ?? this.warehouses,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props =>
      [balances, meta, search, branchId, warehouseId, branches, warehouses, isRefreshing];
}

class InventoryStockError extends InventoryStockState {
  final String message;
  const InventoryStockError(this.message);
  @override
  List<Object?> get props => [message];
}
