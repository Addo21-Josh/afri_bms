# ARCHITECTURE.md — Afri_BMS System Architecture

> Complete technical architecture for the African Business Management System.

---

## 1. System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        AFRI_BMS CLIENT                           │
│                     (Flutter - Android/iOS)                       │
│                                                                   │
│  ┌─────────┐  ┌─────────┐  ┌──────────┐  ┌────────────────────┐ │
│  │   UI    │  │Riverpod │  │  Domain   │  │      Data          │ │
│  │ Screens │→ │Providers│→ │ UseCases  │→ │  Repositories      │ │
│  │ Widgets │  │ States  │  │ Entities  │  │  DataSources       │ │
│  └─────────┘  └─────────┘  └──────────┘  └────────┬───────────┘ │
│                                                     │             │
│                          ┌──────────────────────────┤             │
│                          │                          │             │
│                    ┌─────▼─────┐            ┌───────▼──────┐     │
│                    │   ISAR    │            │ Supabase SDK │     │
│                    │  (Local)  │            │  (Remote)    │     │
│                    └─────┬─────┘            └───────┬──────┘     │
│                          │                          │             │
│                    ┌─────▼──────────────────────────▼─────┐      │
│                    │         SYNC ENGINE                   │      │
│                    │  (Background Isolate + Queue)         │      │
│                    └──────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────┐
│                      SUPABASE CLOUD                              │
│                                                                   │
│  ┌──────────┐  ┌──────────────┐  ┌────────────┐  ┌───────────┐  │
│  │   Auth   │  │  PostgreSQL  │  │   Storage  │  │   Edge    │  │
│  │  (JWT)   │  │  (Database)  │  │  (Buckets) │  │ Functions │  │
│  └──────────┘  └──────────────┘  └────────────┘  └───────────┘  │
│                                                                   │
│  ┌──────────┐  ┌──────────────┐                                  │
│  │ Realtime │  │   Row Level  │                                  │
│  │   (WS)   │  │  Security    │                                  │
│  └──────────┘  └──────────────┘                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. Clean Architecture Layers

### 2.1 Domain Layer (Pure Dart — No Dependencies)

The domain layer is the innermost layer and contains:

```
domain/
├── entities/          # Business objects (freezed)
│   ├── user_entity.dart
│   ├── business_entity.dart
│   ├── branch_entity.dart
│   ├── product_entity.dart
│   ├── sale_entity.dart
│   └── ...
├── repositories/      # Abstract contracts (interfaces)
│   ├── auth_repository.dart
│   ├── product_repository.dart
│   └── ...
├── usecases/          # Single-responsibility business operations
│   ├── sign_in.dart
│   ├── create_product.dart
│   └── ...
└── value_objects/      # Type-safe value types
    ├── email_address.dart
    ├── money.dart
    └── ...
```

#### Entity Design Pattern (Freezed)

```dart
@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String businessId,
    required String branchId,
    required String name,
    required String? description,
    required String? sku,
    required String? barcode,
    required Money costPrice,
    required Money sellingPrice,
    required int stockQuantity,
    required int reorderLevel,
    required ProductCategory category,
    required List<ProductVariant> variants,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime? deletedAt,
    @Default(false) bool isSynced,
  }) = _Product;
}
```

#### UseCase Pattern

```dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class CreateProduct implements UseCase<Product, CreateProductParams> {
  final ProductRepository _repository;

  CreateProduct(this._repository);

  @override
  Future<Either<Failure, Product>> call(CreateProductParams params) {
    return _repository.createProduct(
      name: params.name,
      costPrice: params.costPrice,
      sellingPrice: params.sellingPrice,
      // ...
    );
  }
}
```

### 2.2 Data Layer

```
data/
├── datasources/
│   ├── remote/                # Supabase API calls
│   │   ├── product_remote_datasource.dart
│   │   └── ...
│   └── local/                 # Isar operations
│       ├── product_local_datasource.dart
│       └── ...
├── models/                    # Data transfer objects
│   ├── product_model.dart     # extends/maps to entity
│   └── ...
├── repositories/              # Concrete implementations
│   ├── product_repository_impl.dart
│   └── ...
└── mappers/                   # Model ↔ Entity conversion
    ├── product_mapper.dart
    └── ...
```

