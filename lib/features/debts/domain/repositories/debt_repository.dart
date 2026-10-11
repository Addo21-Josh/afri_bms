import '../entities/debt_entity.dart';
import '../entities/debt_payment_entity.dart';

abstract class DebtRepository {
  Future<List<DebtEntity>> getDebts({
    required String businessId,
    String? branchId,
    DebtType? debtType,
    DebtStatus? status,
    String? customerId,
    String? supplierId,
  });

  Future<DebtEntity> getDebtById(String debtId);
  Future<DebtEntity> createDebt(DebtEntity debt);
  Future<DebtEntity> updateDebt(DebtEntity debt);
  Future<void> deleteDebt(String debtId);

  Future<List<DebtPaymentEntity>> getDebtPayments(String debtId);
  Future<DebtPaymentEntity> recordDebtPayment({
    required String businessId,
    required String debtId,
    required int amount,
    String paymentMethod = 'cash',
    String? paymentReference,
    String? notes,
  });
}
