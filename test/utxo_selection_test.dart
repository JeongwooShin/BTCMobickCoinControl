import 'package:btcmobick_coin_control/domain/utxo.dart';
import 'package:btcmobick_coin_control/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UTXO selection totals selected coins', (tester) async {
    final utxos = [
      const Utxo(txHash: '00' * 32, txPosition: 0, valueSats: 10000, height: 1),
      const Utxo(txHash: '11' * 32, txPosition: 0, valueSats: 20000, height: 1),
    ];
    await tester.pumpWidget(MobickCoinControlAppForTest(
      child: UtxoScreen(
        korean: true,
        legacyAddress: '1Test',
        segwitAddress: 'bc1test',
        legacy: utxos,
        segwit: const [],
      ),
    ));
    expect(find.textContaining('0.00000000 BMB'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();
    expect(find.textContaining('0.00010000 BMB'), findsWidgets);
  });
}

class MobickCoinControlAppForTest extends StatelessWidget {
  const MobickCoinControlAppForTest({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => MaterialApp(home: child);
}
