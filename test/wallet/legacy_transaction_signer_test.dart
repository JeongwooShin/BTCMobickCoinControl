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

  test('matches independent scalar-one legacy fixture byte-for-byte', () {
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

    final signed = LegacyTransactionSigner.sign(
      wif: wif,
      inputs: [input],
      sourceScriptPubKey: sourceScript,
      outputs: [
        LegacyOutput(
          valueSats: 49000,
          scriptPubKey: recipient.scriptPubKey,
        ),
      ],
    );

    const expectedHex =
        '01000000011111111111111111111111111111111111111111111111111111111111111111000000006a473044022067b89339519b0212f0354c0be3e486755611c933a0238f14a8eb94d9436fc5be0220672589c233bb396922b54ef53587889d8926aaf6a1158e097a3f6758c97c808201210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798ffffffff0168bf0000000000001976a914751e76e8199196d454941c45d1b3a323f1433bd688ac00000000';
    const expectedTxid =
        '40ca317eb28db86c42fb2d93fbe4270e0a7e48166f6d3a41ecb01a3078d70e45';

    expect(signed.hex, expectedHex);
    expect(signed.txid, expectedTxid);
    expect(signed.vbytes, 191);
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
