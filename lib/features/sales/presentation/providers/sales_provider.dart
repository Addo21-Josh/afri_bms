import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/entities/sale_item_entity.dart';
import '../../domain/repositories/sales_repository.dart';
import '../../data/datasources/sales_remote_datasource.dart';
import '../../data/repositories/sales_repository_impl.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import 'pos_cart_provider.dart';

final salesRemoteDatasourceProvider = Provider<SalesRemoteDatasource>((ref) {
  return SalesRemoteDatasourceImpl(Supabase.instance.client);
});

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final remote = ref.watch(salesRemoteDatasourceProvider);
  return SalesRepositoryImpl(remoteDatasource: remote);
});

final salesSearchQueryProvider = StateProvider<String>((ref) => '');

// Sales history provider for active business and active branch
final salesListProvider = FutureProvider.autoDispose<List<SaleEntity>>((ref) async {
  final currentBiz = ref.watch(currentBusinessProvider);
  if (currentBiz == null) return [];

  final currentBranch = ref.watch(currentBranchProvider);
  final searchQuery = ref.watch(salesSearchQueryProvider);
  final repo = ref.watch(salesRepositoryProvider);

  final result = await repo.getSales(
    businessId: currentBiz.id,
    branchId: currentBranch?.id,
    searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
  );

  return result.fold(
    (failure) => throw failure.message,
    (sales) => sales,
  );
});

// Single sale details provider
final saleDetailProvider = FutureProvider.family<SaleEntity, String>((ref, saleId) async {
  final repo = ref.watch(salesRepositoryProvider);
  final result = await repo.getSaleById(saleId);
  return result.fold(
    (failure) => throw failure.message,
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

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      state = AsyncValue.error('User not authenticated.', StackTrace.current);
      return null;
    }

    state = const AsyncValue.loading();

    final saleNumber = _generateSaleNumber();
    final repo = ref.read(salesRepositoryProvider);

    // Map cart items to SaleItemEntity
    final saleItems = cartState.items.map((ci) {
      return SaleItemEntity(
        id: '',
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
    );

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (completedSale) {
        state = AsyncValue.data(completedSale);
        // Clear cart
        ref.read(posCartProvider.notifier).clearCart();
        // Invalidate products to refresh real-time stock
        ref.invalidate(productsListProvider);
        ref.invalidate(stockMovementsProvider);
        ref.invalidate(salesListProvider);
        return completedSale;
      },
    );
  }
}

final salesCheckoutControllerProvider =
    StateNotifierProvider<SalesCheckoutController, AsyncValue<SaleEntity?>>((ref) {
  return SalesCheckoutController(ref);
});
