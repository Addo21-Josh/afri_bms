import 'package:flutter_test/flutter_test.dart';
import 'package:afri_bms/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('required returns error when empty or null', () {
      expect(Validators.required(null), 'This field is required');
      expect(Validators.required(''), 'This field is required');
      expect(Validators.required('   '), 'This field is required');
      expect(Validators.required('Custom error', 'Custom error'), isNull);
      expect(Validators.required('Valid text'), isNull);
    });

    test('email validates formats correctly', () {
      expect(Validators.email(null, required: true), 'Email is required');
      expect(Validators.email(null, required: false), isNull);
      expect(Validators.email('', required: false), isNull);
      expect(Validators.email('not-an-email'), 'Enter a valid email address');
      expect(Validators.email('missing@domain'), 'Enter a valid email address');
      expect(Validators.email('valid.user@example.com'), isNull);
      expect(Validators.email('shop+test@afribms.org'), isNull);
    });

    test('phone validates international and local phone numbers', () {
      expect(Validators.phone(null, required: true), 'Phone number is required');
      expect(Validators.phone(null, required: false), isNull);
      expect(Validators.phone('', required: false), isNull);
      expect(Validators.phone('123'), 'Enter a valid phone number (8-15 digits)');
      expect(Validators.phone('abc1234567'), 'Enter a valid phone number (8-15 digits)');
      expect(Validators.phone('0244123456'), isNull);
      expect(Validators.phone('+233244123456'), isNull);
      expect(Validators.phone('+234 803 123 4567'), isNull);
    });

    test('nonNegativeNumber rejects negatives and non-numbers', () {
      expect(Validators.nonNegativeNumber(null, required: true), 'Amount is required');
      expect(Validators.nonNegativeNumber(null, required: false), isNull);
      expect(Validators.nonNegativeNumber('', required: false), isNull);
      expect(Validators.nonNegativeNumber('abc'), 'Enter a valid number');
      expect(Validators.nonNegativeNumber('-5.50'), 'Amount cannot be negative');
      expect(Validators.nonNegativeNumber('0'), isNull);
      expect(Validators.nonNegativeNumber('150.75'), isNull);
    });

    test('nonNegativeInteger rejects floats, negatives and non-integers', () {
      expect(Validators.nonNegativeInteger(null, required: true), 'Quantity is required');
      expect(Validators.nonNegativeInteger(null, required: false), isNull);
      expect(Validators.nonNegativeInteger('-1'), 'Quantity cannot be negative');
      expect(Validators.nonNegativeInteger('12.34'), 'Enter a valid whole number');
      expect(Validators.nonNegativeInteger('abc'), 'Enter a valid whole number');
      expect(Validators.nonNegativeInteger('0'), isNull);
      expect(Validators.nonNegativeInteger('42'), isNull);
    });

    test('minLength validates minimum character length', () {
      expect(Validators.minLength('ab', 3), 'Must be at least 3 characters');
      expect(Validators.minLength('abc', 3), isNull);
      expect(Validators.minLength('abcd', 3), isNull);
      expect(Validators.minLength('', 5, 'Too short'), 'Too short');
    });
  });
}
