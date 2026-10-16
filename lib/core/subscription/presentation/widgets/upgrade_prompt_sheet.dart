import 'package:flutter/material.dart';
import '../../domain/models/subscription_tier.dart';
import '../screens/subscription_plans_screen.dart';

/// Modal bottom sheet displayed whenever a user encounters a feature or resource limit
class UpgradePromptSheet extends StatelessWidget {
  const UpgradePromptSheet({
    super.key,
    this.featureName = 'Subscription Upgrade',
    this.customMessage,
    this.currentTier = SubscriptionTier.free,
    this.suggestedTier = SubscriptionTier.pro,
  });

  final String featureName;
  final String? customMessage;
  final SubscriptionTier currentTier;
  final SubscriptionTier suggestedTier;

  /// Static helper to trigger the upgrade bottom sheet from anywhere
  static Future<void> show(
    BuildContext context, {
    String featureName = 'Subscription Upgrade',
    String? customMessage,
    SubscriptionTier currentTier = SubscriptionTier.free,
    SubscriptionTier suggestedTier = SubscriptionTier.pro,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpgradePromptSheet(
        featureName: featureName,
        customMessage: customMessage,
        currentTier: currentTier,
        suggestedTier: suggestedTier,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetTierName = suggestedTier.shortName;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: suggestedTier.badgeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  suggestedTier.icon,
                  color: suggestedTier.badgeColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upgrade to $targetTierName',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Unlock premium capabilities for your business',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Message banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    customMessage ??
                        'You reached the ${currentTier.shortName} tier quota for $featureName. Upgrade to $targetTierName to continue expanding without limits.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // What you unlock
          Text(
            'Included in $targetTierName:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          ..._buildPerksList(suggestedTier),

          const SizedBox(height: 20),

          // Price info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Starting at',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Text(
                      '${suggestedTier.formattedPrice(false, currency: 'GHS')}/month',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Cancel anytime',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SubscriptionPlansScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: suggestedTier.badgeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rocket_launch_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'View Plans & Upgrade',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Maybe Later',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    ),
  );
}

  List<Widget> _buildPerksList(SubscriptionTier tier) {
    final perks = tier == SubscriptionTier.enterprise
        ? [
            'Unlimited products, transactions & branches',
            'Unlimited staff accounts & custom role permissions',
            'Real-time automated cloud synchronization',
            'Multi-business & branch performance comparison',
            'Priority 24/7 WhatsApp & email support',
          ]
        : [
            'Up to 1,000 products & 5,000 monthly sales',
            'Up to 5 branches & 10 staff members',
            'Thermal Bluetooth & USB POS printing',
            'Automatic cloud backup & 5-minute auto sync',
            'Full reporting & CSV/PDF data export',
            'Barcode & QR label generation and printing',
          ];

    return perks
        .map(
          (perk) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.5),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    perk,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}
