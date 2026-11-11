import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/supplier_entity.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../../data/datasources/suppliers_remote_datasource.dart';
import '../../data/repositories/supplier_repository_impl.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/sync/presentation/providers/sync_provider.dart';
import '../../../../core/sync/domain/models/sync_queue_item.dart';

final suppliersRemoteDatasourceProvider = Provider<SuppliersRemoteDatasource>((
  ref,
) {
  return SuppliersRemoteDatasourceImpl(Supabase.instance.client);
});

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final remote = ref.watch(suppliersRemoteDatasourceProvider);
  return SupplierRepositoryImpl(remoteDatasource: remote);
});

final supplierSearchQueryProvider = StateProvider<String>((ref) => '');

// Fetch suppliers list for active business with offline cache fallback
final suppliersListProvider = FutureProvider.autoDispose<List<SupplierEntity>>((
  ref,
) async {
  final currentBiz = ref.watch(currentBusinessProvider);
  if (currentBiz == null) return [];

  final searchQuery = ref.watch(supplierSearchQueryProvider);
  final isOnline = ref.watch(syncProvider.select((s) => s.isOnline));
  final localCache = ref.watch(localCacheServiceProvider);

  if (!isOnline) {
    final cached = await localCache.getCachedSuppliers(currentBiz.id);
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      return cached
          .where(
            (s) =>
                s.name.toLowerCase().contains(q) ||
                (s.phone?.contains(q) ?? false),
          )
          .toList();
    }
    return cached;
  }

  final repo = ref.watch(supplierRepositoryProvider);

  try {
    final result = await repo.getSuppliers(
      currentBiz.id,
      searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
    );

    return await result.fold(
      (failure) async => await localCache.getCachedSuppliers(currentBiz.id),
      (suppliers) async {
        if (searchQuery.isEmpty) {
          await localCache.cacheSuppliers(currentBiz.id, suppliers);
        }
        return suppliers;
      },
    );
  } catch (_) {
    return await localCache.getCachedSuppliers(currentBiz.id);
  }
});

