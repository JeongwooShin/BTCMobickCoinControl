import 'package:flutter/material.dart';

void main() {
  runApp(const MobickCoinControlApp());
}

class MobickCoinControlApp extends StatelessWidget {
  const MobickCoinControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BTCMobick Coin Control',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3157D5)),
        useMaterial3: true,
      ),
      home: const WalletImportScreen(),
    );
  }
}

class WalletImportScreen extends StatefulWidget {
  const WalletImportScreen({super.key});

  @override
  State<WalletImportScreen> createState() => _WalletImportScreenState();
}

class _WalletImportScreenState extends State<WalletImportScreen> {
  final _wifController = TextEditingController();
  bool _obscureWif = true;

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
        const SnackBar(content: Text('Enter a WIF private key first.')),
      );
      return;
    }

    // Deliberately do not log or persist the WIF.
    // WIF validation/address derivation is the next implementation milestone.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wallet engine is not enabled yet. No key was transmitted.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BTCMobick Coin Control')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Open your wallet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your private key will be handled locally on this device. '
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
                labelText: 'WIF private key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscureWif ? 'Show key' : 'Hide key',
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
              label: const Text('Scan QR (next milestone)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _continue,
              child: const Text('Continue'),
            ),
            const SizedBox(height: 24),
            const _SecurityNotice(),
          ],
        ),
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

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
                'Development build: transaction signing and broadcasting are '
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