#### Repository Implementation Pattern

```dart
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDatasource _remote;
  final ProductLocalDatasource _local;
  final NetworkInfo _networkInfo;
  final SyncQueue _syncQueue;

  @override
  Future<Either<Failure, Product>> createProduct({...}) async {
    try {
      // 1. Always write to local first
      final localProduct = await _local.insertProduct(model);

      // 2. Queue for sync
      await _syncQueue.enqueue(
        SyncOperation.create,
        table: 'products',
        recordId: localProduct.id,
        data: localProduct.toJson(),
      );

      // 3. Attempt remote sync if online
      if (await _networkInfo.isConnected) {
        await _trySyncProduct(localProduct);
      }

      return Right(localProduct.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
```

### 2.3 Presentation Layer

```
presentation/
├── providers/             # Riverpod providers & state notifiers
│   ├── product_list_provider.dart
│   ├── product_form_provider.dart
│   └── ...
├── screens/               # Full page widgets
│   ├── product_list_screen.dart
│   ├── product_detail_screen.dart
│   └── ...
└── widgets/               # Feature-specific widgets
    ├── product_card.dart
    ├── stock_badge.dart
    └── ...
```

---

## 3. Database Architecture

### 3.1 Supabase PostgreSQL Schema

```sql
-- ==========================================
-- CORE TABLES
-- ==========================================

-- Users (extends Supabase Auth)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Businesses
CREATE TABLE public.businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id),
    name TEXT NOT NULL,
    description TEXT,
    logo_url TEXT,
    default_currency TEXT NOT NULL DEFAULT 'NGN',
    supported_currencies TEXT[] DEFAULT '{NGN}',
    tax_rate DECIMAL(5,2) DEFAULT 0.00,
    address TEXT,
    phone TEXT,
    email TEXT,
    is_active BOOLEAN DEFAULT true,
    subscription_tier TEXT DEFAULT 'free',  -- free, pro, enterprise
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Branches
CREATE TABLE public.branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id),
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    currency TEXT NOT NULL DEFAULT 'NGN',
    is_main BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- User Roles (many-to-many: users ↔ businesses/branches)
CREATE TABLE public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    business_id UUID NOT NULL REFERENCES public.businesses(id),
    branch_id UUID REFERENCES public.branches(id),  -- NULL = all branches
    role TEXT NOT NULL CHECK (role IN ('admin', 'branch_manager', 'salesperson', 'cashier', 'custom')),
    custom_permissions JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    UNIQUE(user_id, business_id, branch_id)
);

-- ==========================================
-- INVENTORY
-- ==========================================

-- Product Categories
CREATE TABLE public.product_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id),
    name TEXT NOT NULL,
    description TEXT,
    parent_id UUID REFERENCES public.product_categories(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Products
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id),
    category_id UUID REFERENCES public.product_categories(id),
    name TEXT NOT NULL,
    description TEXT,
    sku TEXT,
    barcode TEXT,
    cost_price BIGINT NOT NULL DEFAULT 0,      -- in minor units (kobo/pesewa)
    selling_price BIGINT NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'NGN',
    unit TEXT DEFAULT 'pcs',                    -- pcs, kg, litre, etc.
    reorder_level INT DEFAULT 10,
    is_active BOOLEAN DEFAULT true,
    image_urls TEXT[],
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Product Variants (size, color, etc.)
CREATE TABLE public.product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id),
    name TEXT NOT NULL,                          -- e.g., "Large - Red"
    sku TEXT,
    barcode TEXT,
    cost_price BIGINT NOT NULL DEFAULT 0,
    selling_price BIGINT NOT NULL DEFAULT 0,
    attributes JSONB DEFAULT '{}',              -- {"size": "L", "color": "Red"}
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Stock (per branch)
CREATE TABLE public.stock (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id),
    variant_id UUID REFERENCES public.product_variants(id),
    branch_id UUID NOT NULL REFERENCES public.branches(id),
    quantity INT NOT NULL DEFAULT 0,
    batch_number TEXT,
    expiry_date DATE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(product_id, variant_id, branch_id, batch_number)
);

-- Stock Movements (audit trail)
CREATE TABLE public.stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id),
    variant_id UUID REFERENCES public.product_variants(id),
    branch_id UUID NOT NULL REFERENCES public.branches(id),
    movement_type TEXT NOT NULL CHECK (movement_type IN ('in', 'out', 'adjustment', 'transfer')),
    quantity INT NOT NULL,
    reference_type TEXT,                        -- 'sale', 'purchase', 'manual', 'transfer'
    reference_id UUID,
    notes TEXT,
    performed_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ==========================================
-- SALES
-- ==========================================

-- Sales
CREATE TABLE public.sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id),
    branch_id UUID NOT NULL REFERENCES public.branches(id),
    customer_id UUID REFERENCES public.customers(id),
    sold_by UUID NOT NULL REFERENCES public.profiles(id),
    sale_number TEXT NOT NULL,                   -- auto-generated: INV-0001
    subtotal BIGINT NOT NULL DEFAULT 0,
    discount_amount BIGINT DEFAULT 0,
    discount_type TEXT CHECK (discount_type IN ('fixed', 'percentage')),
    tax_amount BIGINT DEFAULT 0,
    total_amount BIGINT NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'NGN',
    payment_status TEXT NOT NULL DEFAULT 'paid'
        CHECK (payment_status IN ('paid', 'partial', 'unpaid', 'refunded')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Sale Items
CREATE TABLE public.sale_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id UUID NOT NULL REFERENCES public.sales(id),
    product_id UUID NOT NULL REFERENCES public.products(id),
    variant_id UUID REFERENCES public.product_variants(id),
    product_name TEXT NOT NULL,                  -- snapshot at time of sale
    quantity INT NOT NULL,
    unit_price BIGINT NOT NULL,
    discount BIGINT DEFAULT 0,
    total BIGINT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ==========================================
-- PAYMENTS
-- ==========================================

-- Payments
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id),
    branch_id UUID NOT NULL REFERENCES public.branches(id),
    sale_id UUID REFERENCES public.sales(id),
    debt_id UUID REFERENCES public.debts(id),
    payment_method TEXT NOT NULL
        CHECK (payment_method IN ('cash', 'mobile_money', 'bank_transfer', 'card', 'other')),
    mobile_money_provider TEXT,                  -- MTN, Vodafone, Airtel
    transaction_reference TEXT,
    amount BIGINT NOT NULL,
    currency TEXT NOT NULL DEFAULT 'NGN',
    received_by UUID REFERENCES public.profiles(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- ==========================================
-- CUSTOMERS & SUPPLIERS
-- ==========================================

-- Customers
CREATE TABLE public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id),
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address TEXT,
    notes TEXT,
    total_purchases BIGINT DEFAULT 0,
    total_debt BIGINT DEFAULT 0,
    credit_limit BIGINT DEFAULT 0,              -- 0 = no limit
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Suppliers
CREATE TABLE public.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id),
    name TEXT NOT NULL,
    contact_person TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    notes TEXT,
    total_supplied BIGINT DEFAULT 0,
    balance_owed BIGINT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- ==========================================
-- DEBT / CREDIT
-- ==========================================

-- Debts (customer owes business, or business owes supplier)
CREATE TABLE public.debts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id),
    branch_id UUID NOT NULL REFERENCES public.branches(id),
    debt_type TEXT NOT NULL CHECK (debt_type IN ('receivable', 'payable')),
    customer_id UUID REFERENCES public.customers(id),
    supplier_id UUID REFERENCES public.suppliers(id),
    sale_id UUID REFERENCES public.sales(id),
    original_amount BIGINT NOT NULL,
    outstanding_amount BIGINT NOT NULL,
    currency TEXT NOT NULL DEFAULT 'NGN',
    due_date DATE,
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'partially_paid', 'paid', 'overdue', 'written_off')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Debt Payments (partial payment tracking)
CREATE TABLE public.debt_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    debt_id UUID NOT NULL REFERENCES public.debts(id),
    payment_id UUID REFERENCES public.payments(id),
    amount BIGINT NOT NULL,
    notes TEXT,
    received_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ==========================================
-- EXPENSES
-- ==========================================

-- Expense Categories
CREATE TABLE public.expense_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Expenses
CREATE TABLE public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id),
    branch_id UUID NOT NULL REFERENCES public.branches(id),
    category_id UUID REFERENCES public.expense_categories(id),
    description TEXT NOT NULL,
    amount BIGINT NOT NULL,
    currency TEXT NOT NULL DEFAULT 'NGN',
    payment_method TEXT NOT NULL
        CHECK (payment_method IN ('cash', 'mobile_money', 'bank_transfer', 'card', 'other')),
    receipt_url TEXT,
    recorded_by UUID NOT NULL REFERENCES public.profiles(id),
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- ==========================================
-- RECEIPTS
-- ==========================================

-- Receipts (generated documents)
CREATE TABLE public.receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id),
    branch_id UUID NOT NULL REFERENCES public.branches(id),
    sale_id UUID NOT NULL REFERENCES public.sales(id),
    receipt_number TEXT NOT NULL,
    receipt_type TEXT NOT NULL CHECK (receipt_type IN ('pdf', 'thermal', 'sms')),
    file_url TEXT,                               -- Supabase Storage URL for PDF
    sent_via TEXT[],                             -- ['whatsapp', 'email', 'sms']
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.2 Isar Collections (Mirror of PostgreSQL)

Each Supabase table has a corresponding Isar collection with:
- Same fields + `isSynced` boolean + `localUpdatedAt` timestamp
- Composite indexes matching query patterns
- Links for relationships (lazy-loaded)

### 3.3 Row Level Security (RLS)

```sql
-- Example: Users can only see data for businesses they belong to
CREATE POLICY "Users see own business data" ON public.products
    FOR SELECT
    USING (
        business_id IN (
            SELECT business_id FROM public.user_roles
            WHERE user_id = auth.uid() AND is_active = true
        )
    );

