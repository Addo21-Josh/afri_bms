import '../../domain/entities/debt_entity.dart';

class DebtModel extends DebtEntity {
  const DebtModel({
    required super.id,
    required super.businessId,
    required super.branchId,
    required super.debtType,
    super.customerId,
    super.supplierId,
    super.saleId,
    required super.personName,
    super.personPhone,
    required super.initialAmount,
    required super.remainingBalance,
    super.dueDate,
    super.status = DebtStatus.active,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      branchId: json['branch_id'] as String,
      debtType: DebtType.fromString(json['debt_type'] as String? ?? 'receivable'),
      customerId: json['customer_id'] as String?,
      supplierId: json['supplier_id'] as String?,
      saleId: json['sale_id'] as String?,
      personName: json['person_name'] as String? ?? 'Unknown',
      personPhone: json['person_phone'] as String?,
      initialAmount: (json['initial_amount'] as num).toInt(),
      remainingBalance: (json['remaining_balance'] as num).toInt(),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      status: DebtStatus.fromString(json['status'] as String? ?? 'active'),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'branch_id': branchId,
      'debt_type': debtType.value,
      'customer_id': customerId,
      'supplier_id': supplierId,
      'sale_id': saleId,
      'person_name': personName,
      'person_phone': personPhone,
      'initial_amount': initialAmount,
      'remaining_balance': remainingBalance,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String().substring(0, 10),
      'status': status.value,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'business_id': businessId,
      'branch_id': branchId,
      'debt_type': debtType.value,
      if (customerId != null) 'customer_id': customerId,
      if (supplierId != null) 'supplier_id': supplierId,
      if (saleId != null) 'sale_id': saleId,
      'person_name': personName,
      if (personPhone != null) 'person_phone': personPhone,
      'initial_amount': initialAmount,
      'remaining_balance': remainingBalance,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String().substring(0, 10),
      'status': status.value,
      if (notes != null) 'notes': notes,
    };
  }
}
