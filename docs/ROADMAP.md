# ROADMAP.md — Afri_BMS Development Roadmap

> Phased implementation plan with milestones, deliverables, and acceptance criteria.

---

## Phase 1: Foundation (Weeks 1–2)

### Week 1: Project Setup & Core Infrastructure

#### 1.1 Project Configuration

- [ ] Update `pubspec.yaml` with all dependencies
- [ ] Configure `analysis_options.yaml` with strict lints
- [ ] Set up folder structure (feature-first architecture)
- [ ] Configure `.env` files for Supabase keys (dev/staging/prod)
- [ ] Set up `build_runner` for code generation
- [ ] Configure Git hooks (pre-commit: format + analyze)

#### 1.2 Core Layer

- [ ] `bootstrap.dart` — App initialization (Isar, Supabase, providers)
- [ ] `app.dart` — MaterialApp.router with theme
- [ ] Theme system — `app_theme.dart`, `app_colors.dart`, `app_typography.dart`
- [ ] Network layer — `dio_client.dart`, `network_info.dart`, interceptors
- [ ] Error handling — `failure.dart`, `app_exception.dart`
- [ ] Logger utility
- [ ] Currency formatter (NGN, GHS, XOF)
- [ ] Date/time formatters
- [ ] Validators (email, phone, money, required)
- [ ] Shared widgets — AppScaffold, LoadingOverlay, EmptyState, ErrorWidget

#### 1.3 Database Setup

- [ ] Isar database initialization
- [ ] Base collection schema with sync metadata
- [ ] Sync queue collection
- [ ] Database migration strategy

#### 1.4 Supabase Setup

- [ ] Create Supabase project
- [ ] Run SQL migrations (all tables)
- [ ] Configure RLS policies
- [ ] Set up Storage buckets
- [ ] Create Edge Functions stubs

**Milestone**: App builds and runs with theme, showing empty shell with navigation.

---

### Week 2: Authentication & Business Setup

#### 2.1 Auth Feature

- [x] `UserEntity` + `UserModel`
- [x] `AuthRepository` (interface + implementation)
- [x] `AuthRemoteDatasource` (Supabase Auth)
- [x] `AuthLocalDatasource` (Isar + SecureStorage)
- [x] Use cases: `SignUp`, `SignIn`, `SignOut`, `ForgotPassword`, `ResetPassword`
- [x] `AuthController` (Riverpod AsyncNotifier)
- [x] Login screen UI
- [x] Register screen UI
- [x] Forgot password screen UI
- [x] Auth state persistence (auto-login)
- [x] GoRouter auth guard

#### 2.2 Business Feature

- [x] `BusinessEntity` + `BusinessModel`
- [x] `BusinessRepository`
- [x] CRUD use cases
- [x] Business creation screen (onboarding flow)
- [x] Business settings screen

#### 2.3 Branch Feature

- [x] `BranchEntity` + `BranchModel`
- [x] `BranchRepository`
- [x] CRUD use cases
- [x] Branch creation during onboarding
- [x] Branch management screen (admin only)
- [x] Branch selector (for multi-branch users)

#### 2.4 Onboarding Flow

- [x] Welcome screen
- [x] Registration → Business creation → Branch setup → Done
- [x] Skip/defer steps where appropriate

**Milestone**: User can register, create a business with a branch, log in, and see the dashboard shell.

---

## Phase 2: Core Features (Weeks 3–5)

### Week 3: User Management & Inventory

#### 3.1 User/Role Management

- [x] `UserRoleEntity` + `UserRoleModel` + `StaffUserEntity`
- [x] `UserManagementRepository` (interface + implementation + datasource)
- [x] Admin creates/assigns staff accounts & roles
- [x] Role assignment & edit dialog
- [x] Custom permissions support
- [x] Staff list screen with role badges
- [x] GoRouter role-based guards for all routes

#### 3.2 Inventory — Products

- [x] `ProductEntity` + `ProductModel`
- [x] `ProductCategoryEntity` + `ProductCategoryModel`
- [x] `ProductRepository` (interface + implementation + datasource)
- [x] CRUD operations & stock tracking per branch
- [x] Product list screen (with search, category filter chips, low stock badges)
- [x] Product detail screen (with financial margins, branch stock level, and adjustment dialog)
- [x] Add/edit product form
- [x] Product category management dialog
- [x] Product image support