-- Branch managers see only their branch
CREATE POLICY "Branch managers see own branch" ON public.sales
    FOR SELECT
    USING (
        branch_id IN (
            SELECT branch_id FROM public.user_roles
            WHERE user_id = auth.uid()
            AND role IN ('branch_manager')
            AND is_active = true
        )
        OR
        EXISTS (
            SELECT 1 FROM public.user_roles
            WHERE user_id = auth.uid()
            AND role = 'admin'
            AND business_id = sales.business_id
        )
    );
```

---

## 4. Sync Engine Architecture

### 4.1 Sync Queue

```dart
@Collection()
class SyncQueueItem {
  Id id = Isar.autoIncrement;

  @Index()
  late String tableName;

  late String recordId;
  late String operation;  // 'create', 'update', 'delete'
  late String payload;    // JSON string

  @Index()
  late int priority;      // 0 = highest

  late int retryCount;
  late int maxRetries;

  @Index()
  late DateTime createdAt;
  DateTime? lastAttemptAt;
  String? errorMessage;

  @Index()
  late String status;     // 'pending', 'processing', 'failed', 'completed'
}
```

### 4.2 Sync Flow

```
┌──────────┐     ┌───────────────┐     ┌──────────────┐
│  User    │────▶│  Repository   │────▶│  Isar (Local)│
│  Action  │     │  (write local)│     │  + SyncQueue │
└──────────┘     └───────────────┘     └──────┬───────┘
                                               │
                      ┌────────────────────────┘
                      ▼
              ┌───────────────┐
              │  Sync Engine  │ (runs in background isolate)
              │               │
              │  1. Check connectivity
              │  2. Dequeue pending items (ordered by priority + createdAt)
              │  3. Batch POST/PUT/DELETE to Supabase
              │  4. Handle conflicts (server wins with merge)
              │  5. Mark synced in Isar
              │  6. Pull remote changes
              │  7. Update local Isar
              └───────────────┘
