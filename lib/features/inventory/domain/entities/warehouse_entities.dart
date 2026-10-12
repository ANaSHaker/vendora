import 'package:equatable/equatable.dart';

class WarehouseEntity extends Equatable {
  final String id;
  final String name;
  final String code;
  final String type;
  final bool isActive;
  final bool isDefault;
  final String? notes;
  final String? branchName;

  const WarehouseEntity({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.isActive,
    required this.isDefault,
    this.notes,
    this.branchName,
  });

  @override
  List<Object?> get props =>
      [id, name, code, type, isActive, isDefault, notes, branchName];
}

class WarehouseFormData extends Equatable {
  final String name;
  final String code;
  final String type;
  final bool isActive;
  final bool isDefault;
  final String? notes;
  final String? branchId;

  const WarehouseFormData({
    required this.name,
    required this.code,
    required this.type,
    this.isActive = true,
    this.isDefault = false,
    this.notes,
    this.branchId,
  });

  @override
  List<Object?> get props =>
      [name, code, type, isActive, isDefault, notes, branchId];
}
