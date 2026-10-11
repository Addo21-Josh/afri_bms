# SKILLS.md — Afri_BMS Development Skills & Knowledge

> Detailed technical knowledge required to build each feature module.

---

## 1. Flutter & Dart Core Skills

### 1.1 Dart Language

| Skill | Level | Usage |
|---|---|---|
| Null safety | Expert | All code is null-safe |
| Generics | Advanced | Repository patterns, UseCases |
| Extensions | Advanced | Context extensions, DateTime formatting |
| Sealed classes | Advanced | Failure types, state unions |
| Records & patterns | Advanced | Dart 3 pattern matching |
| Isolates / `compute()` | Advanced | Heavy DB operations, PDF generation |
| Streams | Advanced | Real-time data, sync events |
| `Future` composition | Advanced | Parallel sync operations |

### 1.2 Flutter Framework

| Skill | Level | Usage |
|---|---|---|
| Widget lifecycle | Expert | Proper initialization & disposal |
| CustomPainter | Intermediate | Custom charts, receipt layouts |
| Platform channels | Intermediate | Bluetooth printer communication |
| Slivers | Advanced | Complex scrollable layouts (POS, reports) |
| Animations (implicit + explicit) | Advanced | Micro-animations, transitions |
| Form validation | Advanced | All data entry screens |
| Navigation 2.0 (GoRouter) | Advanced | Deep linking, role-based guards |
| Responsive design | Advanced | Phone + tablet layouts |

---

## 2. State Management — Riverpod

### 2.1 Provider Types

| Provider | When to Use | Example |
|---|---|---|
| `Provider` | Simple computed/injected values | Repository instances |
| `FutureProvider` | One-time async data fetch | Initial data load |
| `StreamProvider` | Real-time data | Supabase realtime subscriptions |
| `NotifierProvider` | Sync state with logic | Form state, filters |
| `AsyncNotifierProvider` | Async state with logic | CRUD operations |

### 2.2 Code Generation Pattern

```dart
// Use @riverpod annotation for auto-generated providers
@riverpod
class ProductListController extends _$ProductListController {
  @override
  Future<List<Product>> build() async {
    final repo = ref.watch(productRepositoryProvider);
    return repo.getAllProducts();
  }

  Future<void> deleteProduct(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(productRepositoryProvider).deleteProduct(id);
      return ref.read(productRepositoryProvider).getAllProducts();
    });
  }
}
```

### 2.3 Provider Scoping

```dart
// Scope providers per branch/business context
@riverpod
class BusinessScope extends _$BusinessScope {
  @override
  Business build() => throw UnimplementedError('Must be overridden');
}

// In the widget tree
ProviderScope(
  overrides: [
    businessScopeProvider.overrideWith(() => selectedBusiness),
  ],
  child: const BusinessDashboard(),
)
```

---

## 3. Local Database — Isar

### 3.1 Collection Definition

```dart
@Collection()
class ProductCollection {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;  // UUID from Supabase

  @Index()
  late String businessId;

  @Index()
  late String? branchId;

  late String name;

  @Index(type: IndexType.value, caseSensitive: false)
  late String searchableName;  // lowercase for search

  late String? description;
  late String? sku;

  @Index()
  late String? barcode;

  late int costPrice;       // minor units
  late int sellingPrice;    // minor units
  late String currency;
  late int reorderLevel;
  late bool isActive;

  // Sync metadata
  @Index()
  late bool isSynced;
  late DateTime localUpdatedAt;
  late DateTime? serverUpdatedAt;
  late DateTime? deletedAt;

  // Links
  final category = IsarLink<ProductCategoryCollection>();
  final variants = IsarLinks<ProductVariantCollection>();
  final stockEntries = IsarLinks<StockCollection>();
}
```

### 3.2 Query Patterns

