import 'package:btcmobick_coin_control/domain/utxo.dart';
import 'package:btcmobick_coin_control/wallet/address_script.dart';
import 'package:btcmobick_coin_control/wallet/bitcoin_address_deriver.dart';
import 'package:btcmobick_coin_control/wallet/legacy_transaction_finalizer.dart';
import 'package:btcmobick_coin_control/wallet/recipient_address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const wif =
      'KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn';

  test('MAX finalization uses actual signed size for fee', () {
    final wallet = BitcoinAddressDeriver().deriveFromWif(wif);
    final sourceScript = AddressScript.p2pkh(wallet.publicKeyHash);
    final recipient = RecipientAddressParser.parse(
      '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH',
    );
    final input = Utxo(
      txHash: List.filled(64, '3').join(),
      txPosition: 0,
      valueSats: 50000,
      height: 1,
    );

    final result = LegacyTransactionFinalizer.finalize(
      wif: wif,
      inputs: [input],
      sourceScriptPubKey: sourceScript,
      recipientScriptPubKey: recipient.scriptPubKey,
      satsPerVbyte: 2,
    );

    expect(result.changeSats, 0);
    expect(result.feeSats, greaterThanOrEqualTo(result.signed.vbytes * 2));
    expect(result.sendSats + result.feeSats, 50000);
  });

  test('partial finalization preserves requested amount and returns change', () {
    final wallet = BitcoinAddressDeriver().deriveFromWif(wif);
    final sourceScript = AddressScript.p2pkh(wallet.publicKeyHash);
    final recipient = RecipientAddressParser.parse(
      '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH',
    );
    final input = Utxo(
      txHash: List.filled(64, '4').join(),
      txPosition: 1,
      valueSats: 100000,
      height: 1,
    );

    final result = LegacyTransactionFinalizer.finalize(
      wif: wif,
      inputs: [input],
      sourceScriptPubKey: sourceScript,
      recipientScriptPubKey: recipient.scriptPubKey,
      requestedSendSats: 25000,
      changeScriptPubKey: sourceScript,
      satsPerVbyte: 1,
    );

    expect(result.sendSats, 25000);
    expect(result.sendSats + result.feeSats + result.changeSats, 100000);
    expect(result.feeSats, greaterThanOrEqualTo(result.signed.vbytes));
    expect(result.changeSats, greaterThan(0));
  });
}
