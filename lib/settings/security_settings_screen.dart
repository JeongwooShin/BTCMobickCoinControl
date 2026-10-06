import 'package:flutter/material.dart';

import '../security/app_lock_service.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({
    super.key,
    required this.service,
  });

  final AppLockService service;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('보안 설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '개인키 저장 기능은 현재 제공하지 않습니다. '
                '개인키는 필요한 전송 세션에서만 입력하고, 앱 종료 후 다시 사용할 때에는 다시 입력하는 방식을 권장합니다.',
              ),
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '앱 잠금 PIN과 생체인증은 앱 접근 및 중요한 작업의 재인증에 사용됩니다.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