```dart
// Full-text search with index
final products = await isar.productCollections
    .filter()
    .businessIdEqualTo(businessId)
    .searchableNameContains(query.toLowerCase())
    .isActiveEqualTo(true)
    .deletedAtIsNull()
    .sortByName()
    .findAll();

// Unsynced items for sync queue
final unsynced = await isar.productCollections
    .filter()
    .isSyncedEqualTo(false)
    .sortByLocalUpdatedAt()
    .findAll();
```

### 3.3 Transaction Patterns

```dart
// Atomic write for sale + stock update
await isar.writeTxn(() async {
  // 1. Insert sale
  await isar.saleCollections.put(saleCollection);

  // 2. Insert sale items
  for (final item in saleItems) {
    await isar.saleItemCollections.put(item);
  }

  // 3. Decrement stock
  for (final item in saleItems) {
    final stock = await isar.stockCollections
        .filter()
        .productIdEqualTo(item.productId)
        .branchIdEqualTo(branchId)
        .findFirst();

    if (stock != null) {
      stock.quantity -= item.quantity;
      stock.isSynced = false;
      stock.localUpdatedAt = DateTime.now();
      await isar.stockCollections.put(stock);
    }
  }

  // 4. Queue for sync
  await isar.syncQueueItems.put(syncItem);
});
```

---

## 4. Backend — Supabase

### 4.1 Authentication

```dart
// Sign up (creates admin)
final response = await supabase.auth.signUp(
  email: email,
  password: password,
  data: {'full_name': name},
);

// Create staff account (admin action)
// Uses Supabase Edge Function to create user + assign role
final response = await supabase.functions.invoke(
  'create-staff-account',
  body: {
    'email': staffEmail,
    'role': 'salesperson',
    'business_id': businessId,
    'branch_id': branchId,
  },
);

// Sign in
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);
```

### 4.2 Database Operations

```dart
// Insert
await supabase.from('products').insert(productModel.toJson());

// Update
await supabase.from('products')
    .update(productModel.toJson())
    .eq('id', productModel.id);

// Soft delete
await supabase.from('products')
    .update({'deleted_at': DateTime.now().toIso8601String()})
    .eq('id', productId);

// Query with pagination
final response = await supabase.from('products')
    .select('*, product_categories(*), product_variants(*)')
    .eq('business_id', businessId)
    .is_('deleted_at', null)
    .order('created_at', ascending: false)
    .range(offset, offset + limit - 1);
```

### 4.3 Real-time Subscriptions

```dart
// Listen for remote changes
supabase
    .from('products')
    .stream(primaryKey: ['id'])
    .eq('business_id', businessId)
    .listen((List<Map<String, dynamic>> data) {
      // Update local Isar database
      _syncRemoteChanges(data);
    });
```

### 4.4 Edge Functions

| Function | Purpose | Trigger |
|---|---|---|
| `create-staff-account` | Create user + assign role | Admin action |
| `send-receipt-sms` | Send SMS receipt via Africa's Talking | Sale completion |
| `generate-reports` | Heavy report computation | Scheduled / on-demand |
| `check-low-stock` | Alert admin of low stock items | Cron (daily) |
| `sync-batch` | Process batch sync operations | Client push |

### 4.5 Storage

```dart
// Upload product image
final fileName = '${businessId}/products/${productId}_${timestamp}.jpg';
await supabase.storage
    .from('product-images')
    .upload(fileName, imageFile);

// Upload receipt PDF
final fileName = '${businessId}/receipts/${receiptId}.pdf';
await supabase.storage
    .from('receipts')
    .upload(fileName, pdfBytes);
```

---

## 5. Barcode Skills

### 5.1 Scanning (mobile_scanner)

```dart
MobileScanner(
  onDetect: (capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      // Look up product by barcode value
      _onBarcodeScanned(barcode.rawValue);
    }
  },
)
```

### 5.2 Generation (barcode_widget)

