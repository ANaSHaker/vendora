import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/inventory_entities.dart';

sealed class WarehouseStockState extends Equatable {
  const WarehouseStockState();
  @override
  List<Object?> get props => [];
}

class WarehouseStockInitial extends WarehouseStockState {
  const WarehouseStockInitial();
}

class WarehouseStockLoading extends WarehouseStockState {
  const WarehouseStockLoading();
}

class WarehouseStockLoaded extends WarehouseStockState {
  final List<InventoryBalanceEntity> balances;
  final PaginationMeta meta;
  final String search;
  final String? branchId;
  final String? warehouseId;
  final bool lowStockOnly;
  final List<InventoryBranchOptionEntity> branches;
  final List<WarehouseOptionEntity> warehouses;

  const WarehouseStockLoaded({
    required this.balances,
    required this.meta,
    this.search = '',
    this.branchId,
    this.warehouseId,
    this.lowStockOnly = false,
    this.branches = const <InventoryBranchOptionEntity>[],
    this.warehouses = const <WarehouseOptionEntity>[],
  });

  WarehouseStockLoaded copyWith({
    List<InventoryBalanceEntity>? balances,
    PaginationMeta? meta,
    String? search,
    String? Function()? branchId,
    String? Function()? warehouseId,
    bool? lowStockOnly,
    List<InventoryBranchOptionEntity>? branches,
    List<WarehouseOptionEntity>? warehouses,
  }) {
    return WarehouseStockLoaded(
      balances: balances ?? this.balances,
      meta: meta ?? this.meta,
      search: search ?? this.search,
      branchId: branchId != null ? branchId() : this.branchId,
      warehouseId: warehouseId != null ? warehouseId() : this.warehouseId,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      branches: branches ?? this.branches,
      warehouses: warehouses ?? this.warehouses,
    );
  }

  @override
  List<Object?> get props => [
        balances,
        meta,
        search,
        branchId,
        warehouseId,
        lowStockOnly,
        branches,
        warehouses,
      ];
}

class WarehouseStockError extends WarehouseStockState {
  final String message;
  const WarehouseStockError(this.message);
  @override
  List<Object?> get props => [message];
}
