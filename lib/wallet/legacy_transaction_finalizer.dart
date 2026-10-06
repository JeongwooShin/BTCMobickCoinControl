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
  /// Signature DER length can change by a byte when output values change.
  /// Instead of requiring an exact fixed point (which can oscillate), the fee
  /// budget only moves upward. Finalization succeeds once the paid fee is at
  /// least the requested sat/vB rate for the final signed size.
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

      final signed = LegacyTransactionSigner.sign(
        wif: wif,
        inputs: inputs,
        sourceScriptPubKey: sourceScriptPubKey,
        outputs: outputs,
      );

      final requiredFee = signed.vbytes * satsPerVbyte;

      // The transaction actually pays feeBudget because inputs - outputs
      // equals feeBudget. If that covers the requested rate for this exact
      // signed size, it is safe to finalize. A few extra bick may be paid
      // when DER signature length shrinks after a prior iteration.
      if (feeBudget >= requiredFee) {
        return FinalizedLegacyTransaction(
          signed: signed,
          sendSats: send,
          feeSats: feeBudget,
          changeSats: change,
        );
      }

      // Move upward only. This prevents one-byte signature-length oscillation.
      feeBudget = requiredFee;
    }

    throw StateError('Signed transaction fee did not converge safely.');
  }
}
