import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'domain/utxo.dart';
import 'network/electrum_client.dart';
import 'qr/qr_scan_screen.dart';
import 'security/app_lock_gate.dart';
import 'security/app_lock_service.dart';
import 'settings/security_settings_screen.dart';
import 'wallet/address_script.dart';
import 'wallet/bitcoin_address_deriver.dart';
import 'wallet/wif_decoder.dart';
import 'wallet/fee_estimator.dart';
import 'wallet/fee_rate_options.dart';
import 'wallet/recipient_address.dart';
import 'wallet/send_draft.dart';
import 'wallet/legacy_transaction_finalizer.dart';
import 'wallet/segwit_transaction_finalizer.dart';

void main() {
  runApp(const MobickCoinControlApp());
}

enum AppLanguage { korean, english }

class MobickCoinControlApp extends StatefulWidget {
  const MobickCoinControlApp({super.key, this.enableSecurity = true});

  final bool enableSecurity;

  @override
  State<MobickCoinControlApp> createState() => _MobickCoinControlAppState();
}

class _MobickCoinControlAppState extends State<MobickCoinControlApp> {
  AppLanguage _language = AppLanguage.korean;
  late final AppLockService _securityService = AppLockService();

  void _setLanguage(AppLanguage language) {
    setState(() => _language = language);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UTXO Control',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3157D5)),
        useMaterial3: true,
      ),
      builder: widget.enableSecurity
          ? (context, child) => AppLockGate(
                service: _securityService,
                child: child ?? const SizedBox.shrink(),
              )
          : null,
      home: WalletImportScreen(
        language: _language,
        onLanguageChanged: _setLanguage,
        securityService: _securityService,
      ),
    );
  }
}

