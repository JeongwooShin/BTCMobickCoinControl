import 'dart:typed_data';
import '../domain/utxo.dart';
import 'legacy_signer.dart';

class LegacySighash {
  static Uint8List sighashAll({
    required List<Utxo> inputs,
    required int signingIndex,
    required Uint8List sourceScriptPubKey,
    required List<({int valueSats, Uint8List scriptPubKey})> outputs,
  }) {
    if (signingIndex < 0 || signingIndex >= inputs.length) {
      throw const RangeError('Invalid signing input index.');
    }
    final out=<int>[];
    _u32(out,1); _varInt(out,inputs.length);
    for(var i=0;i<inputs.length;i++){
      out.addAll(_hex(inputs[i].txHash).reversed);
      _u32(out,inputs[i].txPosition);
      final script=i==signingIndex ? sourceScriptPubKey : Uint8List(0);
      _varInt(out,script.length); out.addAll(script);
      _u32(out,0xffffffff);
    }
    _varInt(out,outputs.length);
    for(final output in outputs){
      _u64(out,output.valueSats); _varInt(out,output.scriptPubKey.length); out.addAll(output.scriptPubKey);
    }
    _u32(out,0); _u32(out,1); // locktime + SIGHASH_ALL as LE u32
    return LegacySigner.doubleSha256(out);
  }

  static List<int> _hex(String s)=>List.generate(32,(i)=>int.parse(s.substring(i*2,i*2+2),radix:16));
  static void _u32(List<int> o,int v){for(var i=0;i<4;i++){o.add((v>>(8*i))&0xff);}}
  static void _u64(List<int> o,int v){var n=BigInt.from(v);for(var i=0;i<8;i++){o.add((n&BigInt.from(255)).toInt());n>>=8;}}
  static void _varInt(List<int> o,int v){if(v<0xfd){o.add(v);return;}throw const FormatException('Large varint not implemented yet.');}
}
