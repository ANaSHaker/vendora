import 'package:equatable/equatable.dart';

class AdminPlanEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final double price;
  final bool isActive;
  final String? description;
  final int? maxProducts;
  final int? maxUsers;
  final int? maxBranches;

  const AdminPlanEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.isActive,
    this.description,
    this.maxProducts,
    this.maxUsers,
    this.maxBranches,
  });

  @override
  List<Object?> get props => [
        id, name, slug, price, isActive,
        description, maxProducts, maxUsers, maxBranches,
      ];
}
