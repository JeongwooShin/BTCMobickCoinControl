import 'dart:typed_data';

import '../domain/utxo.dart';
import 'legacy_transaction_signer.dart';
import 'segwit_transaction_signer.dart';

class FinalizedSegwitTransaction {
  const FinalizedSegwitTransaction({
    required this.signed,
    required this.sendSats,
    required this.feeSats,
    required this.changeSats,
  });

  final SignedSegwitTransaction signed;
  final int sendSats;
  final int feeSats;
  final int changeSats;
}

class SegwitTransactionFinalizer {
  static FinalizedSegwitTransaction finalize({
    required String wif,
    required List<Utxo> inputs,
    required Uint8List sourceScriptCode,
    required Uint8List recipientScriptPubKey,
    required int satsPerVbyte,
    int? requestedSendSats,
    Uint8List? changeScriptPubKey,
    int maxIterations = 8,
  }) {
    if (inputs.isEmpty || satsPerVbyte <= 0) {
      throw const FormatException('Invalid finalization arguments.');
    }

    final totalIn = inputs.fold<int>(0, (sum, u) => sum + u.valueSats);
    if (requestedSendSats != null && requestedSendSats <= 0) {
      throw const FormatException('Requested send amount must be positive.');
    }

    var feeBudget = 0;
    for (var iteration = 0; iteration < maxIterations; iteration++) {
      final isMax = requestedSendSats == null;
      final send = isMax ? totalIn - feeBudget : requestedSendSats;
      final change = isMax ? 0 : totalIn - send - feeBudget;

      if (send <= 0 || change < 0) {
        throw const FormatException('Selected UTXOs are insufficient.');
      }
      if (change > 0 && changeScriptPubKey == null) {
        throw const FormatException('Change script is required.');
      }

      final outputs = <LegacyOutput>[
        LegacyOutput(
          valueSats: send,
          scriptPubKey: recipientScriptPubKey,
        ),
        if (change > 0)
          LegacyOutput(
            valueSats: change,
            scriptPubKey: changeScriptPubKey!,
          ),
      ];

      final signed = SegwitTransactionSigner.signP2wpkh(
        wif: wif,
        inputs: inputs,
        sourceScriptCode: sourceScriptCode,
        outputs: outputs,
      );
      final requiredFee = signed.vbytes * satsPerVbyte;
      if (feeBudget >= requiredFee) {
        return FinalizedSegwitTransaction(
          signed: signed,
          sendSats: send,
          feeSats: feeBudget,
          changeSats: change,
        );
      }
      feeBudget = requiredFee;
    }

    throw StateError('Signed transaction fee did not converge safely.');
  }
}
