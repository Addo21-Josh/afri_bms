import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:afri_bms/core/subscription/domain/models/subscription_tier.dart';
import 'package:afri_bms/core/subscription/domain/services/paystack_subscription_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late PaystackSubscriptionService service;

  setUp(() {
    mockDio = MockDio();
    service = PaystackSubscriptionService(dio: mockDio);
  });

  group('PaystackSubscriptionService - initializePayment', () {
    test('sends payload in GHS minor units (pesewas) and parses response', () async {
      when(
        () => mockDio.post(
          '/transaction/initialize',
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/transaction/initialize'),
          statusCode: 200,
          data: {
            'status': true,
            'message': 'Authorization URL created',
            'data': {
              'authorization_url': 'https://checkout.paystack.com/access123',
              'access_code': 'access123',
              'reference': 'ref_test_001',
            },
          },
        ),
      );

      final result = await service.initializePayment(
        email: 'merchant@store.com',
        amountInGhs: 50,
        tier: SubscriptionTier.pro,
        isYearly: false,
        metadata: {'business_id': 'biz-123'},
      );

      expect(result.success, isTrue);
      expect(result.authorizationUrl, equals('https://checkout.paystack.com/access123'));
      expect(result.reference, equals('ref_test_001'));

      verify(
        () => mockDio.post(
          '/transaction/initialize',
          options: any(named: 'options'),
          data: captureAny(named: 'data'),
        ),
      ).called(1);
    });

    test('handles failed API response gracefully', () async {
      when(
        () => mockDio.post(
          '/transaction/initialize',
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/transaction/initialize'),
          statusCode: 400,
          data: {
            'status': false,
            'message': 'Invalid amount',
          },
        ),
      );

      final result = await service.initializePayment(
        email: 'merchant@store.com',
        amountInGhs: 0,
        tier: SubscriptionTier.free,
        isYearly: false,
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, equals('Invalid amount'));
    });
  });

  group('PaystackSubscriptionService - verifyPayment', () {
    test('returns true when status is success', () async {
      when(
        () => mockDio.get(
          '/transaction/verify/ref_test_001',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/transaction/verify/ref_test_001'),
          statusCode: 200,
          data: {
            'status': true,
            'data': {
              'status': 'success',
              'reference': 'ref_test_001',
              'amount': 5000,
            },
          },
        ),
      );

      final isSuccess = await service.verifyPayment('ref_test_001');
      expect(isSuccess, isTrue);
    });

    test('returns false when status is failed or abandoned', () async {
      when(
        () => mockDio.get(
          '/transaction/verify/ref_test_002',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/transaction/verify/ref_test_002'),
          statusCode: 200,
          data: {
            'status': true,
            'data': {
              'status': 'failed',
            },
          },
        ),
      );

      final isSuccess = await service.verifyPayment('ref_test_002');
      expect(isSuccess, isFalse);
    });
  });
}
