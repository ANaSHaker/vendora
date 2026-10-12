import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/customer_entities.dart';
import '../../domain/usecases/customers_usecases.dart';
import 'customers_state.dart';

class CustomersCubit extends Cubit<CustomersState> {
  final GetCustomersUseCase _getCustomers;
  final GetCustomerByIdUseCase _getById;
  final CreateCustomerUseCase _create;
  final UpdateCustomerUseCase _update;
  final DeleteCustomerUseCase _delete;

  Timer? _debounce;

  CustomersCubit({
    required GetCustomersUseCase getCustomers,
    required GetCustomerByIdUseCase getCustomerById,
    required CreateCustomerUseCase createCustomer,
    required UpdateCustomerUseCase updateCustomer,
    required DeleteCustomerUseCase deleteCustomer,
  })  : _getCustomers = getCustomers,
        _getById = getCustomerById,
        _create = createCustomer,
        _update = updateCustomer,
        _delete = deleteCustomer,
        super(const CustomersInitial());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> load({String search = '', int page = 1}) async {
    emit(const CustomersLoading());
    final result =
        await _getCustomers(search: search.isEmpty ? null : search, page: page);
    if (isClosed) return;
    result.fold(
      (failure) => emit(CustomersError(failure.message)),
      (paginated) => emit(CustomersLoaded(
        customers: paginated.data,
        meta: paginated.meta,
        search: search,
        page: page,
      )),
    );
  }

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      load(search: query, page: 1);
    });
  }

  Future<void> refresh() async {
    final s = state;
    if (s is CustomersLoaded) {
      await load(search: s.search, page: s.page);
    } else {
      await load();
    }
  }

  Future<void> goToPage(int page) async {
    final s = state;
    if (s is CustomersLoaded) {
      await load(search: s.search, page: page);
    }
  }

  Future<void> selectCustomer(String id) async {
    final s = state;
    if (s is! CustomersLoaded) return;

    emit(s.copyWith(
      selectedId: () => id,
      selectedDetail: () => null,
      loadingDetail: true,
    ));

    final result = await _getById(id);
    if (isClosed) return;
    result.fold(
      (_) => emit(s.copyWith(
        selectedId: () => id,
        loadingDetail: false,
      )),
      (customer) {
        final current = state;
        if (current is CustomersLoaded) {
          emit(current.copyWith(
            selectedDetail: () => customer,
            loadingDetail: false,
          ));
        }
      },
    );
  }

  void closeDetail() {
    final s = state;
    if (s is CustomersLoaded) {
      emit(s.copyWith(
        selectedId: () => null,
        selectedDetail: () => null,
      ));
    }
  }

  Future<bool> createCustomer(CustomerFormData data) async {
    final result = await _create(data);
    return result.fold(
      (_) => false,
      (_) {
        refresh();
        return true;
      },
    );
  }

  Future<bool> updateCustomer(String id, CustomerFormData data) async {
    final result = await _update(id, data);
    return result.fold(
      (_) => false,
      (updated) {
        final s = state;
        if (s is CustomersLoaded) {
          final updatedList = s.customers.map((c) => c.id == id ? updated : c).toList();
          emit(s.copyWith(
            customers: updatedList,
            selectedDetail: s.selectedId == id ? () => updated : null,
          ));
        }
        return true;
      },
    );
  }

  Future<bool> deleteCustomer(String id) async {
    final result = await _delete(id);
    return result.fold(
      (_) => false,
      (_) {
        final s = state;
        if (s is CustomersLoaded) {
          emit(s.copyWith(
            customers: s.customers.where((c) => c.id != id).toList(),
            selectedId: s.selectedId == id ? () => null : null,
            selectedDetail: s.selectedId == id ? () => null : null,
          ));
        }
        return true;
      },
    );
  }
}
