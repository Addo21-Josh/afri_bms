import 'package:flutter/material.dart';

/// Available subscription tiers in Afri_BMS
enum SubscriptionTier {
  free,
  pro,
  enterprise;

  static SubscriptionTier fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'pro':
        return SubscriptionTier.pro;
      case 'enterprise':
        return SubscriptionTier.enterprise;
      case 'free':
      default:
        return SubscriptionTier.free;
    }
  }

  String get id => name;

  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free Starter';
      case SubscriptionTier.pro:
        return 'Afri_BMS Pro';
      case SubscriptionTier.enterprise:
        return 'Afri_BMS Enterprise';
    }
  }

  String get shortName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.enterprise:
        return 'Enterprise';
    }
  }

  String get tagline {
    switch (this) {
      case SubscriptionTier.free:
        return 'For solo traders & small kiosks getting started';
      case SubscriptionTier.pro:
        return 'For growing retail stores, supermarkets & pharmacies';
      case SubscriptionTier.enterprise:
        return 'For multi-branch chains, wholesalers & distributors';
    }
  }

  int get monthlyPriceGhs {
    switch (this) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.pro:
        return 50;
      case SubscriptionTier.enterprise:
        return 150;
    }
  }

  int get yearlyPriceGhs {
    switch (this) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.pro:
        return 500; // 2 months free
      case SubscriptionTier.enterprise:
        return 1500; // 2 months free
    }
  }

  int get monthlyPriceNgn {
    switch (this) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.pro:
        return 5000;
      case SubscriptionTier.enterprise:
        return 15000;
    }
  }

  int get yearlyPriceNgn {
    switch (this) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.pro:
        return 50000; // 2 months free discount
      case SubscriptionTier.enterprise:
        return 150000; // 2 months free discount
    }
  }

  String formattedPrice(bool isYearly, {String currency = 'GHS'}) {
    if (this == SubscriptionTier.free) return 'Free';
    if (currency.toUpperCase() == 'GHS') {
      final amount = isYearly ? yearlyPriceGhs : monthlyPriceGhs;
      return 'GH₵${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    } else {
      final amount = isYearly ? yearlyPriceNgn : monthlyPriceNgn;
      return '₦${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
  }

  bool get isPaid => this != SubscriptionTier.free;
  bool get isProOrHigher =>
      this == SubscriptionTier.pro || this == SubscriptionTier.enterprise;
  bool get isEnterprise => this == SubscriptionTier.enterprise;

  Color get badgeColor {
    switch (this) {
      case SubscriptionTier.free:
        return Colors.blueGrey;
      case SubscriptionTier.pro:
        return const Color(0xFF2E7D32); // Vibrant green
      case SubscriptionTier.enterprise:
        return const Color(0xFF6A1B9A); // Royal purple
    }
  }

  IconData get icon {
    switch (this) {
      case SubscriptionTier.free:
        return Icons.storefront_outlined;
      case SubscriptionTier.pro:
        return Icons.verified_rounded;
      case SubscriptionTier.enterprise:
        return Icons.stars_rounded;
    }
  }
}

/// Feature and resource quotas defined per tier (from docs/FREEMIUM.md)
class TierLimits {
  final int maxBusinesses;
  final int maxBranchesPerBusiness;
  final int maxStaffAccounts;
  final int maxProducts;
  final int maxMonthlyTransactions;
  final int maxCustomers;
  final int maxSuppliers;
  final bool cloudBackup;
  final bool autoSync;
  final bool thermalPrinting;
  final bool barcodeGeneration;
  final bool labelPrinting;
  final bool customRoles;
  final bool fullReports;
  final bool dataExport;
  final int multiCurrencyLimit; // 1, 3, or -1 (unlimited)

  const TierLimits({
    required this.maxBusinesses,
    required this.maxBranchesPerBusiness,
    required this.maxStaffAccounts,
    required this.maxProducts,
    required this.maxMonthlyTransactions,
    required this.maxCustomers,
    required this.maxSuppliers,
    required this.cloudBackup,
    required this.autoSync,
    required this.thermalPrinting,
    required this.barcodeGeneration,
    required this.labelPrinting,
    required this.customRoles,
    required this.fullReports,
    required this.dataExport,
    required this.multiCurrencyLimit,
  });

  /// Free Starter Tier Limits
  static const free = TierLimits(
    maxBusinesses: 1,
    maxBranchesPerBusiness: 1,
    maxStaffAccounts: 2,
    maxProducts: 100,
    maxMonthlyTransactions: 200,
    maxCustomers: 50,
    maxSuppliers: 20,
    cloudBackup: false,
    autoSync: false,
    thermalPrinting: false,
    barcodeGeneration: false,
    labelPrinting: false,
    customRoles: false,
    fullReports: false,
    dataExport: false,
    multiCurrencyLimit: 1,
  );

  /// Pro Tier Limits (₦5,000/mo)
  static const pro = TierLimits(
    maxBusinesses: 3,
    maxBranchesPerBusiness: 5,
    maxStaffAccounts: 10,
    maxProducts: 1000,
    maxMonthlyTransactions: 5000,
    maxCustomers: 500,
    maxSuppliers: 100,
    cloudBackup: true,
    autoSync: true,
    thermalPrinting: true,
    barcodeGeneration: true,
    labelPrinting: true,
    customRoles: false,
    fullReports: true,
    dataExport: true,
    multiCurrencyLimit: 3,
  );

  /// Enterprise Tier Limits (₦15,000/mo) - Unlimited (-1)
  static const enterprise = TierLimits(
    maxBusinesses: -1,
    maxBranchesPerBusiness: -1,
    maxStaffAccounts: -1,
    maxProducts: -1,
    maxMonthlyTransactions: -1,
    maxCustomers: -1,
    maxSuppliers: -1,
    cloudBackup: true,
    autoSync: true,
    thermalPrinting: true,
    barcodeGeneration: true,
    labelPrinting: true,
    customRoles: true,
    fullReports: true,
    dataExport: true,
    multiCurrencyLimit: -1,
  );

  static TierLimits forTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return free;
      case SubscriptionTier.pro:
        return pro;
      case SubscriptionTier.enterprise:
        return enterprise;
    }
  }
}
