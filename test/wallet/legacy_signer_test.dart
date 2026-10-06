import 'dart:typed_data';
import 'package:btcmobick_coin_control/wallet/legacy_signer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ECDSA signing is deterministic and appends SIGHASH_ALL', () {
    final key=Uint8List(32)..[31]=1;
    final digest=LegacySigner.doubleSha256([1,2,3,4]);
    final a=LegacySigner.signDigest(privateKey:key,digest32:digest);
    final b=LegacySigner.signDigest(privateKey:key,digest32:digest);
    expect(a.withSighash,lastByteEquals(0x01));
    expect(a.withSighash,b.withSighash);
    expect(a.der.first,0x30);
  });
}

Matcher lastByteEquals(int value) => predicate<Uint8List>(
  (bytes) => bytes.isNotEmpty && bytes.last == value,
  'last byte equals $value',
);