```

### 4.3 Conflict Resolution Strategy

| Scenario | Resolution |
|---|---|
| Same record updated locally & remotely | Server timestamp wins; local changes re-applied if non-conflicting |
| Record deleted remotely, updated locally | Remote delete wins; notify user |
| Record created offline with duplicate key | Generate new UUID; merge data |
| Network timeout during sync | Retry with exponential backoff (max 5 retries) |

### 4.4 Background Sync Triggers

1. **Connectivity change** — immediately sync when connection restored
2. **Periodic** — every 5 minutes when online
3. **Manual** — pull-to-refresh gesture
4. **App lifecycle** — sync on resume from background
5. **Critical operations** — immediate sync attempt for payments/sales

---

## 5. Authentication Architecture

```
┌────────────────────────────────────────────────┐
│                 Auth Flow                       │
│                                                 │
│  1. Self-Signup                                 │
│     User → Register → Supabase Auth             │
│     → Auto-assign 'admin' role                  │
│     → Create business → Create main branch      │
│                                                 │
│  2. Staff Account Creation (by Admin)           │
│     Admin → Create User → Supabase Auth         │
│     → Assign role + branch in user_roles        │
│     → Send invite email with temp password       │
│                                                 │
│  3. Login                                       │
│     User → Email/Password → Supabase Auth       │
│     → JWT returned → Stored in Isar             │
│     → Fetch user profile + roles                │
│     → Navigate to role-appropriate dashboard    │
│                                                 │
│  4. Session Management                          │
│     JWT auto-refresh (Supabase handles)         │
│     Token expiry → Force re-login               │
│     Role changes → Real-time via Supabase WS    │
└────────────────────────────────────────────────┘
```

### Route Guards

```dart
class RoleGuard extends GoRouterRedirect {
  final List<UserRole> allowedRoles;

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    final user = ref.read(currentUserProvider);

