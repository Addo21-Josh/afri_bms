import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/report_entities.dart';
import '../providers/reports_provider.dart';
import '../widgets/revenue_line_chart.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/top_products_bar_chart.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../services/report_export_service.dart';
import '../../../sales/presentation/providers/sales_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../../core/subscription/domain/models/subscription_tier.dart';
import '../../../../core/subscription/presentation/providers/subscription_provider.dart';
import '../../../../core/subscription/presentation/widgets/upgrade_prompt_sheet.dart';

class ReportsHubScreen extends ConsumerStatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  ConsumerState<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends ConsumerState<ReportsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCustomDateDialog(BuildContext context) async {
    final range = ref.read(customDateRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: range.start, end: range.end),
    );

    if (picked != null) {
      ref.read(customDateRangeProvider.notifier).state = CustomDateRange(
        start: picked.start,
        end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
      );
      ref.read(reportDateFilterProvider.notifier).state = ReportDateFilter.custom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentBiz = ref.watch(currentBusinessProvider);
    final currency = currentBiz?.defaultCurrency ?? 'GHS';
    final currentFilter = ref.watch(reportDateFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Smart Insights & Velocity',
            icon: const Icon(Icons.psychology_outlined),
            onPressed: () => context.push('/smart-insights'),
          ),
          PopupMenuButton<String>(
            tooltip: 'Export Data',
            icon: const Icon(Icons.file_download_outlined),
            onSelected: (val) async {
              final gate = ref.read(featureGateProvider);
              if (!gate.limits.dataExport) {
                UpgradePromptSheet.show(
                  context,
                  featureName: 'Data Export (CSV & PDF)',
                  customMessage: 'Exporting sales, inventory spreadsheets and executive reports is available on Afri_BMS Pro & Enterprise.',
                  currentTier: gate.tier,
                  suggestedTier: SubscriptionTier.pro,
                );
                return;
              }
              final bizName = currentBiz?.name ?? 'Afri_BMS Store';
              if (val == 'sales_csv') {
                final sales = ref.read(salesListProvider).value ?? [];
                await ReportExportService.exportSalesCsv(
                  sales: sales,
                  currency: currency,
                  businessName: bizName,
                );
              } else if (val == 'inventory_csv') {
                final products = ref.read(productsListProvider).value ?? [];
                await ReportExportService.exportInventoryCsv(
                  products: products,
                  currency: currency,
                  businessName: bizName,
                );
              } else if (val == 'executive_pdf') {
                final sData = ref.read(salesReportProvider).value;
                final fData = ref.read(financialReportProvider).value;
                final iData = ref.read(inventoryReportProvider).value;
                if (sData != null && fData != null && iData != null) {
                  await ReportExportService.exportExecutiveSummaryPdf(
                    salesData: sData,
                    financialData: fData,
                    inventoryData: iData,
                    currency: currency,
                    businessName: bizName,
                    branchName: ref.read(currentBranchProvider)?.name,
                  );
                }
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'sales_csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Export Sales CSV'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'inventory_csv',
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Export Inventory CSV'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'executive_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Export Executive PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.point_of_sale), text: 'Sales'),
            Tab(icon: Icon(Icons.account_balance), text: 'P&L / Financials'),
            Tab(icon: Icon(Icons.inventory), text: 'Inventory Valuation'),
            Tab(icon: Icon(Icons.people_alt), text: 'Customers & Debts'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date Filter Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ReportDateFilter.values.map((filter) {
                        final isSelected = currentFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              filter == ReportDateFilter.custom && isSelected
                                  ? () {
                                      final r = ref.watch(customDateRangeProvider);
                                      return '${DateFormat('d MMM').format(r.start)} - ${DateFormat('d MMM').format(r.end)}';
                                    }()
                                  : filter.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                if (filter == ReportDateFilter.custom) {
                                  _showCustomDateDialog(context);
                                } else {
                                  ref.read(reportDateFilterProvider.notifier).state = filter;
                                }
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SalesReportsTab(currency: currency),
                _FinancialReportsTab(currency: currency),
                _InventoryReportsTab(currency: currency),
                _CustomerDebtsReportsTab(currency: currency),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// TAB 1: SALES REPORTS
// ──────────────────────────────────────────────
class _SalesReportsTab extends ConsumerWidget {
  const _SalesReportsTab({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesReportAsync = ref.watch(salesReportProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return salesReportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading sales report: $e')),
      data: (data) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top KPI Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _ReportKpiCard(
                      title: 'Total Revenue',
                      value: CurrencyFormatter.format(data.totalRevenue, currencyCode: currency),
                      icon: Icons.payments,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ReportKpiCard(
                      title: 'Orders Count',
                      value: '${data.totalSalesCount}',
                      icon: Icons.shopping_bag,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ReportKpiCard(
                title: 'Average Order Value (AOV)',
                value: CurrencyFormatter.format(data.averageOrderValue, currencyCode: currency),
                icon: Icons.analytics_outlined,
                color: Colors.indigo,
              ),
              const SizedBox(height: 20),

              // Revenue Trend Chart
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
                            'Revenue Trend Over Time',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Icon(Icons.show_chart, color: colorScheme.primary),
                        ],
                      ),
                      const Divider(height: 20),
                      RevenueLineChart(dailyPoints: data.dailyPoints, currency: currency),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Top Products
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
                            'Top Selling Products',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Icon(Icons.star, color: Colors.amber.shade700),
                        ],
                      ),
                      const Divider(height: 20),
                      TopProductsBarChart(products: data.topProducts, currency: currency),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sales by Category
              if (data.categoryStats.isNotEmpty) ...[
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
                        Text(
                          'Sales by Category',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 20),
                        ...data.categoryStats.map((c) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(c.categoryName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(
                                    '${CurrencyFormatter.format(c.totalRevenue, currencyCode: currency)} (${c.percentage.toStringAsFixed(1)}%)',
                                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Staff Performance
              if (data.staffStats.isNotEmpty) ...[
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
                        Text(
                          'Staff / Cashier Performance',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 20),
                        ...data.staffStats.map((s) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer,
                                child: Text(s.staffName.isNotEmpty ? s.staffName[0].toUpperCase() : 'S'),
                              ),
                              title: Text(s.staffName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${s.salesCount} completed checkouts'),
                              trailing: Text(
                                CurrencyFormatter.format(s.totalRevenue, currencyCode: currency),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// TAB 2: FINANCIAL REPORTS (P&L, CASH FLOW)
// ──────────────────────────────────────────────
class _FinancialReportsTab extends ConsumerWidget {
  const _FinancialReportsTab({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financialReportAsync = ref.watch(financialReportProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return financialReportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading financial report: $e')),
      data: (data) {
        final isProfit = data.netProfit >= 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profit & Loss Card
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
                          Text('Profit & Loss Statement',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isProfit ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isProfit ? 'PROFITABLE' : 'NET LOSS',
                              style: TextStyle(
                                color: isProfit ? Colors.green.shade800 : Colors.red.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _StatementRow(
                        title: 'Gross Revenue (Sales)',
                        amount: CurrencyFormatter.format(data.grossSales, currencyCode: currency),
                        isBold: true,
                      ),
                      const SizedBox(height: 8),
                      _StatementRow(
                        title: 'Less: Cost of Goods Sold (COGS)',
                        amount: '- ${CurrencyFormatter.format(data.costOfGoodsSold, currencyCode: currency)}',
                        color: Colors.red.shade700,
                      ),
                      const Divider(height: 16),
                      _StatementRow(
                        title: 'Gross Profit',
                        amount: CurrencyFormatter.format(data.grossProfit, currencyCode: currency),
                        subtitle: 'Gross Margin: ${data.grossMarginPercent.toStringAsFixed(1)}%',
                        isBold: true,
                        color: Colors.blue.shade900,
                      ),
                      const SizedBox(height: 8),
                      _StatementRow(
                        title: 'Less: Operating Expenses',
                        amount: '- ${CurrencyFormatter.format(data.totalExpenses, currencyCode: currency)}',
                        color: Colors.red.shade700,
                      ),
                      const Divider(height: 20, thickness: 1.5),
                      _StatementRow(
                        title: 'Net Operating Profit',
                        amount: CurrencyFormatter.format(data.netProfit, currencyCode: currency),
                        subtitle: 'Net Margin: ${data.netMarginPercent.toStringAsFixed(1)}%',
                        isBold: true,
                        fontSize: 16,
                        color: isProfit ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Expense Breakdown Pie Chart
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
                      Text(
                        'Operating Expense Breakdown',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20),
                      ExpensePieChart(
                        categories: data.expenseCategories,
                        currency: currency,
                        totalExpenses: data.totalExpenses,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Cash Flow Card
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
                      Text(
                        'Cash Flow Summary',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Cash Inflow (Sales)'),
                          Text(
                            CurrencyFormatter.format(data.totalCashIn, currencyCode: currency),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Cash Outflow (Expenses + COGS)'),
                          Text(
                            CurrencyFormatter.format(data.totalCashOut, currencyCode: currency),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Net Cash Flow', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            CurrencyFormatter.format(data.netCashFlow, currencyCode: currency),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: data.netCashFlow >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// TAB 3: INVENTORY VALUATION & HEALTH
// ──────────────────────────────────────────────
class _InventoryReportsTab extends ConsumerWidget {
  const _InventoryReportsTab({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryReportAsync = ref.watch(inventoryReportProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return inventoryReportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading inventory report: $e')),
      data: (data) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Inventory Valuation Cards
              Row(
                children: [
                  Expanded(
                    child: _ReportKpiCard(
                      title: 'Total Stock Units',
                      value: '${data.totalStockUnits}',
                      icon: Icons.inventory_2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ReportKpiCard(
                      title: 'Total Products (SKUs)',
                      value: '${data.totalSkus}',
                      icon: Icons.category,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                      Text(
                        'Inventory Financial Valuation',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Valuation at Cost (Asset Cost)'),
                          Text(
                            CurrencyFormatter.format(data.totalCostValue, currencyCode: currency),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Valuation at Retail Price'),
                          Text(
                            CurrencyFormatter.format(data.totalRetailValue, currencyCode: currency),
                            style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Potential Gross Profit'),
                          Text(
                            CurrencyFormatter.format(data.potentialProfit, currencyCode: currency),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Stock Health Alert
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
                      Text('Stock Health & Alerts',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(height: 20),
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.warning_amber, color: Colors.orange),
                        title: const Text('Low Stock Alerts'),
                        trailing: Text(
                          '${data.lowStockCount} items',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ),
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                        title: const Text('Out of Stock'),
                        trailing: Text(
                          '${data.outOfStockCount} items',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/stock-movements'),
                          icon: const Icon(Icons.history),
                          label: const Text('View Stock Movement Audit'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// TAB 4: CUSTOMERS & DEBTS REPORT
// ──────────────────────────────────────────────
class _CustomerDebtsReportsTab extends ConsumerWidget {
  const _CustomerDebtsReportsTab({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtAgingAsync = ref.watch(customerSupplierReportProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return debtAgingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading debt aging: $e')),
      data: (data) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReportKpiCard(
                title: 'Total Outstanding Receivables (Customer Credit)',
                value: CurrencyFormatter.format(data.totalReceivables, currencyCode: currency),
                icon: Icons.account_balance_wallet_outlined,
                color: Colors.deepOrange,
              ),
              const SizedBox(height: 20),

              // Aging Buckets Card
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
                      Text(
                        'Debt Aging Ledger',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20),
                      _AgingRow(
                        title: 'Current (0–30 Days)',
                        amount: CurrencyFormatter.format(data.current30Days, currencyCode: currency),
                        color: Colors.green.shade800,
                      ),
                      const SizedBox(height: 8),
                      _AgingRow(
                        title: '31–60 Days Overdue',
                        amount: CurrencyFormatter.format(data.days31To60, currencyCode: currency),
                        color: Colors.amber.shade900,
                      ),
                      const SizedBox(height: 8),
                      _AgingRow(
                        title: '61–90 Days Overdue',
                        amount: CurrencyFormatter.format(data.days61To90, currencyCode: currency),
                        color: Colors.orange.shade900,
                      ),
                      const SizedBox(height: 8),
                      _AgingRow(
                        title: '90+ Days Overdue (High Risk)',
                        amount: CurrencyFormatter.format(data.overdue90Plus, currencyCode: currency),
                        color: Colors.red.shade800,
                        isBold: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/debts'),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Manage Debt & Repayments'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// HELPER SUB-WIDGETS
// ──────────────────────────────────────────────
class _ReportKpiCard extends StatelessWidget {
  const _ReportKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
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
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementRow extends StatelessWidget {
  const _StatementRow({
    required this.title,
    required this.amount,
    this.subtitle,
    this.isBold = false,
    this.color,
    this.fontSize,
  });

  final String title;
  final String amount;
  final String? subtitle;
  final bool isBold;
  final Color? color;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}

class _AgingRow extends StatelessWidget {
  const _AgingRow({
    required this.title,
    required this.amount,
    required this.color,
    this.isBold = false,
  });

  final String title;
  final String amount;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
        Text(
          amount,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
