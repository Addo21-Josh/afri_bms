import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../data/datasources/customers_remote_datasource.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/models/customer_model.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../sales/domain/entities/sale_entity.dart';
import '../../../../core/sync/presentation/providers/sync_provider.dart';
import '../../../../core/sync/domain/models/sync_queue_item.dart';
import '../../../../core/utils/logger.dart';

final customersRemoteDatasourceProvider = Provider<CustomersRemoteDatasource>((ref) {
  return CustomersRemoteDatasourceImpl(Supabase.instance.client);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final remote = ref.watch(customersRemoteDatasourceProvider);
  return CustomerRepositoryImpl(remoteDatasource: remote);
});

final customerSearchQueryProvider = StateProvider<String>((ref) => '');

// Fetch customers list for active business with offline cache fallback
final customersListProvider = FutureProvider.autoDispose<List<CustomerEntity>>((ref) async {
  final currentBiz = ref.watch(currentBusinessProvider);
  if (currentBiz == null) return [];

  final searchQuery = ref.watch(customerSearchQueryProvider);
  final repo = ref.watch(customerRepositoryProvider);
  final localCache = ref.watch(localCacheServiceProvider);

  final result = await repo.getCustomers(
    currentBiz.id,
    searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
  );

  return result.fold(
    (failure) async {
      AppLogger.w('Customers fetch failed: ${failure.message}. Falling back to offline cache.');
      final cached = await localCache.getCachedCustomers(currentBiz.id);
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return cached.where((c) => c.name.toLowerCase().contains(query) || (c.phone?.contains(query) ?? false)).toList();
      }
      return cached;
    },
    (customers) async {
      await localCache.cacheCustomers(currentBiz.id, customers);
      return customers;
    },
  );
});

// Single customer details provider
final customerDetailProvider = FutureProvider.autoDispose.family<CustomerEntity, String>((ref, customerId) async {
  final repo = ref.watch(customerRepositoryProvider);
  final result = await repo.getCustomerById(customerId);
  return result.fold(
    (failure) => throw failure.message,
    (customer) => customer,
  );
});

// Customer purchase history provider
final customerSalesHistoryProvider = FutureProvider.autoDispose.family<List<SaleEntity>, String>((ref, customerId) async {
  final repo = ref.watch(customerRepositoryProvider);
  final result = await repo.getCustomerSales(customerId);
  return result.fold(
    (failure) => throw failure.message,
    (sales) => sales,
  );
});

class CustomerController extends StateNotifier<AsyncValue<CustomerEntity?>> {
  final Ref ref;

  CustomerController(this.ref) : super(const AsyncValue.data(null));

  Future<CustomerEntity?> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    int creditLimit = 0,
    String? notes,
  }) async {
    final currentBiz = ref.read(currentBusinessProvider);
    if (currentBiz == null) {
      state = AsyncValue.error('No active business found.', StackTrace.current);
      return null;
    }

    state = const AsyncValue.loading();
    final repo = ref.read(customerRepositoryProvider);
    final localCache = ref.read(localCacheServiceProvider);

    final result = await repo.createCustomer(
      businessId: currentBiz.id,
      name: name,
      phone: phone,
      email: email,
      address: address,
      creditLimit: creditLimit,
      notes: notes,
    );

    return result.fold(
      (failure) async {
        // Fallback for offline customer creation
        final syncState = ref.read(syncProvider);
        if (!syncState.isOnline || failure.message.contains('SocketException') || failure.message.contains('ClientException') || failure.message.contains('Failed host lookup')) {
          final localCust = CustomerEntity(
            id: const Uuid().v4(),
            businessId: currentBiz.id,
            name: name,
            phone: phone,
            email: email,
            address: address,
            creditLimit: creditLimit,
            notes: notes,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await localCache.saveOfflineCustomer(currentBiz.id, localCust);
          await ref.read(syncProvider.notifier).enqueueOperation(
            table: 'customers',
            operation: SyncOperation.insert,
            recordId: localCust.id,
            payload: CustomerModel.fromEntity(localCust).toJson(),
            businessId: currentBiz.id,
          );

          ref.invalidate(customersListProvider);
          state = AsyncValue.data(localCust);
          return localCust;
        }

        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (customer) async {
        await localCache.saveOfflineCustomer(currentBiz.id, customer);
        ref.invalidate(customersListProvider);
        state = AsyncValue.data(customer);
        return customer;
      },
    );
  }

  Future<CustomerEntity?> updateCustomer(CustomerEntity customer) async {
    state = const AsyncValue.loading();
    final repo = ref.read(customerRepositoryProvider);

    final result = await repo.updateCustomer(customer);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (updated) {
        ref.invalidate(customersListProvider);
        ref.invalidate(customerDetailProvider(customer.id));
        state = AsyncValue.data(updated);
        return updated;
      },
    );
  }

  Future<bool> deleteCustomer(String customerId) async {
    state = const AsyncValue.loading();
    final repo = ref.read(customerRepositoryProvider);

    final result = await repo.deleteCustomer(customerId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        ref.invalidate(customersListProvider);
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  Future<CustomerEntity?> recordDebtRepayment({
    required String customerId,
    required int paymentAmount, // minor units
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(customerRepositoryProvider);

    // Negative adjustment reduces debt
    final result = await repo.updateBalance(
      customerId: customerId,
      balanceAdjustment: -paymentAmount,
    );

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (updated) {
        ref.invalidate(customersListProvider);
        ref.invalidate(customerDetailProvider(customerId));
        state = AsyncValue.data(updated);
        return updated;
      },
    );
  }
}

final customerControllerProvider = StateNotifierProvider<CustomerController, AsyncValue<CustomerEntity?>>((ref) {
  return CustomerController(ref);
});