    if (user == null) return '/login';
    if (!allowedRoles.contains(user.role)) return '/unauthorized';
    return null;  // allow access
  }
}
```

---

## 6. Mobile Money Integration Architecture

### 6.1 Abstraction Layer

```dart
abstract class MobileMoneyGateway {
  Future<Either<Failure, PaymentResult>> initiatePayment({
    required Money amount,
    required String phoneNumber,
    required String provider,  // 'mtn', 'vodafone', 'airtel'
    required String reference,
  });

  Future<Either<Failure, PaymentStatus>> checkStatus(String transactionId);
}

// Implementations
class PaystackGateway implements MobileMoneyGateway { ... }
class ManualRecordingGateway implements MobileMoneyGateway { ... }
```

### 6.2 Payment Flow

```
Customer → Select "Mobile Money" → Enter Phone
    → Select Provider (MTN/Vodafone/Airtel)
    → Initiate via Paystack API (or manual recording)
    → USSD prompt on customer's phone
    → Webhook / poll for confirmation
    → Record payment in local DB
    → Queue for sync
```

---

## 7. Receipt Generation Architecture

### 7.1 PDF Receipt Pipeline

```
Sale Completed → ReceiptGenerator.generatePdf(sale)
    → Build receipt layout (business logo, items, totals)
    → Generate PDF bytes via 'pdf' package
    → Save to local storage
    → Upload to Supabase Storage (when online)
    → Share via WhatsApp/Email using share_plus
```

### 7.2 Thermal Printer Pipeline

```
Sale Completed → ReceiptGenerator.printThermal(sale)
    → Discover Bluetooth printers
    → Build ESC/POS commands (receipt layout)
    → Send to printer via esc_pos_bluetooth
    → Log print status
