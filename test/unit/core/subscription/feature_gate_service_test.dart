import 'package:flutter_test/flutter_test.dart';
import 'package:afri_bms/core/subscription/domain/models/subscription_tier.dart';
import 'package:afri_bms/core/subscription/domain/services/feature_gate_service.dart';

void main() {
  group('FeatureGateService - Free Tier', () {
    late FeatureGateService service;

    setUp(() {
      service = FeatureGateService(tier: SubscriptionTier.free);
    });

    test('enforces product limits (max 100 on free)', () {
      expect(service.checkProductLimit(50).isAllowed, isTrue);
      expect(service.checkProductLimit(99).isAllowed, isTrue);
      
      final blockedResult = service.checkProductLimit(100);
      expect(blockedResult.isAllowed, isFalse);
      expect(blockedResult.isBlocked, isTrue);
      expect(blockedResult.requiredTier, equals(SubscriptionTier.pro));
      expect(blockedResult.maxAllowed, equals(100));
    });

    test('enforces staff accounts limit (max 2 on free)', () {
      expect(service.checkStaffLimit(1).isAllowed, isTrue);
      expect(service.checkStaffLimit(2).isAllowed, isFalse);
    });

    test('enforces branch limit (max 1 on free)', () {
      expect(service.checkBranchLimit(0).isAllowed, isTrue);
      expect(service.checkBranchLimit(1).isAllowed, isFalse);
    });

    test('enforces business limit (max 1 on free)', () {
      expect(service.checkBusinessLimit(0).isAllowed, isTrue);
      expect(service.checkBusinessLimit(1).isAllowed, isFalse);
    });

    test('enforces customer and supplier limits', () {
      expect(service.checkCustomerLimit(49).isAllowed, isTrue);
      expect(service.checkCustomerLimit(50).isAllowed, isFalse);

      expect(service.checkSupplierLimit(19).isAllowed, isTrue);
      expect(service.checkSupplierLimit(20).isAllowed, isFalse);
    });

    test('blocks premium features on free tier', () {
      expect(service.canUseThermalPrinter().isAllowed, isFalse);
      expect(service.canUseCloudBackup().isAllowed, isFalse);
      expect(service.canAccessFullReports().isAllowed, isFalse);
      expect(service.canPrintLabels().isAllowed, isFalse);
      expect(service.canExportData().isAllowed, isFalse);
      expect(service.canUseCustomRoles().isAllowed, isFalse);
    });
  });

  group('FeatureGateService - Pro Tier', () {
    late FeatureGateService service;

    setUp(() {
      service = FeatureGateService(tier: SubscriptionTier.pro);
    });

    test('allows higher product catalog (up to 1000)', () {
      expect(service.checkProductLimit(500).isAllowed, isTrue);
      expect(service.checkProductLimit(999).isAllowed, isTrue);
      expect(service.checkProductLimit(1000).isAllowed, isFalse);
    });

    test('allows up to 10 staff accounts', () {
      expect(service.checkStaffLimit(5).isAllowed, isTrue);
      expect(service.checkStaffLimit(9).isAllowed, isTrue);
      expect(service.checkStaffLimit(10).isAllowed, isFalse);
    });

    test('allows up to 5 branches per business', () {
      expect(service.checkBranchLimit(3).isAllowed, isTrue);
      expect(service.checkBranchLimit(5).isAllowed, isFalse);
    });

    test('allows premium features (thermal print, cloud sync, export)', () {
      expect(service.canUseThermalPrinter().isAllowed, isTrue);
      expect(service.canUseCloudBackup().isAllowed, isTrue);
      expect(service.canAccessFullReports().isAllowed, isTrue);
      expect(service.canPrintLabels().isAllowed, isTrue);
      expect(service.canExportData().isAllowed, isTrue);
    });

    test('blocks enterprise-only custom roles on pro tier', () {
      expect(service.canUseCustomRoles().isAllowed, isFalse);
    });
  });

  group('FeatureGateService - Enterprise Tier', () {
    late FeatureGateService service;

    setUp(() {
      service = FeatureGateService(tier: SubscriptionTier.enterprise);
    });

    test('allows unlimited products, staff, branches, and businesses', () {
      expect(service.checkProductLimit(100000).isAllowed, isTrue);
      expect(service.checkStaffLimit(500).isAllowed, isTrue);
      expect(service.checkBranchLimit(100).isAllowed, isTrue);
      expect(service.checkBusinessLimit(50).isAllowed, isTrue);
      expect(service.checkCustomerLimit(100000).isAllowed, isTrue);
      expect(service.checkSupplierLimit(100000).isAllowed, isTrue);
    });

    test('allows all enterprise features including custom roles', () {
      expect(service.canUseThermalPrinter().isAllowed, isTrue);
      expect(service.canUseCloudBackup().isAllowed, isTrue);
      expect(service.canAccessFullReports().isAllowed, isTrue);
      expect(service.canUseCustomRoles().isAllowed, isTrue);
    });
  });
}
