import '../../domain/entities/payment_entity.dart';
import '../../../sales/domain/entities/sale_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.businessId,
    super.branchId,
    super.saleId,
    super.customerId,
    super.supplierId,
    required super.amount,
    required super.paymentMethod,
    super.provider,
    super.reference,
    super.phoneNumber,
    super.status,
    super.notes,
    required super.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      branchId: json['branch_id'] as String?,
      saleId: json['sale_id'] as String?,
      customerId: json['customer_id'] as String?,
      supplierId: json['supplier_id'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      paymentMethod: PaymentMethod.fromString(
        json['payment_method'] as String? ?? 'cash',
      ),
      provider: json['provider'] as String?,
      reference: json['reference'] as String?,
      phoneNumber: json['phone_number'] as String?,
      status: json['status'] as String? ?? 'completed',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'branch_id': branchId,
      'sale_id': saleId,
      'customer_id': customerId,
      'supplier_id': supplierId,
      'amount': amount,
      'payment_method': paymentMethod.value,
      'provider': provider,
      'reference': reference,
      'phone_number': phoneNumber,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PaymentEntity toEntity() => this;
}
