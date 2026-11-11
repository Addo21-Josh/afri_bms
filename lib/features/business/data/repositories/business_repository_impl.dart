import 'package:fpdart/fpdart.dart';
import 'package:afri_bms/core/errors/app_exception.dart';
import 'package:afri_bms/core/errors/failure.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/repositories/business_repository.dart';
import '../datasources/business_remote_datasource.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessRemoteDatasource remoteDatasource;

  BusinessRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, BusinessEntity>> createBusiness({
    required String ownerId,
    required String name,
    required String defaultCurrency,
    required String firstBranchName,
  }) async {
    try {
      final business = await remoteDatasource.createBusinessWithBranch(
        ownerId: ownerId,
        name: name,
        defaultCurrency: defaultCurrency,
        firstBranchName: firstBranchName,
      );
      return Right(business);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BusinessEntity>>> getUserBusinesses(
    String userId,
  ) async {
    try {
      final list = await remoteDatasource.getUserBusinesses(userId);
      return Right(list);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BusinessEntity>> updateBusiness(
    BusinessEntity business,
  ) async {
    try {
      final updated = await remoteDatasource.updateBusiness(business);
      return Right(updated);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BranchEntity>>> getBusinessBranches(
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
  Future<Either<Failure, void>> deleteBusiness(String businessId) async {
    try {
      await remoteDatasource.deleteBusiness(businessId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
