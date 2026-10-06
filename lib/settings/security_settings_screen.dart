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
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  // Private-key persistence is intentionally not exposed in the app.
  //
  // TODO(wallet-persistence): If this feature is ever restored, implement it
  // as a multi-wallet list rather than the previous single-WIF slot:
  // - list wallets by public address / user label, never by private key
  // - encrypt each WIF independently in platform secure storage
  // - support per-wallet deletion
  // - disabling persistence must warn and delete ALL saved WIF records
  // - require fresh PIN/biometric authentication for save/read/delete actions

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await widget.service.canUseBiometrics();
    final enabled = await widget.service.biometricEnabled();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled && available;
      _loading = false;
    });
  }

  Future<void> _setBiometric(bool enabled) async {
    if (!enabled) {
      await widget.service.setBiometricEnabled(false);
      if (!mounted) return;
      setState(() => _biometricEnabled = false);
      return;
    }

    if (!_biometricAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기기에 사용할 수 있는 생체인증이 없습니다.'),
        ),
      );
      return;
    }

    // Prove that a registered biometric can actually authenticate before
    // enabling it for app unlock and sensitive actions.
    await widget.service.setBiometricEnabled(true);
    final authenticated =
        await widget.service.authenticateBiometric(korean: true);
    if (!authenticated) {
      await widget.service.setBiometricEnabled(false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생체인증 확인에 실패했습니다.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _biometricEnabled = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('생체인증을 사용하도록 설정했습니다.')),
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
                  value: _biometricEnabled,
                  onChanged: _setBiometric,
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('생체인증 사용'),
                  subtitle: Text(
                    _biometricAvailable
                        ? '앱 잠금 해제와 중요한 작업의 재인증에 사용합니다.'
                        : '이 기기에 등록된 생체인증을 사용할 수 없습니다.',
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '개인키 저장 기능은 현재 제공하지 않습니다. '
                      '개인키는 필요한 전송 세션에서만 입력하고, 앱 종료 후 다시 사용할 때에는 다시 입력하는 방식을 권장합니다.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '앱 잠금 PIN과 생체인증은 앱 접근 및 실제 전송 직전의 재인증에 사용됩니다.',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