class WalletImportScreen extends StatefulWidget {
  const WalletImportScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required this.securityService,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final AppLockService securityService;

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
              sessionWif: value,
              securityService: widget.securityService,
            ),
          ),
        );
        _wifController.clear();
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

  Future<void> _scanWifQr() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrScanScreen(
          korean: _ko,
          title: _ko ? 'WIF QR 스캔' : 'Scan WIF QR',
        ),
      ),
    );
    if (!mounted || scanned == null) return;

    try {
      WifDecoder().decode(scanned);
      _wifController.text = scanned;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _ko
                ? 'WIF 개인키를 QR에서 읽었습니다. 계속을 눌러 UTXO를 조회하세요.'
                : 'WIF private key scanned. Tap Continue to look up UTXOs.',
          ),
        ),
      );
    } on WifFormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _ko
                ? '이 QR은 유효한 WIF 개인키가 아닙니다.'
                : 'This QR code is not a valid WIF private key.',
          ),
        ),
      );
    }
  }

  // Private-key persistence is intentionally disabled.
  // TODO(wallet-persistence): if restored, replace the former single-WIF slot
  // with a multi-wallet picker backed by independently encrypted records.
  // The picker should display public addresses/labels only.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UTXO Control'),
        actions: [
          IconButton(
            tooltip: _ko ? '보안 설정' : 'Security settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SecuritySettingsScreen(
                    service: widget.securityService,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
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
                  ? '개인키는 이 기기 안에서만 처리되며 저장하거나 외부로 전송하지 않습니다.'
                  : 'Your private key will be handled locally on this device. '
                      'The first development build does not save or transmit it.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _wifController,
              obscureText: _obscureWif,
              enableSuggestions: false,
              autocorrect: false,
              enableIMEPersonalizedLearning: false,
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
              onPressed: _loading ? null : _scanWifQr,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(_ko ? 'WIF QR 스캔' : 'Scan WIF QR'),
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
                    ? '개인키는 기본적으로 저장하지 않습니다. 저장 기능을 켜면 기기 보안 저장소에 암호화하여 보관되지만, 침해된 기기에서는 위험을 완전히 제거할 수 없습니다. 가급적 이 앱은 필요할 때만 개인키를 입력해 UTXO별 전송에 사용하고, 개인키는 저장하지 않는 것을 권장합니다.'
                    : 'Private keys are not stored by default. Optional storage uses the device secure store, but a compromised device can never be made risk-free. Prefer entering a private key only when you need UTXO-level transfers, and avoid storing private keys in the app.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class UtxoScreen extends StatefulWidget {
  const UtxoScreen({super.key, required this.korean, required this.legacyAddress, required this.segwitAddress, required this.legacy, required this.segwit, required this.sessionWif, required this.securityService});
  final bool korean;
  final String legacyAddress;
  final String segwitAddress;
  final List<Utxo> legacy;
  final List<Utxo> segwit;
  final String sessionWif;
  final AppLockService securityService;

  @override
  State<UtxoScreen> createState() => _UtxoScreenState();
}

class _UtxoScreenState extends State<UtxoScreen> {
  final Set<String> _selected = <String>{};

  String _key(Utxo u) => '${u.txHash}:${u.txPosition}';

  List<Utxo> get _all => [...widget.legacy, ...widget.segwit];

  int get _total => _all.fold(0, (sum, u) => sum + u.valueSats);

  int get _selectedTotal => _all
      .where((u) => _selected.contains(_key(u)))
      .fold(0, (sum, u) => sum + u.valueSats);

  void _toggle(Utxo u, bool? value) {
    setState(() {
      if (value == true) {
        _selected.add(_key(u));
      } else {
        _selected.remove(_key(u));
      }
    });
  }

  void _selectAll() => setState(() {
        _selected
          ..clear()
          ..addAll(_all.map(_key));
      });

  void _clearAll() => setState(_selected.clear);

  void _preview() {
    if (_selected.isEmpty) return;

    final selectedLegacy = widget.legacy
        .where((u) => _selected.contains(_key(u)))
        .toList(growable: false);
    final selectedSegwit = widget.segwit
        .where((u) => _selected.contains(_key(u)))
        .toList(growable: false);

    if (selectedLegacy.isNotEmpty && selectedSegwit.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.korean
                ? '현재는 Legacy와 Native SegWit UTXO를 한 트랜잭션에 섞어 쓰지 않습니다. 한 종류만 선택하세요.'
                : 'Legacy and Native SegWit inputs cannot yet be mixed in one transaction. Select one type only.',
          ),
        ),
      );
      return;
    }

    final isSegwit = selectedSegwit.isNotEmpty;
    final selected = isSegwit ? selectedSegwit : selectedLegacy;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SendDraftScreen(
          korean: widget.korean,
          selected: selected,
          isSegwitSource: isSegwit,
          legacyAddress: widget.legacyAddress,
          segwitAddress: widget.segwitAddress,
          sessionWif: widget.sessionWif,
          securityService: widget.securityService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ko = widget.korean;
    return Scaffold(
      appBar: AppBar(title: Text(ko ? 'UTXO 선택' : 'Select UTXOs')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(ko ? '총 잔액' : 'Total balance',
              style: Theme.of(context).textTheme.titleMedium),
          Text('${(_total / 100000000).toStringAsFixed(8)} BMB',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '${ko ? '선택 합계' : 'Selected'}: '
            '${(_selectedTotal / 100000000).toStringAsFixed(8)} BMB '
            '(${_selected.length} UTXO)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(children: [
            TextButton(onPressed: _all.isEmpty ? null : _selectAll, child: Text(ko ? '전체 선택' : 'Select all')),
            TextButton(onPressed: _selected.isEmpty ? null : _clearAll, child: Text(ko ? '선택 해제' : 'Clear')),
          ]),
          const SizedBox(height: 8),
          _SelectableUtxoGroup(
            title: 'Native SegWit',
            address: widget.segwitAddress,
            items: widget.segwit,
            korean: ko,
            selected: _selected,
            keyFor: _key,
            onChanged: _toggle,
          ),
          const SizedBox(height: 16),
          _SelectableUtxoGroup(
            title: 'Legacy',
            address: widget.legacyAddress,
            items: widget.legacy,
            korean: ko,
            selected: _selected,
            keyFor: _key,
            onChanged: _toggle,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _selected.isEmpty ? null : _preview,
            icon: const Icon(Icons.arrow_forward),
            label: Text(ko ? '전송 초안 만들기' : 'Create send draft'),
          ),
        ],
      ),
    );
  }
}

