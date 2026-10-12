import '../../domain/entities/user_entity.dart';

sealed class UsersState {
  const UsersState();
}

class UsersInitial extends UsersState {
  const UsersInitial();
}

class UsersLoading extends UsersState {
  const UsersLoading();
}

class UsersLoaded extends UsersState {
  final List<UserEntity> users;
  final String search;
  const UsersLoaded({required this.users, this.search = ''});
}

class UsersError extends UsersState {
  final String message;
  const UsersError(this.message);
}
