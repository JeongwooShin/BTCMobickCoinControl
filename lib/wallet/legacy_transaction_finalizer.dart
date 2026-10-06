import 'dart:typed_data';

import '../domain/utxo.dart';
import 'legacy_transaction_signer.dart';

class FinalizedLegacyTransaction {
  const FinalizedLegacyTransaction({
    required this.signed,
    required this.sendSats,
    required this.feeSats,
    required this.changeSats,
  });

  final SignedLegacyTransaction signed;
  final int sendSats;
  final int feeSats;
  final int changeSats;
}

class LegacyTransactionFinalizer {
  /// Finalizes a legacy P2PKH transaction using the actual signed byte length.
  ///
  /// If [requestedSendSats] is null, this is a MAX spend and the recipient
  /// receives total inputs minus the final network fee.
  /// Otherwise the requested amount is fixed and change is recalculated.
  static FinalizedLegacyTransaction finalize({
    required String wif,
    required List<Utxo> inputs,
    required Uint8List sourceScriptPubKey,
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

    var fee = 0;
    var previousFee = -1;
    SignedLegacyTransaction? signed;
    var send = 0;
    var change = 0;

    for (var iteration = 0; iteration < maxIterations; iteration++) {
      final isMax = requestedSendSats == null;
      if (isMax) {
        send = totalIn - fee;
        change = 0;
      } else {
        send = requestedSendSats;
        change = totalIn - send - fee;
      }

      if (send <= 0 || change < 0) {
        throw const FormatException('Selected UTXOs are insufficient.');
      }
      if (change > 0 && changeScriptPubKey == null) {
        throw const FormatException('Change script is required.');
      }

      final outputs = <LegacyOutput>[
        LegacyOutput(valueSats: send, scriptPubKey: recipientScriptPubKey),
        if (change > 0)
          LegacyOutput(valueSats: change, scriptPubKey: changeScriptPubKey!),
      ];

      signed = LegacyTransactionSigner.sign(
        wif: wif,
        inputs: inputs,
        sourceScriptPubKey: sourceScriptPubKey,
        outputs: outputs,
      );

      previousFee = fee;
      fee = signed.vbytes * satsPerVbyte;
      if (fee == previousFee) {
        return FinalizedLegacyTransaction(
          signed: signed,
          sendSats: send,
          feeSats: fee,
          changeSats: change,
        );
      }
    }

    if (signed == null) {
      throw StateError('Transaction was not signed.');
    }

    // One final build with the last measured fee. If signature length changes
    // again, fail closed instead of broadcasting an underfunded transaction.
    final isMax = requestedSendSats == null;
    send = isMax ? totalIn - fee : requestedSendSats;
    change = isMax ? 0 : totalIn - send - fee;
    if (send <= 0 || change < 0) {
      throw const FormatException('Selected UTXOs are insufficient.');
    }
    final outputs = <LegacyOutput>[
      LegacyOutput(valueSats: send, scriptPubKey: recipientScriptPubKey),
      if (change > 0)
        LegacyOutput(valueSats: change, scriptPubKey: changeScriptPubKey!),
    ];
    final finalSigned = LegacyTransactionSigner.sign(
      wif: wif,
      inputs: inputs,
      sourceScriptPubKey: sourceScriptPubKey,
      outputs: outputs,
    );
    final finalFee = finalSigned.vbytes * satsPerVbyte;
    if (finalFee != fee) {
      throw StateError('Signed transaction size did not converge.');
    }
    return FinalizedLegacyTransaction(
      signed: finalSigned,
      sendSats: send,
      feeSats: finalFee,
      changeSats: change,
    );
  }
}
