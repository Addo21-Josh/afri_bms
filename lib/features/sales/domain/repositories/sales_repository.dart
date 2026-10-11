import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../entities/sale_entity.dart';
import '../entities/sale_item_entity.dart';

abstract class SalesRepository {
  Future<Either<Failure, SaleEntity>> processSale({
    required String businessId,
    required String branchId,
    required String cashierId,
    required String saleNumber,
    required int subtotal,
    required int discountAmount,
    required int taxAmount,
    required int totalAmount,
    required PaymentMethod paymentMethod,
    required int amountTendered,
    required int changeGiven,
    String? customerId,
    String? paymentReference,
    String? customerName,
    String? customerPhone,
    String? notes,
    required List<SaleItemEntity> items,
  });

  Future<Either<Failure, List<SaleEntity>>> getSales({
    required String businessId,
    String? branchId,
    int limit = 50,
    int offset = 0,
    String? searchQuery,
  });

  Future<Either<Failure, SaleEntity>> getSaleById(String saleId);
}
