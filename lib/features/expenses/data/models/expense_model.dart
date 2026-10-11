import '../../domain/entities/expense_entity.dart';

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.businessId,
    required super.branchId,
    super.categoryId,
    super.categoryName,
    required super.amount,
    required super.description,
    super.paymentMethod = 'cash',
    super.paymentReference,
    required super.expenseDate,
    super.receiptUrl,
    super.recordedBy,
    super.recordedByName,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    String? catName;
    if (json['expense_categories'] != null && json['expense_categories'] is Map) {
      catName = json['expense_categories']['name'] as String?;
    } else if (json['category_name'] != null) {
      catName = json['category_name'] as String?;
    }

    return ExpenseModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      branchId: json['branch_id'] as String,
      categoryId: json['category_id'] as String?,
      categoryName: catName,
      amount: (json['amount'] as num).toInt(),
      description: json['description'] as String,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      paymentReference: json['payment_reference'] as String?,
      expenseDate: json['expense_date'] != null
          ? DateTime.parse(json['expense_date'] as String)
          : DateTime.now(),
      receiptUrl: json['receipt_url'] as String?,
      recordedBy: json['recorded_by'] as String?,
      recordedByName: json['recorded_by_name'] as String?,
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
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'expense_date': expenseDate.toIso8601String().substring(0, 10),
      'receipt_url': receiptUrl,
      'recorded_by': recordedBy,
      'recorded_by_name': recordedByName,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'business_id': businessId,
      'branch_id': branchId,
      if (categoryId != null) 'category_id': categoryId,
      'amount': amount,
      'description': description,
      'payment_method': paymentMethod,
      if (paymentReference != null) 'payment_reference': paymentReference,
      'expense_date': expenseDate.toIso8601String().substring(0, 10),
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (recordedByName != null) 'recorded_by_name': recordedByName,
      if (notes != null) 'notes': notes,
    };
  }
}
