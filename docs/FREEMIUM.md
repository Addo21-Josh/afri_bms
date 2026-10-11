# FREEMIUM.md — Afri_BMS Monetization & Tier System

> Defines feature gating, subscription tiers, and freemium logic.

---

## 1. Subscription Tiers

| Feature | Free | Pro (₦5,000/mo) | Enterprise (₦15,000/mo) |
|---|---|---|---|
| **Businesses** | 1 | 3 | Unlimited |
| **Branches per business** | 1 | 5 | Unlimited |
| **Staff accounts** | 2 | 10 | Unlimited |
| **Products** | 100 | 1,000 | Unlimited |
| **Monthly transactions** | 200 | 5,000 | Unlimited |
| **Customers** | 50 | 500 | Unlimited |
| **Suppliers** | 20 | 100 | Unlimited |
| **Cloud backup** | ❌ | ✅ | ✅ |
| **Auto sync** | ❌ (manual only) | ✅ (5 min) | ✅ (real-time) |
| **Reports** | Basic (today/week) | Full (all periods) | Full + export |
| **PDF receipts** | ✅ (watermarked) | ✅ | ✅ (custom branding) |
| **Thermal printing** | ❌ | ✅ | ✅ |
| **SMS receipts** | ❌ | ✅ (50/mo) | ✅ (unlimited) |
| **Barcode scanning** | ✅ | ✅ | ✅ |
| **Barcode generation** | ❌ | ✅ | ✅ |
| **Label printing** | ❌ | ✅ | ✅ |
| **Debt/credit tracking** | Basic | Full ledger | Full + aging + interest |
| **Custom roles** | ❌ | ❌ | ✅ |
| **Multi-currency** | 1 currency | 3 currencies | Unlimited |
| **Branch comparison** | ❌ | ❌ | ✅ |
| **API access** | ❌ | ❌ | ✅ |
| **Priority support** | ❌ | Email | Email + WhatsApp |
| **Data export** | ❌ | CSV | CSV + PDF + Excel |
| **Offline mode** | ✅ | ✅ | ✅ |
| **Local database** | ✅ | ✅ | ✅ |

---

## 2. Feature Gating Implementation

```dart
// Tier enum
enum SubscriptionTier {
  free,
  pro,
  enterprise,
}

// Feature limits
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
  final bool customRoles;
  final bool fullReports;
  final bool dataExport;

  const TierLimits({...});

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
    customRoles: false,
    fullReports: false,
    dataExport: false,
  );

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
    customRoles: false,
    fullReports: true,
    dataExport: true,
  );

  static const enterprise = TierLimits(
    maxBusinesses: -1,  // unlimited
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
    customRoles: true,
    fullReports: true,
    dataExport: true,
  );
}

// Feature gate check
class FeatureGate {
  final SubscriptionTier tier;
  final TierLimits limits;

  bool canCreateProduct(int currentCount) {
    if (limits.maxProducts == -1) return true;
    return currentCount < limits.maxProducts;
  }

  bool canUseThermalPrinter() => limits.thermalPrinting;

  bool canExportData() => limits.dataExport;

  // Show upgrade prompt when feature is gated
  void showUpgradePrompt(BuildContext context, String feature) {
    showModalBottomSheet(
      context: context,
      builder: (_) => UpgradePromptSheet(
        feature: feature,
        currentTier: tier,
        suggestedTier: tier == SubscriptionTier.free
            ? SubscriptionTier.pro
            : SubscriptionTier.enterprise,
      ),
    );
  }
}
```

---

## 3. Upgrade Prompts

Upgrade prompts should be:
- **Non-intrusive** — never block core workflows
- **Contextual** — shown when user hits a limit
- **Value-focused** — explain what they unlock
- **Dismissible** — always allow closing

```
┌─────────────────────────────────────────┐
│  ⭐ Upgrade to Pro                      │
│                                         │
│  You've reached the free tier limit     │
│  of 100 products.                       │
│                                         │
│  Upgrade to Pro to manage up to 1,000   │
│  products, plus get:                    │
│  ✅ Cloud backup & auto sync            │
│  ✅ Thermal receipt printing            │
│  ✅ Full reports & analytics            │
│  ✅ Barcode generation                  │
│                                         │
│  Starting at ₦5,000/month              │
│                                         │
│  [  Upgrade Now  ]  [Maybe Later]       │
└─────────────────────────────────────────┘
```

---

## 4. Payment Processing

### In-App Purchase (Google Play / App Store)

```dart
// For subscription management
// Uses: in_app_purchase package

class SubscriptionService {
  Future<void> purchasePro() async {
    // 1. Load products from store
    // 2. Initiate purchase
    // 3. Verify receipt server-side (Supabase Edge Function)
    // 4. Update subscription_tier in database
    // 5. Refresh local tier limits
  }

  Future<void> restorePurchases() async {
    // Restore previous purchases on re-install
  }

  Stream<SubscriptionTier> watchTier() {
    // Real-time tier updates
  }
}
```

### Alternative: Direct Payment (Paystack)

For markets where Google Play billing isn't optimal:
- Direct Paystack payment
- Server validates and activates subscription
- Recurring billing via Paystack subscription API
