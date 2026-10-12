import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final int loyaltyPoints;
  final double totalSpent;
  final String? notes;
  final bool isActive;
  final int ordersCount;
  final String? lastOrderDate;
  final List<CustomerOrderEntity> recentOrders;
  final String createdAt;

  const CustomerEntity({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.loyaltyPoints = 0,
    this.totalSpent = 0,
    this.notes,
    this.isActive = true,
    this.ordersCount = 0,
    this.lastOrderDate,
    this.recentOrders = const [],
    this.createdAt = '',
  });

  @override
  List<Object?> get props => [
        id, name, phone, email, loyaltyPoints, totalSpent, notes,
        isActive, ordersCount, lastOrderDate, createdAt,
      ];
}

class CustomerOrderEntity extends Equatable {
  final String id;
  final String reference;
  final double total;
  final String status;
  final String createdAt;

  const CustomerOrderEntity({
    required this.id,
    required this.reference,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, reference, total, status, createdAt];
}

class CustomerFormData extends Equatable {
  final String name;
  final String? phone;
  final String? email;
  final String? notes;
  final bool isActive;

  const CustomerFormData({
    required this.name,
    this.phone,
    this.email,
    this.notes,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [name, phone, email, notes, isActive];
}
