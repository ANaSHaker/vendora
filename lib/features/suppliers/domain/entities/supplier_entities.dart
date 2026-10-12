import 'package:equatable/equatable.dart';

class SupplierEntity extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxNo;
  final double openingBalance;
  final bool isActive;
  final String? notes;
  final String createdAt;

  const SupplierEntity({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.taxNo,
    this.openingBalance = 0,
    this.isActive = true,
    this.notes,
    this.createdAt = '',
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        address,
        taxNo,
        openingBalance,
        isActive,
        notes,
        createdAt,
      ];
}

class SupplierFormData extends Equatable {
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxNo;
  final double openingBalance;
  final bool isActive;
  final String? notes;

  const SupplierFormData({
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.taxNo,
    this.openingBalance = 0,
    this.isActive = true,
    this.notes,
  });

  @override
  List<Object?> get props =>
      [name, phone, email, address, taxNo, openingBalance, isActive, notes];
}
