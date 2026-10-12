import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.role,
    super.isAdmin,
    super.currencyCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {bool isAdmin = false}) {
    return UserModel(
      id: json['id'].toString(),
      name: json['name'] as String? ??
            json['full_name'] as String? ??
            json['username'] as String? ??
            '',
      email: json['email'] as String? ??
             json['email_address'] as String? ??
             '',
      role: json['role'] as String?,
      isAdmin: isAdmin,
      currencyCode: json['currency'] as String? ??
                    json['currency_code'] as String?,
    );
  }
}
