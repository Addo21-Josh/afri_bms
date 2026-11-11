import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../entities/staff_user_entity.dart';

abstract class UserManagementRepository {
  Future<Either<Failure, List<StaffUserEntity>>> getBusinessStaff(
    String businessId,
  );

  Future<Either<Failure, StaffUserEntity>> assignStaffRole({
    required String businessId,
    required String userEmail,
    required UserRoleType role,
    String? fullName,
    String? password,
    String? phone,
    String? branchId,
    Map<String, dynamic> customPermissions = const {},
  });

  Future<Either<Failure, void>> updateStaffRole({
    required String roleId,
    required UserRoleType newRole,
    String? newBranchId,
    bool? isActive,
    Map<String, dynamic>? customPermissions,
  });

  Future<Either<Failure, void>> removeStaffRole(String roleId);

  Future<Either<Failure, UserRoleType?>> getCurrentUserRole(String businessId);
}
