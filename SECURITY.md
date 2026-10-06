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


## Threat model: compromised Android devices

Application sandboxing, secure-window flags, overlay defenses, biometrics, and Android Keystore materially reduce common theft paths, but they cannot make a private key safe on a fully compromised device.

If malware has root/system privileges, can instrument the wallet process, controls the keyboard/input method, or otherwise compromises the OS, it may observe a WIF while the user imports it or plaintext transaction/key material while the wallet legitimately uses it. Therefore:

- default to no private-key persistence;
- minimize plaintext WIF lifetime;
- never place WIF in clipboard/logs;
- protect sensitive UI from screenshots/casting and overlays;
- mark sensitive views against accessibility snooping where the platform supports it;
- require fresh user authentication for persisted-wallet unlock and high-risk actions;
- encrypt persisted WIF with a random key protected by Android Keystore, preferably hardware-backed when available;
- warn users not to import valuable keys on rooted, modified, untrusted, or malware-suspected devices.

No release documentation may state that private-key theft is impossible.
