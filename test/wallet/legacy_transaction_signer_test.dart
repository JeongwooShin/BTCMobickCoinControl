import 'dart:typed_data';

import 'package:btcmobick_coin_control/domain/utxo.dart';
import 'package:btcmobick_coin_control/wallet/address_script.dart';
import 'package:btcmobick_coin_control/wallet/bitcoin_address_deriver.dart';
import 'package:btcmobick_coin_control/wallet/legacy_transaction_signer.dart';
import 'package:btcmobick_coin_control/wallet/recipient_address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const wif =
      'KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn';

  test('signs a deterministic legacy P2PKH transaction', () {
    final wallet = BitcoinAddressDeriver().deriveFromWif(wif);
    final sourceScript = AddressScript.p2pkh(wallet.publicKeyHash);
    final recipient = RecipientAddressParser.parse(
      '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH',
    );
    final inputs = [
      Utxo(
        txHash: List.filled(64, '1').join(),
        txPosition: 0,
        valueSats: 50000,
        height: 1,
      ),
    ];

    final a = LegacyTransactionSigner.sign(
      wif: wif,
      inputs: inputs,
      sourceScriptPubKey: sourceScript,
      outputs: [
        LegacyOutput(
          valueSats: 49000,
          scriptPubKey: recipient.scriptPubKey,
        ),
      ],
    );
    final b = LegacyTransactionSigner.sign(
      wif: wif,
      inputs: inputs,
      sourceScriptPubKey: sourceScript,
      outputs: [
        LegacyOutput(
          valueSats: 49000,
          scriptPubKey: recipient.scriptPubKey,
        ),
      ],
    );

    expect(a.hex, b.hex);
    expect(a.txid, b.txid);
    expect(a.txid.length, 64);
    expect(a.vbytes, a.bytes.length);
    expect(a.hex.startsWith('0100000001'), isTrue);

    final pubHex = wallet.compressedPublicKey
        .map((v) => v.toRadixString(16).padLeft(2, '0'))
        .join();
    expect(a.hex.contains(pubHex), isTrue);
  });

  test('signed legacy transaction changes when output changes', () {
    final wallet = BitcoinAddressDeriver().deriveFromWif(wif);
    final sourceScript = AddressScript.p2pkh(wallet.publicKeyHash);
    final recipient = RecipientAddressParser.parse(
      '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH',
    );
    final input = Utxo(
      txHash: List.filled(64, '2').join(),
      txPosition: 1,
      valueSats: 50000,
      height: 1,
    );

    SignedLegacyTransaction build(int value) =>
        LegacyTransactionSigner.sign(
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

    expect(build(49000).hex, isNot(build(48000).hex));
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
