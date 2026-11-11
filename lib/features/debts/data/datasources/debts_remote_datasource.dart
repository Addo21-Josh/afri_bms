import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/debt_entity.dart';
import '../models/debt_model.dart';
import '../models/debt_payment_model.dart';

abstract class DebtsRemoteDataSource {
  Future<List<DebtModel>> getDebts({
    required String businessId,
    String? branchId,
    DebtType? debtType,
    DebtStatus? status,
    String? customerId,
    String? supplierId,
  });

  Future<DebtModel> getDebtById(String debtId);
  Future<DebtModel> createDebt(DebtModel debt);
  Future<DebtModel> updateDebt(DebtModel debt);
  Future<void> deleteDebt(String debtId);

  Future<List<DebtPaymentModel>> getDebtPayments(String debtId);
  Future<DebtPaymentModel> recordDebtPayment({
    required String businessId,
    required String debtId,
    required int amount,
    String paymentMethod = 'cash',
    String? paymentReference,
    String? notes,
  });
}

class DebtsRemoteDataSourceImpl implements DebtsRemoteDataSource {
  DebtsRemoteDataSourceImpl({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient;

  final SupabaseClient _supabaseClient;

  @override
  Future<List<DebtModel>> getDebts({
    required String businessId,
    String? branchId,
    DebtType? debtType,
    DebtStatus? status,
    String? customerId,
    String? supplierId,
  }) async {
    try {
      var query = _supabaseClient
          .from('debts')
          .select()
          .eq('business_id', businessId);

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }
      if (debtType != null) {
        query = query.eq('debt_type', debtType.value);
      }
      if (status != null) {
        query = query.eq('status', status.value);
      }
      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }
      if (supplierId != null) {
        query = query.eq('supplier_id', supplierId);
      }

      final res = await query.order('created_at', ascending: false);
      return (res as List)
          .map((e) => DebtModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.message.contains('does not exist')) {
        return [];
      }
      rethrow;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<DebtModel> getDebtById(String debtId) async {
    final res = await _supabaseClient
        .from('debts')
        .select()
        .eq('id', debtId)
        .single();
    return DebtModel.fromJson(res);
  }

  @override
  Future<DebtModel> createDebt(DebtModel debt) async {
    final res = await _supabaseClient
        .from('debts')
        .insert(debt.toInsertJson())
        .select()
        .single();

    final created = DebtModel.fromJson(res);

    // If linked to customer, increment customer's outstanding balance
    if (created.customerId != null && created.debtType == DebtType.receivable) {
      try {
        final cust = await _supabaseClient
            .from('customers')
            .select('outstanding_balance')
            .eq('id', created.customerId!)
            .single();
        final currentBal = (cust['outstanding_balance'] as num?)?.toInt() ?? 0;
        await _supabaseClient
            .from('customers')
            .update({
              'outstanding_balance': currentBal + created.remainingBalance,
            })
            .eq('id', created.customerId!);
      } catch (_) {}
    }

    // If linked to supplier, increment supplier balance
    if (created.supplierId != null && created.debtType == DebtType.payable) {
      try {
        final supp = await _supabaseClient
            .from('suppliers')
            .select('balance')
            .eq('id', created.supplierId!)
            .single();
        final currentBal = (supp['balance'] as num?)?.toInt() ?? 0;
        await _supabaseClient
            .from('suppliers')
            .update({'balance': currentBal + created.remainingBalance})
            .eq('id', created.supplierId!);
      } catch (_) {}
    }

    return created;
  }

  @override
  Future<DebtModel> updateDebt(DebtModel debt) async {
    final res = await _supabaseClient
        .from('debts')
        .update({
          'remaining_balance': debt.remainingBalance,
          'status': debt.status.value,
          if (debt.dueDate != null)
            'due_date': debt.dueDate!.toIso8601String().substring(0, 10),
          'notes': debt.notes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', debt.id)
        .select()
        .single();
    return DebtModel.fromJson(res);
  }

  @override
  Future<void> deleteDebt(String debtId) async {
    await _supabaseClient.from('debts').delete().eq('id', debtId);
  }

  @override
  Future<List<DebtPaymentModel>> getDebtPayments(String debtId) async {
    try {
      final res = await _supabaseClient
          .from('debt_payments')
          .select()
          .eq('debt_id', debtId)
          .order('created_at', ascending: false);
      return (res as List)
          .map((e) => DebtPaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.message.contains('does not exist')) {
        return [];
      }
      rethrow;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<DebtPaymentModel> recordDebtPayment({
    required String businessId,
    required String debtId,
    required int amount,
    String paymentMethod = 'cash',
    String? paymentReference,
    String? notes,
  }) async {
    final currentUser = _supabaseClient.auth.currentUser;

    // 1. Insert debt payment record
    final payload = <String, dynamic>{
      'business_id': businessId,
      'debt_id': debtId,
      'amount': amount,
      'payment_method': paymentMethod,
    };
    if (paymentReference != null)
      payload['payment_reference'] = paymentReference;
    if (notes != null) payload['notes'] = notes;
    if (currentUser != null) payload['recorded_by'] = currentUser.id;

    final res = await _supabaseClient
        .from('debt_payments')
        .insert(payload)
        .select()
        .single();
    final payment = DebtPaymentModel.fromJson(res);

    // 2. Fetch current debt to compute new remaining balance
    final debtRes = await _supabaseClient
        .from('debts')
        .select()
        .eq('id', debtId)
        .single();
    final currentDebt = DebtModel.fromJson(debtRes);
    final newBalance = (currentDebt.remainingBalance - amount).clamp(
      0,
      currentDebt.initialAmount,
    );
    final newStatus = newBalance <= 0 ? 'paid' : currentDebt.status.value;

    await _supabaseClient
        .from('debts')
        .update({
          'remaining_balance': newBalance,
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', debtId);

    // 3. Update linked Customer balance if receivable
    if (currentDebt.customerId != null &&
        currentDebt.debtType == DebtType.receivable) {
      try {
        final cust = await _supabaseClient
            .from('customers')
            .select('outstanding_balance')
            .eq('id', currentDebt.customerId!)
            .single();
        final currentBal = (cust['outstanding_balance'] as num?)?.toInt() ?? 0;
        final updatedBal = (currentBal - amount).clamp(
          0,
          double.infinity.toInt(),
        );
        await _supabaseClient
            .from('customers')
            .update({'outstanding_balance': updatedBal})
            .eq('id', currentDebt.customerId!);
      } catch (_) {}
    }

    // 4. Update linked Supplier balance if payable
    if (currentDebt.supplierId != null &&
        currentDebt.debtType == DebtType.payable) {
      try {
        final supp = await _supabaseClient
            .from('suppliers')
            .select('balance')
            .eq('id', currentDebt.supplierId!)
            .single();
        final currentBal = (supp['balance'] as num?)?.toInt() ?? 0;
        final updatedBal = (currentBal - amount).clamp(
          0,
          double.infinity.toInt(),
        );
        await _supabaseClient
            .from('suppliers')
            .update({'balance': updatedBal})
            .eq('id', currentDebt.supplierId!);
      } catch (_) {}
    }

    return payment;
  }
}
