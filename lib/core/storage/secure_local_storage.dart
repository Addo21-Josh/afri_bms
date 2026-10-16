import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

/// Secure token and session storage adapter for Supabase Auth using [FlutterSecureStorage].
/// Encrypts session tokens using Android KeyStore and iOS Keychain with exception safeguards.
class SecureLocalStorage extends LocalStorage {
  const SecureLocalStorage({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  static const String _sessionKey = 'supabase_auth_session';

  @override
  Future<void> initialize() async {
    // FlutterSecureStorage does not require async initialization
  }

  @override
  Future<bool> hasAccessToken() async {
    try {
      return await _storage.containsKey(key: _sessionKey);
    } catch (e) {
      AppLogger.w('SecureLocalStorage hasAccessToken error: $e');
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      return await _storage.read(key: _sessionKey);
    } catch (e) {
      AppLogger.w('SecureLocalStorage accessToken error: $e');
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _storage.write(key: _sessionKey, value: persistSessionString);
    } catch (e) {
      AppLogger.e('SecureLocalStorage persistSession error: $e');
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _storage.delete(key: _sessionKey);
    } catch (e) {
      AppLogger.w('SecureLocalStorage removePersistedSession error: $e');
    }
  }
}
