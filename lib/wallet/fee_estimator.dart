enum InputScriptType { p2pkh, p2wpkh }

class FeeQuote {
  const FeeQuote({required this.vbytes, required this.feeSats});
  final int vbytes;
  final int feeSats;
}

class FeeEstimator {
  /// Conservative pre-sign estimate for simple P2PKH/P2WPKH spends.
  /// Exact fee is recalculated from the signed transaction before broadcast.
  static FeeQuote estimate({
    required List<InputScriptType> inputs,
    required int outputCount,
    required int satsPerVbyte,
  }) {
    if (inputs.isEmpty || outputCount <= 0 || satsPerVbyte <= 0) {
      throw const FormatException('Invalid fee estimate arguments.');
    }
    var vbytes = 10 + (outputCount * 34);
    for (final type in inputs) {
      vbytes += switch (type) {
        InputScriptType.p2pkh => 148,
        InputScriptType.p2wpkh => 69,
      };
    }
    return FeeQuote(vbytes: vbytes, feeSats: vbytes * satsPerVbyte);
  }
}
