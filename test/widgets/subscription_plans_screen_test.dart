import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afri_bms/core/subscription/presentation/screens/subscription_plans_screen.dart';
import 'package:afri_bms/core/subscription/domain/models/subscription_tier.dart';
import 'package:afri_bms/core/subscription/presentation/providers/subscription_provider.dart';
import 'package:afri_bms/features/business/presentation/providers/business_provider.dart';
import 'package:afri_bms/features/business/domain/entities/business_entity.dart';

class FakeCurrentBusiness extends CurrentBusiness {
  @override
  BusinessEntity? build() => null;
}

void main() {
  Widget buildTestWidget({
    SubscriptionTier currentTier = SubscriptionTier.free,
  }) {
    return ProviderScope(
      overrides: [
        currentBusinessProvider.overrideWith(FakeCurrentBusiness.new),
        currentSubscriptionTierProvider.overrideWithValue(currentTier),
      ],
      child: const MaterialApp(home: SubscriptionPlansScreen()),
    );
  }

  group('SubscriptionPlansScreen Widget Tests', () {
    testWidgets('renders plan title, billing cycle toggle and tier cards', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Plans & Pricing'), findsOneWidget);

      // Check billing cycle options
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.textContaining('Yearly'), findsOneWidget);
      expect(find.text('Save 17%'), findsOneWidget);

      // Check tier names
      expect(find.text('Free Starter'), findsOneWidget);
      expect(find.text('Free'), findsWidgets);

      // Scroll to reveal Pro and Enterprise
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      expect(find.text('Afri_BMS Pro'), findsOneWidget);
      expect(find.textContaining('50'), findsWidgets);
    });

    testWidgets('toggling yearly switches pricing and shows yearly badge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on Yearly toggle
      final yearlyTab = find.textContaining('Yearly');
      expect(yearlyTab, findsOneWidget);
      await tester.tap(yearlyTab);
      await tester.pumpAndSettle();

      // Verify that prices are updated
      expect(find.textContaining('/year'), findsWidgets);
    });
  });
}
