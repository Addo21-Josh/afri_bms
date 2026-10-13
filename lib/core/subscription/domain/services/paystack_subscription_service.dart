import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/paystack_config.dart';
import '../../../../core/utils/logger.dart';

class PaystackInitResponse {
  final String authorizationUrl;
  final String accessCode;
  final String reference;

  PaystackInitResponse({
    required this.authorizationUrl,
    required this.accessCode,
    required this.reference,
  });
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
  /// [amountInPesewas]: e.g., 50 GHS = 5000 pesewas
  Future<PaystackInitResponse?> initializePayment({
    required String email,
    required int amountInPesewas,
    required String businessId,
    required String planName,
    String currency = 'GHS',
  }) async {
    try {
      final response = await _dio.post(
        '/transaction/initialize',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${PaystackConfig.secretKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'email': email,
          'amount': amountInPesewas,
          'currency': currency,
          'channels': ['mobile_money', 'card'],
          'metadata': {
            'business_id': businessId,
            'plan': planName,
            'app': 'Afri_BMS',
          },
        },
      );

      if (response.data != null && response.data['status'] == true) {
        final data = response.data['data'];
        return PaystackInitResponse(
          authorizationUrl: data['authorization_url'] as String,
          accessCode: data['access_code'] as String,
          reference: data['reference'] as String,
        );
      }
      return null;
    } catch (e) {
      AppLogger.e('Paystack initialization failed: $e');
      return null;
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
