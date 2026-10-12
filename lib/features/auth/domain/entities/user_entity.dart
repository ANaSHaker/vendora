import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? role;
  final bool isAdmin;
  final String? currencyCode;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.isAdmin = false,
    this.currencyCode,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  List<Object?> get props => [id, name, email, role, isAdmin, currencyCode];
}
