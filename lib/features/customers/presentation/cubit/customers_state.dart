import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/customer_entities.dart';

sealed class CustomersState extends Equatable {
  const CustomersState();
  @override
  List<Object?> get props => [];
}

class CustomersInitial extends CustomersState {
  const CustomersInitial();
}

class CustomersLoading extends CustomersState {
  const CustomersLoading();
}

class CustomersLoaded extends CustomersState {
  final List<CustomerEntity> customers;
  final PaginationMeta meta;
  final String search;
  final int page;
  final String? selectedId;
  final CustomerEntity? selectedDetail;
  final bool loadingDetail;

  const CustomersLoaded({
    required this.customers,
    required this.meta,
    this.search = '',
    this.page = 1,
    this.selectedId,
    this.selectedDetail,
    this.loadingDetail = false,
  });

  CustomersLoaded copyWith({
    List<CustomerEntity>? customers,
    PaginationMeta? meta,
    String? search,
    int? page,
    String? Function()? selectedId,
    CustomerEntity? Function()? selectedDetail,
    bool? loadingDetail,
  }) {
    return CustomersLoaded(
      customers: customers ?? this.customers,
      meta: meta ?? this.meta,
      search: search ?? this.search,
      page: page ?? this.page,
      selectedId: selectedId != null ? selectedId() : this.selectedId,
      selectedDetail:
          selectedDetail != null ? selectedDetail() : this.selectedDetail,
      loadingDetail: loadingDetail ?? this.loadingDetail,
    );
  }

  @override
  List<Object?> get props =>
      [customers, meta, search, page, selectedId, selectedDetail, loadingDetail];
}

class CustomersError extends CustomersState {
  final String message;
  const CustomersError(this.message);
  @override
  List<Object?> get props => [message];
}
