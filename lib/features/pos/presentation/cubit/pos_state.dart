import 'package:equatable/equatable.dart';
import '../../domain/entities/pos_entities.dart';
import '../../../../core/error/failures.dart';

enum PosSetupStep { idle, loadingBranches, selectBranch, loadingWarehouses, selectWarehouse, ready }

class PosState extends Equatable {
  final PosSetupStep setupStep;
  final List<BranchEntity> branches;
  final BranchEntity? selectedBranch;
  final List<WarehouseEntity> warehouses;
  final WarehouseEntity? selectedWarehouse;

  final List<PosProductEntity> products;
  final List<PosCategoryEntity> categories;
  final bool productsLoading;

  final String searchQuery;
  final String? selectedCategoryId;

  final bool submitting;
  final PosOrderEntity? lastOrder;
  final Failure? submitFailure;
  final bool autoPrint;

  const PosState({
    this.setupStep = PosSetupStep.idle,
    this.branches = const [],
    this.selectedBranch,
    this.warehouses = const [],
    this.selectedWarehouse,
    this.products = const [],
    this.categories = const [],
    this.productsLoading = false,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.submitting = false,
    this.lastOrder,
    this.submitFailure,
    this.autoPrint = false,
  });

  List<PosProductEntity> get filteredProducts {
    var list = products;
    if (selectedCategoryId != null) {
      list = list.where((p) => p.categoryId == selectedCategoryId).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.sku?.toLowerCase().contains(q) ?? false) ||
            (p.barcode?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return list;
  }

  bool get isReady => setupStep == PosSetupStep.ready;

  PosState copyWith({
    PosSetupStep? setupStep,
    List<BranchEntity>? branches,
    BranchEntity? Function()? selectedBranch,
    List<WarehouseEntity>? warehouses,
    WarehouseEntity? Function()? selectedWarehouse,
    List<PosProductEntity>? products,
    List<PosCategoryEntity>? categories,
    bool? productsLoading,
    String? searchQuery,
    String? Function()? selectedCategoryId,
    bool? submitting,
    PosOrderEntity? Function()? lastOrder,
    Failure? Function()? submitFailure,
    bool? autoPrint,
  }) {
    return PosState(
      setupStep: setupStep ?? this.setupStep,
      branches: branches ?? this.branches,
      selectedBranch: selectedBranch != null ? selectedBranch() : this.selectedBranch,
      warehouses: warehouses ?? this.warehouses,
      selectedWarehouse: selectedWarehouse != null ? selectedWarehouse() : this.selectedWarehouse,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      productsLoading: productsLoading ?? this.productsLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId != null ? selectedCategoryId() : this.selectedCategoryId,
      submitting: submitting ?? this.submitting,
      lastOrder: lastOrder != null ? lastOrder() : this.lastOrder,
      submitFailure: submitFailure != null ? submitFailure() : this.submitFailure,
      autoPrint: autoPrint ?? this.autoPrint,
    );
  }

  @override
  List<Object?> get props => [
        setupStep,
        branches,
        selectedBranch,
        warehouses,
        selectedWarehouse,
        products,
        categories,
        productsLoading,
        searchQuery,
        selectedCategoryId,
        submitting,
        lastOrder,
        submitFailure,
        autoPrint,
      ];
}
