import 'package:flutter/material.dart';

import '../security/app_lock_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({
    super.key,
    required this.service,
  });

  final AppLockService service;

  @override
  State<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _loading = true;
  bool _persistWallet = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final persist = await widget.service.walletPersistenceEnabled();
    if (!mounted) return;
    setState(() {
      _persistWallet = persist;
      _loading = false;
    });
  }

  Future<void> _setPersistence(bool enabled) async {
    if (enabled) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('개인키 저장 위험 안내'),
          content: const Text(
            '개인키는 Android 보안 저장소를 이용해 암호화된 형태로 저장됩니다. '
            '하지만 루팅, 악성코드, 운영체제 손상 등으로 기기가 완전히 침해된 경우 '
            '탈취 위험을 완전히 제거할 수 없습니다. 저장하지 않는 설정이 가장 안전합니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('위험을 이해하고 저장 사용'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
    }

    await widget.service.setWalletPersistenceEnabled(enabled);
    if (!mounted) return;
    setState(() => _persistWallet = enabled);
  }

  Future<void> _deleteSavedWallet() async {
    await widget.service.clearSavedWallet();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('저장된 개인키를 삭제했습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('보안 설정')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _persistWallet,
                  onChanged: _setPersistence,
                  title: const Text('개인키 암호화 저장'),
                  subtitle: Text(
                    _persistWallet
                        ? '켜짐 · 다음에 가져오는 WIF 개인키를 기기 보안 저장소에 저장합니다.'
                        : '꺼짐 (권장) · 개인키를 세션에서만 사용합니다.',
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '앱 PIN은 개인키 암호화 키로 직접 사용하지 않습니다. '
                      '개인키 저장은 플랫폼 보안 저장소를 사용하며, 앱 잠금과 별도의 보호 계층입니다.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _deleteSavedWallet,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('저장된 개인키 삭제'),
                ),
              ],
            ),
    );
  }
}
