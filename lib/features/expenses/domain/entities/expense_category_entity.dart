import 'package:equatable/equatable.dart';

class ExpenseCategoryEntity extends Equatable {
  const ExpenseCategoryEntity({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    this.icon = 'category',
    this.color = '0xFF2196F3',
    this.isSystem = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String businessId;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        businessId,
        name,
        description,
        icon,
        color,
        isSystem,
        createdAt,
        updatedAt,
      ];
}
