import 'package:flutter_test/flutter_test.dart';
import 'package:afri_bms/features/inventory/domain/entities/product_entity.dart';
import 'package:afri_bms/features/inventory/domain/entities/category_entity.dart';

void main() {
  group('ProductEntity', () {
    final now = DateTime(2026, 10, 15);
    final category = ProductCategoryEntity(
      id: 'cat-1',
      businessId: 'biz-1',
      name: 'Beverages',
      createdAt: now,
    );

    test('isLowStock returns true when current stock is <= reorderLevel', () {
      final product = ProductEntity(
        id: 'prod-1',
        businessId: 'biz-1',
        categoryId: 'cat-1',
        category: category,
        name: 'Malt Drink',
        costPrice: 500, // 5.00 GHS
        sellingPrice: 800, // 8.00 GHS
        reorderLevel: 10,
        currentBranchStock: 10,
        createdAt: now,
        updatedAt: now,
      );

      expect(product.isLowStock, isTrue);

      final outOfStockProduct = ProductEntity(
        id: 'prod-2',
        businessId: 'biz-1',
        name: 'Empty Drink',
        costPrice: 500,
        sellingPrice: 800,
        reorderLevel: 10,
        currentBranchStock: 0,
        createdAt: now,
        updatedAt: now,
      );

      expect(outOfStockProduct.isLowStock, isTrue);
    });

    test(
      'isLowStock returns false when current stock is strictly above reorderLevel',
      () {
        final product = ProductEntity(
          id: 'prod-1',
          businessId: 'biz-1',
          name: 'Juice Pack',
          costPrice: 1200,
          sellingPrice: 1800,
          reorderLevel: 10,
          currentBranchStock: 11,
          createdAt: now,
          updatedAt: now,
        );

        expect(product.isLowStock, isFalse);
      },
    );

    test('supports value equality through Equatable props', () {
      final productA = ProductEntity(
        id: 'prod-1',
        businessId: 'biz-1',
        name: 'Soap Bar',
        costPrice: 300,
        sellingPrice: 500,
        createdAt: now,
        updatedAt: now,
      );

      final productB = ProductEntity(
        id: 'prod-1',
        businessId: 'biz-1',
        name: 'Soap Bar',
        costPrice: 300,
        sellingPrice: 500,
        createdAt: now,
        updatedAt: now,
      );

      expect(productA, equals(productB));
    });
  });
}
