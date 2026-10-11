import '../../domain/entities/staff_user_entity.dart';

class StaffUserModel {
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

  const StaffUserModel({
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

  factory StaffUserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final branch = json['branches'] as Map<String, dynamic>?;

    return StaffUserModel(
      roleId: json['id'] as String,
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String,
      branchId: json['branch_id'] as String?,
      branchName: branch?['name'] as String?,
      role: UserRoleType.fromString(json['role'] as String? ?? 'salesperson'),
      email: (profile?['email'] ?? json['email'] ?? '') as String,
      fullName: (profile?['full_name'] ?? json['full_name'] ?? 'Staff Member') as String,
      phone: profile?['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      customPermissions: (json['custom_permissions'] as Map<String, dynamic>?) ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': roleId,
      'user_id': userId,
      'business_id': businessId,
      'branch_id': branchId,
      'role': role.toDbString(),
      'is_active': isActive,
      'custom_permissions': customPermissions,
    };
  }

  StaffUserEntity toEntity() {
    return StaffUserEntity(
      roleId: roleId,
      userId: userId,
      businessId: businessId,
      branchId: branchId,
      branchName: branchName,
      role: role,
      email: email,
      fullName: fullName,
      phone: phone,
      isActive: isActive,
      customPermissions: customPermissions,
      createdAt: createdAt,
    );
  }
}
