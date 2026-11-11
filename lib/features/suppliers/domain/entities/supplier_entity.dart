import 'package:equatable/equatable.dart';

class SupplierEntity extends Equatable {
  final String id;
  final String businessId;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final int outstandingBalance; // Amount owed to supplier (minor units)
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SupplierEntity({
    required this.id,
    required this.businessId,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.outstandingBalance = 0,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  bool get hasBalance => outstandingBalance > 0;

  String get initials {
    if (name.isEmpty) return 'S';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  List<Object?> get props => [
    id,
    businessId,
    name,
    contactPerson,
    phone,
    email,
    address,
    outstandingBalance,
    notes,
    isActive,
    createdAt,
    updatedAt,
  ];
}
