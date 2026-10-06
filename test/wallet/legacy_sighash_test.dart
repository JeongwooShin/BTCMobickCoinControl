import 'dart:typed_data';
import 'package:btcmobick_coin_control/domain/utxo.dart';
import 'package:btcmobick_coin_control/wallet/legacy_sighash.dart';
import 'package:flutter_test/flutter_test.dart';

void main(){
 test('SIGHASH_ALL digest changes with signing input index',(){
  final inputs=[
   Utxo(txHash:List.filled(64,'1').join(),txPosition:0,valueSats:10000,height:1),
   Utxo(txHash:List.filled(64,'2').join(),txPosition:1,valueSats:20000,height:1),
  ];
  final script=Uint8List.fromList([0x76,0xa9,0x14,...List.filled(20,1),0x88,0xac]);
  final outputs=[(valueSats:29000,scriptPubKey:Uint8List.fromList([0x51]))];
  final a=LegacySighash.sighashAll(inputs:inputs,signingIndex:0,sourceScriptPubKey:script,outputs:outputs);
  final b=LegacySighash.sighashAll(inputs:inputs,signingIndex:1,sourceScriptPubKey:script,outputs:outputs);
  expect(a.length,32); expect(b.length,32); expect(a, isNot(equals(b)));
 });
}