```dart
// Generate barcode for display
BarcodeWidget(
  barcode: Barcode.ean13(),
  data: product.barcode,
  width: 200,
  height: 80,
)

// Generate QR code
BarcodeWidget(
  barcode: Barcode.qrCode(),
  data: jsonEncode({
    'id': product.id,
    'name': product.name,
    'price': product.sellingPrice,
  }),
  width: 150,
  height: 150,
)
```

### 5.3 Label Printing

```dart
// Generate printable label image
Future<Uint8List> generateLabel(Product product) async {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);

  // Draw product name
  // Draw barcode
  // Draw price

  final picture = recorder.endRecording();
  final image = await picture.toImage(400, 200);
  final byteData = await image.toByteData(format: ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
```

---

## 6. Receipt & Printing Skills

### 6.1 PDF Generation (pdf package)

```dart
Future<Uint8List> generateReceiptPdf(Sale sale, Business business) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
      build: (context) {
        return pw.Column(
          children: [
            // Business header
            pw.Text(business.name, style: pw.TextStyle(fontSize: 18)),
            pw.Text(business.address),
            pw.Divider(),
            // Sale details
            pw.Text('Receipt #${sale.saleNumber}'),
            pw.Text('Date: ${DateFormat.yMd().format(sale.createdAt)}'),
            pw.Divider(),
            // Items table
            _buildItemsTable(sale.items),
            pw.Divider(),
            // Totals
            _buildTotals(sale),
            // Barcode
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: sale.id,
              width: 100,
              height: 100,
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
```

### 6.2 Thermal Printing (ESC/POS)

```dart
Future<void> printReceipt(Sale sale) async {
  final printer = await _discoverPrinter();
  final profile = await CapabilityProfile.load();
  final generator = Generator(PaperSize.mm80, profile);

  List<int> bytes = [];
  bytes += generator.text(business.name,
      styles: PosStyles(align: PosAlign.center, bold: true));
  bytes += generator.text(business.address,
      styles: PosStyles(align: PosAlign.center));
  bytes += generator.hr();

  // Items
  for (final item in sale.items) {
    bytes += generator.row([
      PosColumn(text: item.productName, width: 6),
      PosColumn(text: '${item.quantity}', width: 2),
      PosColumn(text: formatCurrency(item.total), width: 4),
    ]);
  }

  bytes += generator.hr();
  bytes += generator.text('TOTAL: ${formatCurrency(sale.totalAmount)}',
      styles: PosStyles(bold: true, height: PosTextSize.size2));
  bytes += generator.qrcode(sale.id);
  bytes += generator.cut();

  await printer.printBytes(bytes);
}
```

### 6.3 Share via WhatsApp

```dart
Future<void> shareReceipt(Uint8List pdfBytes, String receiptNumber) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/receipt_$receiptNumber.pdf');
  await file.writeAsBytes(pdfBytes);

  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'Your receipt #$receiptNumber from ${business.name}',
  );
}
```

---

## 7. Sync Engine Skills

### 7.1 Background Sync with WorkManager

```dart
// Register periodic sync
Workmanager().registerPeriodicTask(
  'sync-task',
  'backgroundSync',
  frequency: const Duration(minutes: 15),
  constraints: Constraints(
    networkType: NetworkType.connected,
  ),
);

// Callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final syncEngine = SyncEngine();
    await syncEngine.syncAll();
    return true;
  });
}
```

### 7.2 Connectivity Monitoring

```dart
@riverpod
Stream<ConnectivityResult> connectivity(Ref ref) {
  return Connectivity().onConnectivityChanged;
}

// React to connectivity changes
ref.listen(connectivityProvider, (previous, next) {
  next.whenData((result) {
    if (result != ConnectivityResult.none) {
      ref.read(syncEngineProvider).syncAll();
    }
  });
});
```

### 7.3 Delta Sync

```dart
Future<void> pullRemoteChanges(String tableName) async {
  // Get last sync timestamp
  final lastSync = await _getLastSyncTimestamp(tableName);

  // Fetch only records updated after last sync
  final records = await supabase
      .from(tableName)
      .select()
      .eq('business_id', businessId)
      .gt('updated_at', lastSync.toIso8601String())
      .order('updated_at');

  // Upsert into Isar
  await _upsertLocal(tableName, records);

  // Update last sync timestamp
  await _setLastSyncTimestamp(tableName, DateTime.now());
}
```

