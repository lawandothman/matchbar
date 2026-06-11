# World Cup App

World Cup 2026 in your menu bar. Shows live scores while matches are on, fixtures and group tables in a popover, and sends goal notifications.

No API key, no setup — data comes from ESPN's public scoreboard API.

## Build

```sh
make run   # dev
make app   # bundle WorldCupApp.app
```

## Notifications

Goal, kickoff and full-time notifications only work from the bundled app (`make app`) — macOS won't deliver them for a bare `swift run` binary.

## Release

One-time setup:

1. Create a **Developer ID Application** certificate: Xcode → Settings → Accounts → Manage Certificates → + → Developer ID Application.
2. Create an App Store Connect API key (Users and Access → Integrations → App Store Connect API, role Developer), download the `.p8`, then store it:

   ```sh
   xcrun notarytool store-credentials worldcup-notary \
     --key AuthKey_XXXXXXXXXX.p8 --key-id XXXXXXXXXX --issuer ISSUER-UUID
   ```

Then `make release` signs, notarizes, staples, and produces a distributable `WorldCupApp.dmg`.

### CI releases

Pushing a tag like `v0.2.0` builds, signs, notarizes, and publishes a GitHub Release automatically. Required repo secrets:

| Secret | Value |
|---|---|
| `DEVELOPER_ID_P12` | base64 of the exported Developer ID Application cert (`base64 -i cert.p12`) |
| `DEVELOPER_ID_P12_PASSWORD` | password chosen when exporting the .p12 |
| `NOTARY_KEY` | contents of the App Store Connect API `.p8` key |
| `NOTARY_KEY_ID` | the key's ID |
| `NOTARY_ISSUER_ID` | issuer ID from the App Store Connect API page |
