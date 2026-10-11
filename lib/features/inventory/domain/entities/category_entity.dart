import 'package:equatable/equatable.dart';

class ProductCategoryEntity extends Equatable {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const ProductCategoryEntity({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, businessId, name, description, isActive, createdAt];
}
