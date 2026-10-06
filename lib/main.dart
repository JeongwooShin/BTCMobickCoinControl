import 'package:flutter/material.dart';

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

  bool get _ko => widget.language == AppLanguage.korean;

  @override
  void dispose() {
    _wifController.clear();
    _wifController.dispose();
    super.dispose();
  }

  void _continue() {
    final value = _wifController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ko ? 'WIF 개인키를 입력하세요.' : 'Enter a WIF private key first.')),
      );
      return;
    }

    // Deliberately do not log or persist the WIF.
    // WIF validation/address derivation is the next implementation milestone.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _ko
              ? '아직 지갑 엔진이 활성화되지 않았습니다. 개인키는 전송되지 않았습니다.'
              : 'Wallet engine is not enabled yet. No key was transmitted.',
        ),
      ),
    );
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
              onPressed: _continue,
              child: Text(_ko ? '계속' : 'Continue'),
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
