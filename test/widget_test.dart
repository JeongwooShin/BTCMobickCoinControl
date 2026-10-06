import 'package:btcmobick_coin_control/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Korean wallet import screen is the default',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MobickCoinControlApp());

    expect(find.text('BTCMobick Coin Control'), findsOneWidget);
    expect(find.text('지갑 열기'), findsOneWidget);
    expect(find.text('WIF 개인키'), findsOneWidget);
    expect(find.text('계속'), findsOneWidget);
    expect(find.textContaining('트랜잭션 서명과 브로드캐스트는 비활성화'),
        findsOneWidget);
  });

  testWidgets('empty WIF is rejected locally in Korean',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MobickCoinControlApp());

    await tester.tap(find.text('계속'));
    await tester.pump();

    expect(find.text('WIF 개인키를 입력하세요.'), findsOneWidget);
  });

  testWidgets('language can switch to English', (WidgetTester tester) async {
    await tester.pumpWidget(const MobickCoinControlApp());

    await tester.tap(find.text('한국어').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Open your wallet'), findsOneWidget);
    expect(find.text('WIF private key'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
