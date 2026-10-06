import 'dart:typed_data';
import '../domain/utxo.dart';

class UnsignedTransaction {
  const UnsignedTransaction({required this.bytes, required this.hex});
  final Uint8List bytes;
  final String hex;
}

class TransactionSerializer {
  static UnsignedTransaction legacyUnsigned({
    required List<Utxo> inputs,
    required int outputValueSats,
    required Uint8List outputScript,
    int changeValueSats = 0,
    Uint8List? changeScript,
  }) {
    if (inputs.isEmpty || outputValueSats <= 0) throw const FormatException('Invalid transaction values.');
    final out=<int>[];
    _u32(out,1);
    _varInt(out,inputs.length);
    for(final u in inputs){
      final txid=_hex(u.txHash).reversed.toList();
      out.addAll(txid);
      _u32(out,u.txPosition);
      out.add(0); // empty scriptSig before signing
      _u32(out,0xffffffff);
    }
    final hasChange = changeValueSats > 0;
    if (hasChange && changeScript == null) {
      throw const FormatException('Change script is required.');
    }
    out.add(hasChange ? 2 : 1);
    _u64(out,outputValueSats);
    _varInt(out,outputScript.length);
    out.addAll(outputScript);
    if (hasChange) {
      _u64(out,changeValueSats);
      _varInt(out,changeScript!.length);
      out.addAll(changeScript);
    }
    _u32(out,0); // locktime
    final bytes=Uint8List.fromList(out);
    return UnsignedTransaction(bytes:bytes,hex:bytes.map((b)=>b.toRadixString(16).padLeft(2,'0')).join());
  }

  static List<int> _hex(String s) {
    if(s.length!=64) throw const FormatException('Invalid txid.');
    return List.generate(32,(i)=>int.parse(s.substring(i*2,i*2+2),radix:16));
  }
  static void _u32(List<int> o,int v){for(var i=0;i<4;i++){o.add((v>>(8*i))&0xff);}}
  static void _u64(List<int> o,int v){var n=BigInt.from(v);for(var i=0;i<8;i++){o.add((n&BigInt.from(255)).toInt());n>>=8;}}
  static void _varInt(List<int> o,int v){if(v<0xfd){o.add(v);return;}throw const FormatException('Large varint not implemented yet.');}
}
