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
      throw const FormatException('Bech32 recipient parsing is not enabled yet.');
    }
    throw const FormatException('Unsupported recipient address.');
  }
}
