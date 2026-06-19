# Development

Tickeys-Swift uses SwiftPM and a manual `.app` bundle script. Full Xcode is not
required.

## Build

Run tests and build a local app bundle:

```sh
make test
make app
```

The local app bundle is written to:

```text
.build/app/Tickeys-Swift.app
```

For a universal Intel + Apple Silicon app:

```sh
make build-universal
```

## Local Install

```sh
pkill Tickeys-Swift
rm -rf /Applications/Tickeys-Swift.app
cp -R .build/app/Tickeys-Swift.app /Applications/Tickeys-Swift.app
open /Applications/Tickeys-Swift.app
```

The app uses bundle id `github.zjjfly.Tickeys-Swift`. Grant Accessibility
permission in System Settings > Privacy & Security > Accessibility.

During local development, rebuilding or reinstalling may require removing the
old Accessibility entry and re-adding `/Applications/Tickeys-Swift.app`.

## Packaging

`scripts/build-app.sh` creates `.build/app/Tickeys-Swift.app`, copies resources,
writes `Info.plist`, copies `LICENSE` and `NOTICE.md`, and signs the bundle.
Local builds are ad-hoc signed by default.

For Developer ID signing:

```sh
DEVELOPER_ID="Your Team Name (TEAMID)" make build-universal
```

See [notarization.md](notarization.md) for notarization steps.
