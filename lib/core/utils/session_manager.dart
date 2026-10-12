import 'package:flutter/widgets.dart';
import '../../features/business/presentation/providers/business_provider.dart';
import '../../features/users/presentation/providers/staff_provider.dart';
import '../../features/inventory/presentation/providers/inventory_provider.dart';
import '../../features/sales/presentation/providers/pos_cart_provider.dart';
import '../../features/sales/presentation/providers/sales_provider.dart';
import '../../features/customers/presentation/providers/customers_provider.dart';
import '../../features/suppliers/presentation/providers/suppliers_provider.dart';
import '../../features/payments/presentation/providers/payments_provider.dart';
import '../../features/expenses/presentation/providers/expenses_provider.dart';
import '../../features/debts/presentation/providers/debts_provider.dart';
import 'logger.dart';

class SessionManager {
  /// Invalidate all tenant, business, role, inventory, and cart providers
  /// whenever a user logs in, logs out, or switches accounts.
  static void invalidateAllSessionData(dynamic refOrWidgetRef) {
    AppLogger.i('Clearing all session cached providers for account switch...');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
      // 1. Explicitly clear stateful active notifiers
      try {
        refOrWidgetRef.read(currentBusinessProvider.notifier).clear();
      } catch (_) {}
      try {
        refOrWidgetRef.read(currentBranchProvider.notifier).clear();
      } catch (_) {}
      try {
        refOrWidgetRef.read(posCartProvider.notifier).clearCart();
      } catch (_) {}

      // 2. Invalidate all session-scoped providers to force refresh
      refOrWidgetRef.invalidate(userBusinessesProvider);
      refOrWidgetRef.invalidate(currentBusinessProvider);
      refOrWidgetRef.invalidate(businessBranchesProvider);
      refOrWidgetRef.invalidate(userAssignedBranchIdProvider);
      refOrWidgetRef.invalidate(currentBranchProvider);
      refOrWidgetRef.invalidate(currentUserRoleProvider);
      refOrWidgetRef.invalidate(businessStaffListProvider);
      refOrWidgetRef.invalidate(productsListProvider);
      refOrWidgetRef.invalidate(productCategoriesProvider);
      refOrWidgetRef.invalidate(selectedCategoryFilterProvider);
      refOrWidgetRef.invalidate(productSearchQueryProvider);
      refOrWidgetRef.invalidate(posCartProvider);
      refOrWidgetRef.invalidate(salesListProvider);
      refOrWidgetRef.invalidate(salesSearchQueryProvider);
      refOrWidgetRef.invalidate(stockMovementsProvider);
      refOrWidgetRef.invalidate(customersListProvider);
      refOrWidgetRef.invalidate(suppliersListProvider);
      refOrWidgetRef.invalidate(businessPaymentsProvider);
      refOrWidgetRef.invalidate(expensesListProvider);
      refOrWidgetRef.invalidate(expenseCategoriesProvider);
      refOrWidgetRef.invalidate(debtsListProvider);
      refOrWidgetRef.invalidate(totalReceivablesSummaryProvider);
      refOrWidgetRef.invalidate(totalPayablesSummaryProvider);
    } catch (e) {
      AppLogger.w('Warning while invalidating session data: $e');
    }
  });
}
}
