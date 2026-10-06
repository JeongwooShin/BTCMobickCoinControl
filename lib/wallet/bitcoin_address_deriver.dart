import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

import 'wif_decoder.dart';

class DerivedSingleKeyWallet {
  const DerivedSingleKeyWallet({
    required this.compressedPublicKey,
    required this.p2pkhAddress,
    required this.p2wpkhAddress,
  });

  final Uint8List compressedPublicKey;
  final String p2pkhAddress;
  final String p2wpkhAddress;
}

class BitcoinAddressDeriver {
  static const _base58 =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  static const _bech32 = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

  DerivedSingleKeyWallet deriveFromWif(String wif) {
    final decoded = WifDecoder().decode(wif);
    if (!decoded.compressed) {
      throw const WifFormatException(
        'Native SegWit requires a compressed public key.',
      );
    }

    final privateScalar = _bytesToBigInt(decoded.privateKey);
    final domain = ECDomainParameters('secp256k1');
    if (privateScalar <= BigInt.zero || privateScalar >= domain.n) {
      throw const WifFormatException('Private key scalar is out of range.');
    }

    final point = domain.G * privateScalar;
    if (point == null || point.isInfinity) {
      throw const WifFormatException('Unable to derive public key.');
    }

    final publicKey = Uint8List.fromList(point.getEncoded(true));
    final keyHash = _hash160(publicKey);

    return DerivedSingleKeyWallet(
      compressedPublicKey: publicKey,
      p2pkhAddress: _base58Check(Uint8List.fromList([0x00, ...keyHash])),
      p2wpkhAddress: _segwitV0Address('bc', keyHash),
    );
  }

  Uint8List _hash160(Uint8List input) {
    final sha = Uint8List.fromList(sha256.convert(input).bytes);
    final ripemd = RIPEMD160Digest();
    return ripemd.process(sha);
  }

  String _base58Check(Uint8List payload) {
    final first = sha256.convert(payload).bytes;
    final checksum = sha256.convert(first).bytes.sublist(0, 4);
    final data = Uint8List.fromList([...payload, ...checksum]);
    var number = _bytesToBigInt(data);
    final chars = <String>[];
    final radix = BigInt.from(58);
    while (number > BigInt.zero) {
      final mod = (number % radix).toInt();
      chars.add(_base58[mod]);
      number ~/= radix;
    }
    for (final byte in data) {
      if (byte != 0) break;
      chars.add('1');
    }
    return chars.reversed.join();
  }

  String _segwitV0Address(String hrp, Uint8List program) {
    final data = <int>[0, ..._convertBits(program, 8, 5, true)];
    final checksum = _bech32Checksum(hrp, data);
    return '$hrp' '1' +
        [...data, ...checksum].map((v) => _bech32[v]).join();
  }

  List<int> _convertBits(
    List<int> data,
    int fromBits,
    int toBits,
    bool pad,
  ) {
    var acc = 0;
    var bits = 0;
    final result = <int>[];
    final maxv = (1 << toBits) - 1;
    for (final value in data) {
      acc = (acc << fromBits) | value;
      bits += fromBits;
      while (bits >= toBits) {
        bits -= toBits;
        result.add((acc >> bits) & maxv);
      }
    }
    if (pad && bits > 0) {
      result.add((acc << (toBits - bits)) & maxv);
    }
    return result;
  }

  List<int> _bech32Checksum(String hrp, List<int> data) {
    final values = <int>[
      ...hrp.codeUnits.map((c) => c >> 5),
      0,
      ...hrp.codeUnits.map((c) => c & 31),
      ...data,
      0, 0, 0, 0, 0, 0,
    ];
    final polymod = _polymod(values) ^ 1;
    return List<int>.generate(6, (i) => (polymod >> (5 * (5 - i))) & 31);
  }

  int _polymod(List<int> values) {
    const generators = [
      0x3b6a57b2,
      0x26508e6d,
      0x1ea119fa,
      0x3d4233dd,
      0x2a1462b3,
    ];
    var chk = 1;
    for (final value in values) {
      final top = chk >> 25;
      chk = ((chk & 0x1ffffff) << 5) ^ value;
      for (var i = 0; i < 5; i++) {
        if (((top >> i) & 1) != 0) chk ^= generators[i];
      }
    }
    return chk;
  }

  BigInt _bytesToBigInt(List<int> bytes) {
    var result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }
}
