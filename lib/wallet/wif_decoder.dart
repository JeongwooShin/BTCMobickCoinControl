import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class DecodedWif {
  const DecodedWif({
    required this.privateKey,
    required this.compressed,
  });

  final Uint8List privateKey;
  final bool compressed;
}

class WifFormatException implements Exception {
  const WifFormatException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Strict structural decoder. Base58Check checksum verification is intentionally
/// implemented in the crypto milestone together with SHA-256/address derivation.
class WifDecoder {
  static const _alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  DecodedWif decode(String input) {
    final wif = input.trim();
    final decoded = _decodeBase58(wif);
    if (decoded.length != 37 && decoded.length != 38) {
      throw const WifFormatException('Unexpected WIF payload length.');
    }

    final payload = decoded.sublist(0, decoded.length - 4);
    final checksum = decoded.sublist(decoded.length - 4);
    final firstHash = sha256.convert(payload).bytes;
    final expected = sha256.convert(firstHash).bytes.sublist(0, 4);
    for (var i = 0; i < 4; i++) {
      if (checksum[i] != expected[i]) {
        throw const WifFormatException('Invalid WIF checksum.');
      }
    }

    return _decodeValidatedBytes(decoded);
  }

  DecodedWif decodeStructure(String input) {
    final wif = input.trim();
    if (wif.isEmpty) {
      throw const WifFormatException('WIF is empty.');
    }

    final decoded = _decodeBase58(wif);
    if (decoded.length != 37 && decoded.length != 38) {
      throw const WifFormatException('Unexpected WIF payload length.');
    }

    return _decodeValidatedBytes(decoded);
  }

  DecodedWif _decodeValidatedBytes(Uint8List decoded) {
    // Bitcoin-compatible mainnet WIF version byte.
    if (decoded[0] != 0x80) {
      throw const WifFormatException('Unsupported WIF network/version.');
    }

    final compressed = decoded.length == 38;
    if (compressed && decoded[33] != 0x01) {
      throw const WifFormatException('Invalid compressed WIF marker.');
    }

    return DecodedWif(
      privateKey: Uint8List.fromList(decoded.sublist(1, 33)),
      compressed: compressed,
    );
  }

  Uint8List _decodeBase58(String value) {
    var number = BigInt.zero;
    final radix = BigInt.from(58);

    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final digit = _alphabet.indexOf(char);
      if (digit < 0) {
        throw const WifFormatException('WIF contains a non-Base58 character.');
      }
      number = number * radix + BigInt.from(digit);
    }

    final bytes = <int>[];
    while (number > BigInt.zero) {
      bytes.add((number & BigInt.from(0xff)).toInt());
      number >>= 8;
    }
    final result = bytes.reversed.toList();

    var leadingZeroes = 0;
    while (leadingZeroes < value.length && value[leadingZeroes] == '1') {
      leadingZeroes++;
    }

    return Uint8List.fromList([
      ...List<int>.filled(leadingZeroes, 0),
      ...result,
    ]);
  }
}
