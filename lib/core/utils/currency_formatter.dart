import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(int amountInMinorUnits, {String currencyCode = 'NGN'}) {
    final amount = amountInMinorUnits / 100;
    
    // Fallback symbols if intl doesn't have them
    String symbol = currencyCode;
    switch (currencyCode) {
      case 'NGN':
        symbol = '₦';
        break;
      case 'GHS':
        symbol = 'GH₵';
        break;
      case 'XOF':
        symbol = 'CFA ';
        break;
      case 'USD':
        symbol = '\$';
        break;
    }

    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );

    return formatter.format(amount);
  }
}
