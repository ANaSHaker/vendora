import '../../domain/entities/customer_entities.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    required super.name,
    super.phone,
    super.email,
    super.loyaltyPoints,
    super.totalSpent,
    super.notes,
    super.isActive,
    super.ordersCount,
    super.lastOrderDate,
    super.recentOrders,
    super.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['recent_orders'] as List<dynamic>? ?? [];
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      loyaltyPoints: (json['loyalty_points'] as num?)?.toInt() ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      lastOrderDate: json['last_order_date'] as String?,
      recentOrders: rawOrders
          .map((e) =>
              CustomerOrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson(CustomerFormData data) => {
        'name': data.name,
        'phone': data.phone,
        'email': data.email,
        'notes': data.notes,
        'is_active': data.isActive,
      };
}

class CustomerOrderModel extends CustomerOrderEntity {
  const CustomerOrderModel({
    required super.id,
    required super.reference,
    required super.total,
    required super.status,
    required super.createdAt,
  });

  factory CustomerOrderModel.fromJson(Map<String, dynamic> json) {
    return CustomerOrderModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'paid',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
