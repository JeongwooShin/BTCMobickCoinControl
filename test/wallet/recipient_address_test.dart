import 'package:btcmobick_coin_control/wallet/recipient_address.dart';
import 'package:flutter_test/flutter_test.dart';
void main(){
 test('parses canonical P2PKH address',(){
  final r=RecipientAddressParser.parse('1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH');
  expect(r.type,RecipientType.p2pkh); expect(r.scriptPubKey.length,25);
 });
 test('rejects checksum mutation',(){
  expect(()=>RecipientAddressParser.parse('1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMJ'),throwsA(isA<FormatException>()));
 });
}
