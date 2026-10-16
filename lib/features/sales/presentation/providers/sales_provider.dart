import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/entities/sale_item_entity.dart';
import '../../domain/repositories/sales_repository.dart';
import '../../data/datasources/sales_remote_datasource.dart';
import '../../data/repositories/sales_repository_impl.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/sale_item_model.dart';
import '../../../business/domain/entities/business_entity.dart';
import '../../../business/domain/entities/branch_entity.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../debts/domain/entities/debt_entity.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import 'pos_cart_provider.dart';
import '../../../../core/sync/presentation/providers/sync_provider.dart';
import '../../../../core/sync/domain/models/sync_queue_item.dart';
import '../../../../core/utils/logger.dart';

final salesRemoteDatasourceProvider = Provider<SalesRemoteDatasource>((ref) {
  return SalesRemoteDatasourceImpl(Supabase.instance.client);
});

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final remote = ref.watch(salesRemoteDatasourceProvider);
  return SalesRepositoryImpl(remoteDatasource: remote);
});

final salesSearchQueryProvider = StateProvider<String>((ref) => '');

// Sales history provider for active business and active branch with offline fallback
final salesListProvider = FutureProvider.autoDispose<List<SaleEntity>>((ref) async {
  final currentBiz = ref.watch(currentBusinessProvider);
  if (currentBiz == null) return [];

  final currentBranch = ref.watch(currentBranchProvider);
  final searchQuery = ref.watch(salesSearchQueryProvider);
  final repo = ref.watch(salesRepositoryProvider);
  final localCache = ref.watch(localCacheServiceProvider);
  final syncState = ref.watch(syncProvider);

  if (!syncState.isOnline) {
    var cached = await localCache.getCachedSales(currentBiz.id);
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      cached = cached.where((s) => s.saleNumber.toLowerCase().contains(q) || (s.customerName?.toLowerCase().contains(q) ?? false)).toList();
    }
    return cached;
  }

  final result = await repo.getSales(
    businessId: currentBiz.id,
    branchId: currentBranch?.id,
    searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
  );

  return result.fold(
    (failure) async {
      AppLogger.w('Sales fetch failed: ${failure.message}. Falling back to offline cache.');
      var cached = await localCache.getCachedSales(currentBiz.id);
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        cached = cached.where((s) => s.saleNumber.toLowerCase().contains(q) || (s.customerName?.toLowerCase().contains(q) ?? false)).toList();
      }
      return cached;
    },
    (sales) async {
      await localCache.cacheSales(currentBiz.id, sales);
      return sales;
    },
  );
});

// Single sale details provider with offline fallback
final saleDetailProvider = FutureProvider.family<SaleEntity, String>((ref, saleId) async {
  final currentBiz = ref.watch(currentBusinessProvider);
  final repo = ref.watch(salesRepositoryProvider);
  final localCache = ref.watch(localCacheServiceProvider);
  final syncState = ref.watch(syncProvider);

  if (!syncState.isOnline) {
    if (currentBiz != null) {
      final cached = await localCache.getCachedSaleById(currentBiz.id, saleId);
      if (cached != null) return cached;
    }
    throw 'Sale details not available in offline cache';
  }

  final result = await repo.getSaleById(saleId);
  return result.fold(
    (failure) async {
      if (currentBiz != null) {
        final cached = await localCache.getCachedSaleById(currentBiz.id, saleId);
        if (cached != null) return cached;
      }
      throw failure.message;
    },
    (sale) => sale,
  );
});

class SalesCheckoutController extends StateNotifier<AsyncValue<SaleEntity?>> {
  SalesCheckoutController(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  String _generateSaleNumber() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyMMdd').format(now);
    final randomSuffix = Random().nextInt(9000) + 1000;
    return 'SAL-$dateStr-$randomSuffix';
  }

