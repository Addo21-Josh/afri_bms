import 'package:equatable/equatable.dart';

enum UserRoleType {
  admin,
  branchManager,
  salesperson,
  cashier,
  custom;

  String get value => toDbString();

  static UserRoleType fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRoleType.admin;
      case 'branch_manager':
      case 'branchmanager':
        return UserRoleType.branchManager;
      case 'salesperson':
        return UserRoleType.salesperson;
      case 'cashier':
        return UserRoleType.cashier;
      default:
        return UserRoleType.custom;
    }
  }

  String get displayName {
    switch (this) {
      case UserRoleType.admin:
        return 'Admin';
      case UserRoleType.branchManager:
        return 'Branch Manager';
      case UserRoleType.salesperson:
        return 'Salesperson';
      case UserRoleType.cashier:
        return 'Cashier';
      case UserRoleType.custom:
        return 'Custom';
    }
  }

  String toDbString() {
    switch (this) {
      case UserRoleType.admin:
        return 'admin';
      case UserRoleType.branchManager:
        return 'branch_manager';
      case UserRoleType.salesperson:
        return 'salesperson';
      case UserRoleType.cashier:
        return 'cashier';
      case UserRoleType.custom:
        return 'custom';
    }
  }
}

class StaffUserEntity extends Equatable {
  final String roleId;
  final String userId;
  final String businessId;
  final String? branchId;
  final String? branchName;
  final UserRoleType role;
  final String email;
  final String fullName;
  final String? phone;
  final bool isActive;
  final Map<String, dynamic> customPermissions;
  final DateTime createdAt;

  const StaffUserEntity({
    required this.roleId,
    required this.userId,
    required this.businessId,
    this.branchId,
    this.branchName,
    required this.role,
    required this.email,
    required this.fullName,
    this.phone,
    this.isActive = true,
    this.customPermissions = const {},
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    roleId,
    userId,
    businessId,
    branchId,
    branchName,
    role,
    email,
    fullName,
    phone,
    isActive,
    customPermissions,
    createdAt,
  ];
}
