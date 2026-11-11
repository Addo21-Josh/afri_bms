import '../models/subscription_tier.dart';

/// Represents the verdict of a feature gate evaluation.
class GateResult {
  final bool isAllowed;
  final String? featureName;
  final String? reason;
  final SubscriptionTier currentTier;
  final SubscriptionTier requiredTier;
  final int? currentCount;
  final int? maxAllowed;

  const GateResult({
    required this.isAllowed,
    this.featureName,
    this.reason,
    required this.currentTier,
    this.requiredTier = SubscriptionTier.pro,
    this.currentCount,
    this.maxAllowed,
  });

  bool get isBlocked => !isAllowed;

  static GateResult allowed(SubscriptionTier currentTier) {
    return GateResult(isAllowed: true, currentTier: currentTier);
  }
}

/// Service that enforces freemium limits and checks feature access.
class FeatureGateService {
  final SubscriptionTier tier;
  final TierLimits limits;

  FeatureGateService({required this.tier}) : limits = TierLimits.forTier(tier);

  // ─── Resource Quota Checks ──────────────────────────────────────────────────

  GateResult checkProductLimit(int currentProductCount) {
    if (limits.maxProducts == -1 || currentProductCount < limits.maxProducts) {
      return GateResult.allowed(tier);
    }
    return GateResult(
      isAllowed: false,
      featureName: 'Product Catalog',
      reason:
          "You've reached your ${tier.shortName} limit of ${limits.maxProducts} products. Upgrade to Pro for up to 1,000 products.",
      currentTier: tier,
      requiredTier: SubscriptionTier.pro,
      currentCount: currentProductCount,
      maxAllowed: limits.maxProducts,
    );
  }

  GateResult checkStaffLimit(int currentStaffCount) {
    if (limits.maxStaffAccounts == -1 ||
        currentStaffCount < limits.maxStaffAccounts) {
      return GateResult.allowed(tier);
    }
    return GateResult(
      isAllowed: false,
      featureName: 'Staff Accounts',
      reason:
          "You've reached your limit of ${limits.maxStaffAccounts} staff accounts. Upgrade to add more team members.",
      currentTier: tier,
      requiredTier: tier == SubscriptionTier.free
          ? SubscriptionTier.pro
          : SubscriptionTier.enterprise,
      currentCount: currentStaffCount,
      maxAllowed: limits.maxStaffAccounts,
    );
  }

  GateResult checkBranchLimit(int currentBranchCount) {
    if (limits.maxBranchesPerBusiness == -1 ||
        currentBranchCount < limits.maxBranchesPerBusiness) {
      return GateResult.allowed(tier);
    }
    return GateResult(
      isAllowed: false,
      featureName: 'Branches & Locations',
      reason:
          "You've reached your limit of ${limits.maxBranchesPerBusiness} branch. Upgrade to Pro to manage up to 5 branches.",
      currentTier: tier,
      requiredTier: tier == SubscriptionTier.free
          ? SubscriptionTier.pro
          : SubscriptionTier.enterprise,
      currentCount: currentBranchCount,
      maxAllowed: limits.maxBranchesPerBusiness,
    );
  }

  GateResult checkBusinessLimit(int currentBusinessCount) {
    if (limits.maxBusinesses == -1 ||
        currentBusinessCount < limits.maxBusinesses) {
      return GateResult.allowed(tier);
    }
    return GateResult(
      isAllowed: false,
      featureName: 'Multiple Businesses',
      reason:
          "You've reached your limit of ${limits.maxBusinesses} business. Upgrade to Pro to run up to 3 businesses.",
      currentTier: tier,
      requiredTier: tier == SubscriptionTier.free
          ? SubscriptionTier.pro
          : SubscriptionTier.enterprise,
      currentCount: currentBusinessCount,
      maxAllowed: limits.maxBusinesses,
    );
  }

  GateResult checkCustomerLimit(int currentCustomerCount) {
    if (limits.maxCustomers == -1 ||
        currentCustomerCount < limits.maxCustomers) {
      return GateResult.allowed(tier);
    }
    return GateResult(
      isAllowed: false,
      featureName: 'Customer Directory',
      reason:
          "You've reached your limit of ${limits.maxCustomers} customers. Upgrade to Pro to store up to 500 customers.",
      currentTier: tier,
      requiredTier: SubscriptionTier.pro,
      currentCount: currentCustomerCount,
      maxAllowed: limits.maxCustomers,
    );
  }

