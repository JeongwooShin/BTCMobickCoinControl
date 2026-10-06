import 'dart:typed_data';

import '../domain/utxo.dart';
import 'bitcoin_address_deriver.dart';
import 'legacy_signer.dart';
import 'legacy_transaction_signer.dart';
import 'segwit_v0_sighash.dart';
import 'wif_decoder.dart';

class SignedSegwitTransaction {
  const SignedSegwitTransaction({
    required this.bytes,
    required this.hex,
    required this.txid,
    required this.wtxid,
    required this.vbytes,
    required this.weight,
  });

  final Uint8List bytes;
  final String hex;
  final String txid;
  final String wtxid;
  final int vbytes;
  final int weight;
}

class SegwitTransactionSigner {
  static SignedSegwitTransaction signP2wpkh({
    required String wif,
    required List<Utxo> inputs,
    required Uint8List sourceScriptCode,
    required List<LegacyOutput> outputs,
  }) {
    if (inputs.isEmpty || outputs.isEmpty) {
      throw const FormatException('Transaction must have inputs and outputs.');
    }

    final decoded = WifDecoder().decode(wif);
    if (!decoded.compressed) {
      throw const FormatException('Compressed WIF is required.');
    }
    final wallet = BitcoinAddressDeriver().deriveFromWif(wif);
    final outputRecords = outputs
        .map((o) => (valueSats: o.valueSats, scriptPubKey: o.scriptPubKey))
        .toList(growable: false);

    final witnesses = <List<Uint8List>>[];
    for (var i = 0; i < inputs.length; i++) {
      final digest = SegwitV0Sighash.sighashAll(
        inputs: inputs,
        signingIndex: i,
        scriptCode: sourceScriptCode,
        outputs: outputRecords,
      );
      final signature = LegacySigner.signDigest(
        privateKey: decoded.privateKey,
        digest32: digest,
      );
      witnesses.add([
        signature.withSighash,
        wallet.compressedPublicKey,
      ]);
    }

    final stripped = _serializeStripped(inputs, outputs);
    final full = <int>[];
    _u32(full, 2);
    full
      ..add(0x00)
      ..add(0x01);
    _writeInputs(full, inputs);
    _writeOutputs(full, outputs);
    for (final witness in witnesses) {
      _varInt(full, witness.length);
      for (final item in witness) {
        _varInt(full, item.length);
        full.addAll(item);
      }
    }
    _u32(full, 0);

    final bytes = Uint8List.fromList(full);
    final strippedBytes = Uint8List.fromList(stripped);
    final txid = _displayHash(LegacySigner.doubleSha256(strippedBytes));
    final wtxid = _displayHash(LegacySigner.doubleSha256(bytes));
    final weight = strippedBytes.length * 4 + (bytes.length - strippedBytes.length);
    final vbytes = (weight + 3) ~/ 4;

    return SignedSegwitTransaction(
      bytes: bytes,
      hex: _hexString(bytes),
      txid: txid,
      wtxid: wtxid,
      vbytes: vbytes,
      weight: weight,
    );
  }

  static List<int> _serializeStripped(
    List<Utxo> inputs,
    List<LegacyOutput> outputs,
  ) {
    final out = <int>[];
    _u32(out, 2);
    _writeInputs(out, inputs);
    _writeOutputs(out, outputs);
    _u32(out, 0);
    return out;
  }

  static void _writeInputs(List<int> out, List<Utxo> inputs) {
    _varInt(out, inputs.length);
    for (final input in inputs) {
      out.addAll(_hex(input.txHash).reversed);
      _u32(out, input.txPosition);
      _varInt(out, 0);
      _u32(out, 0xfffffffd);
    }
  }

  static void _writeOutputs(List<int> out, List<LegacyOutput> outputs) {
    _varInt(out, outputs.length);
    for (final output in outputs) {
      if (output.valueSats <= 0 || output.scriptPubKey.isEmpty) {
        throw const FormatException('Invalid transaction output.');
      }
      _u64(out, output.valueSats);
      _varInt(out, output.scriptPubKey.length);
      out.addAll(output.scriptPubKey);
    }
  }

  static String _displayHash(Uint8List hash) =>
      hash.reversed.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static String _hexString(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

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
