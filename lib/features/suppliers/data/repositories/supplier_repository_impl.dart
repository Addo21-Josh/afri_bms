import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/supplier_entity.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../datasources/suppliers_remote_datasource.dart';
import '../models/supplier_model.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final SuppliersRemoteDatasource remoteDatasource;

  const SupplierRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, List<SupplierEntity>>> getSuppliers(
    String businessId, {
    String? searchQuery,
  }) async {
    try {
      final models = await remoteDatasource.getSuppliers(
        businessId,
        searchQuery: searchQuery,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SupplierEntity>> getSupplierById(String supplierId) async {
    try {
      final model = await remoteDatasource.getSupplierById(supplierId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SupplierEntity>> createSupplier({
    required String businessId,
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    try {
      final model = await remoteDatasource.createSupplier(
        businessId: businessId,
        name: name,
        contactPerson: contactPerson,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SupplierEntity>> updateSupplier(SupplierEntity supplier) async {
    try {
      final model = SupplierModel(
        id: supplier.id,
        businessId: supplier.businessId,
        name: supplier.name,
        contactPerson: supplier.contactPerson,
        phone: supplier.phone,
        email: supplier.email,
        address: supplier.address,
        outstandingBalance: supplier.outstandingBalance,
        notes: supplier.notes,
        isActive: supplier.isActive,
        createdAt: supplier.createdAt,
        updatedAt: supplier.updatedAt,
      );
      final updated = await remoteDatasource.updateSupplier(model);
      return Right(updated.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSupplier(String supplierId) async {
    try {
      await remoteDatasource.deleteSupplier(supplierId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SupplierEntity>> updateBalance({
    required String supplierId,
    required int balanceAdjustment,
  }) async {
    try {
      final updated = await remoteDatasource.updateBalance(
        supplierId: supplierId,
        balanceAdjustment: balanceAdjustment,
      );
      return Right(updated.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
