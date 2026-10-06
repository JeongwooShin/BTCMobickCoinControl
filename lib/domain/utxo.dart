class Utxo {
  const Utxo({required this.txHash, required this.txPosition, required this.valueSats, required this.height});
  final String txHash; final int txPosition; final int valueSats; final int height;
  double get coinValue => valueSats / 100000000.0;
  factory Utxo.fromElectrumJson(Map<String,dynamic> json) {
    final h=json['tx_hash'], p=json['tx_pos'], v=json['value'], ht=json['height'];
    if(h is! String||p is! int||v is! int||ht is! int||h.length!=64||p<0||v<0||ht<0) {
      throw const FormatException('Malformed ElectrumX UTXO response.');
    }
    return Utxo(txHash:h,txPosition:p,valueSats:v,height:ht);
  }
}