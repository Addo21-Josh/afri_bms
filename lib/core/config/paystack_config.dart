class PaystackConfig {
  /// Public key used for frontend client identification.
  /// NEVER store the secret key (sk_...) in this client codebase.
  static const String publicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'pk_test_c5a1fed0d80b54cf0e07350b9abd667fe577bf08',
  );
}
