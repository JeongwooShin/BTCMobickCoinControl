import 'package:btcmobick_coin_control/domain/utxo.dart';
import 'package:btcmobick_coin_control/wallet/fee_estimator.dart';
import 'package:btcmobick_coin_control/wallet/send_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MAX spend subtracts estimated fee and creates no change', () {
    final selected = [
      Utxo(txHash: List.filled(64, '0').join(), txPosition: 0, valueSats: 10000, height: 1),
      Utxo(txHash: List.filled(64, '1').join(), txPosition: 0, valueSats: 30000, height: 1),
    ];
    final draft = SendDraftBuilder.maxSpend(
      selected: selected,
      inputTypes: const [InputScriptType.p2pkh, InputScriptType.p2pkh],
      recipient: 'recipient',
      satsPerVbyte: 1,
    );
    expect(draft.estimatedVbytes, 340);
    expect(draft.feeSats, 340);
    expect(draft.sendSats, 39660);
    expect(draft.changeSats, 0);
  });

  test('rejects spend when fee consumes selection', () {
    final selected = [
      Utxo(txHash: List.filled(64, '0').join(), txPosition: 0, valueSats: 100, height: 1),
    ];
    expect(
      () => SendDraftBuilder.maxSpend(
        selected: selected,
        inputTypes: const [InputScriptType.p2pkh],
        recipient: 'recipient',
        satsPerVbyte: 10,
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
