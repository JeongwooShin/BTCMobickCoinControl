# Android Release Checklist — UTXO Control

## Code and crypto

- [ ] `flutter analyze` returns 0 issues
- [ ] `flutter test` passes all tests
- [ ] Legacy P2PKH real small-value send verified
- [ ] Native SegWit P2WPKH real small-value send verified
- [ ] MAX and partial send verified
- [ ] Change handling verified
- [ ] TXID returned by ElectrumX matches locally calculated TXID
- [ ] Broadcast failure and network-disconnect behavior reviewed

## Secret handling

- [ ] No real WIF, seed phrase, private key, wallet backup, API secret, or signing key in repository history
- [ ] No WIF/private-key logging
- [ ] No private-key persistence in current release
- [ ] Session WIF survives app lock only while process remains alive
- [ ] Force-stop/process death requires WIF import again
- [ ] FLAG_SECURE / screenshot protection verified on sensitive screens

## App security

- [ ] 6-digit PIN setup verified
- [ ] Biometric ON/OFF verified
- [ ] Automatic biometric prompt after app return verified
- [ ] App immediately re-locks after leaving foreground
- [ ] Broadcast requires fresh authentication

## QR

- [ ] Camera permission requested only when QR scanner is used
- [ ] WIF QR import verified
- [ ] Recipient-address QR import verified
- [ ] Invalid QR handling verified

## Branding

- [ ] App name: UTXO Control
- [ ] Final launcher icon applied at all Android densities
- [ ] Store icon 512×512 prepared
- [ ] Version name/code finalized
- [ ] Package/application ID reviewed before first production release

## Play Console

- [ ] Developer account type appropriate for cryptocurrency software wallet
- [ ] Organization verification / D-U-N-S / website completed if required
- [ ] Privacy policy public URL entered
- [ ] Privacy policy accessible from inside app
- [ ] Data safety form completed accurately
- [ ] App category and financial-features declarations completed
- [ ] Content rating completed
- [ ] Store title, short description, full description completed
- [ ] Screenshots uploaded
- [ ] Support email and website set

## Release signing

- [ ] Production Android keystore created outside repository
- [ ] Keystore and passwords backed up securely
- [ ] Release signing configured without committing secrets
- [ ] AAB built in release mode
- [ ] Release AAB installed/tested via Play internal testing

## Final privacy audit

Current release should declare the minimum necessary permissions and no analytics/advertising SDKs. Re-review the Data safety form before every release that adds an SDK or changes network behavior.
