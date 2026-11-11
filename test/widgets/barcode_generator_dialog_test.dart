import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afri_bms/features/inventory/domain/entities/product_entity.dart';
import 'package:afri_bms/features/business/domain/entities/business_entity.dart';
import 'package:afri_bms/features/business/presentation/providers/business_provider.dart';
import 'package:afri_bms/features/inventory/presentation/widgets/barcode_generator_dialog.dart';

class FakeCurrentBusiness extends CurrentBusiness {
  @override
  BusinessEntity? build() => const BusinessEntity(
    id: 'biz-1',
    name: 'Afri_BMS Store',
    ownerId: 'owner-1',
    defaultCurrency: 'GHS',
  );
}

void main() {
  final testProduct = ProductEntity(
    id: 'prod-test-uuid-12345678',
    businessId: 'biz-1',
    name: 'Homemade Shea Butter 250g Container Extra',
    costPrice: 2000,
    sellingPrice: 4500,
    sku: 'SHEA-250-EXTRA-LONG-SKU-99',
    barcode: 'SHEA-250-EXTRA-LONG-SKU-99',
    reorderLevel: 10,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets(
    'BarcodeGeneratorDialog renders without overflow on phone viewport',
    (tester) async {
      // Set standard phone viewport (narrow 360x780 to test tightest constraints)
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentBusinessProvider.overrideWith(FakeCurrentBusiness.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BarcodeGeneratorDialog(
                product: testProduct,
                currency: 'GHS',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Title and Product info
      expect(find.text('Barcode & Price Label'), findsOneWidget);
      expect(
        find.text('Homemade Shea Butter 250g Container Extra'),
        findsOneWidget,
      );
      expect(find.text('GHS 45.00'), findsOneWidget);

      // Verify Barcode Type Chips
      expect(find.text('Code-128'), findsOneWidget);
      expect(find.text('QR Code'), findsOneWidget);

      // Verify Sheet Quantity Dropdown
      expect(find.text('Quantity:'), findsOneWidget);
      expect(find.text('24 Labels (A4)'), findsOneWidget);

      // Switch to QR Code
      await tester.tap(find.text('QR Code'));
      await tester.pumpAndSettle();

      // Verify buttons
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Print Labels'), findsOneWidget);

      // No overflows encountered
      expect(tester.takeException(), isNull);
    },
  );
}
