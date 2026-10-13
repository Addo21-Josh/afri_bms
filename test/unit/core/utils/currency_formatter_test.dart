import 'package:flutter_test/flutter_test.dart';
import 'package:afri_bms/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats GHS by default using minor units (pesewas)', () {
      final formatted = CurrencyFormatter.format(5000);
      expect(formatted, contains('GH₵'));
      expect(formatted, contains('50.00'));
    });

    test('formats zero and large amounts correctly in GHS', () {
      expect(CurrencyFormatter.format(0), contains('0.00'));
      expect(CurrencyFormatter.format(1500000), contains('15,000.00'));
    });

    test('formats NGN correctly', () {
      final formatted = CurrencyFormatter.format(250000, currencyCode: 'NGN');
      expect(formatted, contains('₦'));
      expect(formatted, contains('2,500.00'));
    });

    test('formats international currencies (USD, EUR, GBP)', () {
      expect(CurrencyFormatter.format(1000, currencyCode: 'USD'), contains('\$10.00'));
      expect(CurrencyFormatter.format(1000, currencyCode: 'EUR'), contains('€10.00'));
      expect(CurrencyFormatter.format(1000, currencyCode: 'GBP'), contains('£10.00'));
    });

    test('formats other African currencies (KES, ZAR, KSh, FCFA)', () {
      expect(CurrencyFormatter.format(10000, currencyCode: 'KES'), contains('KSh'));
      expect(CurrencyFormatter.format(10000, currencyCode: 'ZAR'), contains('R'));
      expect(CurrencyFormatter.format(10000, currencyCode: 'XOF'), contains('FCFA'));
    });
  });
}
