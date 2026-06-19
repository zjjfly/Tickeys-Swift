# Tickeys-Swift

[English](README.md) | [简体中文](README.zh-CN.md)

Tickeys-Swift is a native macOS menu bar app that plays keyboard sound effects
as you type.

It is a Swift rewrite of [Tickeys](https://github.com/yingDev/Tickeys), with no OpenAL/freealut runtime dependency and
a SwiftUI settings window.

## Features

- Global keyboard sound feedback.
- Built-in sound schemes, including bubble, typewriter, mechanical keyboard,
  sword, Cherry G80, and drum sounds.
- Volume and pitch controls.
- Blacklist mode: mute keyboard sounds in selected apps.
- Whitelist mode: only play keyboard sounds in selected apps.
- Menu bar app with a lightweight settings window.
- English and Simplified Chinese localization.

Tickeys-Swift requires Accessibility permission because it listens for global
keyboard events.

## Sound Schemes

Built-in sound schemes live in:

```text
Resources/data
```

`Resources/data/schemes.json` keeps the legacy Tickeys scheme format, so custom
schemes can continue to use:

```json
{
  "name": "myDrum",
  "display_name": "My Drum",
  "files": ["1.wav", "2.wav", "3.wav", "4.wav", "space.wav", "backspace.wav", "enter.wav"],
  "non_unique_count": 4,
  "key_audio_map": {"36": 6, "49": 4, "51": 5}
}
```

## Development

Build, local install, packaging, signing, and notarization notes are in
[docs/development.md](docs/development.md).

## License

Application code is distributed under the MIT License. See [LICENSE](LICENSE).

Bundled sound resources have their own notices and licenses. See
[NOTICE.md](NOTICE.md) and the license/readme files under `Resources/data`.
