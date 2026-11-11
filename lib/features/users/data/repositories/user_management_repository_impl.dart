import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/staff_user_entity.dart';
import '../../domain/repositories/user_management_repository.dart';
import '../datasources/user_management_remote_datasource.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  final UserManagementRemoteDatasource remoteDatasource;

  UserManagementRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, List<StaffUserEntity>>> getBusinessStaff(
    String businessId,
  ) async {
    try {
      final models = await remoteDatasource.getBusinessStaff(businessId);
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, StaffUserEntity>> assignStaffRole({
    required String businessId,
    required String userEmail,
    required UserRoleType role,
    String? fullName,
    String? password,
    String? phone,
    String? branchId,
    Map<String, dynamic> customPermissions = const {},
  }) async {
    try {
      final model = await remoteDatasource.assignStaffRole(
        businessId: businessId,
        userEmail: userEmail,
        role: role,
        fullName: fullName,
        password: password,
        phone: phone,
        branchId: branchId,
        customPermissions: customPermissions,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateStaffRole({
    required String roleId,
    required UserRoleType newRole,
    String? newBranchId,
    bool? isActive,
    Map<String, dynamic>? customPermissions,
  }) async {
    try {
      await remoteDatasource.updateStaffRole(
        roleId: roleId,
        newRole: newRole,
        newBranchId: newBranchId,
        isActive: isActive,
        customPermissions: customPermissions,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeStaffRole(String roleId) async {
    try {
      await remoteDatasource.removeStaffRole(roleId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserRoleType?>> getCurrentUserRole(
    String businessId,
  ) async {
    try {
      final role = await remoteDatasource.getCurrentUserRole(businessId);
      return Right(role);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
