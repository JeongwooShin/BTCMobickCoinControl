# UTXO Control

A non-custodial Flutter wallet for BTCMobick focused on explicit UTXO (coin) control.

> **Status:** Release candidate. Real-network sends have been validated with small values; complete the release checklist before production distribution.

## Goals

- Import a WIF private key by QR scan or manual entry.
- Derive and display the corresponding BTCMobick address locally.
- Query BTCMobick UTXOs through ElectrumX.
- List every UTXO and allow explicit coin selection.
- Build, sign, review, and broadcast transactions.
- Keep private keys and signing material on the user's device.
- No advertising SDKs or analytics SDKs in the initial release.
- Android first; iOS after the Android implementation is validated.

## Network

The Android app connects to the BTCMobick ElectrumX service at `wallet.mobick.info:40009` over TLS. Because the service currently uses a self-signed certificate, the app verifies its SHA-256 certificate fingerprint. A certificate rotation requires a reviewed app update before the old certificate expires.

## Security model

The application is intended to be non-custodial.

- Private keys must never be transmitted to Runbickers or any application backend.
- Transaction signing must happen locally.
- No real WIF/private key, seed phrase, signing key, or production secret may be committed to this repository.
- WIF keys are held in memory for the active session and are not persisted.
- Broadcast receives only a signed raw transaction.
- Release builds must be tested against deterministic transaction test vectors and the existing Python reference implementation.

See [SECURITY.md](SECURITY.md).

## Release status

Completed:

- WIF import by QR scan and manual entry.
- Local address derivation, UTXO lookup and explicit coin selection.
- Legacy and Native SegWit transaction construction and local signing.
- Recipient QR scan, review, reauthentication and network broadcast.
- Small-value BTCMobick end-to-end testing.

Remaining release gates:

- Run the complete deterministic test suite in the release environment.
- Build and verify the release-signed Android App Bundle.
- Complete Android closed testing and the Google Play declarations.

## Reference implementation

The existing Python sender will be added only after all real private keys and user data have been removed. It is a protocol reference, not production mobile code.

## Legal and release documents

- [Privacy Policy](docs/PRIVACY_POLICY.md)
- [Terms of Use](docs/TERMS_OF_USE.md)
- [Google Play listing draft](docs/PLAY_STORE_LISTING.md)
- [Android release checklist](docs/RELEASE_CHECKLIST.md)

The public website may mirror these documents at runbickers.com, but the repository is the canonical source for the open-source project.

## License

A source license will be finalized before the repository is made public. Until then, no license is granted merely by access to this private repository.
