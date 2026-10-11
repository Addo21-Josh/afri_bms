import 'package:equatable/equatable.dart';

class ExpenseEntity extends Equatable {
  const ExpenseEntity({
    required this.id,
    required this.businessId,
    required this.branchId,
    this.categoryId,
    this.categoryName,
    required this.amount, // in minor units
    required this.description,
    this.paymentMethod = 'cash',
    this.paymentReference,
    required this.expenseDate,
    this.receiptUrl,
    this.recordedBy,
    this.recordedByName,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String businessId;
  final String branchId;
  final String? categoryId;
  final String? categoryName;
  final int amount; // in minor units (e.g. pesewas / cents)
  final String description;
  final String paymentMethod;
  final String? paymentReference;
  final DateTime expenseDate;
  final String? receiptUrl;
  final String? recordedBy;
  final String? recordedByName;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        businessId,
        branchId,
        categoryId,
        categoryName,
        amount,
        description,
        paymentMethod,
        paymentReference,
        expenseDate,
        receiptUrl,
        recordedBy,
        recordedByName,
        notes,
        createdAt,
        updatedAt,
      ];
}
