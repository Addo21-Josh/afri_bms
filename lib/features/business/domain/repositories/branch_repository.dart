import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../entities/branch_entity.dart';

abstract class BranchRepository {
  Future<Either<Failure, List<BranchEntity>>> getBranches(String businessId);
  Future<Either<Failure, BranchEntity>> createBranch({
    required String businessId,
    required String name,
    required String currency,
    String? address,
    String? phone,
    bool isMain,
  });
  Future<Either<Failure, BranchEntity>> updateBranch(BranchEntity branch);
  Future<Either<Failure, void>> deleteBranch(String branchId);
}
