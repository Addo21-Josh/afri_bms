import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../data/datasources/payments_remote_datasource.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../sales/domain/entities/sale_entity.dart';

final paymentsRemoteDatasourceProvider = Provider<PaymentsRemoteDatasource>((
  ref,
) {
  return PaymentsRemoteDatasourceImpl(Supabase.instance.client);
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final remote = ref.watch(paymentsRemoteDatasourceProvider);
  return PaymentRepositoryImpl(remoteDatasource: remote);
});

// Payments per sale
final salePaymentsProvider = FutureProvider.autoDispose
    .family<List<PaymentEntity>, String>((ref, saleId) async {
      final repo = ref.watch(paymentRepositoryProvider);
      final result = await repo.getPaymentsBySale(saleId);
      return result.fold(
        (failure) => throw failure.message,
        (payments) => payments,
      );
    });

// Payments per customer
final customerPaymentsProvider = FutureProvider.autoDispose
    .family<List<PaymentEntity>, String>((ref, customerId) async {
      final repo = ref.watch(paymentRepositoryProvider);
      final result = await repo.getPaymentsByCustomer(customerId);
      return result.fold(
        (failure) => throw failure.message,
        (payments) => payments,
      );
    });

// Recent payments for active business & branch
final businessPaymentsProvider =
    FutureProvider.autoDispose<List<PaymentEntity>>((ref) async {
      final currentBiz = ref.watch(currentBusinessProvider);
      if (currentBiz == null) return [];

      final currentBranch = ref.watch(currentBranchProvider);
      final repo = ref.watch(paymentRepositoryProvider);

      final result = await repo.getPaymentsByBusiness(
        businessId: currentBiz.id,
        branchId: currentBranch?.id,
      );

      return result.fold(
        (failure) => throw failure.message,
        (payments) => payments,
      );
    });

class PaymentController extends StateNotifier<AsyncValue<PaymentEntity?>> {
  final Ref ref;

  PaymentController(this.ref) : super(const AsyncValue.data(null));

  Future<PaymentEntity?> recordPayment({
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
    final currentBiz = ref.read(currentBusinessProvider);
    final currentBranch = ref.read(currentBranchProvider);

    if (currentBiz == null) {
      state = AsyncValue.error('No active business found.', StackTrace.current);
      return null;
    }

    state = const AsyncValue.loading();
    final repo = ref.read(paymentRepositoryProvider);

    final result = await repo.recordPayment(
      businessId: currentBiz.id,
      branchId: branchId ?? currentBranch?.id,
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

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (payment) {
        ref.invalidate(businessPaymentsProvider);
        if (saleId != null) ref.invalidate(salePaymentsProvider(saleId));
        if (customerId != null)
          ref.invalidate(customerPaymentsProvider(customerId));
        state = AsyncValue.data(payment);
        return payment;
      },
    );
  }
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, AsyncValue<PaymentEntity?>>((ref) {
      return PaymentController(ref);
    });