#### 3.3 Inventory — Variants

- [x] `ProductVariantEntity` + `ProductVariantModel`
- [x] Variant management in product form
- [x] Attribute system (size, color, custom)

**Milestone**: Admin can create staff with roles. Products with categories and variants can be created and viewed.

---

### Week 4: Stock & Sales

#### 4.1 Stock Management

- [x] `StockEntity` + `StockModel`
- [x] `StockMovementEntity` + `StockMovementModel`
- [x] `StockRepository` / `InventoryRepository` audit extensions
- [x] Stock per branch tracking
- [x] Stock adjustment modal (batch, expiry, reason, type)
- [x] Batch number tracking
- [x] Expiry date tracking
- [x] Stock movement history (`StockMovementsScreen`)
- [x] Low stock indicator (badges on product cards)

#### 4.2 Sales — POS

- [x] `SaleEntity` + `SaleModel`
- [x] `SaleItemEntity` + `SaleItemModel`
- [x] `SalesRepository` + `SalesRemoteDatasource`
- [x] POS screen with responsive catalog & cart (`PosScreen`)
- [x] Product search & category filters in POS
- [x] Quick-add by barcode camera scanner
- [x] Quantity adjustment (+/- stepper)
- [x] Discount (fixed & percentage calculations)
- [x] Tax calculation
- [x] Cart total calculation
- [x] Sale notes & customer memo

#### 4.3 Sales — Checkout

- [x] Payment method selection (Cash, MoMo: MTN / Telecel / AirtelTigo, Card/POS)
- [x] Change calculation (Cash denomination buttons & live change display)
- [x] Sale completion & stock deduction (atomic PostgreSQL procedure `process_sale` + fallback)
- [x] Digital receipt preview & sharing (`SaleReceiptScreen`)
- [x] Sales history log (`SalesHistoryScreen`)
- [x] Sale number auto-generation (`SAL-YYMMDD-XXXX`)

**Milestone**: Full POS workflow — search/scan product → add to cart → adjust quantities → apply discount → select payment → complete sale → stock decremented.

---

### Week 5: Customers, Suppliers & Payments

#### 5.1 Customers

- [x] `CustomerEntity` + `CustomerModel`
- [x] `CustomerRepository`
- [x] Customer list screen (search + filter)
- [x] Add/edit customer form (`CustomerFormDialog`)
- [x] Customer detail screen (purchase history, debt summary, repayment action)
- [x] Attach customer to sale during checkout (integrated with POS & Checkout dialog)

#### 5.2 Suppliers

- [x] `SupplierEntity` + `SupplierModel`
- [x] `SupplierRepository`
- [x] Supplier list screen (search + filter, payables summary)
- [x] Add/edit supplier form (`SupplierFormDialog`)
- [x] Supplier detail screen (supply history, balance settlement)

#### 5.3 Payment Methods

- [x] `PaymentEntity` + `PaymentModel`
- [x] `PaymentRepository`
- [x] Cash payment recording
- [x] Mobile money payment recording
- [x] Mobile money provider selection (MTN Mobile Money, Telecel Cash, AirtelTigo Money, M-Pesa)
- [x] Transaction reference capture
- [x] Payment history per sale

**Milestone**: Customers and suppliers can be managed. Sales can be linked to customers. Multiple payment methods work.

---

## Phase 3: Financial Features (Weeks 6–7)

### Week 6: Expenses & Debt/Credit

#### 6.1 Expenses

- [x] `ExpenseEntity` + `ExpenseModel`
- [x] `ExpenseCategoryEntity` + `ExpenseCategoryModel`
- [x] `ExpenseRepository`
- [x] Expense category management
- [x] Add expense form (amount, category, description, payment method, date)
- [x] Expense list screen (filterable by date, category, branch)
- [x] Expense receipt photo upload

#### 6.2 Debt/Credit Ledger

- [x] `DebtEntity` + `DebtModel`
- [x] `DebtPaymentEntity` + `DebtPaymentModel`
- [x] `DebtRepository`
- [x] Auto-create debt on partial/unpaid sale
- [x] Debt list screen (receivables + payables)
- [x] Debt detail screen (payment history, aging)
- [x] Record partial payment against debt
- [x] Debt aging buckets (current, 30d, 60d, 90d+)
- [x] Overdue notifications/badges

