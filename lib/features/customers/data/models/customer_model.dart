import '../../domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    required super.businessId,
    required super.name,
    super.phone,
    super.email,
    super.address,
    super.creditLimit,
    super.outstandingBalance,
    super.notes,
    super.isActive,
    required super.createdAt,
    super.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      creditLimit: (json['credit_limit'] as num?)?.toInt() ?? 0,
      outstandingBalance: (json['outstanding_balance'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  factory CustomerModel.fromEntity(CustomerEntity entity) {
    return CustomerModel(
      id: entity.id,
      businessId: entity.businessId,
      name: entity.name,
      phone: entity.phone,
      email: entity.email,
      address: entity.address,
      creditLimit: entity.creditLimit,
      outstandingBalance: entity.outstandingBalance,
      notes: entity.notes,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'credit_limit': creditLimit,
      'outstanding_balance': outstandingBalance,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  CustomerEntity toEntity() => this;
}
