import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pointycastle/export.dart';

class AppLockService {
  AppLockService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuthentication,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _localAuthentication = localAuthentication ?? LocalAuthentication();

  static const _pinSaltKey = 'security.pin_salt.v1';
  static const _pinHashKey = 'security.pin_hash.v1';
  static const _persistWalletKey = 'security.persist_wallet.v1';
  static const _savedWifKey = 'wallet.wif.v1';
  static const _pinIterations = 150000;

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuthentication;

  Future<bool> hasPin() async {
    final salt = await _storage.read(key: _pinSaltKey);
    final hash = await _storage.read(key: _pinHashKey);
    if (salt == null || hash == null) return false;
    try {
      return base64Decode(salt).length == 16 &&
          base64Decode(hash).length == 32;
    } catch (_) {
      return false;
    }
  }

  Future<void> setPin(String pin) async {
    _validatePin(pin);
    final salt = Uint8List.fromList(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    );
    final hash = _derivePin(pin, salt);
    await _storage.write(key: _pinSaltKey, value: base64Encode(salt));
    await _storage.write(key: _pinHashKey, value: base64Encode(hash));
  }

  Future<bool> verifyPin(String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) return false;
    final saltText = await _storage.read(key: _pinSaltKey);
    final hashText = await _storage.read(key: _pinHashKey);
    if (saltText == null || hashText == null) return false;

    final salt = Uint8List.fromList(base64Decode(saltText));
    final expected = Uint8List.fromList(base64Decode(hashText));
    final actual = _derivePin(pin, salt);
    return _constantTimeEquals(actual, expected);
  }

  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuthentication.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateBiometric({required bool korean}) async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: korean
            ? 'BTCMobick Coin Control 잠금을 해제하세요.'
            : 'Unlock BTCMobick Coin Control.',
        biometricOnly: true,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> walletPersistenceEnabled() async =>
      (await _storage.read(key: _persistWalletKey)) == 'true';

  Future<void> setWalletPersistenceEnabled(bool enabled) async {
    await _storage.write(
      key: _persistWalletKey,
      value: enabled ? 'true' : 'false',
    );
    if (!enabled) {
      await clearSavedWallet();
    }
  }

  Future<void> saveWalletWif(String wif) async {
    if (!await walletPersistenceEnabled()) return;
    if (wif.isEmpty) return;
    // flutter_secure_storage encrypts the value using platform secure storage.
    await _storage.write(key: _savedWifKey, value: wif);
  }

  Future<String?> readSavedWalletWif() => _storage.read(key: _savedWifKey);

  Future<void> clearSavedWallet() => _storage.delete(key: _savedWifKey);

  Future<void> changePin(String currentPin, String newPin) async {
    if (!await verifyPin(currentPin)) {
      throw const FormatException('Current PIN is incorrect.');
    }
    await setPin(newPin);
  }

  static void _validatePin(String pin) {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw const FormatException('PIN must contain exactly 6 digits.');
    }
  }

  static Uint8List _derivePin(String pin, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _pinIterations, 32));
    return derivator.process(Uint8List.fromList(utf8.encode(pin)));
  }

  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
