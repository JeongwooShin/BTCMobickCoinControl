import 'package:btcmobick_coin_control/wallet/wif_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final decoder = WifDecoder();

  test('rejects empty WIF', () {
    expect(() => decoder.decodeStructure(''), throwsA(isA<WifFormatException>()));
  });

  test('rejects non-Base58 characters before any crypto work', () {
    expect(
      () => decoder.decodeStructure('O0Il-not-base58'),
      throwsA(isA<WifFormatException>()),
    );
  });

  test('rejects structurally invalid Base58 input', () {
    expect(
      () => decoder.decodeStructure('1111111111111111111111111111111111111'),
      throwsA(isA<WifFormatException>()),
    );
  });
}
