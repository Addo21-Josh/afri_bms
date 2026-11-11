import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final int creditLimit; // Minor currency units (e.g. kobo/pesewas)
  final int outstandingBalance; // Amount owed to business (debt)
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CustomerEntity({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.creditLimit = 0,
    this.outstandingBalance = 0,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  bool get hasDebt => outstandingBalance > 0;

  int? get availableCredit =>
      creditLimit > 0 ? (creditLimit - outstandingBalance) : null;

  String get initials {
    if (name.isEmpty) return 'C';
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
    phone,
    email,
    address,
    creditLimit,
    outstandingBalance,
    notes,
    isActive,
    createdAt,
    updatedAt,
  ];
}
