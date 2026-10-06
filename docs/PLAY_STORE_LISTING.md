# Google Play Store Listing Draft — UTXO Control

## Product name

**UTXO Control**

Suggested store-facing title if more BTCMobick discoverability is needed:

**UTXO Control – BTCMobick**

## Short description

**BTCMobick UTXO coin control with local signing, QR import, and non-custodial security.**

## Full description

UTXO Control is a non-custodial coin-control utility for BTCMobick.

Choose exactly which UTXOs to spend, review transaction details before broadcast, and sign transactions locally on your device.

### Key features

- View BTCMobick Legacy and Native SegWit balances and UTXOs
- Select individual UTXOs for coin control
- Send MAX or a custom amount
- Legacy P2PKH and Native SegWit P2WPKH support
- Local transaction construction and signing
- WIF import by manual entry or QR scan
- Recipient-address QR scanning
- Fee selection and final fee review
- Change returned to the source wallet type
- TXID verification, copy, and BTCMobick block-explorer link
- 6-digit app PIN and optional biometric unlock
- Automatic re-lock when the app leaves the foreground
- Session-only private-key handling; no persistent private-key storage
- No analytics SDK and no advertising SDK in the initial release

### Security model

Your private key stays on your device. UTXO Control does not upload WIF private keys to Runbickers or an application backend. Signing is performed locally, and only public blockchain queries or a signed transaction are sent to network services.

UTXO Control is not a wallet-backup service. Keep an independent backup of every private key or seed phrase you use.

### Important

Cryptocurrency transactions can be irreversible. Always verify the recipient, amount, fee, selected UTXOs, and change before broadcasting. Test unfamiliar releases with small amounts first.

### Search terms to use naturally in store metadata

BTCMobick, BMB, Mobick, UTXO, coin control, BTCMobick wallet, Mobick wallet, Native SegWit, P2WPKH, Legacy P2PKH

Do not keyword-stuff unrelated brand names into the title or description.

## Suggested category

Finance

## Suggested screenshots

Use real app screenshots from a test-only wallet. Never expose a real private key or valuable wallet.

1. **Unlock**
   - PIN/biometric lock screen
   - Caption: “App lock with PIN and biometrics”

2. **Open wallet**
   - WIF entry screen with QR scan button
   - Use a synthetic/test WIF only
   - Caption: “Open a wallet locally by WIF or QR”

3. **UTXO selection**
   - Legacy and Native SegWit UTXO lists
   - Show multiple small test UTXOs
   - Caption: “Choose exactly which UTXOs to spend”

4. **Send draft**
   - Recipient, MAX/custom amount, fee tier
   - Caption: “Review amount, fee, and change before signing”

5. **Final review**
   - Recipient, selected total, final fee, change, vbytes
   - Caption: “Transaction details are verified before broadcast”

6. **Broadcast result**
   - Successful TXID, copy icon, block explorer button
   - Caption: “Copy the TXID or open it in the BTCMobick explorer”

## Screenshot safety checklist

- Do not show a real WIF, seed phrase, QR containing a valuable private key, or production secret.
- Use a synthetic/test-only wallet and small or already-spent transactions.
- Ensure notifications, status-bar previews, names, phone numbers, and unrelated personal data are absent.
- Keep screenshots visually consistent and use the same language for the store locale.
