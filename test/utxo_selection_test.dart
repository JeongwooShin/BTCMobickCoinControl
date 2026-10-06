import 'package:btcmobick_coin_control/domain/utxo.dart';
import 'package:btcmobick_coin_control/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UTXO selection totals selected coins', (tester) async {
    final utxos = [
      Utxo(
        txHash: List.filled(32, '00').join(),
        txPosition: 0,
        valueSats: 10000,
        height: 1,
      ),
      Utxo(
        txHash: List.filled(32, '11').join(),
        txPosition: 0,
        valueSats: 20000,
        height: 1,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: UtxoScreen(
          korean: true,
          legacyAddress: '1Test',
          segwitAddress: 'bc1test',
          legacy: utxos,
          segwit: const [],
          sessionWif: 'test-only-wif',
        ),
      ),
    );

    expect(find.textContaining('선택 합계'), findsOneWidget);
    expect(find.textContaining('0.00000000 BMB'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();

    expect(find.textContaining('0.00010000 BMB'), findsWidgets);
    expect(find.textContaining('(1 UTXO)'), findsOneWidget);
  });
}
