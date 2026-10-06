# Google Play Data Safety Draft — UTXO Control

This is a working compliance note, not legal advice. Re-check the final APK/AAB and every bundled SDK before submitting the Play Console form.

## Current app behavior

UTXO Control:

- does not create a user account;
- does not include analytics or advertising SDKs;
- does not upload WIF/private keys or seed phrases;
- processes signing locally on the device;
- sends public-blockchain query identifiers (for example Electrum script hashes) to a BTCMobick ElectrumX server;
- sends a signed raw transaction when the user explicitly broadcasts;
- opens the BTCMobick block explorer in the user's external browser on request;
- requests camera access for QR scanning;
- may use Android biometric authentication.

## Important Play definition

Google Play defines "collection" broadly as transmitting user data off the device, including transmission to third-party servers. Therefore the Data safety form must be answered from the actual network behavior, not only from whether Runbickers stores a database.

## Recommended review before submission

1. Inspect all dependencies and the final release manifest.
2. Confirm no SDK performs analytics, crash reporting, advertising, or identifier collection.
3. Decide whether wallet-query metadata and transaction information fall under Google's current "financial information" categories for the final implementation.
4. If a data type is transmitted off-device, declare it accurately even if processing is ephemeral.
5. User-initiated transfers may qualify for a "sharing" exception, but that does not automatically remove the need to consider whether the data is "collected."
6. Keep the Privacy Policy consistent with the final Data safety answers.

## Current conservative position

Do **not** simply select "no data collected" without reviewing the ElectrumX traffic against the current Play definitions. Although UTXO Control has no analytics/backend database, blockchain query identifiers and signed transactions leave the device as part of core wallet functionality.

Private keys/WIFs are not transmitted and should never be declared as collected because the app does not send them off-device.
