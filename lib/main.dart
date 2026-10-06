import 'dart:io';

import 'package:flutter/material.dart';

import 'network/electrum_client.dart';
import 'wallet/address_script.dart';
import 'wallet/bitcoin_address_deriver.dart';
import 'wallet/wif_decoder.dart';

void main() {
  runApp(const MobickCoinControlApp());
}

enum AppLanguage { korean, english }

class MobickCoinControlApp extends StatefulWidget {
  const MobickCoinControlApp({super.key});

  @override
  State<MobickCoinControlApp> createState() => _MobickCoinControlAppState();
}

class _MobickCoinControlAppState extends State<MobickCoinControlApp> {
  AppLanguage _language = AppLanguage.korean;

  void _setLanguage(AppLanguage language) {
    setState(() => _language = language);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BTCMobick Coin Control',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3157D5)),
        useMaterial3: true,
      ),
      home: WalletImportScreen(
        language: _language,
        onLanguageChanged: _setLanguage,
      ),
    );
  }
}

class WalletImportScreen extends StatefulWidget {
  const WalletImportScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  State<WalletImportScreen> createState() => _WalletImportScreenState();
}

class _WalletImportScreenState extends State<WalletImportScreen> {
  final _wifController = TextEditingController();
  bool _obscureWif = true;
  bool _loading = false;

  bool get _ko => widget.language == AppLanguage.korean;

  @override
  void dispose() {
    _wifController.clear();
    _wifController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_loading) return;
    final value = _wifController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ko ? 'WIF 개인키를 입력하세요.' : 'Enter a WIF private key first.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final wallet = BitcoinAddressDeriver().deriveFromWif(value);
      final client = ElectrumClient();
      await client.connect();
      try {
        final legacyHash = AddressScript.electrumScriptHash(
          AddressScript.p2pkh(wallet.publicKeyHash),
        );
        final segwitHash = AddressScript.electrumScriptHash(
          AddressScript.p2wpkh(wallet.publicKeyHash),
        );
        final legacy = await client.listUnspent(legacyHash);
        final segwit = await client.listUnspent(segwitHash);
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UtxoScreen(
              korean: _ko,
              legacyAddress: wallet.p2pkhAddress,
              segwitAddress: wallet.p2wpkhAddress,
              legacy: legacy,
              segwit: segwit,
            ),
          ),
        );
      } finally {
        await client.close();
      }
    } on WifFormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ko ? '개인키 형식 오류: ${error.message}' : 'Private key error: ${error.message}')),
      );
    } on HandshakeException catch (_) {
      if (!mounted) return;
      debugPrint('Mobick TLS handshake failed; no secrets logged.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ko ? 'BTCMobick 보안 연결(TLS) 협상에 실패했습니다.' : 'BTCMobick TLS handshake failed.')),
      );
    } on ElectrumException catch (error) {
      if (!mounted) return;
      debugPrint('ElectrumX failure: ${error.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ko ? 'BTCMobick 네트워크 연결 실패: ${error.message}' : 'BTCMobick network error: ${error.message}')),
      );
    } catch (error, stack) {
      if (!mounted) return;
      debugPrint('Wallet lookup failure (no secrets logged): ${error.runtimeType}');
      debugPrintStack(stackTrace: stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ko ? 'UTXO 조회 중 오류가 발생했습니다.' : 'An error occurred while looking up UTXOs.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BTCMobick Coin Control'),
        actions: [
          PopupMenuButton<AppLanguage>(
            tooltip: _ko ? '언어 선택' : 'Select language',
            initialValue: widget.language,
            onSelected: widget.onLanguageChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: AppLanguage.korean,
                child: Text('한국어'),
              ),
              PopupMenuItem(
                value: AppLanguage.english,
                child: Text('English'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: Text(_ko ? '한국어' : 'EN')),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              _ko ? '지갑 열기' : 'Open your wallet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _ko
                  ? '개인키는 이 기기 안에서만 처리됩니다. 현재 개발 버전은 개인키를 저장하거나 외부로 전송하지 않습니다.'
                  : 'Your private key will be handled locally on this device. '
                      'The first development build does not save or transmit it.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _wifController,
              obscureText: _obscureWif,
              enableSuggestions: false,
              autocorrect: false,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                labelText: _ko ? 'WIF 개인키' : 'WIF private key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscureWif
                      ? (_ko ? '개인키 보기' : 'Show key')
                      : (_ko ? '개인키 숨기기' : 'Hide key'),
                  onPressed: () => setState(() => _obscureWif = !_obscureWif),
                  icon: Icon(
                    _obscureWif ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(_ko ? 'QR 스캔 (다음 단계)' : 'Scan QR (next milestone)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _continue,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_ko ? '계속' : 'Continue'),
            ),
            const SizedBox(height: 24),
            _SecurityNotice(korean: _ko),
          ],
        ),
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice({required this.korean});

  final bool korean;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                korean
                    ? '개발 버전: 결정론적 테스트가 준비될 때까지 트랜잭션 서명과 브로드캐스트는 비활성화되어 있습니다.'
                    : 'Development build: transaction signing and broadcasting are '
                        'disabled until deterministic tests are in place.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class UtxoScreen extends StatelessWidget {
  const UtxoScreen({super.key, required this.korean, required this.legacyAddress, required this.segwitAddress, required this.legacy, required this.segwit});
  final bool korean;
  final String legacyAddress;
  final String segwitAddress;
  final List<dynamic> legacy;
  final List<dynamic> segwit;

  @override
  Widget build(BuildContext context) {
    final all = [...legacy, ...segwit];
    final total = all.fold<int>(0, (sum, u) => sum + (u.valueSats as int));
    return Scaffold(
      appBar: AppBar(title: Text(korean ? 'UTXO 조회' : 'UTXO lookup')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(korean ? '총 잔액' : 'Total balance', style: Theme.of(context).textTheme.titleMedium),
          Text('${(total / 100000000).toStringAsFixed(8)} BMB', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          _UtxoGroup(title: 'Native SegWit', address: segwitAddress, items: segwit),
          const SizedBox(height: 16),
          _UtxoGroup(title: 'Legacy', address: legacyAddress, items: legacy),
        ],
      ),
    );
  }
}

class _UtxoGroup extends StatelessWidget {
  const _UtxoGroup({required this.title, required this.address, required this.items});
  final String title;
  final String address;
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          SelectableText(address, style: Theme.of(context).textTheme.bodySmall),
          const Divider(height: 24),
          if (items.isEmpty) const Text('No UTXOs')
          else ...items.map((u) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${(u.valueSats / 100000000).toStringAsFixed(8)} BMB'),
            subtitle: Text('${u.txHash.substring(0, 12)}… : ${u.txPosition}'),
          )),
        ]),
      ),
    );
  }
}
