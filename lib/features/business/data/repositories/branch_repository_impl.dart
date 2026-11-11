import 'package:fpdart/fpdart.dart';
import 'package:afri_bms/core/errors/app_exception.dart';
import 'package:afri_bms/core/errors/failure.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/repositories/branch_repository.dart';
import '../datasources/business_remote_datasource.dart';

class BranchRepositoryImpl implements BranchRepository {
  final BusinessRemoteDatasource remoteDatasource;

  BranchRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, List<BranchEntity>>> getBranches(
    String businessId,
  ) async {
    try {
      final list = await remoteDatasource.getBusinessBranches(businessId);
      return Right(list);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BranchEntity>> createBranch({
    required String businessId,
    required String name,
    required String currency,
    String? address,
    String? phone,
    bool isMain = false,
  }) async {
    try {
      final branch = await remoteDatasource.createBranch(
        businessId: businessId,
        name: name,
        currency: currency,
        address: address,
        phone: phone,
        isMain: isMain,
      );
      return Right(branch);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BranchEntity>> updateBranch(
    BranchEntity branch,
  ) async {
    try {
      final updated = await remoteDatasource.updateBranch(branch);
      return Right(updated);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBranch(String branchId) async {
    try {
      await remoteDatasource.deleteBranch(branchId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
