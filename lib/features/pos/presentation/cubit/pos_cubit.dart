import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/storage/local_storage.dart';
import '../../domain/entities/pos_entities.dart';
import '../../domain/usecases/pos_usecases.dart';
import 'cart_state.dart';
import 'pos_state.dart';

class PosCubit extends Cubit<PosState> {
  final GetBranchesUseCase _getBranches;
  final GetWarehousesUseCase _getWarehouses;
  final GetPosProductsUseCase _getProducts;
  final GetPosCategoriesUseCase _getCategories;
  final CreateOrderUseCase _createOrder;
  final LocalStorage _storage;

  Timer? _searchDebounce;

  PosCubit({
    required GetBranchesUseCase getBranches,
    required GetWarehousesUseCase getWarehouses,
    required GetPosProductsUseCase getProducts,
    required GetPosCategoriesUseCase getCategories,
    required CreateOrderUseCase createOrder,
    required LocalStorage storage,
  })  : _getBranches = getBranches,
        _getWarehouses = getWarehouses,
        _getProducts = getProducts,
        _getCategories = getCategories,
        _createOrder = createOrder,
        _storage = storage,
        super(PosState(autoPrint: storage.autoPrint));

  Future<void> initialize() async {
    emit(state.copyWith(setupStep: PosSetupStep.loadingBranches));
    final result = await _getBranches();
    if (isClosed) return;
    result.fold(
      (_) => emit(state.copyWith(setupStep: PosSetupStep.idle)),
      (branches) {
        if (branches.length == 1) {
          emit(state.copyWith(
            branches: branches,
            selectedBranch: () => branches.first,
            setupStep: PosSetupStep.loadingWarehouses,
          ));
          _loadWarehouses(branches.first.id);
        } else {
          emit(state.copyWith(
            branches: branches,
            setupStep: PosSetupStep.selectBranch,
          ));
        }
      },
    );
  }

  void selectBranch(BranchEntity branch) {
    emit(state.copyWith(
      selectedBranch: () => branch,
      setupStep: PosSetupStep.loadingWarehouses,
      warehouses: [],
      selectedWarehouse: () => null,
    ));
    _loadWarehouses(branch.id);
  }

  Future<void> _loadWarehouses(String branchId) async {
    final result = await _getWarehouses(branchId: branchId);
    if (isClosed) return;
    result.fold(
      (_) => emit(state.copyWith(setupStep: PosSetupStep.selectBranch)),
      (warehouses) {
        if (warehouses.isEmpty) {
          // No warehouses for this branch — proceed without one
          emit(state.copyWith(
            warehouses: warehouses,
            selectedWarehouse: () => null,
            setupStep: PosSetupStep.ready,
          ));
          _loadProductsAndCategories();
        } else if (warehouses.length == 1) {
          emit(state.copyWith(
            warehouses: warehouses,
            selectedWarehouse: () => warehouses.first,
            setupStep: PosSetupStep.ready,
          ));
          _loadProductsAndCategories();
        } else {
          emit(state.copyWith(
            warehouses: warehouses,
            setupStep: PosSetupStep.selectWarehouse,
          ));
        }
      },
    );
  }

  void skipWarehouse() {
    emit(state.copyWith(
      selectedWarehouse: () => null,
      setupStep: PosSetupStep.ready,
    ));
    _loadProductsAndCategories();
  }

  void switchBranch() {
    emit(state.copyWith(
      setupStep: PosSetupStep.selectBranch,
      selectedBranch: () => null,
      warehouses: [],
      selectedWarehouse: () => null,
    ));
  }

  void switchWarehouse() {
    if (state.warehouses.isNotEmpty) {
      emit(state.copyWith(setupStep: PosSetupStep.selectWarehouse));
    }
  }

  void selectWarehouse(WarehouseEntity warehouse) {
    emit(state.copyWith(
      selectedWarehouse: () => warehouse,
      setupStep: PosSetupStep.ready,
    ));
    _loadProductsAndCategories();
  }

  Future<void> _loadProductsAndCategories() async {
    emit(state.copyWith(productsLoading: true));
    final warehouseId = state.selectedWarehouse?.id;
    final productsF = _getProducts(warehouseId: warehouseId);
    final categoriesF = _getCategories();
    final productsResult = await productsF;
    if (isClosed) return;
    productsResult.fold((_) {}, (p) => emit(state.copyWith(products: p)));
    final categoriesResult = await categoriesF;
    if (isClosed) return;
    categoriesResult.fold((_) {}, (c) => emit(state.copyWith(categories: c)));
    emit(state.copyWith(productsLoading: false));
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
    _searchDebounce?.cancel();
  }

  void selectCategory(String? categoryId) {
    emit(state.copyWith(
      selectedCategoryId: () => categoryId,
      searchQuery: '',
    ));
  }

  Future<void> submitOrder({
    required CartState cart,
    required String paymentMethod,
    required double paymentAmount,
  }) async {
    final branch = state.selectedBranch;
    if (branch == null) return;
    final warehouse = state.selectedWarehouse;

    emit(state.copyWith(
      submitting: true,
      submitFailure: () => null,
      lastOrder: () => null,
    ));

    double orderDiscount = 0;
    if (cart.discount != null) {
      orderDiscount = cart.discount!.type == DiscountType.flat
          ? cart.discount!.value
          : cart.subtotal * cart.discount!.value / 100;
    }

    final params = CreateOrderParams(
      branchId: branch.id,
      warehouseId: warehouse?.id,
      customerId: cart.customer?.id,
      items: cart.items
          .map((i) => (
                productId: i.productId,
                quantity: i.quantity,
                discount: i.lineDiscount,
              ))
          .toList(),
      orderDiscount: orderDiscount,
      note: cart.note,
      paymentMethod: paymentMethod,
      paymentAmount: paymentAmount,
    );

    final result = await _createOrder(params);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        submitting: false,
        submitFailure: () => failure,
      )),
      (order) {
        emit(state.copyWith(
          submitting: false,
          lastOrder: () => order,
        ));
        _loadProductsAndCategories();
      },
    );
  }

  void clearLastOrder() {
    emit(state.copyWith(lastOrder: () => null, submitFailure: () => null));
  }

  Future<void> toggleAutoPrint() async {
    final newVal = !state.autoPrint;
    emit(state.copyWith(autoPrint: newVal));
    await _storage.saveAutoPrint(newVal);
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
