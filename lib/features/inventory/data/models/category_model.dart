import '../../domain/entities/category_entity.dart';

class ProductCategoryModel {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const ProductCategoryModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'description': description,
      'is_active': isActive,
    };
  }

  ProductCategoryEntity toEntity() {
    return ProductCategoryEntity(
      id: id,
      businessId: businessId,
      name: name,
      description: description,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}
