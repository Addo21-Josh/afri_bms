import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../users/presentation/providers/staff_provider.dart';
import '../../../../core/sync/presentation/providers/sync_provider.dart';
import '../../../../core/subscription/domain/models/subscription_tier.dart';
import '../../../../core/subscription/presentation/providers/subscription_provider.dart';
import '../../../../core/subscription/presentation/screens/subscription_plans_screen.dart';
import '../../../../core/subscription/presentation/widgets/upgrade_prompt_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentLocale = ref.watch(localeProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final printerConfig = ref.watch(printerConfigProvider);
    final currentBiz = ref.watch(currentBusinessProvider);
    final currentTier = ref.watch(currentSubscriptionTierProvider);
    final userRole = ref.watch(currentUserRoleProvider).valueOrNull;
    final syncState = ref.watch(syncProvider);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ─── USER & ACCOUNT CARD ───
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      (currentBiz?.name.isNotEmpty == true
                              ? currentBiz!.name[0]
                              : user?.email?[0] ?? 'A')
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentBiz?.name ?? 'My Business',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'Logged in',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (userRole?.displayName ?? 'Administrator')
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSecondaryContainer,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: currentTier.badgeColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currentTier.shortName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
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
          ),
          const SizedBox(height: 20),

          // ─── SECTION: SUBSCRIPTION & BILLING ───
          _buildSectionHeader(context, 'Subscription & Billing'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: currentTier.badgeColor.withValues(alpha: 0.35),
              ),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: currentTier.badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  currentTier.icon,
                  color: currentTier.badgeColor,
                  size: 22,
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      currentTier.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: currentTier.badgeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      currentTier.shortName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                currentTier.isPaid
                    ? 'Active Plan • Manage subscription or upgrade'
                    : 'Free Starter • Upgrade to Pro for cloud sync & thermal printing',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionPlansScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // ─── SECTION: APP PREFERENCES ───
          _buildSectionHeader(context, 'Preferences & Appearance'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                // Language
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLanguages.getFlag(currentLocale),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  title: Text(l10n.settingsLanguage),
                  subtitle: Text(AppLanguages.getLabel(currentLocale)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguageDialog(context, ref, currentLocale),
                ),
                const Divider(height: 1),
                // Theme
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      currentThemeMode == ThemeMode.dark
                          ? Icons.dark_mode
                          : currentThemeMode == ThemeMode.light
                          ? Icons.light_mode
                          : Icons.brightness_auto,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(l10n.settingsTheme),
                  subtitle: Text(
                    currentThemeMode == ThemeMode.dark
                        ? l10n.settingsThemeDark
                        : currentThemeMode == ThemeMode.light
                        ? l10n.settingsThemeLight
                        : l10n.settingsThemeSystem,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _showThemeDialog(context, ref, currentThemeMode, l10n),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── SECTION: BUSINESS & OUTLETS ───
          _buildSectionHeader(context, 'Business & Store Operations'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: _iconBox(context, Icons.storefront_outlined),
                  title: Text(l10n.businessSettingsTitle),
                  subtitle: Text(
                    'Profile, currency (${currentBiz?.defaultCurrency ?? 'GHS'}), tax (${currentBiz?.taxRate ?? 0}%)',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/business-settings'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: _iconBox(context, Icons.account_tree_outlined),
                  title: Text(l10n.businessBranches),
                  subtitle: const Text(
                    'Manage store branches and staff allocation',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/branches'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: _iconBox(context, Icons.badge_outlined),
                  title: Text(l10n.navStaff),
                  subtitle: const Text(
                    'Staff accounts, PINs, and cashier permissions',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/staff'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── SECTION: HARDWARE & RECEIPT PRINTER ───
          _buildSectionHeader(context, 'Hardware & Printing'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: _iconBox(context, Icons.print_outlined),
                  title: Text(l10n.settingsPrinter),
                  subtitle: Text(
                    printerConfig.printerName != null
                        ? '${printerConfig.printerName} (${printerConfig.paperWidthMm}mm)'
                        : l10n.settingsPrinterNone,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _showPrinterDialog(context, ref, printerConfig, l10n),
                ),
                SwitchListTile(
                  secondary: _iconBox(context, Icons.receipt_long_outlined),
                  title: const Text('Auto-print Receipt on Sale'),
                  subtitle: const Text(
                    'Automatically trigger print when checkout completes',
                  ),
                  value: printerConfig.autoPrintReceipt,
                  onChanged: (val) {
                    ref
                        .read(printerConfigProvider.notifier)
                        .updatePrinter(autoPrint: val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── SECTION: DATA, SYNC & BACKUP ───
          _buildSectionHeader(context, 'Data, Sync & Storage'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: _iconBox(context, Icons.sync_outlined),
                  title: Text(l10n.navSync),
                  subtitle: Text(
                    syncState.isOnline
                        ? (syncState.pendingCount > 0
                              ? '${syncState.pendingCount} changes pending sync'
                              : 'All data synchronized')
                        : 'Offline mode active',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: syncState.isOnline
                              ? Colors.green
                              : Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => context.push('/sync-center'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: _iconBox(context, Icons.cloud_done_outlined),
                  title: Text(l10n.backupTitle),
                  subtitle: const Text(
                    'Create full JSON snapshots, restore store data',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/backup'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── SECTION: ABOUT & SUPPORT ───
          _buildSectionHeader(context, 'About & Support'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: _iconBox(context, Icons.info_outline),
                  title: Text(l10n.settingsAbout),
                  subtitle: const Text('Version 1.0.0+1 (Phase 5 Release)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAboutDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: _iconBox(context, Icons.support_agent_outlined),
                  title: Text(l10n.settingsSupport),
                  subtitle: const Text('FAQs, user guides, contact support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSupportDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── LOGOUT BUTTON ───
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context, ref, l10n),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: Text(
              l10n.navLogout,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _iconBox(BuildContext context, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(128),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: colorScheme.primary, size: 20),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguages.supported.map((loc) {
            final isSelected = loc.languageCode == currentLocale.languageCode;
            return ListTile(
              leading: Text(
                AppLanguages.getFlag(loc),
                style: const TextStyle(fontSize: 22),
              ),
              title: Text(
                AppLanguages.getLabel(loc),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : const Icon(Icons.circle_outlined, color: Colors.grey),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(loc);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
    AppLocalizations l10n,
  ) {
    final themeOptions = [
      (ThemeMode.system, l10n.settingsThemeSystem, Icons.brightness_auto),
      (ThemeMode.light, l10n.settingsThemeLight, Icons.light_mode),
      (ThemeMode.dark, l10n.settingsThemeDark, Icons.dark_mode),
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themeOptions.map((opt) {
            final isSelected = opt.$1 == currentMode;
            return ListTile(
              leading: Icon(
                opt.$3,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(
                opt.$2,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : const Icon(Icons.circle_outlined, color: Colors.grey),
              onTap: () {
                ref.read(themeModeProvider.notifier).setThemeMode(opt.$1);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPrinterDialog(
    BuildContext context,
    WidgetRef ref,
    PrinterConfig config,
    AppLocalizations l10n,
  ) {
    final nameController = TextEditingController(
      text: config.printerName ?? 'POS-58 Bluetooth',
    );
    int selectedWidth = config.paperWidthMm;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(l10n.settingsPrinter),
          actionsOverflowButtonSpacing: 8,
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Printer Device Name / Model',
                      hintText: 'e.g. MTP-II, POS-58, Epson TM-T20',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Paper Roll Width',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('58 mm (Standard)'),
                        selected: selectedWidth == 58,
                        onSelected: (val) {
                          if (val) setDialogState(() => selectedWidth = 58);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('80 mm (Wide)'),
                        selected: selectedWidth == 80,
                        onSelected: (val) {
                          if (val) setDialogState(() => selectedWidth = 80);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref
                    .read(printerConfigProvider.notifier)
                    .updatePrinter(name: null);
                Navigator.pop(ctx);
              },
              child: const Text(
                'Disconnect',
                style: TextStyle(color: Colors.red),
              ),
            ),
            FilledButton(
              onPressed: () {
                final gate = ref.read(featureGateProvider);
                if (!gate.limits.thermalPrinting) {
                  Navigator.pop(ctx);
                  UpgradePromptSheet.show(
                    context,
                    featureName: 'Thermal Receipt Printing',
                    customMessage:
                        'Pairing and printing to physical ESC/POS thermal printers requires Afri_BMS Pro or Enterprise.',
                    currentTier: gate.tier,
                    suggestedTier: SubscriptionTier.pro,
                  );
                  return;
                }
                final name = nameController.text.trim();
                ref
                    .read(printerConfigProvider.notifier)
                    .updatePrinter(
                      name: name.isNotEmpty ? name : 'POS-58 Bluetooth',
                      widthMm: selectedWidth,
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Printer configured: $name ($selectedWidth mm)',
                    ),
                  ),
                );
              },
              child: const Text('Save & Pair'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Afri_BMS',
      applicationVersion: '1.0.0+1 (Build 101)',
      applicationLegalese:
          '© 2026 Afri_BMS. Built for retail and inventory in African markets.',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/logo/main_logo.jpg',
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      ),
      children: const [
        SizedBox(height: 16),
        Text(
          'Afri_BMS empowers business owners across Nigeria, Ghana, Kenya, and Pan-Africa with offline-first point of sale, smart inventory forecasting, and real-time ledger management.',
        ),
      ],
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & Customer Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need assistance or have feedback? Reach out to our 24/7 support desk:',
            ),
            SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.email_outlined, color: Colors.teal),
              title: Text('support@afribms.com'),
              subtitle: Text('Email support'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.chat_outlined, color: Colors.green),
              title: Text('+234 800 AFRIBMS'),
              subtitle: Text('WhatsApp & Phone'),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.navLogout),
        content: Text(l10n.authLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              if (context.mounted) context.go('/login');
              await ref.read(authControllerProvider.notifier).signOut();
            },
            child: Text(l10n.navLogout),
          ),
        ],
      ),
    );
  }
}