---

## 8. Report & Analytics Skills

### 8.1 Charts (fl_chart)

```dart
// Sales trend line chart
LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: salesData.map((d) =>
          FlSpot(d.date.millisecondsSinceEpoch.toDouble(), d.amount.toDouble())
        ).toList(),
        gradient: LinearGradient(colors: [primary, primaryLight]),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [primary.withOpacity(0.3), primary.withOpacity(0.0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    ],
  ),
)
```

### 8.2 Report Computation (Isolate)

```dart
// Heavy computation in isolate
Future<ProfitLossReport> generateProfitLoss(DateRange range) async {
  return compute(_computeProfitLoss, {
    'sales': await _fetchSalesForRange(range),
    'expenses': await _fetchExpensesForRange(range),
    'costOfGoods': await _fetchCostOfGoods(range),
  });
}

static ProfitLossReport _computeProfitLoss(Map<String, dynamic> data) {
  // Heavy number crunching runs in background isolate
  final totalRevenue = data['sales'].fold(0, (sum, s) => sum + s.totalAmount);
  final totalExpenses = data['expenses'].fold(0, (sum, e) => sum + e.amount);
  final totalCost = data['costOfGoods'];
  final grossProfit = totalRevenue - totalCost;
  final netProfit = grossProfit - totalExpenses;
  // ... build report
}
```

---

## 9. Payment Integration Skills

### 9.1 Paystack SDK

```dart
// Initialize payment
final plugin = PaystackPlugin();
await plugin.initialize(publicKey: PaystackConfig.publicKey);

Charge charge = Charge()
  ..amount = (amount * 100).toInt() // In minor units
  ..reference = 'AFRI-${DateTime.now().millisecondsSinceEpoch}'
  ..email = customer.email ?? 'noreply@afribms.com'
  ..putCustomField('name', customer.name);

CheckoutResponse response = await plugin.checkout(
  context,
  method: CheckoutMethod.selectable,
  charge: charge,
);

if (response.status == true) {
  // Record payment locally
}
```

### 9.2 Manual Recording (Offline-Safe)

```dart
// For offline or manual payment tracking
Future<Either<Failure, Payment>> recordManualPayment({
  required String saleId,
  required PaymentMethod method,  // cash, mobile_money
  required int amount,
  required String? mobileMoneyProvider,
  required String? transactionReference,
}) async {
  final payment = PaymentModel(
    id: uuid.v4(),
    saleId: saleId,
    paymentMethod: method.name,
    mobileMoneyProvider: mobileMoneyProvider,
    transactionReference: transactionReference,
    amount: amount,
    isSynced: false,
  );

  await _localDatasource.insertPayment(payment);
  await _syncQueue.enqueue('payments', payment.id, payment.toJson());

  return Right(payment.toEntity());
}
```

---

## 10. i18n Skills

### 10.1 ARB File Structure

```json
// app_en.arb
{
  "@@locale": "en",
  "appTitle": "Afri_BMS",
  "loginTitle": "Welcome Back",
  "loginSubtitle": "Sign in to manage your business",
  "emailLabel": "Email Address",
  "passwordLabel": "Password",
  "signInButton": "Sign In",
  "salesTotal": "Total: {currency}{amount}",
  "@salesTotal": {
    "placeholders": {
      "currency": { "type": "String", "example": "₦" },
      "amount": { "type": "String", "example": "1,250,000" }
    }
  },
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "placeholders": {
      "count": { "type": "int" }
    }
  },
  "stockStatus": "{status, select, inStock{In Stock} low{Low Stock} out{Out of Stock} other{Unknown}}",
  "@stockStatus": {
    "placeholders": {
      "status": { "type": "String" }
    }
  }
}
```

