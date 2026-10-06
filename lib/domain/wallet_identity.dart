enum AddressType { p2pkh, p2wpkh }

class WalletIdentity {
  const WalletIdentity({
    required this.address,
    required this.compressed,
    required this.addressType,
  });

  final String address;
  final bool compressed;
  final AddressType addressType;
}
