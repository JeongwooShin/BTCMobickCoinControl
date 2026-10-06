import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class Base58Check {
  static const _alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  static Uint8List decode(String value) {
    var number = BigInt.zero;
    for (final rune in value.runes) {
      final digit = _alphabet.indexOf(String.fromCharCode(rune));
      if (digit < 0) throw const FormatException('Invalid Base58 character.');
      number = number * BigInt.from(58) + BigInt.from(digit);
    }
    final bytes = <int>[];
    while (number > BigInt.zero) {
      bytes.add((number & BigInt.from(0xff)).toInt());
      number >>= 8;
    }
    var zeros = 0;
    while (zeros < value.length && value[zeros] == '1') { zeros++; }
    final decoded = Uint8List.fromList([...List<int>.filled(zeros, 0), ...bytes.reversed]);
    if (decoded.length < 5) throw const FormatException('Base58Check value too short.');
    final payload = decoded.sublist(0, decoded.length - 4);
    final checksum = decoded.sublist(decoded.length - 4);
    final first = sha256.convert(payload).bytes;
    final expected = sha256.convert(first).bytes.sublist(0, 4);
    for (var i=0;i<4;i++) {
      if (checksum[i] != expected[i]) throw const FormatException('Invalid Base58Check checksum.');
    }
    return Uint8List.fromList(payload);
  }
}
