import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/smart_insights_provider.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class SmartInsightsScreen extends ConsumerStatefulWidget {
  const SmartInsightsScreen({super.key});

  @override
  ConsumerState<SmartInsightsScreen> createState() =>
      _SmartInsightsScreenState();
}

class _SmartInsightsScreenState extends ConsumerState<SmartInsightsScreen>
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

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(currentBusinessProvider);
    final currency = business?.defaultCurrency ?? 'GHS';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Business Intelligence'),
        actions: [
          IconButton(
            tooltip: 'Auto-Reorder Generator',
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () => context.push('/auto-reorder'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.speed), text: 'Sales Velocity'),
            Tab(icon: Icon(Icons.trending_up), text: 'Most Profitable'),
            Tab(icon: Icon(Icons.store), text: 'Branch Comparison'),
            Tab(icon: Icon(Icons.people), text: 'Customer Habits'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SalesVelocityTab(currency: currency),
          _ProfitabilityTab(currency: currency),
          _BranchComparisonTab(currency: currency),
          _CustomerHabitsTab(currency: currency),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// TAB 1: SALES VELOCITY & STOCKOUT FORECAST
// ──────────────────────────────────────────────
class _SalesVelocityTab extends ConsumerWidget {
  const _SalesVelocityTab({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final velocityList = ref.watch(salesVelocityProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (velocityList.isEmpty) {
      return const Center(child: Text('No velocity data recorded yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: velocityList.length,
      itemBuilder: (context, index) {
        final item = velocityList[index];
        final days = item.daysRemaining;

        Color statusColor = Colors.green;
        String statusText = 'Adequate Stock';

        if (item.currentStock == 0) {
          statusColor = Colors.red.shade800;
          statusText = 'OUT OF STOCK';
        } else if (days != null && days <= 5) {
          statusColor = Colors.red.shade700;
          statusText = 'Runs out in $days days!';
        } else if (days != null && days <= 14) {
          statusColor = Colors.orange.shade800;
          statusText = 'Runs out in $days days';
        } else if (days != null) {
          statusText = '$days days of stock left';
        } else {
          statusText = 'No recent velocity';
          statusColor = Colors.grey;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
                    Expanded(
                      child: Text(
                        item.productName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Stock: ${item.currentStock} units',
                      style: TextStyle(color: colorScheme.outline),
                    ),
                    Text(
                      'Velocity: ${item.velocityPerDay.toStringAsFixed(1)} units/day',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// TAB 2: MOST PROFITABLE PRODUCTS
// ──────────────────────────────────────────────
class _ProfitabilityTab extends ConsumerWidget {
  const _ProfitabilityTab({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(productProfitabilityProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (list.isEmpty) {
      return const Center(
        child: Text('No product profitability data available yet.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.productName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${item.profitMarginPercent.toStringAsFixed(1)}% Margin',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sold: ${item.quantitySold} units',
                      style: TextStyle(
                        color: colorScheme.outline,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Total Profit: ${CurrencyFormatter.format(item.totalProfit, currencyCode: currency)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// TAB 3: BRANCH PERFORMANCE COMPARISON
// ──────────────────────────────────────────────
class _BranchComparisonTab extends ConsumerWidget {
  const _BranchComparisonTab({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(branchPerformanceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (branches.isEmpty) {
      return const Center(
        child: Text('No branch performance data recorded yet.'),
      );
    }

    final maxRevenue = branches.first.totalRevenue;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: branches.length,
      itemBuilder: (context, index) {
        final b = branches[index];
        final ratio = maxRevenue > 0
            ? (b.totalRevenue / maxRevenue).clamp(0.0, 1.0)
            : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
                      b.branchName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(
                        b.totalRevenue,
                        currencyCode: currency,
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      index == 0 ? colorScheme.primary : Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Completed Orders: ${b.ordersCount}',
                      style: TextStyle(
                        color: colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'AOV: ${CurrencyFormatter.format(b.averageOrderValue, currencyCode: currency)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// TAB 4: CUSTOMER HABITS & PATTERNS
// ──────────────────────────────────────────────
class _CustomerHabitsTab extends ConsumerWidget {
  const _CustomerHabitsTab({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(customerPatternsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (list.isEmpty) {
      return const Center(child: Text('No customer purchase history yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final c = list[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
                      c.customerName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Prefers: ${c.preferredPaymentMethod}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Orders: ${c.ordersCount} visits',
                      style: TextStyle(color: colorScheme.outline),
                    ),
                    Text(
                      'Total Spent: ${CurrencyFormatter.format(c.totalSpent, currencyCode: currency)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
