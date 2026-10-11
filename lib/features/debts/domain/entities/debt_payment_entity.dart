import 'package:equatable/equatable.dart';

class DebtPaymentEntity extends Equatable {
  const DebtPaymentEntity({
    required this.id,
    required this.businessId,
    required this.debtId,
    required this.amount, // in minor units
    this.paymentMethod = 'cash',
    this.paymentReference,
    this.notes,
    this.recordedBy,
    required this.createdAt,
  });

  final String id;
  final String businessId;
  final String debtId;
  final int amount; // in minor units
  final String paymentMethod;
  final String? paymentReference;
  final String? notes;
  final String? recordedBy;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        businessId,
        debtId,
        amount,
        paymentMethod,
        paymentReference,
        notes,
        recordedBy,
        createdAt,
      ];
}
