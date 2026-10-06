import 'package:btcmobick_coin_control/domain/utxo.dart';
import 'package:btcmobick_coin_control/wallet/address_script.dart';
import 'package:btcmobick_coin_control/wallet/bitcoin_address_deriver.dart';
import 'package:btcmobick_coin_control/wallet/legacy_transaction_signer.dart';
import 'package:btcmobick_coin_control/wallet/segwit_transaction_finalizer.dart';
import 'package:btcmobick_coin_control/wallet/segwit_transaction_signer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testWif =
      'KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn';

  test('Native SegWit P2WPKH signs witness transaction deterministically', () {
    final wallet = BitcoinAddressDeriver().deriveFromWif(testWif);
    final input = Utxo(
      txHash: List<String>.filled(32, '11').join(),
      txPosition: 0,
      valueSats: 50000,
      height: 1,
    );

    final signed = SegwitTransactionSigner.signP2wpkh(
      wif: testWif,
      inputs: [input],
      sourceScriptCode: AddressScript.p2pkh(wallet.publicKeyHash),
      outputs: [
        LegacyOutput(
          valueSats: 49000,
          scriptPubKey: AddressScript.p2wpkh(wallet.publicKeyHash),
        ),
      ],
    );

    expect(signed.hex.startsWith('02000000000101'), isTrue);
    expect(signed.hex.endsWith('00000000'), isTrue);
    expect(signed.txid.length, 64);
    expect(signed.wtxid.length, 64);
    expect(signed.txid, isNot(signed.wtxid));
    expect(signed.vbytes, lessThan(signed.bytes.length));
    expect(signed.weight, greaterThan(0));

    final signedAgain = SegwitTransactionSigner.signP2wpkh(
      wif: testWif,
      inputs: [input],
      sourceScriptCode: AddressScript.p2pkh(wallet.publicKeyHash),
      outputs: [
        LegacyOutput(
          valueSats: 49000,
          scriptPubKey: AddressScript.p2wpkh(wallet.publicKeyHash),
        ),
      ],
    );
    expect(signedAgain.hex, signed.hex);
    expect(signedAgain.txid, signed.txid);
  });

  test('SegWit finalizer pays at least requested sat/vB and preserves value', () {
    final wallet = BitcoinAddressDeriver().deriveFromWif(testWif);
    final inputs = [
      Utxo(
        txHash: List<String>.filled(32, '22').join(),
        txPosition: 1,
        valueSats: 100000,
        height: 1,
      ),
    ];

    final finalized = SegwitTransactionFinalizer.finalize(
      wif: testWif,
      inputs: inputs,
      sourceScriptCode: AddressScript.p2pkh(wallet.publicKeyHash),
      recipientScriptPubKey: AddressScript.p2wpkh(wallet.publicKeyHash),
      requestedSendSats: 50000,
      changeScriptPubKey: AddressScript.p2wpkh(wallet.publicKeyHash),
      satsPerVbyte: 2,
    );

    expect(
      finalized.sendSats + finalized.feeSats + finalized.changeSats,
      100000,
    );
    expect(finalized.feeSats, greaterThanOrEqualTo(finalized.signed.vbytes * 2));
    expect(finalized.changeSats, greaterThan(0));
  });
}
