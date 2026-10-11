import '../../domain/entities/expense_category_entity.dart';

class ExpenseCategoryModel extends ExpenseCategoryEntity {
  const ExpenseCategoryModel({
    required super.id,
    required super.businessId,
    required super.name,
    super.description,
    super.icon = 'category',
    super.color = '0xFF2196F3',
    super.isSystem = false,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ExpenseCategoryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'category',
      color: json['color'] as String? ?? '0xFF2196F3',
      isSystem: json['is_system'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      if (description != null) 'description': description,
      'icon': icon,
      'color': color,
      'is_system': isSystem,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'business_id': businessId,
      'name': name,
      if (description != null) 'description': description,
      'icon': icon,
      'color': color,
      'is_system': isSystem,
    };
  }
}
