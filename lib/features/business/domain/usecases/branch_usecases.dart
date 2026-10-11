import 'package:fpdart/fpdart.dart';
import 'package:afri_bms/core/errors/failure.dart';
import '../entities/branch_entity.dart';
import '../repositories/branch_repository.dart';

class GetBranchesUseCase {
  final BranchRepository repository;
  GetBranchesUseCase(this.repository);

  Future<Either<Failure, List<BranchEntity>>> call(String businessId) {
    return repository.getBranches(businessId);
  }
}

class CreateBranchUseCase {
  final BranchRepository repository;
  CreateBranchUseCase(this.repository);

  Future<Either<Failure, BranchEntity>> call({
    required String businessId,
    required String name,
    required String currency,
    String? address,
    String? phone,
    bool isMain = false,
  }) {
    return repository.createBranch(
      businessId: businessId,
      name: name,
      currency: currency,
      address: address,
      phone: phone,
      isMain: isMain,
    );
  }
}

class UpdateBranchUseCase {
  final BranchRepository repository;
  UpdateBranchUseCase(this.repository);

  Future<Either<Failure, BranchEntity>> call(BranchEntity branch) {
    return repository.updateBranch(branch);
  }
}

class DeleteBranchUseCase {
  final BranchRepository repository;
  DeleteBranchUseCase(this.repository);

  Future<Either<Failure, void>> call(String branchId) {
    return repository.deleteBranch(branchId);
  }
}
