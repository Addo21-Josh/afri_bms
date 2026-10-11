import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/supplier_entity.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../../data/datasources/suppliers_remote_datasource.dart';
import '../../data/repositories/supplier_repository_impl.dart';
import '../../../business/presentation/providers/business_provider.dart';

final suppliersRemoteDatasourceProvider = Provider<SuppliersRemoteDatasource>((ref) {
  return SuppliersRemoteDatasourceImpl(Supabase.instance.client);
});

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final remote = ref.watch(suppliersRemoteDatasourceProvider);
  return SupplierRepositoryImpl(remoteDatasource: remote);
});

final supplierSearchQueryProvider = StateProvider<String>((ref) => '');

// Fetch suppliers list for active business
final suppliersListProvider = FutureProvider.autoDispose<List<SupplierEntity>>((ref) async {
  final currentBiz = ref.watch(currentBusinessProvider);
  if (currentBiz == null) return [];

  final searchQuery = ref.watch(supplierSearchQueryProvider);
  final repo = ref.watch(supplierRepositoryProvider);

  final result = await repo.getSuppliers(
    currentBiz.id,
    searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
  );

  return result.fold(
    (failure) => throw failure.message,
    (suppliers) => suppliers,
  );
});

// Single supplier detail provider
final supplierDetailProvider = FutureProvider.autoDispose.family<SupplierEntity, String>((ref, supplierId) async {
  final repo = ref.watch(supplierRepositoryProvider);
  final result = await repo.getSupplierById(supplierId);
  return result.fold(
    (failure) => throw failure.message,
    (supplier) => supplier,
  );
});

class SupplierController extends StateNotifier<AsyncValue<SupplierEntity?>> {
  final Ref ref;

  SupplierController(this.ref) : super(const AsyncValue.data(null));

  Future<SupplierEntity?> createSupplier({
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    final currentBiz = ref.read(currentBusinessProvider);
    if (currentBiz == null) {
      state = AsyncValue.error('No active business found.', StackTrace.current);
      return null;
    }

    state = const AsyncValue.loading();
    final repo = ref.read(supplierRepositoryProvider);

    final result = await repo.createSupplier(
      businessId: currentBiz.id,
      name: name,
      contactPerson: contactPerson,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    );

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (supplier) {
        ref.invalidate(suppliersListProvider);
        state = AsyncValue.data(supplier);
        return supplier;
      },
    );
  }

  Future<SupplierEntity?> updateSupplier(SupplierEntity supplier) async {
    state = const AsyncValue.loading();
    final repo = ref.read(supplierRepositoryProvider);

    final result = await repo.updateSupplier(supplier);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (updated) {
        ref.invalidate(suppliersListProvider);
        ref.invalidate(supplierDetailProvider(supplier.id));
        state = AsyncValue.data(updated);
        return updated;
      },
    );
  }

  Future<bool> deleteSupplier(String supplierId) async {
    state = const AsyncValue.loading();
    final repo = ref.read(supplierRepositoryProvider);

    final result = await repo.deleteSupplier(supplierId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        ref.invalidate(suppliersListProvider);
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  Future<SupplierEntity?> recordSupplierPayment({
    required String supplierId,
    required int paymentAmount, // minor units
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(supplierRepositoryProvider);

    // Negative adjustment reduces amount owed
    final result = await repo.updateBalance(
      supplierId: supplierId,
      balanceAdjustment: -paymentAmount,
    );

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (updated) {
        ref.invalidate(suppliersListProvider);
        ref.invalidate(supplierDetailProvider(supplierId));
        state = AsyncValue.data(updated);
        return updated;
      },
    );
  }
}

final supplierControllerProvider = StateNotifierProvider<SupplierController, AsyncValue<SupplierEntity?>>((ref) {
  return SupplierController(ref);
});