class _SelectableUtxoGroup extends StatelessWidget {
  const _SelectableUtxoGroup({
    required this.title,
    required this.address,
    required this.items,
    required this.korean,
    required this.selected,
    required this.keyFor,
    required this.onChanged,
  });

  final String title;
  final String address;
  final List<Utxo> items;
  final bool korean;
  final Set<String> selected;
  final String Function(Utxo) keyFor;
  final void Function(Utxo, bool?) onChanged;

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
          if (items.isEmpty)
            Text(korean ? 'UTXO 없음' : 'No UTXOs')
          else
            ...items.map((u) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selected.contains(keyFor(u)),
                  onChanged: (value) => onChanged(u, value),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('${(u.valueSats / 100000000).toStringAsFixed(8)} BMB'),
                  subtitle: Text('${u.txHash.substring(0, 12)}… : ${u.txPosition}'),
                )),
        ]),
      ),
    );
  }
}

enum _FeeChoice { economy, normal, fast, custom }

class SendDraftScreen extends StatefulWidget {
  const SendDraftScreen({super.key, required this.korean, required this.selected, required this.isSegwitSource, required this.legacyAddress, required this.segwitAddress, required this.sessionWif, required this.securityService});
  final bool korean;
  final List<Utxo> selected;
  final bool isSegwitSource;
  final String legacyAddress;
  final String segwitAddress;
  final String sessionWif;
  final AppLockService securityService;

  @override
  State<SendDraftScreen> createState() => _SendDraftScreenState();
}

