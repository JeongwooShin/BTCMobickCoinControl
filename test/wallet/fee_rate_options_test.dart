import 'package:btcmobick_coin_control/wallet/fee_rate_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds three fee tiers from minimum', () {
    final rates = FeeRateOptions.fromNetworkMinimum(2);
    expect(rates.economy, 2);
    expect(rates.normal, 4);
    expect(rates.fast, 8);
    expect(rates.acceptsCustom(1), isFalse);
    expect(rates.acceptsCustom(2), isTrue);
  });

  test('minimum never falls below one', () {
    expect(FeeRateOptions.fromNetworkMinimum(0).minimum, 1);
  });
}
