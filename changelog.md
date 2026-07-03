# Changelog / 更新日志

## 0.1.1
- 升级最低系统要求至 macOS 13
  - Raised minimum supported macOS version to macOS 13
- 新增“开机启动”开关，放入设置窗口中显示
  - Added launch-at-login support and exposed it in the Settings window
- 优化状态栏菜单“重新启动监听”文案并补充快捷键说明
  - Refined the status bar menu label for restarting the listener and added keyboard shortcut guidance
- 从构建元数据 / changelog 中读取应用版本号，并在设置页面中显示
  - Sourced app version from build metadata / changelog and displayed it in Settings
- 移除频繁输入事件中的噪声日志，降低 CPU 使用负担
  - Removed noisy per-key logging in input callbacks to reduce CPU usage

## 0.1.0
- 完成对原版 Tickeys 的 Swift 重写
  - Completed the Swift rewrite of the original Tickeys
- 保留并实现原始应用的全部核心功能
  - Retained and implemented all core features of the original app
- 引入 macOS 原生打包支持与统一构建流程
  - Added native macOS packaging support and a unified build workflow
- 新增可生成 `.icns` 图标资源的自动生成脚本
  - Added an icon generation script that can automatically create `.icns` assets
