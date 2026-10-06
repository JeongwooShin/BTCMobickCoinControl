# Security Policy

BTCMobick Coin Control handles cryptocurrency signing material. Security takes precedence over convenience.

## Non-negotiable rules

1. **Never commit secrets.** No real WIF, seed phrase, private key, signing key, API credential, wallet backup, or production secret belongs in Git.
2. **Private keys stay local.** A WIF/private key must not be sent to Runbickers, logging, analytics, crash-reporting, ElectrumX, or any third party.
3. **Local signing only.** Only public network queries and signed raw transactions may leave the device.
4. **No secret logging.** Logs and exception reports must redact WIFs, raw private keys and other signing material.
5. **No analytics/advertising SDK in the initial release.** Any future third-party SDK requires a separate privacy/security review.
6. **Session-only keys first.** Persistent wallet storage must not be added until an explicit Android Keystore/iOS Keychain design and review are complete.
7. **Validate before broadcast.** The review screen must show destination, amount, selected inputs, fee and change before signing/broadcast.
8. **Test before real funds.** Transaction serialization and signatures must be checked against deterministic vectors and the sanitized Python reference implementation.

## Development safety

Use synthetic/test keys in automated tests. Real-wallet tests must use small values and must never store private keys in source, fixtures, CI variables, screenshots, issues or pull requests.

## Reporting a vulnerability

Do not publish exploitable wallet vulnerabilities or exposed secrets in a public issue. A private reporting channel will be documented before the repository is made public.

## Release gate

No production release should occur until:

- address derivation is independently verified;
- supported script/address types are explicitly documented;
- UTXO parsing is covered by tests;
- fee/change/dust handling is tested;
- transaction serialization and signing are cross-checked;
- ElectrumX failure and malformed-response handling is tested;
- secrets are absent from the repository history;
- release signing and store credentials are kept outside source control.