```

### 7.3 SMS Receipt

```
Sale Completed → ReceiptGenerator.sendSms(sale, customerPhone)
    → Format compact text receipt
    → Send via SMS gateway (Twilio / Africa's Talking)
    → Log delivery status
```

---

## 8. Barcode Architecture

### 8.1 Scanning

```dart
// Uses mobile_scanner package
class BarcodeScannerService {
  Future<String?> scan() async {
    // Camera-based scanning
    // Supports: EAN-8, EAN-13, UPC-A, UPC-E, Code 128, QR Code
  }
}
```

### 8.2 Generation

```dart
// Uses barcode_widget package
class BarcodeGeneratorService {
  Widget generateBarcode(String data, BarcodeType type);
  Widget generateQrCode(String data);
  Future<Uint8List> generateImage(String data, BarcodeType type);
}
```

### 8.3 Label Printing

```
Generate barcode image → Create label layout (barcode + name + price)
    → Print via Bluetooth label printer
    → Or generate PDF label sheet for standard printer
```

---

## 9. Report Engine Architecture

### 9.1 Report Types

| Report | Data Source | Output |
|---|---|---|
| Daily Sales Summary | `sales` + `sale_items` | Chart + table |
| Weekly/Monthly Sales | `sales` aggregated | Line chart + summary |
| Profit & Loss | `sales` - `expenses` - cost | Financial statement |
| Inventory Valuation | `products` × `stock` quantities | Table + total |
| Low Stock Alert | `stock` WHERE qty < reorder_level | Alert list |
| Customer Ledger | `debts` + `debt_payments` per customer | Ledger table |
| Supplier Ledger | `debts` + `debt_payments` per supplier | Ledger table |
| Branch Comparison | `sales` grouped by branch | Comparison chart |
| Tax Report | `sales` with tax calculations | Tax summary |
| Aging Report | `debts` grouped by age buckets | Aging table |

### 9.2 Report Generation

```dart
abstract class ReportGenerator<T extends ReportData> {
  Future<T> generateData(ReportParams params);
  Widget buildChart(T data);
  Future<Uint8List> exportPdf(T data);
  Future<Uint8List> exportCsv(T data);
}
```

---

## 10. Internationalization (i18n) Architecture

```
l10n/
├── app_en.arb           # English (default)
├── app_fr.arb           # French (future)
├── app_sw.arb           # Swahili (future)
└── l10n.yaml            # Configuration
```

### Usage Pattern

```dart
// In ARB file
{
  "salesTitle": "Sales",
  "@salesTitle": { "description": "Title for sales screen" },

  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": { "placeholders": { "count": { "type": "int" } } }
}

// In code
Text(context.l10n.salesTitle)
Text(context.l10n.itemCount(items.length))
```

---

## 11. Security Architecture

### 11.1 Data Security

| Layer | Mechanism |
|---|---|
| Transport | HTTPS / TLS 1.3 |
| Authentication | Supabase Auth (JWT) |
| Authorization | RLS policies + app-level role checks |
| Local storage | Isar encrypted mode |
| Sensitive data | flutter_secure_storage for tokens |
| API keys | Dart defines / .env (never in source) |

### 11.2 Input Validation

- All user inputs validated at UI level AND domain level
- SQL injection prevented by Supabase parameterized queries
- XSS irrelevant (native app) but sanitize text displays
- Rate limiting via Supabase Edge Functions

---

## 12. Performance Architecture

### 12.1 Strategies

| Area | Strategy |
|---|---|
| Lists | Paginated loading (20 items/page) with infinite scroll |
| Images | Cached with `cached_network_image`, compressed before upload |
| Database | Isar indexes on frequently queried fields |
| State | Riverpod `keepAlive` for critical providers; dispose others |
| Build | Tree-shaking, code splitting per feature |
| Animations | Hardware-accelerated, 60fps target |
| Sync | Batched operations, delta sync (only changed records) |

### 12.2 Memory Management

- Dispose controllers and streams in `dispose()` / `ref.onDispose()`
- Limit in-memory list sizes (paginate)
- Use `compute()` for heavy Isar operations (JSON parsing, reports)
