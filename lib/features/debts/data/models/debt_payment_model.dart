import '../../domain/entities/debt_payment_entity.dart';

class DebtPaymentModel extends DebtPaymentEntity {
  const DebtPaymentModel({
    required super.id,
    required super.businessId,
    required super.debtId,
    required super.amount,
    super.paymentMethod = 'cash',
    super.paymentReference,
    super.notes,
    super.recordedBy,
    required super.createdAt,
  });

  factory DebtPaymentModel.fromJson(Map<String, dynamic> json) {
    return DebtPaymentModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      debtId: json['debt_id'] as String,
      amount: (json['amount'] as num).toInt(),
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      paymentReference: json['payment_reference'] as String?,
      notes: json['notes'] as String?,
      recordedBy: json['recorded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'debt_id': debtId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'notes': notes,
      'recorded_by': recordedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'business_id': businessId,
      'debt_id': debtId,
      'amount': amount,
      'payment_method': paymentMethod,
      if (paymentReference != null) 'payment_reference': paymentReference,
      if (notes != null) 'notes': notes,
      if (recordedBy != null) 'recorded_by': recordedBy,
    };
  }
}