// Single supplier detail provider with offline cache fallback
final supplierDetailProvider = FutureProvider.autoDispose
    .family<SupplierEntity, String>((ref, supplierId) async {
      final currentBiz = ref.watch(currentBusinessProvider);
      final isOnline = ref.watch(syncProvider.select((s) => s.isOnline));
      final localCache = ref.watch(localCacheServiceProvider);

      if (!isOnline && currentBiz != null) {
        final cached = await localCache.getCachedSupplierById(
          currentBiz.id,
          supplierId,
        );
        if (cached != null) return cached;
      }

      final repo = ref.watch(supplierRepositoryProvider);
      try {
        final result = await repo.getSupplierById(supplierId);
        return await result.fold((failure) async {
          if (currentBiz != null) {
            final cached = await localCache.getCachedSupplierById(
              currentBiz.id,
              supplierId,
            );
            if (cached != null) return cached;
          }
          throw failure.message;
        }, (supplier) => supplier);
      } catch (e) {
        if (currentBiz != null) {
          final cached = await localCache.getCachedSupplierById(
            currentBiz.id,
            supplierId,
          );
          if (cached != null) return cached;
        }
        rethrow;
      }
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
    final isOnline = ref.read(syncProvider).isOnline;

    if (!isOnline) {
      final offlineId = const Uuid().v4();
      final now = DateTime.now();
      final offlineSupplier = SupplierEntity(
        id: offlineId,
        businessId: currentBiz.id,
        name: name,
        contactPerson: contactPerson,
        phone: phone,
        email: email,
        address: address,
        outstandingBalance: 0,
        notes: notes,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final localCache = ref.read(localCacheServiceProvider);
      await localCache.saveOfflineSupplier(currentBiz.id, offlineSupplier);

      await ref
          .read(syncProvider.notifier)
          .enqueueOperation(
            table: 'suppliers',
            operation: SyncOperation.insert,
            recordId: offlineId,
            payload: {
              'id': offlineId,
              'business_id': currentBiz.id,
              'name': name,
              'contact_person': contactPerson,
              'phone': phone,
              'email': email,
              'address': address,
              'outstanding_balance': 0,
              'notes': notes,
              'is_active': true,
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            },
          );

      ref.invalidate(suppliersListProvider);
      state = AsyncValue.data(offlineSupplier);
      return offlineSupplier;
    }

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
        ref
            .read(localCacheServiceProvider)
            .saveOfflineSupplier(currentBiz.id, supplier);
        ref.invalidate(suppliersListProvider);
        state = AsyncValue.data(supplier);
        return supplier;
      },
    );
  }

  Future<SupplierEntity?> updateSupplier(SupplierEntity supplier) async {
    state = const AsyncValue.loading();
    final isOnline = ref.read(syncProvider).isOnline;

    if (!isOnline) {
      final currentBiz = ref.read(currentBusinessProvider);
      if (currentBiz != null) {
        await ref
            .read(localCacheServiceProvider)
            .saveOfflineSupplier(currentBiz.id, supplier);
        await ref
            .read(syncProvider.notifier)
            .enqueueOperation(
              table: 'suppliers',
              operation: SyncOperation.update,
              recordId: supplier.id,
              payload: {
                'name': supplier.name,
                'contact_person': supplier.contactPerson,
                'phone': supplier.phone,
                'email': supplier.email,
                'address': supplier.address,
                'notes': supplier.notes,
                'is_active': supplier.isActive,
                'updated_at': DateTime.now().toIso8601String(),
              },
            );
        ref.invalidate(suppliersListProvider);
        ref.invalidate(supplierDetailProvider(supplier.id));
        state = AsyncValue.data(supplier);
        return supplier;
      }
    }

    final repo = ref.read(supplierRepositoryProvider);

    final result = await repo.updateSupplier(supplier);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (updated) {
        final currentBiz = ref.read(currentBusinessProvider);
        if (currentBiz != null) {
          ref
              .read(localCacheServiceProvider)
              .saveOfflineSupplier(currentBiz.id, updated);
        }
        ref.invalidate(suppliersListProvider);
        ref.invalidate(supplierDetailProvider(supplier.id));
        state = AsyncValue.data(updated);
        return updated;
      },
    );
  }

  Future<bool> deleteSupplier(String supplierId) async {
    state = const AsyncValue.loading();
    final isOnline = ref.read(syncProvider).isOnline;
    final currentBiz = ref.read(currentBusinessProvider);

    if (!isOnline && currentBiz != null) {
      await ref
          .read(localCacheServiceProvider)
          .deleteOfflineSupplier(currentBiz.id, supplierId);
      await ref
          .read(syncProvider.notifier)
          .enqueueOperation(
            table: 'suppliers',
            operation: SyncOperation.delete,
            recordId: supplierId,
            payload: {},
          );
      ref.invalidate(suppliersListProvider);
      state = const AsyncValue.data(null);
      return true;
    }

    final repo = ref.read(supplierRepositoryProvider);

    final result = await repo.deleteSupplier(supplierId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        if (currentBiz != null) {
          ref
              .read(localCacheServiceProvider)
              .deleteOfflineSupplier(currentBiz.id, supplierId);
        }
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
        final currentBiz = ref.read(currentBusinessProvider);
        if (currentBiz != null) {
          ref
              .read(localCacheServiceProvider)
              .saveOfflineSupplier(currentBiz.id, updated);
        }
        ref.invalidate(suppliersListProvider);
        ref.invalidate(supplierDetailProvider(supplierId));
        state = AsyncValue.data(updated);
        return updated;
      },
    );
  }
}

final supplierControllerProvider =
    StateNotifierProvider<SupplierController, AsyncValue<SupplierEntity?>>((
      ref,
    ) {
      return SupplierController(ref);
    });
