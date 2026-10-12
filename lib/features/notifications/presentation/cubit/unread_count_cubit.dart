import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/notifications_usecases.dart';

/// Lightweight cubit for the header bell badge.
/// Provided at shell level so it's always alive.
class UnreadCountCubit extends Cubit<int> {
  final GetUnreadCountUseCase _getCount;

  UnreadCountCubit({required GetUnreadCountUseCase getCount})
      : _getCount = getCount,
        super(0);

  Future<void> refresh() async {
    final result = await _getCount();
    result.fold((_) {}, (count) => emit(count));
  }

  void decrement() {
    if (state > 0) emit(state - 1);
  }

  void reset() => emit(0);
}
