import 'dart:typed_data';

import 'package:btcmobick_coin_control/domain/utxo.dart';
import 'package:btcmobick_coin_control/wallet/address_script.dart';
import 'package:btcmobick_coin_control/wallet/bitcoin_address_deriver.dart';
import 'package:btcmobick_coin_control/wallet/legacy_transaction_signer.dart';
import 'package:btcmobick_coin_control/wallet/recipient_address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const wifPartA = 'KwDiBf89QgGbjEhKnhXJuH7LrciVr';
  const wifPartB = 'Zi3qYjgd9M7rFU73sVHnoWn';
  const wif = wifPartA + wifPartB;

  test('signer is deterministic and uses version 2', () {
    final wallet = BitcoinAddressDeriver().deriveFromWif(wif);
    final sourceScript = AddressScript.p2pkh(wallet.publicKeyHash);
    final recipient = RecipientAddressParser.parse(
      '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH',
    );
    final input = Utxo(
      txHash: List.filled(64, '1').join(),
      txPosition: 0,
      valueSats: 50000,
      height: 1,
    );

    SignedLegacyTransaction build(int value) => LegacyTransactionSigner.sign(
          wif: wif,
          inputs: [input],
          sourceScriptPubKey: sourceScript,
          outputs: [
            LegacyOutput(
              valueSats: value,
              scriptPubKey: recipient.scriptPubKey,
            ),
          ],
        );

    final a = build(49000);
    final b = build(49000);
    expect(a.hex, b.hex);
    expect(a.txid, b.txid);
    expect(a.hex.startsWith('0200000001'), isTrue);
    expect(a.vbytes, 191);

    const expectedTxid =
        '7c96cec9eab2b7f86133d5528f98279d1af0415b991dae56d6f533060eab8bbf';
    expect(a.txid, expectedTxid);

    final pubHex = wallet.compressedPublicKey
        .map((v) => v.toRadixString(16).padLeft(2, '0'))
        .join();
    expect(a.hex.contains(pubHex), isTrue);
    expect(build(48000).hex, isNot(a.hex));
  });

  test('rejects empty transaction', () {
    expect(
      () => LegacyTransactionSigner.sign(
        wif: wif,
        inputs: const [],
        sourceScriptPubKey: Uint8List(0),
        outputs: const [],
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
