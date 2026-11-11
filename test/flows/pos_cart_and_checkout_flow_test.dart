import 'package:flutter_test/flutter_test.dart';
import 'package:afri_bms/core/subscription/domain/models/subscription_tier.dart';
import 'package:afri_bms/core/subscription/domain/services/feature_gate_service.dart';
import 'package:afri_bms/features/sales/domain/entities/sale_entity.dart';
import 'package:afri_bms/features/sales/domain/entities/sale_item_entity.dart';

void main() {
  group('POS Checkout & Freemium Quota Integration Flow', () {
    test('complete sale cycle with cart calculation and free plan limits', () {
      final now = DateTime.now();

      // 1. Initial State: Free Tier Store
      var tier = SubscriptionTier.free;
      var gateService = FeatureGateService(tier: tier);

      // 2. Check initial sales quota (0 sales made out of 200 allowed on Free)
      var quotaCheck = gateService.checkMonthlySalesLimit(0);
      expect(quotaCheck.isAllowed, isTrue);

      // 3. Assemble POS Cart items
      final item1 = SaleItemEntity(
        id: 'cart-item-1',
        saleId: 'sale-101',
        productId: 'p-01',
        productName: 'Peak Evaporated Milk 170g',
        unitCostPrice: 500, // GH₵5.00
        unitPrice: 750, // GH₵7.50
        quantity: 4, // Subtotal = GH₵30.00 (3000 pesewas)
        discountAmount: 0,
        totalPrice: 3000,
        createdAt: now,
      );

      final item2 = SaleItemEntity(
        id: 'cart-item-2',
        saleId: 'sale-101',
        productId: 'p-02',
        productName: 'Golden Tree Chocolate 100g',
        unitCostPrice: 1200, // GH₵12.00
        unitPrice: 1800, // GH₵18.00
        quantity: 2, // Subtotal = GH₵36.00 (3600 pesewas)
        discountAmount: 200, // GH₵2.00 discount
        totalPrice: 3400,
        createdAt: now,
      );

      final items = [item1, item2];
      final calculatedSubtotal = items.fold<int>(
        0,
        (sum, it) => sum + (it.unitPrice * it.quantity),
      );
      final calculatedDiscount = items.fold<int>(
        0,
        (sum, it) => sum + it.discountAmount,
      );
      final calculatedTotal = calculatedSubtotal - calculatedDiscount;

      expect(calculatedSubtotal, equals(6600)); // GH₵66.00
      expect(calculatedDiscount, equals(200)); // GH₵2.00
      expect(calculatedTotal, equals(6400)); // GH₵64.00

      // 4. Complete Transaction via Mobile Money
      final sale = SaleEntity(
        id: 'sale-101',
        businessId: 'biz-accra',
        branchId: 'branch-osu',
        cashierId: 'cashier-01',
        cashierName: 'Ama Serwaa',
        saleNumber: 'POS-2026-0001',
        subtotal: calculatedSubtotal,
        discountAmount: calculatedDiscount,
        totalAmount: calculatedTotal,
        paymentMethod: PaymentMethod.mobileMoney,
        paymentStatus: PaymentStatus.paid,
        amountTendered: 6400,
        paymentReference: 'MOMO-REF-99212',
        items: items,
        createdAt: now,
      );

      expect(sale.paymentMethod, equals(PaymentMethod.mobileMoney));
      expect(sale.paymentStatus, equals(PaymentStatus.paid));
      expect(sale.totalAmount, equals(6400));

      // 5. Test hitting Free plan limit of 200 monthly sales
      quotaCheck = gateService.checkMonthlySalesLimit(200);
      expect(quotaCheck.isAllowed, isFalse);
      expect(quotaCheck.requiredTier, equals(SubscriptionTier.pro));

      // 6. Upgrade to Pro Tier (GH₵50 / month)
      tier = SubscriptionTier.pro;
      gateService = FeatureGateService(tier: tier);

      // 7. Verify quota check now allows up to 5,000 monthly sales on Pro
      quotaCheck = gateService.checkMonthlySalesLimit(200);
      expect(quotaCheck.isAllowed, isTrue);

      // Thermal Bluetooth printing unlocked on Pro
      expect(gateService.canUseThermalPrinter().isAllowed, isTrue);

      // Automated cloud sync unlocked on Pro
      expect(gateService.canUseCloudBackup().isAllowed, isTrue);
    });
  });
}
