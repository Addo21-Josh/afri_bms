# Privacy Policy for Afri_BMS

**Effective Date:** October 15, 2026  
**Last Updated:** October 15, 2026  
**Developer / Controller:** Afri_BMS Team (support@afribms.com)  
**Application Name:** Afri_BMS: POS & Inventory Management  

---

## 1. Introduction

Afri_BMS ("we", "our", or "us") provides an all-in-one Point of Sale (POS), Inventory Tracking, and Business Management platform designed for small and medium-sized enterprises across Africa and emerging markets. We are committed to protecting your privacy and ensuring you have complete control over your business data.

This Privacy Policy explains how information is collected, used, stored, and disclosed when you access our mobile applications, web portals, and associated cloud synchronization services.

---

## 2. Information We Collect

### A. Account & Authentication Information
- **Account Registration:** When you register, we collect your name, email address, and authentication credentials.
- **Business Profile:** Business name, physical address, business phone number, operating currency (default: GHS / NGN / KES / USD), and tax identification number (if entered).
- **Staff Profiles:** Names and role assignments (Owner, Manager, Cashier) of employees operating branch terminals.

### B. Commercial & Transactional Data
- **Inventory & Catalog:** Product descriptions, barcodes/SKUs, product categories, cost prices, selling prices, and reorder levels.
- **Sales & Checkout Records:** Sales transaction timestamps, line items, discounts, totals, and payment methods (Cash, Mobile Money, Card, Split, Store Credit).
- **Customer & Supplier Directories:** Customer names, phone numbers, delivery addresses, and credit balances. Supplier names, contact persons, and payables.
- **Debts & Expenses:** Incurred overhead expenses, debtor lists, and repayment history.

### C. Device & Hardware Permissions
- **Camera (`android.permission.CAMERA`):** Used exclusively for real-time barcode and QR code scanning at checkout and during stock audits. We do **not** capture, store, or transmit ambient photos or videos.
- **Storage & Keystore (`FlutterSecureStorage`):** Encrypted local credentials, access tokens, and offline Isar database records stored securely on the device.
- **Bluetooth & Printing (`android.permission.BLUETOOTH` / Network):** Used solely for pairing with thermal receipt printers and printing customer receipts.

### D. Payment & Subscription Processing
- All card and mobile money billing transactions for Afri_BMS subscription tiers (Pro and Enterprise) are processed directly by our PCI-DSS Level 1 compliant payment partner, **Paystack**.
- Afri_BMS **never** collects, processes, or stores your credit card numbers, CVVs, or mobile money PINs on our servers.

---

## 3. How We Use Your Information

We use the data collected strictly to operate, maintain, and enhance the Afri_BMS service:
1. **Business Operations:** Powering your checkout register, generating thermal/PDF receipts, tracking low stock alerts, and computing profit & loss reports.
2. **Offline-First Synchronization:** Encrypting and syncing your local sales and stock movements with your Supabase cloud business database when connectivity is restored.
3. **Account Security:** Enforcing multi-tenant Row Level Security (RLS) so that only verified staff members of your business can view your store data.
4. **Customer Support:** Resolving technical inquiries and operational assistance.

---

## 4. Data Sharing & Third-Party Processors

We do not sell, rent, or trade your personal or business data. We only disclose data to trusted service providers that strictly process data on our behalf under confidentiality agreements:
- **Cloud Infrastructure:** Supabase Inc. (PostgreSQL database, authentication, and secure edge functions).
- **Payment Processing:** Paystack Payments Limited (Subscription billing via Mobile Money and Bank Cards).
- **SMS & Receipts:** Africa's Talking / Twilio (Optional SMS receipt delivery to your customers).

---

## 5. Security & Encryption Standards

Afri_BMS implements enterprise-grade technical and organizational safeguards:
- **In-Transit Encryption:** All network communication is enforced over HTTPS/TLS with cleartext traffic disabled app-wide (`usesCleartextTraffic="false"`).
- **At-Rest Encryption:** Local session tokens are encrypted via platform hardware keystores (Android KeyStore and iOS Keychain).
- **Database Multi-Tenancy:** Row-level security policies ensure complete tenant isolation; no business can access another merchant's records.

---

## 6. Your Rights & Data Deletion

Under applicable data protection laws (including GDPR and regional African data privacy statutes), you have the right to:
- **Access & Export:** Export your inventory, customer directory, and sales history in CSV/PDF formats at any time from the app.
- **Rectification:** Update or correct business and product details through the app settings.
- **Account Deletion:** You may request complete erasure of your business account and all associated transactional data by contacting **support@afribms.com** or visiting **Settings > Business Settings > Request Account Deletion**. Upon verification, all records are permanently purged from active databases within 30 days.

---

## 7. Children's Privacy

Afri_BMS is a business productivity application and is not directed to individuals under the age of 18. We do not knowingly collect personal data from children.

---

## 8. Updates to this Policy

We may update this Privacy Policy periodically to reflect new features or regulatory requirements. We will notify you of material changes via an in-app notice or email notification prior to changes taking effect.

---

## 9. Contact Us

If you have questions, feedback, or data privacy requests, please reach out to:
- **Email:** support@afribms.com
- **Website:** https://afribms.com
- **Support WhatsApp:** +233 (0) 50 000 0000
