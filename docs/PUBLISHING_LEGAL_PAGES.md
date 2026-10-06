# Publishing Legal Pages — UTXO Control

## Recommended structure

Keep the source documents in this repository:

- `docs/PRIVACY_POLICY.md`
- `docs/TERMS_OF_USE.md`
- `SECURITY.md`
- `README.md`

For Google Play, publish the Privacy Policy at a stable public HTTPS URL.

## Preferred hosting

Best option:

**runbickers.com/utxo-control/privacy**

with the content generated from `docs/PRIVACY_POLICY.md`.

Second-best option:

GitHub Pages from this public repository, for example:

**https://jeongwooshin.github.io/BTCMobickCoinControl/privacy/**

The store URL should be:

- publicly accessible without login;
- HTTPS;
- not geofenced;
- not a PDF;
- stable across releases.

## Why keep both repository and web copy?

The repository is the canonical version-controlled source. The website is the user-facing stable URL for Play Store review and ordinary users.

When the policy changes, update the repository first and then deploy the same revision to the public web page.