class _SendDraftScreenState extends State<SendDraftScreen> {
  final _recipient = TextEditingController();
  final _customFee = TextEditingController(text: '1');
  final _amount = TextEditingController();
  bool _maxSpend = true;
  _FeeChoice _choice = _FeeChoice.normal;
  FeeRateOptions _rates = FeeRateOptions.fromNetworkMinimum(1);
  bool _loadingRates = true;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    final client = ElectrumClient();
    try {
      await client.connect();
      final minimum = await client.estimateFeeSatsPerVbyte(targetBlocks: 2);
      if (mounted) setState(() => _rates = FeeRateOptions.fromNetworkMinimum(minimum));
    } catch (_) {
      // Safe fallback remains 1 bick/vB; no wallet secret is involved.
    } finally {
      await client.close();
      if (mounted) setState(() => _loadingRates = false);
    }
  }

  int? _requestedSats() {
    if (_maxSpend) return null;
    final text = _amount.text.trim().replaceAll(',', '');
    final value = double.tryParse(text);
    if (value == null || value <= 0) return -1;
    return (value * 100000000).round();
  }

  Future<void> _scanRecipientQr() async {
    final ko = widget.korean;
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrScanScreen(
          korean: ko,
          title: ko ? '받는 주소 QR 스캔' : 'Scan recipient QR',
        ),
      ),
    );
    if (!mounted || scanned == null) return;

    try {
      final parsed = RecipientAddressParser.parse(scanned);
      setState(() => _recipient.text = parsed.address);
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ko
                ? '지원되는 BTCMobick 주소 QR이 아닙니다.'
                : 'This QR is not a supported BTCMobick address.',
          ),
        ),
      );
    }
  }

  void _review() {
    final ko = widget.korean;
    RecipientAddress recipient;
    try {
      recipient = RecipientAddressParser.parse(_recipient.text);
    } on FormatException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ko
                ? '받는 주소 오류: ${e.message}'
                : 'Recipient error: ${e.message}',
          ),
        ),
      );
      return;
    }

    final feeRate = _feeRate;
    if (feeRate < _rates.minimum) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ko ? '수수료율을 확인하세요.' : 'Check the fee rate.',
          ),
        ),
      );
      return;
    }

    final requested = _requestedSats();
    if (requested == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ko ? '전송 금액을 확인하세요.' : 'Check the send amount.',
          ),
        ),
      );
      return;
    }

    try {
      final wallet = BitcoinAddressDeriver().deriveFromWif(widget.sessionWif);

      late final int feeSats;
      late final int sendSats;
      late final int changeSats;
      late final String signedHex;
      late final String txid;
      late final int vbytes;
      late final String? changeAddress;

      if (widget.isSegwitSource) {
        final sourceScriptCode = AddressScript.p2pkh(wallet.publicKeyHash);
        final changeScript = AddressScript.p2wpkh(wallet.publicKeyHash);
        final finalized = SegwitTransactionFinalizer.finalize(
          wif: widget.sessionWif,
          inputs: widget.selected,
          sourceScriptCode: sourceScriptCode,
          recipientScriptPubKey: recipient.scriptPubKey,
          requestedSendSats: requested,
          changeScriptPubKey: changeScript,
          satsPerVbyte: feeRate,
        );
        feeSats = finalized.feeSats;
        sendSats = finalized.sendSats;
        changeSats = finalized.changeSats;
        signedHex = finalized.signed.hex;
        txid = finalized.signed.txid;
        vbytes = finalized.signed.vbytes;
        changeAddress = changeSats > 0 ? widget.segwitAddress : null;
      } else {
        final sourceScript = AddressScript.p2pkh(wallet.publicKeyHash);
        final changeRecipient = RecipientAddressParser.parse(
          widget.legacyAddress,
        );
        final finalized = LegacyTransactionFinalizer.finalize(
          wif: widget.sessionWif,
          inputs: widget.selected,
          sourceScriptPubKey: sourceScript,
          recipientScriptPubKey: recipient.scriptPubKey,
          requestedSendSats: requested,
          changeScriptPubKey: changeRecipient.scriptPubKey,
          satsPerVbyte: feeRate,
        );
        feeSats = finalized.feeSats;
        sendSats = finalized.sendSats;
        changeSats = finalized.changeSats;
        signedHex = finalized.signed.hex;
        txid = finalized.signed.txid;
        vbytes = finalized.signed.vbytes;
        changeAddress = changeSats > 0 ? widget.legacyAddress : null;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TransactionReviewScreen(
            korean: ko,
            selected: widget.selected,
            recipient: recipient.address,
            feeRate: feeRate,
            feeSats: feeSats,
            receiveSats: sendSats,
            changeSats: changeSats,
            changeAddress: changeAddress,
            signedHex: signedHex,
            txid: txid,
            vbytes: vbytes,
            securityService: widget.securityService,
          ),
        ),
      );
    } on FormatException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ko
                ? '트랜잭션 생성 오류: ${e.message}'
                : 'Transaction error: ${e.message}',
          ),
        ),
      );
    } on StateError catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ko
                ? '서명된 트랜잭션 크기가 안정적으로 확정되지 않았습니다.'
                : 'Signed transaction size did not converge safely.',
          ),
        ),
      );
    }
  }

  int get _feeRate {
    return switch (_choice) {
      _FeeChoice.economy => _rates.economy,
      _FeeChoice.normal => _rates.normal,
      _FeeChoice.fast => _rates.fast,
      _FeeChoice.custom => int.tryParse(_customFee.text) ?? 0,
    };
  }

  @override
  void dispose() {
    _recipient.clear();
    _customFee.clear();
    _amount.clear();
    _recipient.dispose();
    _customFee.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ko = widget.korean;
    final selectedTotal = widget.selected.fold<int>(0, (sum, u) => sum + u.valueSats);
    final feeRate = _feeRate;
    final validFee = feeRate >= _rates.minimum;
    final inputTypes = List<InputScriptType>.filled(
      widget.selected.length,
      widget.isSegwitSource
          ? InputScriptType.p2wpkh
          : InputScriptType.p2pkh,
    );
    final feeQuote = FeeEstimator.estimate(
      inputs: inputTypes,
      outputCount: 1,
      satsPerVbyte: validFee ? feeRate : _rates.minimum,
    );
    final requestedSats = _requestedSats();
    final sendDraft = requestedSats == -1
        ? null
        : (() {
            try {
              return SendDraftBuilder.amountSpend(
                selected: widget.selected,
                inputTypes: inputTypes,
                recipient: 'preview',
                requestedSendSats: requestedSats,
                satsPerVbyte: validFee ? feeRate : _rates.minimum,
              );
            } on FormatException {
              return null;
            }
          })();
    final receiveSats = sendDraft?.sendSats ?? 0;
    final changeSats = sendDraft?.changeSats ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(ko ? '전송 초안' : 'Send draft')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(ko ? '선택한 UTXO' : 'Selected UTXOs', style: Theme.of(context).textTheme.titleMedium),
          Text(
            '${widget.selected.length} UTXO · ${(selectedTotal / 100000000).toStringAsFixed(8)} BMB · '
            '${widget.isSegwitSource ? 'Native SegWit' : 'Legacy'}',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _recipient,
            decoration: InputDecoration(
              labelText: ko ? '받는 주소' : 'Recipient address',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: ko ? '받는 주소 QR 스캔' : 'Scan recipient QR',
                onPressed: _scanRecipientQr,
                icon: const Icon(Icons.qr_code_scanner),
              ),
            ),
          ),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(ko ? 'MAX' : 'MAX')),
              ButtonSegment(value: false, label: Text(ko ? '직접 입력' : 'Custom amount')),
            ],
            selected: {_maxSpend},
            onSelectionChanged: (s) => setState(() => _maxSpend = s.first),
          ),
          if (!_maxSpend) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: ko ? '전송할 BMB' : 'BMB to send',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(ko ? '전송 속도' : 'Transfer speed', style: Theme.of(context).textTheme.titleMedium),
          if (_loadingRates) const LinearProgressIndicator(),
          RadioGroup<_FeeChoice>(
            groupValue: _choice,
            onChanged: (v) => setState(() => _choice = v ?? _choice),
            child: Column(children: [
              RadioListTile(value: _FeeChoice.economy, title: Text(ko ? '절약' : 'Economy'), subtitle: Text('${_rates.economy} sat/vB')),
              RadioListTile(value: _FeeChoice.normal, title: Text(ko ? '일반 (권장)' : 'Normal (recommended)'), subtitle: Text('${_rates.normal} sat/vB')),
              RadioListTile(value: _FeeChoice.fast, title: Text(ko ? '빠름' : 'Fast'), subtitle: Text('${_rates.fast} sat/vB')),
              RadioListTile(value: _FeeChoice.custom, title: Text(ko ? '직접 설정' : 'Custom'), subtitle: Text(ko ? '최소 권장: ${_rates.minimum} sat/vB' : 'Recommended minimum: ${_rates.minimum} sat/vB')),
            ]),
          ),
          if (_choice == _FeeChoice.custom)
            TextField(
              controller: _customFee,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'sat/vB',
                border: const OutlineInputBorder(),
                errorText: validFee ? null : (ko ? '최소 ${_rates.minimum} sat/vB 이상 입력하세요.' : 'Enter at least ${_rates.minimum} sat/vB.'),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ko ? 'MAX 전송 명세' : 'MAX transfer summary', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _AmountRow(label: ko ? '선택 UTXO 합계' : 'Selected total', sats: selectedTotal),
                _AmountRow(label: ko ? '실제 전송액' : 'Recipient receives', sats: receiveSats, emphasize: true),
                _AmountRow(label: ko ? '예상 네트워크 수수료' : 'Estimated network fee', sats: sendDraft?.feeSats ?? feeQuote.feeSats),
                _AmountRow(label: ko ? '내게 돌아오는 잔돈 (change)' : 'Change back to wallet', sats: changeSats),
                const Divider(),
                Text('${feeQuote.vbytes} vB × ${validFee ? feeRate : _rates.minimum} sat/vB'),
                Text(ko
                    ? '예상 수수료: ${feeQuote.feeSats} bick (≈ ${(feeQuote.feeSats / 100000000).toStringAsFixed(8)} BMB)'
                    : 'Estimated fee: ${feeQuote.feeSats} bick (≈ ${(feeQuote.feeSats / 100000000).toStringAsFixed(8)} BMB)'),
                const SizedBox(height: 6),
                Text(ko
                    ? 'MAX에서는 선택한 UTXO 합계에서 네트워크 수수료를 뺀 금액을 수신자가 받습니다. 잔돈(change)은 0입니다.'
                    : 'With MAX, the recipient receives the selected total minus the network fee. Change is zero.'),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(ko
                ? '안전 잠금: 검토 단계에서 로컬 서명된 트랜잭션을 만들지만, 네트워크 브로드캐스트는 아직 비활성화되어 있습니다.'
                : 'Safety lock: review creates a locally signed transaction, but network broadcast remains disabled.'),
          )),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: validFee && sendDraft != null && receiveSats > 0 ? _review : null,
            child: Text(ko ? '검토' : 'Review'),
          ),
        ],
      ),
    );
  }
}


