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
