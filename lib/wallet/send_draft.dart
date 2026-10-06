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
    if (selected.isEmpty || selected.length != inputTypes.length) {
      throw const FormatException('Selected inputs are invalid.');
    }
    if (recipient.trim().isEmpty) {
      throw const FormatException('Recipient is empty.');
    }
    final total = selected.fold<int>(0, (sum, u) => sum + u.valueSats);
    final quote = FeeEstimator.estimate(
      inputs: inputTypes,
      outputCount: 1,
      satsPerVbyte: satsPerVbyte,
    );
    final send = total - quote.feeSats;
    if (send <= 0) throw const FormatException('Selected amount is below fee.');
    return SendDraft(
      selected: List.unmodifiable(selected),
      recipient: recipient.trim(),
      sendSats: send,
      feeSats: quote.feeSats,
      changeSats: 0,
      estimatedVbytes: quote.vbytes,
    );
  }
}
