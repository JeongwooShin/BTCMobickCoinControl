import 'package:btcmobick_coin_control/wallet/bitcoin_address_deriver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scalar one produces canonical compressed public key and addresses', () {
    const wif =
        'KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn';

    final wallet = BitcoinAddressDeriver().deriveFromWif(wif);

    expect(
      wallet.compressedPublicKey
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
      '0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798',
    );
    expect(wallet.p2pkhAddress, '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH');
    expect(wallet.p2wpkhAddress, 'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kygt080');
  });
}
