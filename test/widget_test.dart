import 'package:btcmobick_coin_control/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wallet import screen renders without exposing a key',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MobickCoinControlApp());

    expect(find.text('BTCMobick Coin Control'), findsOneWidget);
    expect(find.text('Open your wallet'), findsOneWidget);
    expect(find.text('WIF private key'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.textContaining('signing and broadcasting are disabled'),
        findsOneWidget);
  });

  testWidgets('empty WIF is rejected locally', (WidgetTester tester) async {
    await tester.pumpWidget(const MobickCoinControlApp());

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Enter a WIF private key first.'), findsOneWidget);
  });
}
