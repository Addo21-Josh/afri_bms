import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../business/presentation/widgets/branch_selector.dart';
import '../../../business/presentation/widgets/business_switcher_dialog.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../inventory/presentation/screens/product_list_screen.dart';
import '../../../users/domain/entities/staff_user_entity.dart';
import '../../../users/presentation/providers/staff_provider.dart';
import '../../../users/presentation/screens/staff_list_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../sales/presentation/screens/pos_screen.dart';
import '../../../sales/presentation/screens/sales_history_screen.dart';
import 'package:intl/intl.dart';
import '../../../sales/presentation/providers/sales_provider.dart';
import '../../../sales/presentation/screens/sale_receipt_screen.dart';
import '../../../reports/presentation/widgets/revenue_line_chart.dart';
import '../../../reports/presentation/widgets/top_products_bar_chart.dart';
import '../../../reports/domain/entities/report_entities.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../alerts/presentation/providers/alerts_provider.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/sync/presentation/providers/sync_provider.dart';
import '../../../customers/presentation/providers/customers_provider.dart';
import '../../../inventory/domain/entities/category_entity.dart';
import '../../../inventory/domain/entities/product_entity.dart';
import '../../../customers/domain/entities/customer_entity.dart';
import '../../../sales/domain/entities/sale_entity.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warmOfflineCache();
    });
  }

  void _warmOfflineCache() {
    final currentBiz = ref.read(currentBusinessProvider);
    if (currentBiz == null) return;
    // Proactively load and cache categories, products, customers & sales in the background
    ref.read(productCategoriesProvider.future).catchError((_) => <ProductCategoryEntity>[]);
    ref.read(customersListProvider.future).catchError((_) => <CustomerEntity>[]);
    ref.read(productsListProvider.future).catchError((_) => <ProductEntity>[]);
    ref.read(salesListProvider.future).catchError((_) => <SaleEntity>[]);
  }

  Widget _buildOverviewTab(BuildContext context) {
    final currentBiz = ref.watch(currentBusinessProvider);
    final currentBranch = ref.watch(currentBranchProvider);
    final productsAsync = ref.watch(productsListProvider);
    final branchesAsync = ref.watch(businessBranchesProvider);
    final staffAsync = ref.watch(businessStaffListProvider);
    final userRole = ref.watch(currentUserRoleProvider).value;
    final isStaffOrSales = userRole == UserRoleType.salesperson || userRole == UserRoleType.cashier;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final lowStockCount = productsAsync.maybeWhen(
      data: (products) => products.where((p) => p.isLowStock).length,
      orElse: () => 0,
    );

    final totalProducts = productsAsync.maybeWhen(
      data: (products) => products.length,
      orElse: () => 0,
    );

    final totalBranches = branchesAsync.maybeWhen(
      data: (branches) => branches.length,
      orElse: () => 1,
    );

    final totalStaff = staffAsync.maybeWhen(
      data: (staff) => staff.length,
      orElse: () => 0,
    );

    final salesAsync = ref.watch(salesListProvider);
    final currency = currentBiz?.defaultCurrency ?? 'GHS';

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));
    final endOfYesterday = startOfToday.subtract(const Duration(seconds: 1));

    int todayRevenue = 0;
    int todaySalesCount = 0;
    int yesterdayRevenue = 0;

    final salesList = salesAsync.value ?? [];
    for (final s in salesList) {
      if (s.createdAt.isAfter(startOfToday) && s.createdAt.isBefore(endOfToday)) {
        todayRevenue += s.totalAmount;
        todaySalesCount++;
      } else if (s.createdAt.isAfter(startOfYesterday) && s.createdAt.isBefore(endOfYesterday)) {
        yesterdayRevenue += s.totalAmount;
      }
    }

    final Map<String, int> past7DaysMap = {};
    for (int i = 6; i >= 0; i--) {
      final d = startOfToday.subtract(Duration(days: i));
      final k = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      past7DaysMap[k] = 0;
    }
    for (final s in salesList) {
      final k = '${s.createdAt.year}-${s.createdAt.month.toString().padLeft(2, '0')}-${s.createdAt.day.toString().padLeft(2, '0')}';
      if (past7DaysMap.containsKey(k)) {
        past7DaysMap[k] = past7DaysMap[k]! + s.totalAmount;
      }
    }
    final past7DaysPoints = past7DaysMap.entries.map((e) {
      final parts = e.key.split('-');
      return DailySalesPoint(
        date: DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
        totalAmount: e.value,
        salesCount: 0,
      );
    }).toList();

    final Map<String, _TopProductMini> productTotals = {};
    for (final s in salesList) {
      for (final item in s.items) {
        final cur = productTotals[item.productId] ?? _TopProductMini(item.productName, item.variantName, 0, 0);
        productTotals[item.productId] = _TopProductMini(
          item.productName,
          item.variantName,
          cur.qty + item.quantity,
          cur.revenue + item.totalPrice,
        );
      }
    }
    final topSelling = productTotals.entries.map((e) => ProductSalesStat(
      productId: e.key,
      productName: e.value.name,
      sku: e.value.sku,
      quantitySold: e.value.qty,
      totalRevenue: e.value.revenue,
      totalProfit: 0,
    )).toList()..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    final recentSales = salesList.take(4).toList();

    final businessesAsync = ref.watch(userBusinessesProvider);

    if (businessesAsync.isLoading && currentBiz == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your business profile...'),
            ],
          ),
        ),
      );
    }

    if (businessesAsync.hasValue && businessesAsync.value!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('No Business Assigned', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('You have not set up a business or been assigned to any business by an administrator yet.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push('/business-setup'),
                icon: const Icon(Icons.add_business),
                label: const Text('Set Up Business'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business & Branch Header Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.store, color: colorScheme.onPrimaryContainer, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    currentBiz?.name ?? 'Afri_BMS Business',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (userRole != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      userRole.displayName,
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              'Currency: ${currentBiz?.defaultCurrency ?? 'GHS'} • Branch: ${currentBranch?.name ?? 'All Branches'}',
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => showBusinessSwitcherModal(context),
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: const Text('Switch', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  const BranchSelector(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Low Stock Warning Banner
          if (lowStockCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$lowStockCount product(s) are at or below reorder level in ${currentBranch?.name ?? 'current branch'}!',
                      style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentTabIndex = 1),
                    child: const Text('View'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Metrics Overview Cards
          Text(isStaffOrSales ? 'Store Metrics' : 'Business Metrics', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (isStaffOrSales)
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Total Products',
                    value: totalProducts.toString(),
                    icon: Icons.inventory_2_outlined,
                    color: colorScheme.primary,
                    onTap: () => setState(() => _currentTabIndex = 1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Low Stock Items',
                    value: lowStockCount.toString(),
                    icon: Icons.notification_important_outlined,
                    color: Colors.orange,
                    onTap: () => setState(() => _currentTabIndex = 1),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Total Products',
                    value: totalProducts.toString(),
                    icon: Icons.inventory_2_outlined,
                    color: colorScheme.primary,
                    onTap: () => setState(() => _currentTabIndex = 1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Active Branches',
                    value: totalBranches.toString(),
                    icon: Icons.store_outlined,
                    color: colorScheme.secondary,
                    onTap: () => context.push('/branches'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Team Members',
                    value: totalStaff.toString(),
                    icon: Icons.people_outline,
                    color: colorScheme.tertiary,
                    onTap: () => setState(() => _currentTabIndex = 2),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),

          // Quick Actions Grid
          Text('Quick Actions', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (isStaffOrSales)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _buildActionTile(
                  context,
                  title: 'Point of Sale (POS)',
                  icon: Icons.point_of_sale,
                  color: colorScheme.primary,
                  onTap: () => setState(() => _currentTabIndex = 1),
                ),
                _buildActionTile(
                  context,
                  title: 'Sales History',
                  icon: Icons.receipt_long,
                  color: Colors.green,
                  onTap: () => setState(() => _currentTabIndex = 3),
                ),
                _buildActionTile(
                  context,
                  title: 'Product Catalog',
                  icon: Icons.inventory_2_outlined,
                  color: colorScheme.secondary,
                  onTap: () => setState(() => _currentTabIndex = 2),
                ),
                _buildActionTile(
                  context,
                  title: 'Scan Barcode',
                  icon: Icons.qr_code_scanner,
                  color: colorScheme.tertiary,
                  onTap: () => setState(() => _currentTabIndex = 1),
                ),
                _buildActionTile(
                  context,
                  title: 'Customers',
                  icon: Icons.people_alt_outlined,
                  color: Colors.indigo,
                  onTap: () => context.push('/customers'),
                ),
                _buildActionTile(
                  context,
                  title: 'Debt & Credit',
                  icon: Icons.assignment_late_outlined,
                  color: Colors.deepOrange,
                  onTap: () => context.push('/debts'),
                ),
              ],
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _buildActionTile(
                  context,
                  title: 'Point of Sale (POS)',
                  icon: Icons.point_of_sale,
                  color: colorScheme.primary,
                  onTap: () => setState(() => _currentTabIndex = 1),
                ),
                _buildActionTile(
                  context,
                  title: 'Add Product',
                  icon: Icons.add_box_outlined,
                  color: Colors.green,
                  onTap: () => context.push('/inventory/add'),
                ),
                _buildActionTile(
                  context,
                  title: 'Sales History',
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                  onTap: () => context.push('/sales'),
                ),
                _buildActionTile(
                  context,
                  title: 'Stock Movements',
                  icon: Icons.track_changes,
                  color: Colors.orange,
                  onTap: () => context.push('/stock-movements'),
                ),
                _buildActionTile(
                  context,
                  title: 'Manage Staff',
                  icon: Icons.person_add_outlined,
                  color: colorScheme.secondary,
                  onTap: () => setState(() => _currentTabIndex = 3),
                ),
                _buildActionTile(
                  context,
                  title: 'Branches',
                  icon: Icons.apartment_outlined,
                  color: colorScheme.tertiary,
                  onTap: () => context.push('/branches'),
                ),
                _buildActionTile(
                  context,
                  title: 'Expenses',
                  icon: Icons.payments_outlined,
                  color: Colors.purple,
                  onTap: () => context.push('/expenses'),
                ),
                _buildActionTile(
                  context,
                  title: 'Debt & Credit',
                  icon: Icons.assignment_late_outlined,
                  color: Colors.deepOrange,
                  onTap: () => context.push('/debts'),
                ),
                _buildActionTile(
                  context,
                  title: 'Customers',
                  icon: Icons.people_alt_outlined,
                  color: Colors.indigo,
                  onTap: () => context.push('/customers'),
                ),
                _buildActionTile(
                  context,
                  title: 'Analytics & Reports',
                  icon: Icons.analytics_outlined,
                  color: Colors.indigo,
                  onTap: () => context.push('/reports'),
                ),
              ],
            ),
          const SizedBox(height: 24),

          // Today's Sales Summary Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.today, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text("Today's Sales Summary",
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: todayRevenue >= yesterdayRevenue
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          todayRevenue >= yesterdayRevenue ? '▲ Up vs Yesterday' : '▼ Lower vs Yesterday',
                          style: TextStyle(
                            color: todayRevenue >= yesterdayRevenue ? Colors.green.shade800 : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Revenue Today', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(todayRevenue, currencyCode: currency),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Completed Orders', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              '$todaySalesCount orders',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 7-Day Revenue Trend Line Chart
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '7-Day Revenue Trend',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/reports'),
                        icon: const Icon(Icons.arrow_forward, size: 14),
                        label: const Text('View All', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  RevenueLineChart(dailyPoints: past7DaysPoints, currency: currency),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Top Selling Products
          if (topSelling.isNotEmpty) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Top Products by Sales',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.star_outline, color: Colors.amber.shade700, size: 20),
                      ],
                    ),
                    const Divider(height: 16),
                    TopProductsBarChart(products: topSelling, currency: currency, maxItems: 3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Recent Transactions List
          if (recentSales.isNotEmpty) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => context.push('/sales'),
                          child: const Text('View All', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    ...recentSales.map((sale) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.receipt, color: colorScheme.primary, size: 20),
                          ),
                          title: Text(sale.saleNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${DateFormat('d MMM, HH:mm').format(sale.createdAt)} • ${sale.paymentMethod.name.toUpperCase()}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            CurrencyFormatter.format(sale.totalAmount, currencyCode: currency),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SaleReceiptScreen(sale: sale, currency: currency),
                              ),
                            );
                          },
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreTab(BuildContext context) {
    final userRole = ref.watch(currentUserRoleProvider).value;
    final isStaffOrSales = userRole == UserRoleType.salesperson || userRole == UserRoleType.cashier;
    final authUser = ref.watch(authControllerProvider).value;
    final supaUser = Supabase.instance.client.auth.currentUser;
    final displayName = authUser?.fullName ?? (supaUser?.userMetadata?['full_name'] as String? ?? 'Staff Member');
    final displayEmail = authUser?.email ?? (supaUser?.email ?? '');
    final currentBiz = ref.watch(currentBusinessProvider);
    final currentBranch = ref.watch(currentBranchProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isStaffOrSales) ...[
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          displayEmail,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${userRole?.displayName ?? 'Staff'} • ${currentBranch?.name ?? currentBiz?.name ?? 'Assigned Branch'}',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (isStaffOrSales) ...[
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.blue),
            title: const Text('Sales History & Receipts'),
            subtitle: const Text('View transactions and reprinted receipts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/sales'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people_outline, color: Colors.teal),
            title: const Text('Customers & Clients'),
            subtitle: const Text('Manage store clients and contact info'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/customers'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.assignment_late_outlined, color: Colors.deepOrange),
            title: const Text('Debt & Credit Ledger'),
            subtitle: const Text('Customer store credits, debt aging & partial repayments'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/debts'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.payments_outlined, color: Colors.purple),
            title: const Text('Expenses & Outflows'),
            subtitle: const Text('Record operational expenditures and receipts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/expenses'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.analytics_outlined, color: Colors.indigo),
            title: const Text('Reports & Analytics'),
            subtitle: const Text('Sales trends, performance and store insights'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/reports'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync, color: Colors.blueAccent),
            title: const Text('Sync & Offline Center'),
            subtitle: const Text('Manage offline queue and connectivity'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/sync-center'),
          ),
          const Divider(),
        ] else ...[
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.blue),
            title: const Text('Sales History & Receipts'),
            subtitle: const Text('Review checkout orders and digital receipts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/sales'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people_outline, color: Colors.teal),
            title: const Text('Customers & Clients'),
            subtitle: const Text('Manage customer directory, balances and history'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/customers'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.assignment_late_outlined, color: Colors.deepOrange),
            title: const Text('Debt & Credit Ledger'),
            subtitle: const Text('Customer receivables, supplier payables & repayments'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/debts'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.payments_outlined, color: Colors.purple),
            title: const Text('Expenses & Outflows'),
            subtitle: const Text('Track operational costs, categories and receipts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/expenses'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined, color: Colors.deepOrange),
            title: const Text('Suppliers & Vendors'),
            subtitle: const Text('Manage supplier contacts and outstanding payables'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/suppliers'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.analytics_outlined, color: Colors.indigo),
            title: const Text('Reports & Analytics'),
            subtitle: const Text('Sales, P&L, inventory valuation & debt aging'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/reports'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.psychology_outlined, color: Colors.deepPurple),
            title: const Text('Smart Intelligence & Velocity'),
            subtitle: const Text('Stockout run-out forecast, profitability & habits'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/smart-insights'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_shopping_cart, color: Colors.blueAccent),
            title: const Text('Auto-Reorder Generator'),
            subtitle: const Text('Instant purchase order for low-stock items'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/auto-reorder'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined, color: Colors.amber),
            title: const Text('Alerts & Notifications'),
            subtitle: const Text('Low stock warnings, overdue credit & targets'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/alerts'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.track_changes, color: Colors.orange),
            title: const Text('Stock Movement Audit'),
            subtitle: const Text('Inventory additions, deductions and adjustments'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/stock-movements'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync, color: Colors.blueAccent),
            title: const Text('Sync & Offline Center'),
            subtitle: const Text('Manage offline queue, delta sync & connection'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/sync-center'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup_outlined, color: Colors.teal),
            title: const Text('Cloud Backup & Restore'),
            subtitle: const Text('Export JSON database snapshot & automated backups'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/backup'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.swap_horiz_rounded, color: Colors.indigo),
            title: const Text('Switch / Manage Business'),
            subtitle: const Text('Change active company or delete unused workspaces'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showBusinessSwitcherModal(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Branches'),
            subtitle: const Text('Manage your retail outlets and locations'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/branches'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            subtitle: const Text('Preferences, printing, branches & business profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings'),
          ),
          const Divider(),
        ],
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Log Out', style: TextStyle(color: Colors.red)),
          onTap: () async {
            if (context.mounted) context.go('/login');
            await ref.read(authControllerProvider.notifier).signOut();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reset tab index if role shifts between logins
    ref.listen(currentUserRoleProvider, (previous, next) {
      if (previous?.value != next.value && mounted) {
        setState(() => _currentTabIndex = 0);
      }
    });

    // Proactively warm offline cache whenever active business is resolved/changed
    ref.listen(currentBusinessProvider, (previous, next) {
      if (next != null && next.id != previous?.id) {
        _warmOfflineCache();
      }
    });

    final roleAsync = ref.watch(currentUserRoleProvider);
    final businessesAsync = ref.watch(userBusinessesProvider);

    // If role or user businesses are currently loading on account switch, show clean loader
    if ((roleAsync.isLoading && !roleAsync.hasValue) ||
        (businessesAsync.isLoading && !businessesAsync.hasValue)) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading workspace privileges...'),
            ],
          ),
        ),
      );
    }

    final userRole = roleAsync.value;
    final isStaffOrSales = userRole == UserRoleType.salesperson || userRole == UserRoleType.cashier;

    final pages = isStaffOrSales
        ? [
            _buildOverviewTab(context),
            const PosScreen(),
            const ProductListScreen(),
            const SalesHistoryScreen(),
            _buildMoreTab(context),
          ]
        : [
            _buildOverviewTab(context),
            const PosScreen(),
            const ProductListScreen(),
            const StaffListScreen(),
            _buildMoreTab(context),
          ];

    final destinations = isStaffOrSales
        ? const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'POS',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Products',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Sales',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'POS',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Inventory',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Team',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ];

    final safeTabIndex = _currentTabIndex.clamp(0, pages.length - 1);

    return Scaffold(
      appBar: safeTabIndex == 0
          ? AppBar(
              title: Text(isStaffOrSales ? 'Store Dashboard' : 'Afri_BMS Dashboard'),
              actions: [
                const SyncStatusBadge(),
                IconButton(
                  tooltip: 'Alerts & Notifications',
                  icon: Badge(
                    isLabelVisible: ref.watch(unreadAlertsCountProvider) > 0,
                    label: Text('${ref.watch(unreadAlertsCountProvider)}'),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  onPressed: () => context.push('/alerts'),
                ),
                IconButton(
                  tooltip: 'Sync & Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(syncProvider.notifier).triggerSync();
                    ref.invalidate(userBusinessesProvider);
                    ref.invalidate(businessBranchesProvider);
                    ref.invalidate(productsListProvider);
                    ref.invalidate(businessStaffListProvider);
                    ref.invalidate(currentUserRoleProvider);
                  },
                ),
              ],
            )
          : null,
      body: pages[safeTabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeTabIndex,
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        destinations: destinations,
      ),
    );
  }
}

class _TopProductMini {
  _TopProductMini(this.name, this.sku, this.qty, this.revenue);

  final String name;
  final String? sku;
  final int qty;
  final int revenue;
}
