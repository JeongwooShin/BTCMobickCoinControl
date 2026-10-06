import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class LegacySignature {
  const LegacySignature({required this.der, required this.withSighash});
  final Uint8List der;
  final Uint8List withSighash;
}

class LegacySigner {
  static LegacySignature signDigest({
    required Uint8List privateKey,
    required Uint8List digest32,
    int sighashType = 0x01,
  }) {
    if (privateKey.length != 32 || digest32.length != 32) {
      throw const FormatException('Signing inputs must be 32 bytes.');
    }
    final domain = ECDomainParameters('secp256k1');
    final d = _bigInt(privateKey);
    if (d <= BigInt.zero || d >= domain.n) {
      throw const FormatException('Private key scalar is out of range.');
    }
    final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
    signer.init(true, PrivateKeyParameter(ECPrivateKey(d, domain)));
    final sig = signer.generateSignature(digest32) as ECSignature;
    var s = sig.s;
    if (s > (domain.n >> 1)) s = domain.n - s; // standard low-S
    final der = _der(sig.r, s);
    return LegacySignature(
      der: der,
      withSighash: Uint8List.fromList([...der, sighashType]),
    );
  }

  static Uint8List doubleSha256(List<int> bytes) {
    final first = sha256.convert(bytes).bytes;
    return Uint8List.fromList(sha256.convert(first).bytes);
  }

  static BigInt _bigInt(List<int> bytes) {
    var n = BigInt.zero;
    for (final b in bytes) n = (n << 8) | BigInt.from(b);
    return n;
  }

  static Uint8List _der(BigInt r, BigInt s) {
    List<int> integer(BigInt v) {
      var hex = v.toRadixString(16);
      if (hex.length.isOdd) hex = '0$hex';
      var b = [for (var i=0;i<hex.length;i+=2) int.parse(hex.substring(i,i+2),radix:16)];
      if (b.isEmpty || (b.first & 0x80) != 0) b = [0, ...b];
      return [0x02, b.length, ...b];
    }
    final body = [...integer(r), ...integer(s)];
    return Uint8List.fromList([0x30, body.length, ...body]);
  }
}
