# Android Release Checklist — UTXO Control

## Fixed release identity

- [x] App name: UTXO Control
- [x] Application ID: `com.runbickers.btcmobick_coin_control`
- [x] Initial version: `1.0.0+1`
- [x] Minimum Android API: 24
- [x] Upload-key alias: `utxo-control-upload`

The application ID becomes permanent after the first Play Console upload.

## Code and crypto

- [x] GitHub Actions `Flutter CI` passes `flutter analyze`
- [x] GitHub Actions `Flutter CI` passes all deterministic tests
- [ ] Legacy P2PKH real small-value send verified
- [ ] Native SegWit P2WPKH real small-value send verified
- [ ] MAX and partial send verified
- [ ] Change handling verified
- [x] A real small-value network send completed
- [x] TXID returned by ElectrumX matched the locally calculated TXID
- [x] Broadcast failure and network-disconnect behavior reviewed

## Secret handling

- [x] Repository history confirmed free of real WIF, seed, private key and signing secrets (public scalar-1 test vector only)
- [x] No WIF/private-key logging found in the release path
- [x] WIF is held in memory and is not persisted
- [x] Force-stop/process death verified to require WIF import again on the signed release build
- [x] Screenshot protection verified on physical device (ADB capture is fully black)

## App security

- [x] 6-digit PIN setup verified
- [x] Biometric ON/OFF verified
- [x] App relock behavior verified
- [x] Broadcast requires fresh authentication

## QR

- [x] WIF QR import verified on a physical device
- [x] Recipient-address QR import verified on a physical device
- [ ] Invalid QR handling verified

## Network and privacy

- [x] Release manifest includes INTERNET, CAMERA, USE_BIOMETRIC and HIDE_OVERLAY_WINDOWS
- [x] ElectrumX uses TLS on `wallet.mobick.info:40009`
- [x] The self-signed server certificate SHA-256 fingerprint is pinned
- [x] TLS 1.3, certificate pin and Electrum protocol 1.4 handshake verified
- [ ] Review the pin before the server certificate expires on 2027-06-06
- [x] Privacy policy accurately describes ElectrumX network metadata
- [x] No advertising or analytics SDK is included

## Release signing

- [x] Dedicated upload keystore created outside the repository
- [x] Release signing configured without committing secrets
- [x] Public upload-certificate fingerprints documented
- [ ] Keystore and password file backed up to two secure locations
- [x] Release AAB built and signature verified (GitHub Actions run `37566249079`)
- [x] Signed release APK installed and cold-launched on Samsung SM-F958N / Android 16
- [ ] Release installed through Play internal testing

Back up both files before the first Play upload:

- `C:\Users\WP11\.android\keystores\utxo-control-upload.jks`
- `D:\github\BTCMobickCoinControl\android\key.properties`

The properties file contains the password. Neither file may be committed to Git.

## Branding and store assets

- [x] Final launcher name applied
- [x] Final launcher icon reviewed at all Android densities
- [x] Store icon 512×512 prepared at `store-assets/utxo-control-icon-512.png`
- [ ] Store title, descriptions and screenshots finalized

## Play Console

- [ ] Organization verification, D-U-N-S and website verification completed
- [ ] Privacy-policy public URL entered
- [ ] Financial Features declaration completed
- [ ] Data safety and content rating completed
- [ ] Support email, phone and website verified
- [ ] Closed or internal test completed

Re-review this checklist whenever an SDK, permission, server endpoint or key-handling behavior changes.
