import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/stock_count_entities.dart';

sealed class StockCountState extends Equatable {
  const StockCountState();
  @override
  List<Object?> get props => [];
}

class StockCountInitial extends StockCountState {
  const StockCountInitial();
}

class StockCountLoading extends StockCountState {
  const StockCountLoading();
}

class StockCountLoaded extends StockCountState {
  final List<StockCountEntity> counts;
  final PaginationMeta meta;
  final String search;
  final String? statusFilter;
  final int page;
  final String? selectedId;
  final StockCountEntity? selectedDetail;
  final bool loadingDetail;

  const StockCountLoaded({
    required this.counts,
    required this.meta,
    this.search = '',
    this.statusFilter,
    this.page = 1,
    this.selectedId,
    this.selectedDetail,
    this.loadingDetail = false,
  });

  StockCountLoaded copyWith({
    List<StockCountEntity>? counts,
    PaginationMeta? meta,
    String? search,
    String? Function()? statusFilter,
    int? page,
    String? Function()? selectedId,
    StockCountEntity? Function()? selectedDetail,
    bool? loadingDetail,
  }) {
    return StockCountLoaded(
      counts: counts ?? this.counts,
      meta: meta ?? this.meta,
      search: search ?? this.search,
      statusFilter:
          statusFilter != null ? statusFilter() : this.statusFilter,
      page: page ?? this.page,
      selectedId: selectedId != null ? selectedId() : this.selectedId,
      selectedDetail:
          selectedDetail != null ? selectedDetail() : this.selectedDetail,
      loadingDetail: loadingDetail ?? this.loadingDetail,
    );
  }

  @override
  List<Object?> get props => [
        counts,
        meta,
        search,
        statusFilter,
        page,
        selectedId,
        selectedDetail,
        loadingDetail,
      ];
}

class StockCountError extends StockCountState {
  final String message;
  const StockCountError(this.message);
  @override
  List<Object?> get props => [message];
}
