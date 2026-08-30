import '../../../../core/secure/secure_store.dart';

abstract final class AuthStoreKeys {
  static const sessionToken = 'auth.session.token';
  static const sessionPhone = 'auth.session.phone';
  static const pinHash = 'auth.pin.hash';
  static const pinSalt = 'auth.pin.salt';
  static const biometricEnabled = 'auth.biometric.enabled';
  static const locale = 'auth.locale';
}

final class AuthLocalDataSource {
  AuthLocalDataSource(this._store);

  final SecureStore _store;

  Future<void> writeSession({
    required String token,
    required String phone,
    required bool biometricEnabled,
  }) async {
    await _store.write(AuthStoreKeys.sessionToken, token);
    await _store.write(AuthStoreKeys.sessionPhone, phone);
    await _store.write(
      AuthStoreKeys.biometricEnabled,
      biometricEnabled ? '1' : '0',
    );
  }

  Future<String?> readSessionToken() => _store.read(AuthStoreKeys.sessionToken);

  Future<String?> readSessionPhone() => _store.read(AuthStoreKeys.sessionPhone);

  Future<bool> readBiometricEnabled() async {
    return await _store.read(AuthStoreKeys.biometricEnabled) == '1';
  }

  Future<void> writePin({required String hash, required String salt}) async {
    await _store.write(AuthStoreKeys.pinHash, hash);
    await _store.write(AuthStoreKeys.pinSalt, salt);
  }

  Future<String?> readPinHash() => _store.read(AuthStoreKeys.pinHash);

  Future<String?> readPinSalt() => _store.read(AuthStoreKeys.pinSalt);

  Future<void> writeLocale(String locale) =>
      _store.write(AuthStoreKeys.locale, locale);

  Future<String?> readLocale() => _store.read(AuthStoreKeys.locale);

  Future<void> clearSession() async {
    await _store.delete(AuthStoreKeys.sessionToken);
    await _store.delete(AuthStoreKeys.sessionPhone);
  }
}
