import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../entities/business_entity.dart';
import '../entities/branch_entity.dart';

abstract class BusinessRepository {
  Future<Either<Failure, BusinessEntity>> createBusiness({
    required String ownerId,
    required String name,
    required String defaultCurrency,
    required String firstBranchName,
  });

  Future<Either<Failure, List<BusinessEntity>>> getUserBusinesses(String userId);
  Future<Either<Failure, BusinessEntity>> updateBusiness(BusinessEntity business);
  Future<Either<Failure, List<BranchEntity>>> getBusinessBranches(String businessId);
}
