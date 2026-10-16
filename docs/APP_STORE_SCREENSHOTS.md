# App Store & Google Play Screenshot Specifications

This document outlines the visual storyboard, banner captions, and resolution standards for producing app store screenshots for **Afri_BMS** on both phone and tablet devices.

---

## 1. Resolution & Dimension Standards

| Device Class | Platform | Dimensions (px) | Aspect Ratio | Required Count |
| :--- | :--- | :--- | :--- | :--- |
| **Android Phone** | Google Play | 1080 x 2400 (or 1080 x 1920) | 20:9 or 16:9 | 6 to 8 |
| **Android 7" Tablet** | Google Play | 1200 x 1920 | 16:10 | 4 to 6 |
| **Android 10" Tablet** | Google Play | 1600 x 2560 (or 1920 x 1200) | 16:10 | 4 to 6 |
| **iPhone 6.7" / 6.5"** | Apple App Store | 1290 x 2796 (iPhone 15/16 Pro Max) | 19.5:9 | 5 to 7 |
| **iPad Pro 12.9"** | Apple App Store | 2048 x 2732 | 4:3 | 4 to 6 |

---

## 2. Phone Screenshot Storyboard (8 Screens)

Each screenshot uses a curated gradient header banner, bold headline, clear subtitle, and framed device mockup showing active app data.

### Screen 1: Rapid POS Checkout
- **Top Caption:** "LIGHTNING FAST POS CHECKOUT"
- **Subtitle:** "Process sales in seconds with Cash, Card & Mobile Money"
- **Featured UI:** [POSScreen](file:///c:/Users/DELL/StudioProjects/afri_bms/lib/features/sales/presentation/screens/pos_screen.dart) with shopping cart items, quantity controls, and checkout modal showing payment options.

### Screen 2: 100% Offline Resilience
- **Top Caption:** "WORKS 100% OFFLINE"
- **Subtitle:** "Never miss a sale — automatic cloud sync when reconnected"
- **Featured UI:** POS screen with the "Offline Mode Active" badge and [SyncCenterScreen](file:///c:/Users/DELL/StudioProjects/afri_bms/lib/core/sync/presentation/screens/sync_center_screen.dart).

### Screen 3: Barcode Scanning & Generation
- **Top Caption:** "SCAN & GENERATE BARCODES"
- **Subtitle:** "Use your phone camera or print custom barcode stickers"
- **Featured UI:** [BarcodeScannerScreen](file:///c:/Users/DELL/StudioProjects/afri_bms/lib/features/inventory/presentation/screens/barcode_scanner_screen.dart) viewfinder active, overlaying product card with EAN-13 barcode.

### Screen 4: Real-Time Inventory & Low-Stock Alerts
- **Top Caption:** "SMART INVENTORY TRACKING"
- **Subtitle:** "Instant reorder alerts before top sellers run out"
- **Featured UI:** [ProductListScreen](file:///c:/Users/DELL/StudioProjects/afri_bms/lib/features/inventory/presentation/screens/product_list_screen.dart) showing stock pills, low-stock warning chips, and category filtering.

### Screen 5: Thermal Printing & Digital Receipts
- **Top Caption:** "THERMAL RECEIPT PRINTING"
- **Subtitle:** "Pair Bluetooth printers or share PDF receipts via WhatsApp"
- **Featured UI:** [SaleReceiptScreen](file:///c:/Users/DELL/StudioProjects/afri_bms/lib/features/sales/presentation/screens/sale_receipt_screen.dart) showing receipt layout with barcode, store logo, and "Print to 58mm" button.

### Screen 6: Debt & Customer Credit Ledger
- **Top Caption:** "TRACK CUSTOMER DEBTS & CREDIT"
- **Subtitle:** "Eliminate lost money with partial payment histories"
- **Featured UI:** [DebtListScreen](file:///c:/Users/DELL/StudioProjects/afri_bms/lib/features/debts/presentation/screens/debt_list_screen.dart) and [CustomerDetailScreen](file:///c:/Users/DELL/StudioProjects/afri_bms/lib/features/customers/presentation/screens/customer_detail_screen.dart) showing balance cards.

### Screen 7: Multi-Branch & Staff Management
- **Top Caption:** "MULTI-BRANCH & CASHIER CONTROL"
- **Subtitle:** "Monitor all shop outlets & staff shifts in one place"
- **Featured UI:** [BranchManagementScreen](file:///c:/Users/DELL/StudioProjects/afri_bms/lib/features/business/presentation/screens/branch_management_screen.dart) and [StaffListScreen](file:///c:/Users/DELL/StudioProjects/afri_bms/lib/features/users/presentation/screens/staff_list_screen.dart).

### Screen 8: Profit & Loss Analytics
- **Top Caption:** "PROFIT & LOSS FINANCIAL HUB"
- **Subtitle:** "Clear gross profit, overhead expenses, and margins"
- **Featured UI:** [ReportsHubScreen](file:///c:/Users/DELL/StudioProjects/afri_bms/lib/features/reports/presentation/screens/reports_hub_screen.dart) featuring revenue charts, COGS, and export buttons.

---

## 3. Tablet Screenshot Storyboard (4 Screens)

Tablet layouts focus on the dual-pane adaptive register and reporting viewports:
1. **Wide POS Register & Live Cart:** Dual-pane view displaying catalog grid on the left and sticky register cart with tender buttons on the right.
2. **Comprehensive Business Dashboard:** High-level metrics, quick actions, and revenue trends across branches.
3. **Inventory Management & Stock Auditing:** Detailed tabular product management with inline stock adjustments and bulk SKU labels.
4. **Financial Reports & Expense Breakdown:** Full-width analytics charts with export to Excel/PDF.

---

## 4. Production Checklist for Graphics Upload
- [ ] Render screenshots on physical Google Pixel 8 (1080 x 2400) or high-res simulator.
- [ ] Export raw uncompressed PNG images.
- [ ] Apply brand framing (Dark Indigo `#1B3A5C` gradient headers, white device frames).
- [ ] Upload to Google Play Console under **Store presence > Main store listing > Phone screenshots**.
- [ ] Upload to App Store Connect under **iOS App > Version 1.0 > 6.7" Display & 6.5" Display**.
