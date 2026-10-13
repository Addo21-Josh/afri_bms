import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/paystack_config.dart';
import '../../../../core/utils/logger.dart';
import '../models/subscription_tier.dart';

final paystackSubscriptionServiceProvider = Provider<PaystackSubscriptionService>((ref) {
  return PaystackSubscriptionService();
});

class PaystackInitResult {
  PaystackInitResult({
    required this.success,
    this.authorizationUrl,
    this.accessCode,
    this.reference,
    this.errorMessage,
  });

  final bool success;
  final String? authorizationUrl;
  final String? accessCode;
  final String? reference;
  final String? errorMessage;
}

class PaystackSubscriptionService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.paystack.co',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  /// Initializes a Paystack transaction in GHS (Ghana Cedis)
  /// [amountInGhs]: e.g., 50 GHS -> 5000 pesewas
  Future<PaystackInitResult> initializePayment({
    required String email,
    required int amountInGhs,
    required SubscriptionTier tier,
    required bool isYearly,
    Map<String, dynamic>? metadata,
    String currency = 'GHS',
  }) async {
    try {
      final amountInPesewas = amountInGhs * 100;
      final payload = {
        'email': email,
        'amount': amountInPesewas,
        'currency': currency,
        'channels': ['mobile_money', 'card'],
        'metadata': {
          'tier': tier.name,
          'billing_cycle': isYearly ? 'yearly' : 'monthly',
          'app': 'Afri_BMS',
          ...?metadata,
        },
      };

      final response = await _dio.post(
        '/transaction/initialize',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${PaystackConfig.secretKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: payload,
      );

      if (response.data != null && response.data['status'] == true) {
        final data = response.data['data'];
        return PaystackInitResult(
          success: true,
          authorizationUrl: data['authorization_url'] as String?,
          accessCode: data['access_code'] as String?,
          reference: data['reference'] as String?,
        );
      }
      final msg = response.data?['message']?.toString() ?? 'Initialization failed';
      return PaystackInitResult(success: false, errorMessage: msg);
    } catch (e) {
      AppLogger.e('Paystack initialization failed: $e');
      return PaystackInitResult(success: false, errorMessage: e.toString());
    }
  }

  /// Verifies a Paystack transaction by reference
  Future<bool> verifyPayment(String reference) async {
    try {
      final response = await _dio.get(
        '/transaction/verify/$reference',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${PaystackConfig.secretKey}',
          },
        ),
      );

      if (response.data != null && response.data['status'] == true) {
        final data = response.data['data'];
        final status = data['status'] as String?;
        return status == 'success';
      }
      return false;
    } catch (e) {
      AppLogger.e('Paystack verification failed: $e');
      return false;
    }
  }

  /// Opens the Paystack hosted checkout page in the in-app or system browser
  Future<bool> openCheckout(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
    return false;
  }
}
