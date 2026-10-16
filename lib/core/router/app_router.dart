import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/business/presentation/screens/business_setup_screen.dart';
import '../../features/business/presentation/screens/business_settings_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/business/presentation/screens/branch_management_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/inventory/presentation/screens/product_list_screen.dart';
import '../../features/inventory/presentation/screens/product_form_screen.dart';
import '../../features/inventory/presentation/screens/product_detail_screen.dart';
import '../../features/inventory/presentation/screens/stock_movements_screen.dart';
import '../../features/sales/presentation/screens/pos_screen.dart';
import '../../features/sales/presentation/screens/sales_history_screen.dart';
import '../../features/users/presentation/screens/staff_list_screen.dart';
import '../../features/customers/presentation/screens/customer_list_screen.dart';
import '../../features/customers/presentation/screens/customer_detail_screen.dart';
import '../../features/suppliers/presentation/screens/supplier_list_screen.dart';
import '../../features/suppliers/presentation/screens/supplier_detail_screen.dart';
import '../../features/expenses/presentation/screens/expense_list_screen.dart';
import '../../features/debts/presentation/screens/debt_list_screen.dart';
import '../../features/debts/presentation/screens/debt_detail_screen.dart';
import '../../features/reports/presentation/screens/reports_hub_screen.dart';
import '../../features/alerts/presentation/screens/alerts_screen.dart';
import '../../features/smart/presentation/screens/smart_insights_screen.dart';
import '../../features/smart/presentation/screens/auto_reorder_screen.dart';
import '../sync/presentation/screens/sync_center_screen.dart';
import '../../features/backup/presentation/screens/backup_screen.dart';
import 'auth_guard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: AuthGuard.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/business-setup',
        builder: (context, state) => const BusinessSetupScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/business-settings',
        builder: (context, state) => const BusinessSettingsScreen(),
      ),
      GoRoute(
        path: '/branches',
        builder: (context, state) => const BranchManagementScreen(),
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/inventory/add',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/inventory/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/staff',
        builder: (context, state) => const StaffListScreen(),
      ),
      GoRoute(
        path: '/pos',
        builder: (context, state) => const PosScreen(),
      ),
      GoRoute(
        path: '/sales',
        builder: (context, state) => const SalesHistoryScreen(),
      ),
      GoRoute(
        path: '/stock-movements',
        builder: (context, state) => const StockMovementsScreen(),
      ),
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomerListScreen(),
      ),
      GoRoute(
        path: '/customers/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomerDetailScreen(customerId: id);
        },
      ),
      GoRoute(
        path: '/suppliers',
        builder: (context, state) => const SupplierListScreen(),
      ),
      GoRoute(
        path: '/suppliers/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SupplierDetailScreen(supplierId: id);
        },
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpenseListScreen(),
      ),
      GoRoute(
        path: '/debts',
        builder: (context, state) => const DebtListScreen(),
      ),
      GoRoute(
        path: '/debts/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DebtDetailScreen(debtId: id);
        },
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsHubScreen(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/smart-insights',
        builder: (context, state) => const SmartInsightsScreen(),
      ),
      GoRoute(
        path: '/auto-reorder',
        builder: (context, state) => const AutoReorderScreen(),
      ),
      GoRoute(
        path: '/sync-center',
        builder: (context, state) => const SyncCenterScreen(),
      ),
      GoRoute(
        path: '/backup',
        builder: (context, state) => const BackupScreen(),
      ),
    ],
  );
});
