# Tickeys-Swift

[English](README.md) | [简体中文](README.zh-CN.md)

Tickeys-Swift 是一个原生 macOS 菜单栏应用，可以在你打字时播放键盘音效。

它是 Tickeys 的 Swift 重写版本，不再依赖 OpenAL/freealut 运行时，并提供
SwiftUI 设置窗口。

## 功能

- 全局键盘声音反馈。
- 内置多种音效方案，包括冒泡、打字机、机械键盘、剑气、Cherry G80 和鼓声。
- 音量和音调控制。
- 黑名单模式：在选中的应用中静音键盘音效。
- 白名单模式：只在选中的应用中播放键盘音效。
- 菜单栏应用和轻量设置窗口。
- 英文和简体中文本地化。

Tickeys-Swift 需要辅助功能权限，因为它需要监听全局键盘事件。

## 音效方案

内置音效方案位于：

```text
Resources/data
```

`Resources/data/schemes.json` 保持兼容旧版 Tickeys 的 scheme 格式，因此自定义
音效方案仍然可以使用：

```json
{
  "name": "myDrum",
  "display_name": "My Drum",
  "files": ["1.wav", "2.wav", "3.wav", "4.wav", "space.wav", "backspace.wav", "enter.wav"],
  "non_unique_count": 4,
  "key_audio_map": {"36": 6, "49": 4, "51": 5}
}
```

## 开发

构建、本地安装、打包、签名和公证说明见
[docs/development.md](docs/development.md)。

## 许可

应用代码基于 MIT License 分发。见 [LICENSE](LICENSE)。

内置音效资源有各自的说明和许可。见 [NOTICE.md](NOTICE.md) 以及
`Resources/data` 下的 license/readme 文件。