  Future<SaleEntity?> completeCheckout({
    required PaymentMethod paymentMethod,
    required int amountTendered,
    required int changeGiven,
    String? customerId,
    String? paymentReference,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) async {
    final currentBiz = ref.read(currentBusinessProvider);
    final currentBranch = ref.read(currentBranchProvider);
    final cartState = ref.read(posCartProvider);

    if (currentBiz == null) {
      state = AsyncValue.error('No active business selected.', StackTrace.current);
      return null;
    }

    if (currentBranch == null) {
      state = AsyncValue.error('No active branch selected.', StackTrace.current);
      return null;
    }

    if (cartState.items.isEmpty) {
      state = AsyncValue.error('Cart is empty.', StackTrace.current);
      return null;
    }

    // Determine user ID: Supabase auth → business owner → cached user ID
    String currentUserId = Supabase.instance.client.auth.currentUser?.id ?? currentBiz.ownerId;
    if (currentUserId.isEmpty) {
      // Last resort: try cached user ID for offline
      final cachedId = await ref.read(localCacheServiceProvider).getLastUserId();
      currentUserId = cachedId ?? '';
    }
    if (currentUserId.isEmpty) {
      state = AsyncValue.error('User not authenticated.', StackTrace.current);
      return null;
    }

    state = const AsyncValue.loading();

    final saleNumber = _generateSaleNumber();

    // Map cart items to SaleItemEntity
    final saleItems = cartState.items.map((ci) {
      return SaleItemEntity(
        id: const Uuid().v4(),
        saleId: '',
        productId: ci.product.id,
        variantId: ci.variant?.id,
        productName: ci.product.name,
        variantName: ci.variant?.name,
        unitCostPrice: ci.unitCostPrice,
        unitPrice: ci.unitPrice,
        quantity: ci.quantity,
        discountAmount: ci.discountAmount,
        totalPrice: ci.lineTotal,
        createdAt: DateTime.now(),
      );
    }).toList();

    final effectiveCustomerId = customerId ?? cartState.customerId;
    final syncState = ref.read(syncProvider);

    // ────────────────────────────────────────────────────────────────────────
    // FAST OFFLINE PATH:
    // If device is in offline mode, do NOT make remote HTTP/RPC requests.
    // Completes immediately in local storage within milliseconds.
    // ────────────────────────────────────────────────────────────────────────
    if (!syncState.isOnline) {
      AppLogger.i('Offline mode active. Processing sale $saleNumber immediately in local storage...');
      return await _processOfflineSale(
        currentBiz: currentBiz,
        currentBranch: currentBranch,
        currentUserId: currentUserId,
        saleNumber: saleNumber,
        cartState: cartState,
        paymentMethod: paymentMethod,
        amountTendered: amountTendered,
        changeGiven: changeGiven,
        effectiveCustomerId: effectiveCustomerId,
        paymentReference: paymentReference,
        customerName: customerName,
        customerPhone: customerPhone,
        notes: notes,
        saleItems: saleItems,
      );
    }

    // ────────────────────────────────────────────────────────────────────────
    // ONLINE PATH (with 6s timeout and instant offline fallback):
    // ────────────────────────────────────────────────────────────────────────
    final repo = ref.read(salesRepositoryProvider);

    try {
      final result = await repo.processSale(
        businessId: currentBiz.id,
        branchId: currentBranch.id,
        cashierId: currentUserId,
        saleNumber: saleNumber,
        subtotal: cartState.subtotal,
        discountAmount: cartState.discountAmount,
        taxAmount: cartState.taxAmount,
        totalAmount: cartState.totalAmount,
        paymentMethod: paymentMethod,
        amountTendered: amountTendered,
        changeGiven: changeGiven,
        customerId: effectiveCustomerId,
        paymentReference: paymentReference,
        customerName: customerName ?? cartState.customerName,
        customerPhone: customerPhone ?? cartState.customerPhone,
        notes: notes ?? cartState.notes,
        items: saleItems,
      ).timeout(const Duration(seconds: 6), onTimeout: () {
        AppLogger.w('Online sale request timed out after 6 seconds. Falling back to offline mode.');
        return const Left(NetworkFailure('Network request timed out. Processing offline sale.'));
      });

      return await result.fold(
        (failure) async {
          final isNetworkError = failure is NetworkFailure ||
              failure.message.contains('SocketException') ||
              failure.message.contains('ClientException') ||
              failure.message.contains('Failed host lookup') ||
              failure.message.contains('timed out') ||
              failure.message.contains('Network error') ||
              failure.message.contains('Network unavailable') ||
              failure.message.contains('Connection refused') ||
              failure.message.contains('Network is unreachable') ||
              failure.message.contains('HandshakeException');

          if (isNetworkError || !ref.read(syncProvider).isOnline) {
            AppLogger.i('Network issue during checkout ($failure). Completing sale $saleNumber offline...');
            return await _processOfflineSale(
              currentBiz: currentBiz,
              currentBranch: currentBranch,
              currentUserId: currentUserId,
              saleNumber: saleNumber,
              cartState: cartState,
              paymentMethod: paymentMethod,
              amountTendered: amountTendered,
              changeGiven: changeGiven,
              effectiveCustomerId: effectiveCustomerId,
              paymentReference: paymentReference,
              customerName: customerName,
              customerPhone: customerPhone,
              notes: notes,
              saleItems: saleItems,
            );
          }

          state = AsyncValue.error(failure.message, StackTrace.current);
          return null;
        },
        (completedSale) async {
          await ref.read(localCacheServiceProvider).saveOfflineSale(currentBiz.id, completedSale);
          state = AsyncValue.data(completedSale);
          ref.read(posCartProvider.notifier).clearCart();
          ref.invalidate(productsListProvider);
          ref.invalidate(stockMovementsProvider);
          ref.invalidate(salesListProvider);
          return completedSale;
        },
      );
    } catch (e) {
      AppLogger.w('Unexpected error during checkout: $e. Falling back to offline mode.');
      return await _processOfflineSale(
        currentBiz: currentBiz,
        currentBranch: currentBranch,
        currentUserId: currentUserId,
        saleNumber: saleNumber,
        cartState: cartState,
        paymentMethod: paymentMethod,
        amountTendered: amountTendered,
        changeGiven: changeGiven,
        effectiveCustomerId: effectiveCustomerId,
        paymentReference: paymentReference,
        customerName: customerName,
        customerPhone: customerPhone,
        notes: notes,
        saleItems: saleItems,
      );
    }
  }

  Future<SaleEntity> _processOfflineSale({
    required BusinessEntity currentBiz,
    required BranchEntity currentBranch,
    required String currentUserId,
    required String saleNumber,
    required CartState cartState,
    required PaymentMethod paymentMethod,
    required int amountTendered,
    required int changeGiven,
    required String? effectiveCustomerId,
    required String? paymentReference,
    required String? customerName,
    required String? customerPhone,
    required String? notes,
    required List<SaleItemEntity> saleItems,
  }) async {
    final saleId = const Uuid().v4();
    final now = DateTime.now();

    final localItems = saleItems.map((si) => SaleItemEntity(
      id: si.id.isNotEmpty ? si.id : const Uuid().v4(),
      saleId: saleId,
      productId: si.productId,
      variantId: si.variantId,
      productName: si.productName,
      variantName: si.variantName,
      unitCostPrice: si.unitCostPrice,
      unitPrice: si.unitPrice,
      quantity: si.quantity,
      discountAmount: si.discountAmount,
      totalPrice: si.totalPrice,
      createdAt: now,
    )).toList();

    final isCreditSale = paymentMethod == PaymentMethod.credit;
    final isPartial = !isCreditSale && amountTendered < cartState.totalAmount;
    final paymentStatus = isCreditSale
        ? PaymentStatus.pending
        : (isPartial ? PaymentStatus.partial : PaymentStatus.paid);

    final offlineSale = SaleEntity(
      id: saleId,
      businessId: currentBiz.id,
      branchId: currentBranch.id,
      cashierId: currentUserId,
      saleNumber: saleNumber,
      subtotal: cartState.subtotal,
      discountAmount: cartState.discountAmount,
      taxAmount: cartState.taxAmount,
      totalAmount: cartState.totalAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      amountTendered: amountTendered,
      changeGiven: changeGiven,
      customerId: effectiveCustomerId,
      paymentReference: paymentReference,
      customerName: customerName ?? cartState.customerName,
      customerPhone: customerPhone ?? cartState.customerPhone,
      notes: notes ?? cartState.notes,
      items: localItems,
      createdAt: now,
    );

    final localCache = ref.read(localCacheServiceProvider);

    // 1. Save sale to local cache
    await localCache.saveOfflineSale(currentBiz.id, offlineSale);

    // 2. Batch decrement offline stock for products
    final stockDeductions = <String, int>{};
    for (final item in localItems) {
      stockDeductions[item.productId] = (stockDeductions[item.productId] ?? 0) + item.quantity;
    }
    await localCache.deductOfflineStockBatch(currentBiz.id, stockDeductions);

    // 3. Prepare sync queue operations in batch
    final queueItems = <SyncQueueItem>[
      SyncQueueItem(
        id: const Uuid().v4(),
        businessId: currentBiz.id,
        table: 'sales',
        operation: SyncOperation.insert,
        recordId: offlineSale.id,
        payload: SaleModel.fromEntity(offlineSale).toJson(),
        createdAt: now,
      ),
    ];

    for (final item in localItems) {
      queueItems.add(
        SyncQueueItem(
          id: const Uuid().v4(),
          businessId: currentBiz.id,
          table: 'sale_items',
          operation: SyncOperation.insert,
          recordId: item.id,
          payload: SaleItemModel.fromEntity(item).toJson(),
          createdAt: now,
        ),
      );
    }

    // 4. Auto-create offline debt receivable if credit or partial sale
    final unpaidAmount = isCreditSale
        ? cartState.totalAmount
        : (cartState.totalAmount - amountTendered).clamp(0, cartState.totalAmount);

    if (unpaidAmount > 0) {
      final debtId = const Uuid().v4();
      final dueDate = now.add(const Duration(days: 30));
      final pName = (customerName != null && customerName.isNotEmpty)
          ? customerName
          : (cartState.customerName?.isNotEmpty == true
              ? cartState.customerName!
              : 'Customer ($saleNumber)');

      final offlineDebt = DebtEntity(
        id: debtId,
        businessId: currentBiz.id,
        branchId: currentBranch.id,
        debtType: DebtType.receivable,
        customerId: effectiveCustomerId,
        saleId: offlineSale.id,
        personName: pName,
        personPhone: customerPhone ?? cartState.customerPhone,
        initialAmount: unpaidAmount,
        remainingBalance: unpaidAmount,
        dueDate: dueDate,
        status: DebtStatus.active,
        notes: 'Auto-created from Sale #$saleNumber',
        createdAt: now,
        updatedAt: now,
      );

      await localCache.saveOfflineDebt(currentBiz.id, offlineDebt);

      queueItems.add(
        SyncQueueItem(
          id: const Uuid().v4(),
          businessId: currentBiz.id,
          table: 'debts',
          operation: SyncOperation.insert,
          recordId: debtId,
          payload: {
            'id': debtId,
            'business_id': currentBiz.id,
            'branch_id': currentBranch.id,
            'debt_type': 'receivable',
            'customer_id': effectiveCustomerId,
            'sale_id': offlineSale.id,
            'person_name': pName,
            'person_phone': customerPhone ?? cartState.customerPhone,
            'initial_amount': unpaidAmount,
            'remaining_balance': unpaidAmount,
            'due_date': dueDate.toIso8601String().substring(0, 10),
            'status': 'active',
            'notes': 'Auto-created from Sale #$saleNumber',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          },
          createdAt: now,
        ),
      );
    }

    // 5. Enqueue all mutations in a single batch
    await ref.read(syncProvider.notifier).enqueueOperations(queueItems);

    state = AsyncValue.data(offlineSale);
    ref.read(posCartProvider.notifier).clearCart();
    ref.invalidate(productsListProvider);
    ref.invalidate(salesListProvider);

    return offlineSale;
  }
}

final salesCheckoutControllerProvider =
    StateNotifierProvider<SalesCheckoutController, AsyncValue<SaleEntity?>>((ref) {
  return SalesCheckoutController(ref);
});
