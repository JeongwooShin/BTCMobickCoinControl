import 'dart:io';

import 'package:flutter/material.dart';

import 'domain/utxo.dart';
import 'network/electrum_client.dart';
import 'wallet/address_script.dart';
import 'wallet/bitcoin_address_deriver.dart';
import 'wallet/wif_decoder.dart';
import 'wallet/fee_estimator.dart';
import 'wallet/fee_rate_options.dart';
import 'wallet/recipient_address.dart';
import 'wallet/send_draft.dart';
import 'wallet/transaction_serializer.dart';

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


class UtxoScreen extends StatefulWidget {
  const UtxoScreen({super.key, required this.korean, required this.legacyAddress, required this.segwitAddress, required this.legacy, required this.segwit});
  final bool korean;
  final String legacyAddress;
  final String segwitAddress;
  final List<Utxo> legacy;
  final List<Utxo> segwit;

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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SendDraftScreen(
          korean: widget.korean,
          selected: _all.where((u) => _selected.contains(_key(u))).toList(),
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
  const SendDraftScreen({super.key, required this.korean, required this.selected, required this.legacyAddress, required this.segwitAddress});
  final bool korean;
  final List<Utxo> selected;
  final String legacyAddress;
  final String segwitAddress;

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

  void _review() {
    final ko = widget.korean;
    RecipientAddress recipient;
    try {
      recipient = RecipientAddressParser.parse(_recipient.text);
    } on FormatException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ko ? '받는 주소 오류: ${e.message}' : 'Recipient error: ${e.message}')));
      return;
    }
    final feeRate = _feeRate;
    if (feeRate < _rates.minimum) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ko ? '수수료율을 확인하세요.' : 'Check the fee rate.')));
      return;
    }
    final types=List<InputScriptType>.filled(widget.selected.length,InputScriptType.p2pkh);
    final requested=_requestedSats();
    if(requested == -1){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(ko?'전송 금액을 확인하세요.':'Check the send amount.')));return;}
    final draft=SendDraftBuilder.amountSpend(selected:widget.selected,inputTypes:types,recipient:recipient.address,requestedSendSats:requested,satsPerVbyte:feeRate);
    final changeRecipient = RecipientAddressParser.parse(widget.legacyAddress);
    final tx=TransactionSerializer.legacyUnsigned(
      inputs:widget.selected,
      outputValueSats:draft.sendSats,
      outputScript:recipient.scriptPubKey,
      changeValueSats:draft.changeSats,
      changeScript:draft.changeSats > 0 ? changeRecipient.scriptPubKey : null,
    );
    final receive=draft.sendSats;
    final quote=FeeQuote(vbytes:draft.estimatedVbytes,feeSats:draft.feeSats);
    Navigator.of(context).push(MaterialPageRoute(builder:(_)=>TransactionReviewScreen(korean:ko,selected:widget.selected,recipient:recipient.address,feeRate:feeRate,feeSats:quote.feeSats,receiveSats:receive,unsignedHex:tx.hex,changeSats:draft.changeSats,changeAddress:draft.changeSats>0?widget.legacyAddress:null)));
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
    final inputTypes = List<InputScriptType>.filled(widget.selected.length, InputScriptType.p2pkh);
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
          Text('${widget.selected.length} UTXO · ${(selectedTotal / 100000000).toStringAsFixed(8)} BMB'),
          const SizedBox(height: 20),
          TextField(
            controller: _recipient,
            decoration: InputDecoration(
              labelText: ko ? '받는 주소' : 'Recipient address',
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.qr_code_scanner),
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
                ? '안전 잠금: 현재 단계에서는 트랜잭션 생성, 서명, 브로드캐스트를 하지 않습니다.'
                : 'Safety lock: this build does not construct, sign, or broadcast a transaction yet.'),
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


class TransactionReviewScreen extends StatelessWidget {
  const TransactionReviewScreen({super.key,required this.korean,required this.selected,required this.recipient,required this.feeRate,required this.feeSats,required this.receiveSats,required this.unsignedHex,required this.changeSats,required this.changeAddress});
  final bool korean; final List<Utxo> selected; final String recipient; final int feeRate; final int feeSats; final int receiveSats; final String unsignedHex; final int changeSats; final String? changeAddress;

  @override
  Widget build(BuildContext context) {
    final ko=korean;
    return Scaffold(
      appBar: AppBar(title: Text(ko?'최종 검토 (미서명)':'Final review (unsigned)')),
      body: ListView(padding:const EdgeInsets.all(20),children:[
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(ko?'받는 주소':'Recipient',style:Theme.of(context).textTheme.titleMedium),
          SelectableText(recipient),
          const Divider(),
          _AmountRow(label:ko?'실제 수령 예정액':'Recipient receives',sats:receiveSats,emphasize:true),
          _AmountRow(label:ko?'예상 수수료':'Estimated fee',sats:feeSats),
          if(changeSats>0) _AmountRow(label:ko?'내게 돌아오는 잔돈':'Change back to wallet',sats:changeSats),
          if(changeAddress!=null) ...[
            Text(ko?'Change 주소':'Change address',style:Theme.of(context).textTheme.titleSmall),
            SelectableText(changeAddress!),
          ],
          Text('$feeSats bick · $feeRate sat/vB'),
          Text('${selected.length} UTXO input'),
        ]))),
        const SizedBox(height:16),
        ExpansionTile(
          title:Text(ko?'사용 UTXO 보기':'View inputs'),
          children:selected.map((u)=>ListTile(title:Text('${(u.valueSats/100000000).toStringAsFixed(8)} BMB'),subtitle:SelectableText('${u.txHash}:${u.txPosition}'))).toList(),
        ),
        ExpansionTile(
          title:Text(ko?'Unsigned raw transaction':'Unsigned raw transaction'),
          children:[Padding(padding:const EdgeInsets.all(16),child:SelectableText(unsignedHex,style:Theme.of(context).textTheme.bodySmall))],
        ),
        const SizedBox(height:20),
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Text(ko
          ?'안전 잠금: 이 트랜잭션은 아직 서명되지 않았으며 네트워크로 브로드캐스트할 수 없습니다.'
          :'Safety lock: this transaction is unsigned and cannot be broadcast.'))),
        const SizedBox(height:16),
        FilledButton(onPressed:null,child:Text(ko?'서명 및 전송 (아직 비활성)':'Sign & send (disabled)')),
      ]),
    );
  }
}
