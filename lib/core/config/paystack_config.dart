class PaystackConfig {
  static const String publicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'pk_test_c5a1fed0d80b54cf0e07350b9abd667fe577bf08',
  );

  static const String secretKey = String.fromEnvironment(
    'PAYSTACK_SECRET_KEY',
    defaultValue: 'sk_test_13b2a48578d1ae38041849c845381ff78c8221fd',
  );
}
