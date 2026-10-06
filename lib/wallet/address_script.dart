import 'dart:typed_data';
import 'package:crypto/crypto.dart';
class AddressScript {
 static Uint8List p2pkh(Uint8List h){if(h.length!=20)throw const FormatException('P2PKH hash must be 20 bytes.');return Uint8List.fromList([0x76,0xa9,0x14,...h,0x88,0xac]);}
 static Uint8List p2wpkh(Uint8List h){if(h.length!=20)throw const FormatException('P2WPKH hash must be 20 bytes.');return Uint8List.fromList([0x00,0x14,...h]);}
 static String electrumScriptHash(Uint8List s)=>sha256.convert(s).bytes.reversed.map((b)=>b.toRadixString(16).padLeft(2,'0')).join();
}