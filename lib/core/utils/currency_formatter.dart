import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(
    int amountInMinorUnits, {
    String currencyCode = 'NGN',
    String? locale,
  }) {
    final amount = amountInMinorUnits / 100;

    String symbol = currencyCode;
    switch (currencyCode.toUpperCase()) {
      case 'NGN':
        symbol = '₦';
        break;
      case 'GHS':
        symbol = 'GH₵';
        break;
      case 'KES':
        symbol = 'KSh ';
        break;
      case 'ZAR':
        symbol = 'R ';
        break;
      case 'UGX':
        symbol = 'USh ';
        break;
      case 'TZS':
        symbol = 'TSh ';
        break;
      case 'RWF':
        symbol = 'FRw ';
        break;
      case 'XOF':
      case 'XAF':
        symbol = 'FCFA ';
        break;
      case 'USD':
        symbol = '\$';
        break;
      case 'EUR':
        symbol = '€';
        break;
      case 'GBP':
        symbol = '£';
        break;
      default:
        symbol = '$currencyCode ';
        break;
    }

    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 2,
    );

    return formatter.format(amount);
  }
}
