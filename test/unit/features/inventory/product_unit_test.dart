import 'package:flutter_test/flutter_test.dart';
import 'package:afri_bms/features/inventory/domain/constants/product_unit.dart';

void main() {
  group('ProductUnits', () {
    test('contains comprehensive units across all industries', () {
      expect(ProductUnits.all.length, greaterThanOrEqualTo(40));

      final pharmacyUnits = ProductUnits.all
          .where((u) => u.category == ProductUnitCategory.pharmacy)
          .toList();
      final clothingUnits = ProductUnits.all
          .where((u) => u.category == ProductUnitCategory.clothing)
          .toList();
      final generalUnits = ProductUnits.all
          .where((u) => u.category == ProductUnitCategory.general)
          .toList();
      final volumeUnits = ProductUnits.all
          .where((u) => u.category == ProductUnitCategory.volume)
          .toList();
      final weightUnits = ProductUnits.all
          .where((u) => u.category == ProductUnitCategory.weight)
          .toList();
      final foodUnits = ProductUnits.all
          .where((u) => u.category == ProductUnitCategory.food)
          .toList();

      expect(pharmacyUnits.isNotEmpty, isTrue);
      expect(clothingUnits.isNotEmpty, isTrue);
      expect(generalUnits.isNotEmpty, isTrue);
      expect(volumeUnits.isNotEmpty, isTrue);
      expect(weightUnits.isNotEmpty, isTrue);
      expect(foodUnits.isNotEmpty, isTrue);
    });

    test('supports essential pharmacy measurement units', () {
      const expectedCodes = [
        'tab',
        'cap',
        'strip',
        'bottle',
        'tube',
        'vial',
        'ampoule',
        'sachet',
        'dose',
        'inhaler',
        'supp',
      ];
      for (final code in expectedCodes) {
        final unit = ProductUnits.find(code);
        expect(unit, isNotNull, reason: 'Unit $code should exist in registry');
        expect(unit!.category, equals(ProductUnitCategory.pharmacy));
      }
    });

    test('supports essential clothing and textile measurement units', () {
      const expectedCodes = [
        'pair',
        'yard',
        'm',
        'set',
        'bale',
        'roll',
        'bundle',
        'doz',
      ];
      for (final code in expectedCodes) {
        final unit = ProductUnits.find(code);
        expect(
          unit,
          isNotNull,
          reason: 'Clothing unit $code should exist in registry',
        );
        expect(unit!.category, equals(ProductUnitCategory.clothing));
      }
    });

    test('find handles case-insensitivity, trimming, and name matches', () {
      expect(ProductUnits.find('TAB')?.code, equals('tab'));
      expect(ProductUnits.find('  yard  ')?.code, equals('yard'));
      expect(ProductUnits.find('Tablets')?.code, equals('tab'));
      expect(ProductUnits.find('Pairs')?.code, equals('pair'));
      expect(ProductUnits.find(null), isNull);
      expect(ProductUnits.find(''), isNull);
      expect(ProductUnits.find('custom_mystery_unit'), isNull);
    });

    test('format produces readable labels for registered and custom units', () {
      expect(ProductUnits.format('tab'), equals('Tablets (tab)'));
      expect(ProductUnits.format('yard'), equals('Yards (yard)'));
      expect(ProductUnits.format('pair'), equals('Pairs (pair)'));
      expect(ProductUnits.format('pcs'), equals('Pieces (pcs)'));
      // Custom unit fallback
      expect(ProductUnits.format('scoop'), equals('scoop'));
      // Empty/null fallback
      expect(ProductUnits.format(null), equals('Pieces (pcs)'));
      expect(ProductUnits.format('   '), equals('Pieces (pcs)'));
    });

    test(
      'formatShort produces clean compact symbols for receipts and stock badges',
      () {
        expect(ProductUnits.formatShort('tab'), equals('tab'));
        expect(ProductUnits.formatShort('yard'), equals('yard'));
        expect(ProductUnits.formatShort('pair'), equals('pair'));
        expect(ProductUnits.formatShort('scoop'), equals('scoop'));
        expect(ProductUnits.formatShort(null), equals('pcs'));
        expect(ProductUnits.formatShort(''), equals('pcs'));
      },
    );

    test('every unit has non-empty code, name, and description', () {
      for (final unit in ProductUnits.all) {
        expect(unit.code.trim().isNotEmpty, isTrue);
        expect(unit.name.trim().isNotEmpty, isTrue);
        expect(unit.description.trim().isNotEmpty, isTrue);
        expect(unit.displayName, contains(unit.code));
      }
    });
  });
}
