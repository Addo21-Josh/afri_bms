import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payments_remote_datasource.dart';
import '../../../sales/domain/entities/sale_entity.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentsRemoteDatasource remoteDatasource;

  const PaymentRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, PaymentEntity>> recordPayment({
    required String businessId,
    String? branchId,
    String? saleId,
    String? customerId,
    String? supplierId,
    required int amount,
    required PaymentMethod paymentMethod,
    String? provider,
    String? reference,
    String? phoneNumber,
    String status = 'completed',
    String? notes,
  }) async {
    try {
      final model = await remoteDatasource.recordPayment(
        businessId: businessId,
        branchId: branchId,
        saleId: saleId,
        customerId: customerId,
        supplierId: supplierId,
        amount: amount,
        paymentMethod: paymentMethod,
        provider: provider,
        reference: reference,
        phoneNumber: phoneNumber,
        status: status,
        notes: notes,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PaymentEntity>>> getPaymentsBySale(String saleId) async {
    try {
      final models = await remoteDatasource.getPaymentsBySale(saleId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PaymentEntity>>> getPaymentsByCustomer(String customerId) async {
    try {
      final models = await remoteDatasource.getPaymentsByCustomer(customerId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PaymentEntity>>> getPaymentsByBusiness({
    required String businessId,
    String? branchId,
    int limit = 50,
  }) async {
    try {
      final models = await remoteDatasource.getPaymentsByBusiness(
        businessId: businessId,
        branchId: branchId,
        limit: limit,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
