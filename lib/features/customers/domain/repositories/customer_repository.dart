import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../entities/customer_entity.dart';
import '../../../sales/domain/entities/sale_entity.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<CustomerEntity>>> getCustomers(
    String businessId, {
    String? searchQuery,
  });

  Future<Either<Failure, CustomerEntity>> getCustomerById(String customerId);

  Future<Either<Failure, CustomerEntity>> createCustomer({
    required String businessId,
    required String name,
    String? phone,
    String? email,
    String? address,
    int creditLimit = 0,
    String? notes,
  });

  Future<Either<Failure, CustomerEntity>> updateCustomer(
    CustomerEntity customer,
  );

  Future<Either<Failure, void>> deleteCustomer(String customerId);

  Future<Either<Failure, CustomerEntity>> updateBalance({
    required String customerId,
    required int
    balanceAdjustment, // Positive increases debt, negative decreases debt
  });

  Future<Either<Failure, List<SaleEntity>>> getCustomerSales(String customerId);
}
