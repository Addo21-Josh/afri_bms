import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/entities/sale_item_entity.dart';
import '../../domain/repositories/sales_repository.dart';
import '../datasources/sales_remote_datasource.dart';
import '../models/sale_item_model.dart';

class SalesRepositoryImpl implements SalesRepository {
  final SalesRemoteDatasource remoteDatasource;

  SalesRepositoryImpl({required this.remoteDatasource});

  @override
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
  }) async {
    try {
      final itemModels = items.map((i) => SaleItemModel(
        id: i.id,
        saleId: i.saleId,
        productId: i.productId,
        variantId: i.variantId,
        productName: i.productName,
        variantName: i.variantName,
        unitCostPrice: i.unitCostPrice,
        unitPrice: i.unitPrice,
        quantity: i.quantity,
        discountAmount: i.discountAmount,
        totalPrice: i.totalPrice,
        createdAt: i.createdAt,
      )).toList();

      final saleModel = await remoteDatasource.processSale(
        businessId: businessId,
        branchId: branchId,
        cashierId: cashierId,
        saleNumber: saleNumber,
        subtotal: subtotal,
        discountAmount: discountAmount,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod.value,
        amountTendered: amountTendered,
        changeGiven: changeGiven,
        customerId: customerId,
        paymentReference: paymentReference,
        customerName: customerName,
        customerPhone: customerPhone,
        notes: notes,
        items: itemModels,
      );

      return Right(saleModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SaleEntity>>> getSales({
    required String businessId,
    String? branchId,
    int limit = 50,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      final models = await remoteDatasource.getSales(
        businessId: businessId,
        branchId: branchId,
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SaleEntity>> getSaleById(String saleId) async {
    try {
      final model = await remoteDatasource.getSaleById(saleId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
