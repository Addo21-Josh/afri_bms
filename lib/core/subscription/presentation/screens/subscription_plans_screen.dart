import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/subscription_tier.dart';
import '../../domain/services/paystack_subscription_service.dart';
import '../../../config/paystack_config.dart';
import '../providers/subscription_provider.dart';
import '../../../../features/business/presentation/providers/business_provider.dart';
import '../../../../core/utils/haptics.dart';

class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  ConsumerState<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends ConsumerState<SubscriptionPlansScreen> {
  bool _isYearly = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTier = ref.watch(currentSubscriptionTierProvider);
    final activeBiz = ref.watch(currentBusinessProvider);
    final subState = ref.watch(subscriptionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans & Pricing'),
        centerTitle: true,
      ),
      body: subState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Active Business Header Card
                  if (activeBiz != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.08),
                            theme.colorScheme.primary.withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: currentTier.badgeColor.withValues(alpha: 0.15),
                            radius: 24,
                            child: Icon(currentTier.icon, color: currentTier.badgeColor, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeBiz.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: currentTier.badgeColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${currentTier.shortName} Plan',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Active',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Monthly vs Yearly Switch
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBillingToggleOption(
                            title: 'Monthly',
                            isSelected: !_isYearly,
                            onTap: () => setState(() => _isYearly = false),
                          ),
                          _buildBillingToggleOption(
                            title: 'Yearly (2 Mos Free)',
                            badge: 'Save 17%',
                            isSelected: _isYearly,
                            onTap: () => setState(() => _isYearly = true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Plans List
                  _buildPlanCard(
                    tier: SubscriptionTier.free,
                    currentTier: currentTier,
                    isPopular: false,
                    features: [
                      '1 Business & 1 Branch',
                      'Up to 2 Staff accounts',
                      '100 Products & 200 Sales/month',
                      '50 Customers & 20 Suppliers',
                      'Standard PDF Receipts (watermarked)',
                      'Offline Mode & Local Storage',
                      'Barcode Scanning via Camera',
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildPlanCard(
                    tier: SubscriptionTier.pro,
                    currentTier: currentTier,
                    isPopular: true,
                    features: [
                      'Up to 3 Businesses & 5 Branches each',
                      'Up to 10 Staff accounts',
                      '1,000 Products & 5,000 Sales/month',
                      '500 Customers & 100 Suppliers',
                      'Thermal Bluetooth & USB POS Printing',
                      'Automated Cloud Backup & 5-min Auto Sync',
                      'Barcode & Price Label Printing',
                      'Full Financial Reports & CSV/PDF Export',
                      '3 Currencies supported',
                      'Standard Email Support',
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildPlanCard(
                    tier: SubscriptionTier.enterprise,
                    currentTier: currentTier,
                    isPopular: false,
                    features: [
                      'Unlimited Businesses & Branches',
                      'Unlimited Staff accounts',
                      'Unlimited Products & Monthly Sales',
                      'Unlimited Customers & Suppliers',
                      'Real-Time Background Cloud Sync',
                      'Custom Staff Roles & Fine-grained Permissions',
                      'Multi-Business Comparative Analytics',
                      'Unlimited Currencies supported',
                      'White-label Custom Branded Receipts',
                      'Priority 24/7 WhatsApp & Phone Support',
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildBillingToggleOption({
    required String title,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (badge != null && !isSelected) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required SubscriptionTier tier,
    required SubscriptionTier currentTier,
    required bool isPopular,
    required List<String> features,
  }) {
    final theme = Theme.of(context);
    final isCurrent = tier == currentTier;
    final cycleSuffix = tier == SubscriptionTier.free
        ? 'forever'
        : _isYearly
            ? '/year'
            : '/month';

    final formattedPrice = tier.formattedPrice(_isYearly, currency: 'GHS');

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular
              ? tier.badgeColor
              : isCurrent
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : Colors.grey.shade300,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: tier.badgeColor.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner for Popular / Current
          if (isPopular || isCurrent) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isCurrent
                    ? theme.colorScheme.primary
                    : tier.badgeColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Center(
                child: Text(
                  isCurrent ? '✓ YOUR CURRENT PLAN' : '★ MOST POPULAR FOR RETAIL',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tier.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Icon(tier.icon, color: tier.badgeColor, size: 24),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tier.tagline,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),

                // Price display
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formattedPrice,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: tier.badgeColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      cycleSuffix,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Feature check items
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: tier.badgeColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 13, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Plan CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrent
                        ? null
                        : () => _handlePlanSelection(tier, formattedPrice),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? tier.badgeColor : theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isCurrent
                          ? 'Current Active Plan'
                          : tier.index > currentTier.index
                              ? 'Upgrade to ${tier.shortName}'
                              : 'Switch to ${tier.shortName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePlanSelection(SubscriptionTier targetTier, String priceText) {
    AppHaptics.selection();
    final isUpgrade = targetTier.index > ref.read(currentSubscriptionTierProvider).index;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildCheckoutConfirmationSheet(ctx, targetTier, priceText, isUpgrade),
    );
  }

  Widget _buildCheckoutConfirmationSheet(
    BuildContext ctx,
    SubscriptionTier targetTier,
    String priceText,
    bool isUpgrade,
  ) {
    final theme = Theme.of(ctx);
    final activeBiz = ref.read(currentBusinessProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          Row(
            children: [
              CircleAvatar(
                backgroundColor: targetTier.badgeColor.withValues(alpha: 0.12),
                child: Icon(targetTier.icon, color: targetTier.badgeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUpgrade ? 'Confirm Upgrade' : 'Confirm Plan Switch',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'For: ${activeBiz?.name ?? "Active Store"}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Order summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Selected Plan', style: TextStyle(fontSize: 13)),
                    Text(targetTier.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Billing Period', style: TextStyle(fontSize: 13)),
                    Text(_isYearly ? 'Yearly (12 months)' : 'Monthly', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Due Today', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(priceText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: targetTier.badgeColor)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment channel options for paid tiers
          if (targetTier.isPaid) ...[
            Text('Payment Method', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payment_rounded, color: Colors.teal),
              ),
              title: const Text('Paystack (Ghana Cedis)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('MTN MoMo, Telecel Cash, AT Money & Bank Cards', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.radio_button_checked, color: Colors.teal),
            ),
            const SizedBox(height: 12),
          ],

          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _processTierActivation(targetTier);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: targetTier.badgeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              targetTier.isPaid ? 'Proceed to Pay with Paystack' : 'Activate Free Tier',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _processTierActivation(SubscriptionTier targetTier) async {
    if (!targetTier.isPaid) {
      await _applyTierChange(targetTier);
      return;
    }

    final activeBiz = ref.read(currentBusinessProvider);
    final bizEmail = activeBiz?.email;
    final String email = (bizEmail != null && bizEmail.isNotEmpty)
        ? bizEmail
        : 'billing@afribms.com';
    final amountInGhs = _isYearly ? targetTier.yearlyPriceGhs : targetTier.monthlyPriceGhs;

    // Show loading dialog
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Preparing Paystack Checkout...'),
              ],
            ),
          ),
        ),
      ),
    );

    final paystackService = ref.read(paystackSubscriptionServiceProvider);
    final initResult = await paystackService.initializePayment(
      email: email,
      amountInGhs: amountInGhs,
      tier: targetTier,
      isYearly: _isYearly,
      metadata: {
        'business_id': activeBiz?.id,
        'business_name': activeBiz?.name,
      },
    );

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
    }

    if (!initResult.success || initResult.authorizationUrl == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(initResult.errorMessage ?? 'Failed to initialize payment gateway.'),
          ),
        );
      }
      return;
    }

    // Launch checkout in browser / custom tab
    await paystackService.openCheckout(initResult.authorizationUrl!);

    if (!mounted) return;

    // Show verification dialog with test bypass option
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.payment_rounded, color: Colors.teal),
            SizedBox(width: 8),
            Text('Paystack Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A payment window has opened in your browser for GH₵$amountInGhs ($email).',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                'Reference: ${initResult.reference}',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Complete the transaction using MTN Mobile Money, Telecel Cash, AT Money, or Bank Card.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _verifyAndActivate(targetTier, initResult.reference!);
            },
            child: const Text('Verify Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyAndActivate(SubscriptionTier targetTier, String reference) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Verifying transaction with Paystack...'),
              ],
            ),
          ),
        ),
      ),
    );

    final paystackService = ref.read(paystackSubscriptionServiceProvider);
    final verified = await paystackService.verifyPayment(reference);

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
    }

    if (verified) {
      await _applyTierChange(targetTier);
    } else {
      if (mounted) {
        // Offer Sandbox / Test Mode bypass if in test mode
        final isTestMode = PaystackConfig.publicKey.startsWith('pk_test_');
        if (isTestMode) {
          final bypass = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Payment Verification Pending'),
              content: const Text(
                'Paystack returned pending/unpaid.\n\n'
                'Since you are using Paystack Test Mode, would you like to bypass verification and activate for testing?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Dismiss'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Activate (Test Mode)'),
                ),
              ],
            ),
          );
          if (bypass == true) {
            await _applyTierChange(targetTier);
            return;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Payment verification failed or payment is incomplete. Please contact support if debited.'),
            ),
          );
        }
      }
    }
  }

  Future<void> _applyTierChange(SubscriptionTier targetTier) async {
    final success = await ref
        .read(subscriptionControllerProvider.notifier)
        .changeTier(targetTier);

    if (mounted) {
      if (success) {
        AppHaptics.heavy();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E7D32),
            content: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Success! Your business is now on ${targetTier.displayName}.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        AppHaptics.error();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update plan. Please check your connection and retry.'),
          ),
        );
      }
    }
  }
}
