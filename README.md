# UTXO Control

A non-custodial Flutter wallet utility for BTCMobick focused on explicit UTXO (coin) control.

> **Status:** Early development. Do not use with funds you cannot afford to lose.

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

The reference implementation currently targets the BTCMobick ElectrumX service at `wallet.mobick.info`.
Network parameters and server endpoints will be isolated from UI code and documented before release.

## Security model

The application is intended to be non-custodial.

- Private keys must never be transmitted to Runbickers or any application backend.
- Transaction signing must happen locally.
- No real WIF/private key, seed phrase, signing key, or production secret may be committed to this repository.
- Initial development should prefer session-only key handling; persistent key storage is a later, separately reviewed feature.
- Broadcast receives only a signed raw transaction.
- Release builds must be tested against deterministic transaction test vectors and the existing Python reference implementation.

See [SECURITY.md](SECURITY.md).

## Development plan

1. Bootstrap Flutter Android application and CI.
2. Add pure-Dart address/WIF/network primitives with tests.
3. Implement ElectrumX connection and UTXO retrieval.
4. Implement transaction construction and signing against test vectors.
5. Build UTXO selection and send/review UI.
6. Add QR import and camera permissions.
7. Perform small-value BTCMobick end-to-end testing.
8. Security review and Android closed testing.
9. Prepare Play Store release.
10. Add iOS support after Android validation.

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
