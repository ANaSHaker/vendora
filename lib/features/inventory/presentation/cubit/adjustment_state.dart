import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/adjustment_entities.dart';

sealed class AdjustmentState extends Equatable {
  const AdjustmentState();
  @override
  List<Object?> get props => [];
}

class AdjustmentInitial extends AdjustmentState {
  const AdjustmentInitial();
}

class AdjustmentLoading extends AdjustmentState {
  const AdjustmentLoading();
}

class AdjustmentLoaded extends AdjustmentState {
  final List<AdjustmentEntity> adjustments;
  final PaginationMeta meta;
  final String? statusFilter;
  final String? typeFilter;
  final int page;

  const AdjustmentLoaded({
    required this.adjustments,
    required this.meta,
    this.statusFilter,
    this.typeFilter,
    this.page = 1,
  });

  AdjustmentLoaded copyWith({
    List<AdjustmentEntity>? adjustments,
    PaginationMeta? meta,
    String? Function()? statusFilter,
    String? Function()? typeFilter,
    int? page,
  }) {
    return AdjustmentLoaded(
      adjustments: adjustments ?? this.adjustments,
      meta: meta ?? this.meta,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      typeFilter: typeFilter != null ? typeFilter() : this.typeFilter,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [adjustments, meta, statusFilter, typeFilter, page];
}

class AdjustmentError extends AdjustmentState {
  final String message;
  const AdjustmentError(this.message);
  @override
  List<Object?> get props => [message];
}
