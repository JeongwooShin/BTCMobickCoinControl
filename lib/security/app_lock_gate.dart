import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_lock_service.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.service,
    required this.child,
    this.relockAfter = const Duration(seconds: 30),
  });

  final AppLockService service;
  final Widget child;
  final Duration relockAfter;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _hasPin = false;
  bool _unlocked = false;
  bool _biometricsAvailable = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initialize() async {
    final hasPin = await widget.service.hasPin();
    final biometrics = await widget.service.canUseBiometrics();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _biometricsAvailable = biometrics;
      _unlocked = false;
      _loading = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      final backgroundedAt = _backgroundedAt;
      _backgroundedAt = null;
      if (backgroundedAt != null &&
          DateTime.now().difference(backgroundedAt) >= widget.relockAfter &&
          _unlocked) {
        setState(() => _unlocked = false);
      }
    }
  }

  Future<void> _pinCreated() async {
    final biometrics = await widget.service.canUseBiometrics();
    if (!mounted) return;
    setState(() {
      _hasPin = true;
      _biometricsAvailable = biometrics;
      _unlocked = true;
    });
  }

  Future<void> _unlockWithPin(String pin) async {
    final ok = await widget.service.verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      setState(() => _unlocked = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN이 올바르지 않습니다.')),
      );
    }
  }

  Future<void> _unlockWithBiometric() async {
    final ok = await widget.service.authenticateBiometric(korean: true);
    if (ok && mounted) {
      setState(() => _unlocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: Colors.white,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPin) {
      return _PinSetupScreen(
        service: widget.service,
        onCreated: _pinCreated,
      );
    }

    if (!_unlocked) {
      return _UnlockScreen(
        biometricsAvailable: _biometricsAvailable,
        onPinSubmitted: _unlockWithPin,
        onBiometric: _unlockWithBiometric,
      );
    }

    return widget.child;
  }
}

class _PinSetupScreen extends StatefulWidget {
  const _PinSetupScreen({
    required this.service,
    required this.onCreated,
  });

  final AppLockService service;
  final Future<void> Function() onCreated;

  @override
  State<_PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<_PinSetupScreen> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _pin.clear();
    _confirm.clear();
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_pin.text.length != 6 || _confirm.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('6자리 숫자 PIN을 입력하세요.')),
      );
      return;
    }
    if (_pin.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN이 서로 다릅니다.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.service.setPin(_pin.text);
      await widget.onCreated();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 48),
            Icon(
              Icons.lock_outline,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              '앱 잠금 설정',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'BTCMobick Coin Control을 열 때 사용할 6자리 PIN을 설정하세요. '
              '이 PIN은 개인키 암호화 키로 직접 사용되지 않습니다.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _PinField(controller: _pin, label: '6자리 PIN'),
            const SizedBox(height: 12),
            _PinField(controller: _confirm, label: 'PIN 다시 입력'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('PIN 설정'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockScreen extends StatefulWidget {
  const _UnlockScreen({
    required this.biometricsAvailable,
    required this.onPinSubmitted,
    required this.onBiometric,
  });

  final bool biometricsAvailable;
  final Future<void> Function(String) onPinSubmitted;
  final Future<void> Function() onBiometric;

  @override
  State<_UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<_UnlockScreen> {
  final _pin = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _pin.clear();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final submitted = _pin.text;
    _pin.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await widget.onPinSubmitted(submitted);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 72),
            Icon(
              Icons.shield_outlined,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'BTCMobick Coin Control',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'PIN 또는 생체인증으로 잠금을 해제하세요.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _PinField(
              controller: _pin,
              label: '6자리 PIN',
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: const Text('잠금 해제'),
            ),
            if (widget.biometricsAvailable) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : widget.onBiometric,
                icon: const Icon(Icons.fingerprint),
                label: const Text('지문 / 생체인증'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.label,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      maxLength: 6,
      keyboardType: TextInputType.number,
      enableSuggestions: false,
      autocorrect: false,
      enableIMEPersonalizedLearning: false,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      textInputAction:
          onSubmitted == null ? TextInputAction.next : TextInputAction.done,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        counterText: '',
      ),
    );
  }
}
