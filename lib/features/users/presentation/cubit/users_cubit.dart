import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/users_usecases.dart';
import 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  final GetUsersUseCase _get;
  final CreateUserUseCase _create;
  final UpdateUserUseCase _update;
  final DeleteUserUseCase _delete;

  String _search = '';

  UsersCubit({
    required GetUsersUseCase get,
    required CreateUserUseCase create,
    required UpdateUserUseCase update,
    required DeleteUserUseCase delete,
  })  : _get = get,
        _create = create,
        _update = update,
        _delete = delete,
        super(const UsersInitial());

  Future<void> load() async {
    emit(const UsersLoading());
    final result = await _get(search: _search.isEmpty ? null : _search);
    result.fold(
      (f) => emit(UsersError(f.message)),
      (list) => emit(UsersLoaded(users: list, search: _search)),
    );
  }

  void search(String q) {
    _search = q;
    load();
  }

  void refresh() => load();

  Future<bool> createUser(UserFormData data) async {
    final result = await _create(data);
    return result.fold((_) => false, (_) {
      load();
      return true;
    });
  }

  Future<bool> updateUser(String id, UserFormData data) async {
    final result = await _update(id, data);
    return result.fold((_) => false, (_) {
      load();
      return true;
    });
  }

  Future<bool> deleteUser(String id) async {
    final result = await _delete(id);
    return result.fold((_) => false, (_) {
      load();
      return true;
    });
  }
}
