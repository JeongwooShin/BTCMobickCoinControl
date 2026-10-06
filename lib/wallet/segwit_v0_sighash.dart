import 'dart:typed_data';

import '../domain/utxo.dart';
import 'legacy_signer.dart';

class SegwitV0Sighash {
  static Uint8List sighashAll({
    required List<Utxo> inputs,
    required int signingIndex,
    required Uint8List scriptCode,
    required List<({int valueSats, Uint8List scriptPubKey})> outputs,
  }) {
    if (signingIndex < 0 || signingIndex >= inputs.length) {
      throw RangeError('Invalid signing input index.');
    }

    final prevouts = <int>[];
    final sequences = <int>[];
    for (final input in inputs) {
      prevouts.addAll(_hex(input.txHash).reversed);
      _u32(prevouts, input.txPosition);
      _u32(sequences, 0xfffffffd);
    }

    final outputsBytes = <int>[];
    for (final output in outputs) {
      _u64(outputsBytes, output.valueSats);
      _varInt(outputsBytes, output.scriptPubKey.length);
      outputsBytes.addAll(output.scriptPubKey);
    }

    final input = inputs[signingIndex];
    final preimage = <int>[];
    _u32(preimage, 2);
    preimage.addAll(LegacySigner.doubleSha256(prevouts));
    preimage.addAll(LegacySigner.doubleSha256(sequences));
    preimage.addAll(_hex(input.txHash).reversed);
    _u32(preimage, input.txPosition);
    _varInt(preimage, scriptCode.length);
    preimage.addAll(scriptCode);
    _u64(preimage, input.valueSats);
    _u32(preimage, 0xfffffffd);
    preimage.addAll(LegacySigner.doubleSha256(outputsBytes));
    _u32(preimage, 0);
    _u32(preimage, 1);
    return LegacySigner.doubleSha256(preimage);
  }

  static List<int> _hex(String s) {
    if (s.length != 64) throw const FormatException('Invalid txid.');
    return List<int>.generate(
      32,
      (i) => int.parse(s.substring(i * 2, i * 2 + 2), radix: 16),
    );
  }

  static void _u32(List<int> out, int value) {
    for (var i = 0; i < 4; i++) {
      out.add((value >> (8 * i)) & 0xff);
    }
  }

  static void _u64(List<int> out, int value) {
    var n = BigInt.from(value);
    for (var i = 0; i < 8; i++) {
      out.add((n & BigInt.from(255)).toInt());
      n >>= 8;
    }
  }

  static void _varInt(List<int> out, int value) {
    if (value < 0xfd) {
      out.add(value);
      return;
    }
    throw const FormatException('Large varint not implemented yet.');
  }
}
