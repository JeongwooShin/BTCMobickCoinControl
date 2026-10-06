import 'package:btcmobick_coin_control/wallet/recipient_address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses canonical P2PKH address', () {
    final r = RecipientAddressParser.parse(
      '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH',
    );
    expect(r.type, RecipientType.p2pkh);
    expect(r.scriptPubKey.length, 25);
  });

  test('rejects P2PKH checksum mutation', () {
    expect(
      () => RecipientAddressParser.parse(
        '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMJ',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('parses canonical native SegWit P2WPKH address', () {
    final r = RecipientAddressParser.parse(
      'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4',
    );
    expect(r.type, RecipientType.p2wpkh);
    expect(r.scriptPubKey.length, 22);
  });

  test('rejects Bech32 checksum mutation', () {
    expect(
      () => RecipientAddressParser.parse(
        'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t5',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