  GateResult checkSupplierLimit(int currentSupplierCount) {
    if (limits.maxSuppliers == -1 ||
        currentSupplierCount < limits.maxSuppliers) {
      return GateResult.allowed(tier);
    }
    return GateResult(
      isAllowed: false,
      featureName: 'Suppliers Directory',
      reason:
          "You've reached your limit of ${limits.maxSuppliers} suppliers. Upgrade to Pro to store up to 100 suppliers.",
      currentTier: tier,
      requiredTier: SubscriptionTier.pro,
      currentCount: currentSupplierCount,
      maxAllowed: limits.maxSuppliers,
    );
  }

  GateResult checkMonthlySalesLimit(int currentSalesCount) {
    if (limits.maxMonthlyTransactions == -1 ||
        currentSalesCount < limits.maxMonthlyTransactions) {
      return GateResult.allowed(tier);
    }
    return GateResult(
      isAllowed: false,
      featureName: 'Monthly Sales Transactions',
      reason:
          "You've reached your limit of ${limits.maxMonthlyTransactions} monthly sales transactions. Upgrade to Pro for up to 5,000 transactions/month.",
      currentTier: tier,
      requiredTier: SubscriptionTier.pro,
      currentCount: currentSalesCount,
      maxAllowed: limits.maxMonthlyTransactions,
    );
  }

  // ─── Boolean Feature Access Checks ──────────────────────────────────────────

  GateResult canUseThermalPrinter() {
    if (limits.thermalPrinting) return GateResult.allowed(tier);
    return GateResult(
      isAllowed: false,
      featureName: 'Thermal Receipt Printing',
      reason:
          'Thermal Bluetooth/USB POS receipt printing is available on Afri_BMS Pro & Enterprise.',
      currentTier: tier,
      requiredTier: SubscriptionTier.pro,
    );
  }

  GateResult canGenerateBarcode() {
    if (limits.barcodeGeneration) return GateResult.allowed(tier);
    return GateResult(
      isAllowed: false,
      featureName: 'Barcode & QR Generation',
      reason:
          'Generating EAN-13, Code-128, and QR barcodes is available on Afri_BMS Pro & Enterprise.',
      currentTier: tier,
      requiredTier: SubscriptionTier.pro,
    );
  }

  GateResult canPrintLabels() {
    if (limits.labelPrinting) return GateResult.allowed(tier);
    return GateResult(
      isAllowed: false,
      featureName: 'Price Tag & Label Printing',
      reason:
          'Batch printing price labels and barcode sheets is available on Afri_BMS Pro.',
      currentTier: tier,
      requiredTier: SubscriptionTier.pro,
    );
  }

  GateResult canExportData() {
    if (limits.dataExport) return GateResult.allowed(tier);
    return GateResult(
      isAllowed: false,
      featureName: 'Data & Report Export',
      reason:
          'Exporting sales and inventory reports as CSV and PDF is available on Afri_BMS Pro & Enterprise.',
      currentTier: tier,
      requiredTier: SubscriptionTier.pro,
    );
  }

  GateResult canUseCloudBackup() {
    if (limits.cloudBackup) return GateResult.allowed(tier);
    return GateResult(
      isAllowed: false,
      featureName: 'Cloud Backup & Restore',
      reason:
          'Automatic cloud database backup to secure cloud storage is available on Afri_BMS Pro & Enterprise.',
      currentTier: tier,
      requiredTier: SubscriptionTier.pro,
    );
  }

  GateResult canUseCustomRoles() {
    if (limits.customRoles) return GateResult.allowed(tier);
    return GateResult(
      isAllowed: false,
      featureName: 'Custom Staff Roles & Permissions',
      reason:
          'Granular permissions and customized staff roles require Afri_BMS Enterprise.',
      currentTier: tier,
      requiredTier: SubscriptionTier.enterprise,
    );
  }

  GateResult canAccessFullReports() {
    if (limits.fullReports) return GateResult.allowed(tier);
    return GateResult(
      isAllowed: false,
      featureName: 'Advanced Analytics & Full Reports',
      reason:
          'Extended date ranges, customer patterns, and profit margin breakdowns require Afri_BMS Pro.',
      currentTier: tier,
      requiredTier: SubscriptionTier.pro,
    );
  }

  GateResult canUseAutoSync() {
    if (limits.autoSync) return GateResult.allowed(tier);
    return GateResult(
      isAllowed: false,
      featureName: 'Automatic Real-Time Sync',
      reason:
          'Automated background sync every 5 minutes requires Afri_BMS Pro or Enterprise.',
      currentTier: tier,
      requiredTier: SubscriptionTier.pro,
    );
  }
}
