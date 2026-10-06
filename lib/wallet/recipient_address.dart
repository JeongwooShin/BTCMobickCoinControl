import 'dart:typed_data';
import 'address_script.dart';
import 'base58check.dart';

enum RecipientType { p2pkh, p2sh, p2wpkh }

class RecipientAddress {
  const RecipientAddress({required this.address, required this.type, required this.scriptPubKey});
  final String address;
  final RecipientType type;
  final Uint8List scriptPubKey;
}

class RecipientAddressParser {
  static RecipientAddress parse(String input) {
    final address = input.trim();
    if (address.startsWith('1') || address.startsWith('3')) {
      final payload = Base58Check.decode(address);
      if (payload.length != 21) throw const FormatException('Invalid address payload length.');
      final version = payload[0];
      final hash = payload.sublist(1);
      if (version == 0x00) {
        return RecipientAddress(address: address,type: RecipientType.p2pkh,scriptPubKey: AddressScript.p2pkh(hash));
      }
      if (version == 0x05) {
        return RecipientAddress(address: address,type: RecipientType.p2sh,scriptPubKey: Uint8List.fromList([0xa9,0x14,...hash,0x87]));
      }
      throw const FormatException('Unsupported mainnet address version.');
    }
    if (address.toLowerCase().startsWith('bc1')) {
      return _parseBech32(address);
    }
    throw const FormatException('Unsupported recipient address.');
  }

  static RecipientAddress _parseBech32(String address) {
    if (address != address.toLowerCase() && address != address.toUpperCase()) {
      throw const FormatException('Mixed-case Bech32 address.');
    }
    final a=address.toLowerCase(); final pos=a.lastIndexOf('1');
    if(pos<1||pos+7>a.length) throw const FormatException('Invalid Bech32 address.');
    final hrp=a.substring(0,pos); if(hrp!='bc') throw const FormatException('Unsupported Bech32 HRP.');
    const alphabet='qpzry9x8gf2tvdw0s3jn54khce6mua7l';
    final values=<int>[];
    for(final ch in a.substring(pos+1).split('')){final v=alphabet.indexOf(ch);if(v<0)throw const FormatException('Invalid Bech32 character.');values.add(v);}
    if(_polymod([...hrp.codeUnits.map((x)=>x>>5),0,...hrp.codeUnits.map((x)=>x&31),...values])!=1) {
      throw const FormatException('Invalid Bech32 checksum.');
    }
    final data=values.sublist(0,values.length-6); if(data.isEmpty||data[0]!=0)throw const FormatException('Only SegWit v0 is supported.');
    final program=_convertBits(data.sublist(1),5,8,false);
    if(program.length!=20)throw const FormatException('Only P2WPKH recipients are supported.');
    final script=Uint8List.fromList([0x00,0x14,...program]);
    return RecipientAddress(address:a,type:RecipientType.p2wpkh,scriptPubKey:script);
  }

  static List<int> _convertBits(List<int> data,int from,int to,bool pad){var acc=0,bits=0;final out=<int>[];final max=(1<<to)-1;for(final v in data){if(v<0||(v>>from)!=0)throw const FormatException('Invalid Bech32 data.');acc=(acc<<from)|v;bits+=from;while(bits>=to){bits-=to;out.add((acc>>bits)&max);}}if(pad){if(bits>0)out.add((acc<<(to-bits))&max);}else if(bits>=from||((acc<<(to-bits))&max)!=0){throw const FormatException('Invalid Bech32 padding.');}return out;}
  static int _polymod(List<int> values){const g=[0x3b6a57b2,0x26508e6d,0x1ea119fa,0x3d4233dd,0x2a1462b3];var chk=1;for(final v in values){final top=chk>>25;chk=((chk&0x1ffffff)<<5)^v;for(var i=0;i<5;i++){if(((top>>i)&1)!=0)chk^=g[i];}}return chk;}
}
