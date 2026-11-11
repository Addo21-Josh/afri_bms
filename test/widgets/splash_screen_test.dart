import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afri_bms/features/auth/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders app brand title and slogan', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SplashScreen(autoNavigate: false)),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify brand typography
    expect(find.text('Afri_BMS'), findsOneWidget);
    expect(find.text('Smarter Business, Bigger Profits'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump animation halfway
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Afri_BMS'), findsOneWidget);
  });
}
