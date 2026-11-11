import 'package:equatable/equatable.dart';
import '../../../sales/domain/entities/sale_entity.dart';

class PaymentEntity extends Equatable {
  final String id;
  final String businessId;
  final String? branchId;
  final String? saleId;
  final String? customerId;
  final String? supplierId;
  final int amount; // Minor units (kobo/pesewas)
  final PaymentMethod paymentMethod;
  final String? provider;
  final String? reference;
  final String? phoneNumber;
  final String status;
  final String? notes;
  final DateTime createdAt;

  const PaymentEntity({
    required this.id,
    required this.businessId,
    this.branchId,
    this.saleId,
    this.customerId,
    this.supplierId,
    required this.amount,
    required this.paymentMethod,
    this.provider,
    this.reference,
    this.phoneNumber,
    this.status = 'completed',
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    businessId,
    branchId,
    saleId,
    customerId,
    supplierId,
    amount,
    paymentMethod,
    provider,
    reference,
    phoneNumber,
    status,
    notes,
    createdAt,
  ];
}