**Milestone**: Full expense tracking. Debt ledger with partial payments and aging.

---

### Week 7: Receipts & Barcodes

#### 7.1 Receipts — PDF

- [x] Receipt PDF template (business header, items, totals, QR code)
- [x] Generate PDF on sale completion
- [x] Receipt preview screen
- [x] Share receipt (WhatsApp, email, general share)
- [x] Save PDF to local storage
- [x] Upload PDF to Supabase Storage (when online)
- [x] Receipt history screen

#### 7.2 Receipts — Thermal

- [x] Bluetooth printer discovery
- [x] Printer pairing management
- [x] ESC/POS receipt formatting
- [x] Print receipt action button
- [x] Test print function

#### 7.3 Receipts — SMS

- [x] SMS receipt template (compact text format)
- [x] Africa's Talking / Twilio integration (via Edge Function)
- [x] Send SMS receipt action

#### 7.4 Barcode Scanning

- [x] Camera scanner screen (mobile_scanner)
- [x] Scan from POS search bar
- [x] Quick-scan mode (continuous scanning)
- [x] Scan result → product lookup → add to cart

#### 7.5 Barcode Generation

- [x] Generate EAN-13 / Code-128 / QR for products
- [x] Display barcode on product detail
- [x] Copy barcode value
- [x] Export barcode as image

#### 7.6 Label Printing

- [x] Label template (barcode + name + price)
- [x] Batch label generation (multiple products)
- [x] Print labels to label printer
- [x] Export label sheet as PDF

**Milestone**: Receipts can be generated (PDF + thermal + SMS) and shared. Products can be scanned and barcodes generated/printed.

---

## Phase 4: Intelligence (Weeks 8–9)

### Week 8: Reports & Analytics

#### 8.1 Dashboard

- [x] Today's sales summary card (amount, count, comparison)
- [x] Revenue trend chart (line chart, last 7/30 days)
- [x] Top selling products (horizontal bar chart)
- [x] Low stock alerts list
- [x] Recent transactions list
- [x] Quick action buttons (new sale, add product, add expense)

#### 8.2 Sales Reports

- [x] Daily / weekly / monthly sales summary
- [x] Sales by product
- [x] Sales by category
- [x] Sales by salesperson
- [x] Sales trend (line chart)
- [x] Date range selector
- [x] Branch filter (admin only)

#### 8.3 Financial Reports

- [x] Profit & Loss statement
- [x] Revenue vs Expenses chart
- [x] Expense breakdown by category (pie chart)
- [x] Cash flow summary

#### 8.4 Inventory Reports

- [x] Inventory valuation (cost + selling price)
- [x] Low stock report
- [x] Stock movement history
- [x] Expiring products report
- [x] Dead stock (no sales in 90+ days)

#### 8.5 Customer/Supplier Reports

- [x] Customer ledger (transactions + balance)
- [x] Supplier ledger (supplies + balance owed)
- [x] Top customers by revenue
- [x] Debt aging report

**Milestone**: Dashboard with real data. All report types functional with charts.

---

### Week 9: Alerts & Smart Features

#### 9.1 Alerts

- [ ] Low stock alerts (push notification + in-app)
- [ ] Overdue debt alerts
- [ ] Expiring product alerts
- [ ] Daily sales summary notification

#### 9.2 Smart Features

- [ ] Auto-reorder suggestions (products below reorder level)
- [ ] Branch performance comparison (Enterprise)
- [ ] Sales velocity (items/day)
- [ ] Most profitable products ranking
- [ ] Customer purchase patterns

#### 9.3 Data Export

- [ ] Export reports as CSV
- [ ] Export reports as PDF
- [ ] Share exported files

**Milestone**: Smart alerts working. Auto-reorder suggestions. Reports exportable.

---

## Phase 5: Polish & Sync (Weeks 10–11)

### Week 10: Sync & Offline

#### 10.1 Sync Engine

- [ ] Background sync worker (WorkManager)
- [ ] Sync queue processor
- [ ] Conflict resolution implementation
- [ ] Delta sync (changed records only)
- [ ] Batch sync operations
- [ ] Sync status indicator (UI)
- [ ] Manual sync trigger (pull-to-refresh)
- [ ] Sync progress reporting
- [ ] Error recovery & retry logic

