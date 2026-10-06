import '../domain/utxo.dart';
import 'fee_estimator.dart';

class SendDraft {
  const SendDraft({
    required this.selected,
    required this.recipient,
    required this.sendSats,
    required this.feeSats,
    required this.changeSats,
    required this.estimatedVbytes,
  });

  final List<Utxo> selected;
  final String recipient;
  final int sendSats;
  final int feeSats;
  final int changeSats;
  final int estimatedVbytes;
}

class SendDraftBuilder {
  static SendDraft maxSpend({
    required List<Utxo> selected,
    required List<InputScriptType> inputTypes,
    required String recipient,
    required int satsPerVbyte,
  }) {
    return amountSpend(
      selected: selected,
      inputTypes: inputTypes,
      recipient: recipient,
      requestedSendSats: null,
      satsPerVbyte: satsPerVbyte,
    );
  }

  /// Builds either a MAX spend (requestedSendSats == null) or a partial spend.
  /// Partial spend creates a change output back to the source wallet.
  static SendDraft amountSpend({
    required List<Utxo> selected,
    required List<InputScriptType> inputTypes,
    required String recipient,
    required int? requestedSendSats,
    required int satsPerVbyte,
  }) {
    if (selected.isEmpty || selected.length != inputTypes.length) {
      throw const FormatException('Selected inputs are invalid.');
    }
    if (recipient.trim().isEmpty) {
      throw const FormatException('Recipient is empty.');
    }
    final total = selected.fold<int>(0, (sum, u) => sum + u.valueSats);
    final isMax = requestedSendSats == null;
    final outputCount = isMax ? 1 : 2;
    final quote = FeeEstimator.estimate(
      inputs: inputTypes,
      outputCount: outputCount,
      satsPerVbyte: satsPerVbyte,
    );
    final send = isMax ? total - quote.feeSats : requestedSendSats;
    if (send == null || send <= 0) {
      throw const FormatException('Send amount must be positive.');
    }
    final change = total - send - quote.feeSats;
    if (change < 0) {
      throw const FormatException('Selected amount is insufficient.');
    }
    return SendDraft(
      selected: List.unmodifiable(selected),
      recipient: recipient.trim(),
      sendSats: send,
      feeSats: quote.feeSats,
      changeSats: change,
      estimatedVbytes: quote.vbytes,
    );
  }
}
