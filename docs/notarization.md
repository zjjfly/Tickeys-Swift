# Notarization

The Swift rewrite can be packaged without Xcode. Local debug builds use ad-hoc
signing by default, while release distribution should use Developer ID signing
and Apple notarization.

## Build and Sign

Set `DEVELOPER_ID` to the Developer ID Application identity suffix shown by
`security find-identity -v -p codesigning`.

```sh
DEVELOPER_ID="Your Team Name (TEAMID)" make build-universal
```

This runs `scripts/build-app.sh`, creates `.build/app/Tickeys-Swift.app`, and signs the
bundle with hardened runtime.

## Notarize

Create a zip for notarization:

```sh
ditto -c -k --keepParent .build/app/Tickeys-Swift.app .build/Tickeys-Swift.app.zip
```

Submit with Command Line Tools `notarytool`:

```sh
xcrun notarytool submit .build/Tickeys-Swift.app.zip \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --wait
```

Staple the accepted ticket:

```sh
xcrun stapler staple .build/app/Tickeys-Swift.app
spctl --assess --type execute --verbose .build/app/Tickeys-Swift.app
```

`APPLE_APP_PASSWORD` should be an app-specific password or a keychain profile in
CI. Do not commit credentials.
