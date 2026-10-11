import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customers_remote_datasource.dart';
import '../models/customer_model.dart';
import '../../../sales/domain/entities/sale_entity.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomersRemoteDatasource remoteDatasource;

  const CustomerRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, List<CustomerEntity>>> getCustomers(
    String businessId, {
    String? searchQuery,
  }) async {
    try {
      final models = await remoteDatasource.getCustomers(
        businessId,
        searchQuery: searchQuery,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> getCustomerById(String customerId) async {
    try {
      final model = await remoteDatasource.getCustomerById(customerId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> createCustomer({
    required String businessId,
    required String name,
    String? phone,
    String? email,
    String? address,
    int creditLimit = 0,
    String? notes,
  }) async {
    try {
      final model = await remoteDatasource.createCustomer(
        businessId: businessId,
        name: name,
        phone: phone,
        email: email,
        address: address,
        creditLimit: creditLimit,
        notes: notes,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> updateCustomer(CustomerEntity customer) async {
    try {
      final model = CustomerModel(
        id: customer.id,
        businessId: customer.businessId,
        name: customer.name,
        phone: customer.phone,
        email: customer.email,
        address: customer.address,
        creditLimit: customer.creditLimit,
        outstandingBalance: customer.outstandingBalance,
        notes: customer.notes,
        isActive: customer.isActive,
        createdAt: customer.createdAt,
        updatedAt: customer.updatedAt,
      );
      final updated = await remoteDatasource.updateCustomer(model);
      return Right(updated.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String customerId) async {
    try {
      await remoteDatasource.deleteCustomer(customerId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> updateBalance({
    required String customerId,
    required int balanceAdjustment,
  }) async {
    try {
      final updated = await remoteDatasource.updateBalance(
        customerId: customerId,
        balanceAdjustment: balanceAdjustment,
      );
      return Right(updated.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SaleEntity>>> getCustomerSales(String customerId) async {
    try {
      final sales = await remoteDatasource.getCustomerSales(customerId);
      return Right(sales.map((s) => s.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
