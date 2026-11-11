import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../entities/payment_entity.dart';
import '../../../sales/domain/entities/sale_entity.dart';

abstract class PaymentRepository {
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
  });

  Future<Either<Failure, List<PaymentEntity>>> getPaymentsBySale(String saleId);

  Future<Either<Failure, List<PaymentEntity>>> getPaymentsByCustomer(
    String customerId,
  );

  Future<Either<Failure, List<PaymentEntity>>> getPaymentsByBusiness({
    required String businessId,
    String? branchId,
    int limit = 50,
  });
}
