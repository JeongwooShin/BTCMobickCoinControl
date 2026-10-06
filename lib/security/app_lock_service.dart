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
  // Wallet persistence is intentionally disabled for the current release.
  // TODO(wallet-persistence): If persistence is reintroduced, do not restore
  // the old single-WIF design. Implement a multi-wallet list with stable IDs,
  // public address metadata for display, individually encrypted WIF records,
  // per-wallet deletion, and "disable storage" deleting every stored wallet.
  // static const _persistWalletKey = 'security.persist_wallet.v1';
  // static const _savedWifKey = 'wallet.wif.v1';
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

  // Wallet save/read/delete APIs are intentionally disabled.
  // See TODO(wallet-persistence) above before implementing them again.

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
