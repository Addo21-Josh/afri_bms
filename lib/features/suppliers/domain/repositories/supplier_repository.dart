import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../entities/supplier_entity.dart';

abstract class SupplierRepository {
  Future<Either<Failure, List<SupplierEntity>>> getSuppliers(
    String businessId, {
    String? searchQuery,
  });

  Future<Either<Failure, SupplierEntity>> getSupplierById(String supplierId);

  Future<Either<Failure, SupplierEntity>> createSupplier({
    required String businessId,
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? notes,
  });

  Future<Either<Failure, SupplierEntity>> updateSupplier(
    SupplierEntity supplier,
  );

  Future<Either<Failure, void>> deleteSupplier(String supplierId);

  Future<Either<Failure, SupplierEntity>> updateBalance({
    required String supplierId,
    required int balanceAdjustment,
  });
}
