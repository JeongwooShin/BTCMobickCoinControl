# Architecture

## Trust boundary

The core rule is simple:

```text
Private key / WIF
      |
      v
 Flutter application memory
      |
      +--> local address derivation
      +--> local transaction construction
      +--> local transaction signing
      |
      v
signed raw transaction -----> BTCMobick ElectrumX
```

Runbickers infrastructure is not in the private-key path.

## Planned layers

- `presentation`: screens, QR scanner, UTXO selection, transaction review.
- `domain`: immutable wallet/UTXO/transaction models and validation rules.
- `wallet`: WIF/address primitives, transaction builder and signer.
- `network`: ElectrumX protocol, scripthash queries and broadcast.
- `security`: sensitive-memory and later secure-storage abstractions.

UI code must not implement cryptographic or serialization rules.

## Initial scope

The first milestone is Android and session-only WIF import. Persistent key storage, multi-wallet management, analytics, advertising, exchange integration and custodial services are out of scope.

## ElectrumX behavior inherited from the validated Python prototype

- Server: `wallet.mobick.info`
- Existing prototype uses TCP 40008; SSL 40009 is available and should be preferred/evaluated for production.
- Send `server.version` after connection.
- Keep a persistent connection for related requests.
- Ignore unrelated server notifications while matching JSON-RPC responses by request id.
- Query `blockchain.scripthash.listunspent` for UTXOs.
- Use `blockchain.transaction.broadcast` only with an already signed raw transaction.

These assumptions must be verified during implementation rather than blindly copied.


## Application lock and optional wallet persistence

The production app must open behind an application lock. The planned policy is:

- Require a 6-digit app PIN, strong biometric authentication, or supported device credential before wallet UI is revealed.
- Re-lock after backgrounding/timeout and before sensitive signing actions.
- Wallet persistence is **off by default**. Session WIF material is cleared when the session ends as far as the managed runtime permits.
- A Settings screen may enable encrypted private-key persistence only after an explicit risk warning and fresh authentication.
- Persisted wallet material must be encrypted with an app-specific encryption key protected by Android Keystore; plaintext WIF must never be written to preferences, files, logs, backups, clipboard, analytics, or crash reports.
- Sensitive screens should use Android FLAG_SECURE, overlay mitigation where supported, and sensitive accessibility-data protection on supported Android versions.
- The app must not claim protection against a rooted/fully compromised device. A hostile OS, privileged malware, instrumentation, or compromised input method can defeat app-level controls.

The six-digit PIN is an application access control, not a standalone encryption key. It must not directly encrypt WIF material.