### 10.2 Usage in Code

```dart
// Access via extension
Text(context.l10n.loginTitle)
Text(context.l10n.salesTotal('₦', '1,250,000'))
Text(context.l10n.itemCount(products.length))
Text(context.l10n.stockStatus(product.stockStatus.name))
```

---

## 11. Testing Skills

### 11.1 Unit Test Pattern

```dart
void main() {
  late MockProductRepository mockRepo;
  late CreateProduct useCase;

  setUp(() {
    mockRepo = MockProductRepository();
    useCase = CreateProduct(mockRepo);
  });

  group('CreateProduct', () {
    test('should create product successfully', () async {
      // Arrange
      when(() => mockRepo.createProduct(any()))
          .thenAnswer((_) async => Right(tProduct));

      // Act
      final result = await useCase(tCreateProductParams);

      // Assert
      expect(result, Right(tProduct));
      verify(() => mockRepo.createProduct(any())).called(1);
    });

    test('should return failure when repository fails', () async {
      when(() => mockRepo.createProduct(any()))
          .thenAnswer((_) async => Left(ServerFailure('error')));

      final result = await useCase(tCreateProductParams);

      expect(result, Left(ServerFailure('error')));
    });
  });
}
```

### 11.2 Widget Test Pattern

```dart
void main() {
  testWidgets('ProductCard displays product info', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [],
        child: MaterialApp(
          home: ProductCard(product: tProduct),
        ),
      ),
    );

    expect(find.text('Test Product'), findsOneWidget);
    expect(find.text('₦2,500.00'), findsOneWidget);
    expect(find.text('In Stock'), findsOneWidget);
  });
}
```

### 11.3 Integration Test Pattern

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete sale flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Navigate to POS
    await tester.tap(find.byIcon(Icons.point_of_sale));
    await tester.pumpAndSettle();

    // Search product
    await tester.enterText(find.byType(TextField), 'Widget');
    await tester.pumpAndSettle();

    // Add to cart
    await tester.tap(find.text('Widget A'));
    await tester.pumpAndSettle();

    // Complete sale
    await tester.tap(find.text('Complete Sale'));
    await tester.pumpAndSettle();

    // Select payment method
    await tester.tap(find.text('Cash'));
    await tester.pumpAndSettle();

    // Verify receipt generated
    expect(find.text('Sale Completed'), findsOneWidget);
  });
}
```

---

## 12. DevOps & CI/CD Skills

### 12.1 GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: dart analyze
      - run: dart format --set-exit-if-changed .

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3

  build-android:
    needs: [analyze, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release

  build-ios:
    needs: [analyze, test]
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build ios --release --no-codesign
```

---

## 13. Security Skills

### 13.1 Secure Storage

```dart
// Store sensitive data
final secureStorage = FlutterSecureStorage();

// Save token
await secureStorage.write(key: 'access_token', value: token);

// Read token
final token = await secureStorage.read(key: 'access_token');

// Delete on logout
await secureStorage.deleteAll();
```

### 13.2 API Key Protection

```dart
// Use --dart-define for build-time injection
// flutter build apk --dart-define=SUPABASE_URL=https://xxx.supabase.co
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');
```

---

## 14. Performance Skills

### 14.1 Image Optimization

```dart
// Compress before upload
Future<File> compressImage(File file) async {
  final result = await FlutterImageCompress.compressAndGetFile(
    file.path,
    '${file.path}_compressed.jpg',
    quality: 75,
    minWidth: 800,
    minHeight: 800,
  );
  return result!;
}
```

### 14.2 List Performance

```dart
// Use ListView.builder for large lists
ListView.builder(
  itemCount: products.length,
  itemBuilder: (context, index) {
    return ProductCard(product: products[index]);
  },
)

// Use Isar pagination
final page = await isar.products
    .where()
    .offset(pageIndex * pageSize)
    .limit(pageSize)
    .findAll();
```
