class FeeRateOptions {
  const FeeRateOptions({
    required this.minimum,
    required this.economy,
    required this.normal,
    required this.fast,
  });

  final int minimum;
  final int economy;
  final int normal;
  final int fast;

  factory FeeRateOptions.fromNetworkMinimum(int minimum) {
    final min = minimum < 1 ? 1 : minimum;
    return FeeRateOptions(
      minimum: min,
      economy: min,
      normal: min * 2,
      fast: min * 4,
    );
  }

  bool acceptsCustom(int value) => value >= minimum;
}
