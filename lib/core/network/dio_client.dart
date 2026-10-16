import 'package:dio/dio.dart';
import '../utils/logger.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Strict HTTPS enforcement: Cleartext HTTP is disabled at the OS level
        // (android:usesCleartextTraffic="false" in AndroidManifest.xml and ATS on iOS).
        // Standard platform-level X.509 CA trust stores validate all Supabase and
        // Paystack TLS endpoints, avoiding brittle hardcoded certificate pin lockouts.
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.d('Request: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.d('Response: ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          AppLogger.e('DioError: ${e.message}', e, e.stackTrace);
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