class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.sats, this.emphasize = false});
  final String label;
  final int sats;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('${(sats / 100000000).toStringAsFixed(8)} BMB', style: style),
        ],
      ),
    );
  }
}


class TransactionReviewScreen extends StatefulWidget {
  const TransactionReviewScreen({
    super.key,
    required this.korean,
    required this.selected,
    required this.recipient,
    required this.feeRate,
    required this.feeSats,
    required this.receiveSats,
    required this.changeSats,
    required this.changeAddress,
    required this.signedHex,
    required this.txid,
    required this.vbytes,
    required this.securityService,
  });

  final bool korean;
  final List<Utxo> selected;
  final String recipient;
  final int feeRate;
  final int feeSats;
  final int receiveSats;
  final int changeSats;
  final String? changeAddress;
  final String signedHex;
  final String txid;
  final int vbytes;
  final AppLockService securityService;

  @override
  State<TransactionReviewScreen> createState() =>
      _TransactionReviewScreenState();
}

class _TransactionReviewScreenState extends State<TransactionReviewScreen> {
  bool _broadcasting = false;
  String? _broadcastResult;

  Future<bool> _reauthenticateForBroadcast() async {
    final ko = widget.korean;

    final biometricEnabled =
        await widget.securityService.biometricEnabled();
    if (biometricEnabled &&
        await widget.securityService.canUseBiometrics()) {
      final ok = await widget.securityService.authenticateBiometric(
        korean: ko,
      );
      if (ok) return true;
    }

    if (!mounted) return false;
    final controller = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(ko ? 'PIN 재확인' : 'Confirm PIN'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          maxLength: 6,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          enableSuggestions: false,
          autocorrect: false,
          enableIMEPersonalizedLearning: false,
          onSubmitted: (value) {
            if (value.length == 6) {
              Navigator.of(dialogContext).pop(value);
            }
          },
          decoration: InputDecoration(
            labelText: ko ? '6자리 PIN' : '6-digit PIN',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(ko ? '취소' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text;
              if (value.length == 6) {
                Navigator.of(dialogContext).pop(value);
              }
            },
            child: Text(ko ? '확인' : 'Confirm'),
          ),
        ],
      ),
    );

    final submittedPin = pin;
    controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (submittedPin == null) return false;
    final ok = await widget.securityService.verifyPin(submittedPin);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ko ? 'PIN이 올바르지 않습니다.' : 'Incorrect PIN.',
          ),
        ),
      );
    }
    return ok;
  }

  Future<void> _broadcast() async {
    final ko = widget.korean;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          ko ? '실제 네트워크로 전송할까요?' : 'Broadcast to the live network?',
        ),
        content: Text(
          ko
              ? '이 작업은 실제 BTCMobick 트랜잭션을 전송합니다. 받는 주소, 금액, 수수료, change를 다시 확인하세요.'
              : 'This sends a real BTCMobick transaction. Re-check the recipient, amount, fee, and change.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ko ? '취소' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(ko ? '실제 전송' : 'Broadcast'),
          ),
        ],
      ),
    );

    if (confirmed != true || _broadcasting) return;

    final authenticated = await _reauthenticateForBroadcast();
    if (!authenticated || !mounted) return;

    setState(() => _broadcasting = true);
    final client = ElectrumClient();
    try {
      await client.connect();
      final serverTxid =
          await client.broadcastTransaction(widget.signedHex);
      if (!mounted) return;

      if (serverTxid != widget.txid) {
        setState(() => _broadcastResult = 'mismatch:$serverTxid');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ko
                  ? '경고: 서버 TXID가 로컬 TXID와 다릅니다. 추가 전송을 중단하세요.'
                  : 'Warning: server TXID differs from the local TXID. Stop further sends.',
            ),
          ),
        );
        return;
      }

      setState(() => _broadcastResult = serverTxid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ko ? '브로드캐스트 성공' : 'Broadcast successful',
          ),
        ),
      );
    } on ElectrumException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ko
                ? '브로드캐스트 실패: ${e.message}'
                : 'Broadcast failed: ${e.message}',
          ),
        ),
      );
    } finally {
      await client.close();
      if (mounted) setState(() => _broadcasting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ko = widget.korean;
    final selectedTotal =
        widget.selected.fold<int>(0, (sum, u) => sum + u.valueSats);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ko ? '최종 검토 (서명 완료)' : 'Final review (signed)',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ko ? '받는 주소' : 'Recipient',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SelectableText(widget.recipient),
                  const Divider(),
                  _AmountRow(
                    label: ko ? '선택 UTXO 합계' : 'Selected total',
                    sats: selectedTotal,
                  ),
                  _AmountRow(
                    label: ko ? '확정 수령액' : 'Final recipient amount',
                    sats: widget.receiveSats,
                    emphasize: true,
                  ),
                  _AmountRow(
                    label: ko ? '확정 네트워크 수수료' : 'Final network fee',
                    sats: widget.feeSats,
                  ),
                  if (widget.changeSats > 0)
                    _AmountRow(
                      label: ko ? '내게 돌아오는 잔돈' : 'Change back to wallet',
                      sats: widget.changeSats,
                    ),
                  if (widget.changeAddress != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      ko ? 'Change 주소' : 'Change address',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SelectableText(widget.changeAddress!),
                  ],
                  const Divider(),
                  Text(
                    '${widget.feeSats} bick · ${widget.feeRate} sat/vB',
                  ),
                  Text('${widget.vbytes} vB'),
                  Text('${widget.selected.length} UTXO input'),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.receiveSats + widget.feeSats + widget.changeSats == selectedTotal ? '✓' : '⚠'} '
                    '${ko ? '입력 = 수령액 + 수수료 + change' : 'inputs = recipient + fee + change'}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: Text(ko ? '사용 UTXO 보기' : 'View inputs'),
            children: widget.selected
                .map(
                  (u) => ListTile(
                    title: Text(
                      '${(u.valueSats / 100000000).toStringAsFixed(8)} BMB',
                    ),
                    subtitle: SelectableText(
                      '${u.txHash}:${u.txPosition}',
                    ),
                  ),
                )
                .toList(),
          ),
          ExpansionTile(
            title: const Text('TXID'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(widget.txid),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Signed raw transaction'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  widget.signedHex,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                ko
                    ? '트랜잭션은 기기 안에서 서명되었습니다. 아래 버튼을 누르면 실제 BTCMobick 네트워크로 전송됩니다.'
                    : 'The transaction is signed locally. The button below broadcasts it to the live BTCMobick network.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_broadcastResult != null) ...[
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _broadcastResult!.startsWith('mismatch:')
                        ? _broadcastResult!.substring('mismatch:'.length)
                        : _broadcastResult!,
                  ),
                ),
                IconButton(
                  tooltip: ko ? 'TXID 복사' : 'Copy TXID',
                  onPressed: () async {
                    final value = _broadcastResult!.startsWith('mismatch:')
                        ? _broadcastResult!.substring('mismatch:'.length)
                        : _broadcastResult!;
                    await Clipboard.setData(ClipboardData(text: value));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ko ? 'TXID를 복사했습니다.' : 'TXID copied.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                ),
              ],
            ),
            if (!_broadcastResult!.startsWith('mismatch:')) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(
                    'https://blockchain.mobick.info/ko/tx/${widget.txid}',
                  );
                  final opened = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ko
                              ? '블록 익스플로러를 열지 못했습니다.'
                              : 'Could not open the block explorer.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  ko
                      ? '블록 익스플로러에서 보기'
                      : 'View in block explorer',
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed:
                _broadcasting || _broadcastResult != null ? null : _broadcast,
            icon: _broadcasting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(
              _broadcastResult != null
                  ? (ko ? '전송 완료' : 'Broadcast complete')
                  : (ko ? '실제 네트워크로 전송' : 'Broadcast to network'),
            ),
          ),
        ],
      ),
    );
  }
}