#### 10.2 Offline Mode

- [ ] Offline detection banner
- [ ] All CRUD operations work offline
- [ ] Queue all operations for later sync
- [ ] Offline mode indicator on all screens
- [ ] Grace period for expired tokens
- [ ] Data integrity checks

#### 10.3 Cloud Backup

- [ ] Full backup export (Isar → JSON → Supabase Storage)
- [ ] Restore from backup
- [ ] Automatic daily backup (Pro+)
- [ ] Backup history and management

**Milestone**: App works fully offline. Sync is reliable. Cloud backup functional.

---

### Week 11: i18n & Settings

#### 11.1 Internationalization

- [ ] Complete `app_en.arb` with all strings
- [ ] i18n framework setup with `flutter_localizations`
- [ ] Language selector in settings
- [ ] Date/time locale formatting
- [ ] Currency locale formatting
- [ ] RTL support preparation (for Arabic future)

#### 11.2 Settings

- [ ] App settings screen (theme, language, notifications)
- [ ] Business settings (name, logo, tax rate, currencies)
- [ ] Branch settings
- [ ] Account settings (profile, password, logout)
- [ ] Printer settings (pair, test print, default printer)
- [ ] Sync settings (interval, WiFi-only toggle)
- [ ] About screen (version, licenses, support contact)

#### 11.3 UI Polish

- [ ] All micro-animations implemented
- [ ] Skeleton loading states
- [ ] Empty states with illustrations
- [ ] Error states with retry actions
- [ ] Haptic feedback on key actions
- [ ] Pull-to-refresh on all list screens
- [ ] Keyboard handling (dismiss, next field)
- [ ] Responsive layouts tested on multiple device sizes

**Milestone**: All strings externalized. Settings complete. UI polished and consistent.

---

## Phase 6: Production (Week 12)

### 12.1 Freemium Gating

- [ ] Implement `FeatureGate` service
- [ ] Add limit checks to all gated features
- [ ] Upgrade prompt UI
- [ ] Subscription purchase flow (Google Play / Paystack)
- [ ] Tier change handling (upgrade/downgrade)

### 12.2 Testing

- [ ] Unit tests: 90%+ coverage on domain & data layers
- [ ] Widget tests for critical UI components
- [ ] Integration tests for core user flows
- [ ] Manual testing on physical devices (Android + iOS)
- [ ] Performance profiling (memory, CPU, battery)

### 12.3 Security Audit

- [ ] Supabase RLS policies verified
- [ ] No API keys in source code
- [ ] Secure storage for tokens
- [ ] Input validation on all forms
- [ ] SSL pinning consideration

### 12.4 App Store Preparation

- [ ] App icon (all sizes)
- [ ] Splash screen
- [ ] App store screenshots (phone + tablet)
- [ ] App store description (English)
- [ ] Privacy policy
- [ ] Terms of service
- [ ] Google Play listing
- [ ] Apple App Store listing

### 12.5 CI/CD

- [ ] GitHub Actions for automated testing
- [ ] Automated build on PR
- [ ] Release build pipeline (signed APK/IPA)
- [ ] Codemagic / Fastlane for store deployment

### 12.6 Launch

- [ ] Beta testing group (10-20 real users)
- [ ] Feedback collection mechanism
- [ ] Bug tracking setup (Sentry / Crashlytics)
- [ ] Analytics setup (Firebase Analytics / Mixpanel)
- [ ] Support channel (WhatsApp group / email)
- [ ] v1.0.0 release

**Milestone**: Production-ready app deployed to Google Play Store and Apple App Store.

---

## Post-Launch Roadmap

### v1.1 — Quick Wins

- Multiple language support (French, Yoruba, Hausa)
- Dark mode
- Tablet-optimized layouts
- Purchase orders (buy from suppliers)

### v1.2 — Growth

- Multi-business support
- Stock transfer between branches
- Customer loyalty program
- Quotation/proforma invoices

### v1.3 — Intelligence

- AI-powered demand forecasting
- Automated reorder based on sales velocity
- Customer segmentation
- Revenue prediction

### v2.0 — Platform

- Web dashboard (Flutter Web or separate admin panel)
- API access for Enterprise tier
- Integrations (accounting software, e-commerce)
- Marketplace (product catalog sharing)
