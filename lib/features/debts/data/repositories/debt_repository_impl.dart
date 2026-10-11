import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_payment_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../datasources/debts_remote_datasource.dart';
import '../models/debt_model.dart';

class DebtRepositoryImpl implements DebtRepository {
  const DebtRepositoryImpl({required DebtsRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final DebtsRemoteDataSource _remoteDataSource;

  @override
  Future<List<DebtEntity>> getDebts({
    required String businessId,
    String? branchId,
    DebtType? debtType,
    DebtStatus? status,
    String? customerId,
    String? supplierId,
  }) async {
    return _remoteDataSource.getDebts(
      businessId: businessId,
      branchId: branchId,
      debtType: debtType,
      status: status,
      customerId: customerId,
      supplierId: supplierId,
    );
  }

  @override
  Future<DebtEntity> getDebtById(String debtId) async {
    return _remoteDataSource.getDebtById(debtId);
  }

  @override
  Future<DebtEntity> createDebt(DebtEntity debt) async {
    final model = DebtModel(
      id: debt.id,
      businessId: debt.businessId,
      branchId: debt.branchId,
      debtType: debt.debtType,
      customerId: debt.customerId,
      supplierId: debt.supplierId,
      saleId: debt.saleId,
      personName: debt.personName,
      personPhone: debt.personPhone,
      initialAmount: debt.initialAmount,
      remainingBalance: debt.remainingBalance,
      dueDate: debt.dueDate,
      status: debt.status,
      notes: debt.notes,
      createdAt: debt.createdAt,
      updatedAt: debt.updatedAt,
    );
    return _remoteDataSource.createDebt(model);
  }

  @override
  Future<DebtEntity> updateDebt(DebtEntity debt) async {
    final model = DebtModel(
      id: debt.id,
      businessId: debt.businessId,
      branchId: debt.branchId,
      debtType: debt.debtType,
      customerId: debt.customerId,
      supplierId: debt.supplierId,
      saleId: debt.saleId,
      personName: debt.personName,
      personPhone: debt.personPhone,
      initialAmount: debt.initialAmount,
      remainingBalance: debt.remainingBalance,
      dueDate: debt.dueDate,
      status: debt.status,
      notes: debt.notes,
      createdAt: debt.createdAt,
      updatedAt: debt.updatedAt,
    );
    return _remoteDataSource.updateDebt(model);
  }

  @override
  Future<void> deleteDebt(String debtId) async {
    return _remoteDataSource.deleteDebt(debtId);
  }

  @override
  Future<List<DebtPaymentEntity>> getDebtPayments(String debtId) async {
    return _remoteDataSource.getDebtPayments(debtId);
  }

  @override
  Future<DebtPaymentEntity> recordDebtPayment({
    required String businessId,
    required String debtId,
    required int amount,
    String paymentMethod = 'cash',
    String? paymentReference,
    String? notes,
  }) async {
    return _remoteDataSource.recordDebtPayment(
      businessId: businessId,
      debtId: debtId,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentReference: paymentReference,
      notes: notes,
    );
  }
}
