import 'package:flutter_test/flutter_test.dart';
import 'package:afri_bms/features/sales/domain/entities/sale_entity.dart';
import 'package:afri_bms/features/sales/domain/entities/sale_item_entity.dart';

void main() {
  group('PaymentMethod', () {
    test('fromString parses payment methods correctly', () {
      expect(PaymentMethod.fromString('cash'), equals(PaymentMethod.cash));
      expect(PaymentMethod.fromString('mobile_money'), equals(PaymentMethod.mobileMoney));
      expect(PaymentMethod.fromString('momo'), equals(PaymentMethod.mobileMoney));
      expect(PaymentMethod.fromString('card'), equals(PaymentMethod.card));
      expect(PaymentMethod.fromString('split'), equals(PaymentMethod.split));
      expect(PaymentMethod.fromString('credit'), equals(PaymentMethod.credit));
      expect(PaymentMethod.fromString('unknown'), equals(PaymentMethod.cash));
    });

    test('value and label match expected formats', () {
      expect(PaymentMethod.mobileMoney.value, equals('mobile_money'));
      expect(PaymentMethod.mobileMoney.label, equals('Mobile Money'));
      expect(PaymentMethod.cash.label, equals('Cash'));
    });
  });

  group('PaymentStatus', () {
    test('fromString parses status values correctly', () {
      expect(PaymentStatus.fromString('paid'), equals(PaymentStatus.paid));
      expect(PaymentStatus.fromString('pending'), equals(PaymentStatus.pending));
      expect(PaymentStatus.fromString('partial'), equals(PaymentStatus.partial));
      expect(PaymentStatus.fromString('refunded'), equals(PaymentStatus.refunded));
      expect(PaymentStatus.fromString('invalid'), equals(PaymentStatus.paid));
    });
  });

  group('SaleEntity & SaleItemEntity', () {
    test('instantiates with accurate financial calculations and equality', () {
      final now = DateTime.now();
      final item1 = SaleItemEntity(
        id: 'item-1',
        saleId: 'sale-1',
        productId: 'prod-1',
        productName: 'Milo 400g',
        unitCostPrice: 3000,
        unitPrice: 4500,
        quantity: 2,
        discountAmount: 500,
        totalPrice: 8500, // (4500 * 2) - 500
        createdAt: now,
      );

      final sale = SaleEntity(
        id: 'sale-1',
        businessId: 'biz-1',
        branchId: 'branch-1',
        cashierId: 'cashier-1',
        saleNumber: 'REC-001',
        subtotal: 9000,
        discountAmount: 500,
        taxAmount: 0,
        totalAmount: 8500,
        amountTendered: 10000,
        changeGiven: 1500,
        paymentMethod: PaymentMethod.mobileMoney,
        items: [item1],
        createdAt: now,
      );

      expect(sale.totalAmount, equals(8500));
      expect(sale.amountTendered - sale.changeGiven, equals(sale.totalAmount));
      expect(sale.items.length, equals(1));
      expect(sale.items.first.totalPrice, equals(8500));
    });
  });
}
