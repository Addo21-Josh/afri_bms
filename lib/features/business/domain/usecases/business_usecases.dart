import 'package:fpdart/fpdart.dart';
import 'package:afri_bms/core/errors/failure.dart';
import '../entities/business_entity.dart';
import '../repositories/business_repository.dart';

class CreateBusinessUseCase {
  final BusinessRepository repository;
  CreateBusinessUseCase(this.repository);

  Future<Either<Failure, BusinessEntity>> call({
    required String ownerId,
    required String name,
    required String defaultCurrency,
    required String firstBranchName,
  }) {
    return repository.createBusiness(
      ownerId: ownerId,
      name: name,
      defaultCurrency: defaultCurrency,
      firstBranchName: firstBranchName,
    );
  }
}

class GetUserBusinessesUseCase {
  final BusinessRepository repository;
  GetUserBusinessesUseCase(this.repository);

  Future<Either<Failure, List<BusinessEntity>>> call(String userId) {
    return repository.getUserBusinesses(userId);
  }
}

class UpdateBusinessUseCase {
  final BusinessRepository repository;
  UpdateBusinessUseCase(this.repository);

  Future<Either<Failure, BusinessEntity>> call(BusinessEntity business) {
    return repository.updateBusiness(business);
  }
}
