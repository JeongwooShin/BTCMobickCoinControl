# Privacy Policy — UTXO Control

**Effective date:** 2026-10-06

UTXO Control is a non-custodial BTCMobick wallet utility that lets users inspect and select UTXOs, sign transactions locally, and broadcast signed transactions to the BTCMobick network.

## 1. Data we do not collect

UTXO Control does not require an account and does not collect, store, sell, or share personal information.

In particular, UTXO Control does **not** collect or transmit:

- WIF private keys or other private-key material;
- seed phrases or wallet backups;
- contact lists, messages, photos, precise location, or advertising identifiers;
- analytics or advertising data.

UTXO Control currently contains no advertising SDK and no analytics SDK.

## 2. Private keys and wallet data

WIF private keys are processed locally on the user's device for address derivation and transaction signing.

Private keys are not uploaded to Runbickers or any application backend. The current release does not provide persistent private-key storage. A WIF may remain in application memory while the current app process is alive so the user can return to an in-progress wallet session after app re-authentication. If the app process is terminated, that in-memory session is lost.

Users are responsible for keeping an independent backup of their private keys or seed phrases. UTXO Control is not a backup service.

## 3. Network communications

To provide wallet functionality, the app communicates with the BTCMobick network infrastructure.

The app may send public blockchain data such as script hashes and transaction queries to a BTCMobick ElectrumX server, and may send a fully signed raw transaction when the user chooses to broadcast it. Private keys are not included in these network requests.

When a user chooses “View in block explorer,” the app opens the BTCMobick block explorer in an external browser. The browser and the destination website may process network information according to their own privacy policies.

## 4. Device permissions

UTXO Control may request:

- **Camera:** only for scanning WIF or recipient-address QR codes.
- **Biometric authentication:** to unlock the app or authorize sensitive actions.

QR contents are processed locally and are not sent to Runbickers.

## 5. Data retention and deletion

UTXO Control does not maintain a user account or server-side user database, so there is no server-side personal-data retention or account-deletion process.

Session-only wallet secrets are not intentionally written to persistent app storage. Android or the operating system may terminate the application process at any time, which clears the app's in-memory session.

## 6. Security

The app uses local signing, application locking, biometric authentication where enabled, secure-window protections, and other platform controls. No mobile application can guarantee protection on a rooted, modified, malware-infected, or otherwise compromised device.

## 7. Children

UTXO Control is a cryptocurrency utility and is not directed to children.

## 8. Changes to this policy

If a future release introduces analytics, advertising, persistent wallet storage, account services, or other data handling, this policy and the Google Play Data safety declaration will be updated before that release.

## 9. Contact

Developer: Runbickers / UTXO Control project  
Website: https://runbickers.com  
Source repository: https://github.com/JeongwooShin/BTCMobickCoinControl

For privacy or security inquiries, use the contact method published on the project website or repository.
