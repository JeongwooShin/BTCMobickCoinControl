import 'dart:typed_data';

import '../domain/utxo.dart';
import 'bitcoin_address_deriver.dart';
import 'legacy_sighash.dart';
import 'legacy_signer.dart';
import 'wif_decoder.dart';

class LegacyOutput {
  const LegacyOutput({required this.valueSats, required this.scriptPubKey});
  final int valueSats;
  final Uint8List scriptPubKey;
}

class SignedLegacyTransaction {
  const SignedLegacyTransaction({
    required this.bytes,
    required this.hex,
    required this.txid,
    required this.vbytes,
  });

  final Uint8List bytes;
  final String hex;
  final String txid;
  final int vbytes;
}

class LegacyTransactionSigner {
  static SignedLegacyTransaction sign({
    required String wif,
    required List<Utxo> inputs,
    required Uint8List sourceScriptPubKey,
    required List<LegacyOutput> outputs,
  }) {
    if (inputs.isEmpty || outputs.isEmpty) {
      throw const FormatException('Transaction must have inputs and outputs.');
    }
    for (final output in outputs) {
      if (output.valueSats <= 0 || output.scriptPubKey.isEmpty) {
        throw const FormatException('Invalid transaction output.');
      }
    }

    final decoded = WifDecoder().decode(wif);
    if (!decoded.compressed) {
      throw const FormatException('Compressed WIF is required.');
    }
    final wallet = BitcoinAddressDeriver().deriveFromWif(wif);
    final outputRecords = outputs
        .map((o) => (valueSats: o.valueSats, scriptPubKey: o.scriptPubKey))
        .toList(growable: false);

    final scripts = <Uint8List>[];
    for (var i = 0; i < inputs.length; i++) {
      final digest = LegacySighash.sighashAll(
        inputs: inputs,
        signingIndex: i,
        sourceScriptPubKey: sourceScriptPubKey,
        outputs: outputRecords,
      );
      final signature = LegacySigner.signDigest(
        privateKey: decoded.privateKey,
        digest32: digest,
      );
      scripts.add(
        _scriptSig(signature.withSighash, wallet.compressedPublicKey),
      );
    }

    final out = <int>[];
    _u32(out, 2);
    _varInt(out, inputs.length);
    for (var i = 0; i < inputs.length; i++) {
      out.addAll(_hex(inputs[i].txHash).reversed);
      _u32(out, inputs[i].txPosition);
      _varInt(out, scripts[i].length);
      out.addAll(scripts[i]);
      _u32(out, 0xfffffffd);
    }

    _varInt(out, outputs.length);
    for (final output in outputs) {
      _u64(out, output.valueSats);
      _varInt(out, output.scriptPubKey.length);
      out.addAll(output.scriptPubKey);
    }
    _u32(out, 0);

    final bytes = Uint8List.fromList(out);
    final hash = LegacySigner.doubleSha256(bytes);
    final txid = hash.reversed
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return SignedLegacyTransaction(
      bytes: bytes,
      hex: bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      txid: txid,
      vbytes: bytes.length,
    );
  }

  static Uint8List _scriptSig(Uint8List signature, Uint8List publicKey) {
    if (signature.length >= 0x4c || publicKey.length >= 0x4c) {
      throw const FormatException('Pushdata size not supported.');
    }
    return Uint8List.fromList([
      signature.length,
      ...signature,
      publicKey.length,
      ...publicKey,
    ]);
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
