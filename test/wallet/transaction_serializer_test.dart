import 'dart:typed_data';
import 'package:btcmobick_coin_control/domain/utxo.dart';
import 'package:btcmobick_coin_control/wallet/transaction_serializer.dart';
import 'package:flutter_test/flutter_test.dart';
void main(){
 test('serializes only selected inputs into unsigned MAX transaction',(){
  final inputs=[
   Utxo(txHash:List.filled(64,'0').join(),txPosition:1,valueSats:10000,height:1),
   Utxo(txHash:List.filled(64,'1').join(),txPosition:2,valueSats:20000,height:1),
  ];
  final tx=TransactionSerializer.legacyUnsigned(inputs:inputs,outputValueSats:29660,outputScript:Uint8List.fromList([0x51]));
  expect(tx.hex.startsWith('0100000002'),isTrue);
  expect(tx.hex.contains(List.filled(64,'0').join()),isTrue);
  expect(tx.hex.contains(List.filled(64,'1').join()),isTrue);
  expect(tx.hex.endsWith('00000000'),isTrue);
 });
 test('partial spend serializes recipient and change outputs',(){
  final input=[Utxo(txHash:List.filled(64,'2').join(),txPosition:0,valueSats:50000,height:1)];
  final tx=TransactionSerializer.legacyUnsigned(inputs:input,outputValueSats:20000,outputScript:Uint8List.fromList([0x51]),changeValueSats:29774,changeScript:Uint8List.fromList([0x52]));
  expect(tx.hex.startsWith('0100000001'),isTrue);
  expect(tx.hex.contains('0251'),isTrue);
  expect(tx.hex.contains('0152'),isTrue);
 });
}
