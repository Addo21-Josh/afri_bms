import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:afri_bms/core/widgets/shared_widgets.dart';

void main() {
  testWidgets('EmptyStateWidget renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            title: 'No Items',
            subtitle: 'Start adding items to see them here',
          ),
        ),
      ),
    );

    expect(find.text('No Items'), findsOneWidget);
    expect(find.text('Start adding items to see them here'), findsOneWidget);
  });

  testWidgets('AppScaffold renders title and body', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppScaffold(title: 'Test Title', body: Text('Test Body')),
      ),
    );

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Body'), findsOneWidget);
  });
}
