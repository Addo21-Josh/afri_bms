import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:afri_bms/features/inventory/presentation/widgets/unit_picker_sheet.dart';

void main() {
  group('ProductUnitPickerSheet Widget Tests', () {
    testWidgets('renders header, categories, and units list', (WidgetTester tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductUnitPickerSheet(
              currentUnit: 'pcs',
              onSelected: (val) => selected = val,
            ),
          ),
        ),
      );

      expect(find.text('Select Measurement Unit'), findsOneWidget);
      expect(find.text('Pharmacy & Health'), findsOneWidget);
      expect(find.text('Clothing & Fashion'), findsOneWidget);
      expect(find.text('Tablets'), findsOneWidget);

      // Tap on Tablets
      await tester.tap(find.text('Tablets'));
      await tester.pump();

      expect(selected, equals('tab'));
    });

    testWidgets('filters units list when searching', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductUnitPickerSheet(
              currentUnit: 'pcs',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // Enter search term 'yard'
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'yard');
      await tester.pump();

      expect(find.text('Yards'), findsOneWidget);
      expect(find.text('Tablets'), findsNothing);
    });

    testWidgets('filters units by category chip selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductUnitPickerSheet(
              currentUnit: 'pcs',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // Tap 'Clothing & Fashion' category chip
      await tester.tap(find.text('Clothing & Fashion'));
      await tester.pump();

      // Clothing units should appear, pharmacy units should not
      expect(find.text('Pairs'), findsOneWidget);
      expect(find.text('Yards'), findsOneWidget);
      expect(find.text('Tablets'), findsNothing);
    });
  });
}
