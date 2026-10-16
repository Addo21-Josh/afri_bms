import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:afri_bms/core/storage/secure_local_storage.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data.containsKey(key);
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

void main() {
  group('SecureLocalStorage', () {
    late FakeFlutterSecureStorage fakeStorage;
    late SecureLocalStorage storage;

    setUp(() {
      fakeStorage = FakeFlutterSecureStorage();
      storage = SecureLocalStorage(storage: fakeStorage);
    });

    test('initialize completes without error', () async {
      await expectLater(storage.initialize(), completes);
    });

    test('persistSession stores session string securely', () async {
      const sessionJson = '{"access_token":"secret_jwt_token","user_id":"123"}';
      await storage.persistSession(sessionJson);

      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), equals(sessionJson));
    });

    test('removePersistedSession removes session from storage', () async {
      await storage.persistSession('test-token');
      expect(await storage.hasAccessToken(), isTrue);

      await storage.removePersistedSession();
      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
    });
  });
}
