import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:afri_bms/core/subscription/domain/models/subscription_tier.dart';
import 'package:afri_bms/core/subscription/presentation/widgets/upgrade_prompt_sheet.dart';

void main() {
  group('UpgradePromptSheet Widget Tests', () {
    testWidgets('renders title, perks, and GHS pricing for Pro upgrade', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpgradePromptSheet(
              featureName: 'Thermal Receipt Printing',
              currentTier: SubscriptionTier.free,
              suggestedTier: SubscriptionTier.pro,
            ),
          ),
        ),
      );

      // Verify header and feature mention
      expect(find.text('Upgrade to Pro'), findsOneWidget);
      expect(find.textContaining('Thermal Receipt Printing'), findsOneWidget);

      // Verify GHS price tag
      expect(find.textContaining('GH₵50'), findsOneWidget);
      expect(find.text('Cancel anytime'), findsOneWidget);

      // Verify Action button
      expect(find.text('View Plans & Upgrade'), findsOneWidget);
    });

    testWidgets('renders Enterprise perks and GHS pricing when suggested tier is Enterprise', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpgradePromptSheet(
              featureName: 'Unlimited Businesses',
              currentTier: SubscriptionTier.pro,
              suggestedTier: SubscriptionTier.enterprise,
            ),
          ),
        ),
      );

      expect(find.text('Upgrade to Enterprise'), findsOneWidget);
      expect(find.textContaining('GH₵150'), findsOneWidget);
      expect(find.textContaining('Unlimited Businesses'), findsOneWidget);
    });
  });
}
