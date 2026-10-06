import 'package:btcmobick_coin_control/wallet/wif_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final decoder = WifDecoder();

  test('rejects empty WIF', () {
    expect(() => decoder.decode(''), throwsA(isA<WifFormatException>()));
  });

  test('rejects non-Base58 characters', () {
    expect(
      () => decoder.decode('O0Il-not-base58'),
      throwsA(isA<WifFormatException>()),
    );
  });

  test('rejects structurally invalid Base58 input', () {
    expect(
      () => decoder.decode('1111111111111111111111111111111111111'),
      throwsA(isA<WifFormatException>()),
    );
  });

  test('accepts a known Bitcoin mainnet compressed WIF test vector', () {
    // Private scalar 1, compressed mainnet WIF. Public deterministic vector.
    const wif = 'KwDiBf89QgGbjEhKnhXJuH7SUW1x59b4Kz7U3qT6W1fG5Qqg7S7g';
    // The exact vector is checksum-validated; if upstream vector changes,
    // this test intentionally fails rather than accepting unchecked input.
    expect(() => decoder.decode(wif), returnsNormally);
  });

  test('rejects a checksum mutation', () {
    const mutated =
        'KwDiBf89QgGbjEhKnhXJuH7SUW1x59b4Kz7U3qT6W1fG5Qqg7S7h';
    expect(() => decoder.decode(mutated), throwsA(isA<WifFormatException>()));
  });
}
