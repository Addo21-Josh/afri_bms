import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:afri_bms/core/widgets/shared_widgets.dart';

void main() {
  group('ErrorStateWidget Sanitization & Rendering', () {
    test(
      'cleanMessage converts SocketException raw string into clear user message',
      () {
        const rawError =
            "AppException: ClientException with SocketException: Failed host lookup: 'cmuwfwzvwvjulydhnalq.supabase.co' (OS Error: No address associated with hostname, errno = 7), uri=https://cmuwfwzvwvjulydhnalq.supabase.co/rest/v1/products?select=id%2Cname";

        final cleaned = ErrorStateWidget.cleanMessage(rawError);
        expect(
          cleaned,
          equals(
            'Unable to reach the server. Please check your internet connection.',
          ),
        );
      },
    );

    test(
      'cleanMessage strips technical prefixes like AppException: and Exception:',
      () {
        expect(
          ErrorStateWidget.cleanMessage(
            'AppException: Product not found in database',
          ),
          equals('Product not found in database'),
        );
        expect(
          ErrorStateWidget.cleanMessage(
            'Exception: Insufficient stock for transaction',
          ),
          equals('Insufficient stock for transaction'),
        );
      },
    );

    testWidgets(
      'renders user-friendly message on screen instead of raw socket dump',
      (tester) async {
        const rawError =
            "ClientException with SocketException: Failed host lookup: 'cmuwfwzvwvjulydhnalq.supabase.co'";
        var retried = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStateWidget(
                message: rawError,
                onRetry: () => retried = true,
              ),
            ),
          ),
        );

        // Verify human-friendly message is shown
        expect(
          find.text(
            'Unable to reach the server. Please check your internet connection.',
          ),
          findsOneWidget,
        );
        // Verify raw technical error is NOT shown
        expect(find.textContaining('SocketException'), findsNothing);
        expect(find.textContaining('Failed host lookup'), findsNothing);

        // Verify retry button works
        expect(find.text('Try Again'), findsOneWidget);
        await tester.tap(find.text('Try Again'));
        expect(retried, isTrue);
      },
    );
  });
}
