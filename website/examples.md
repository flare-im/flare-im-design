# Examples

Flare UI 提供两类示例，二者用途不同。

## 组件示例

本站 Component Catalog 中的预览使用内存态与静态数据，用于检查单个组件的 API、状态、主题、响应式和可访问性。它们不初始化 Flare SDK，也不代表完整产品装配。

- [Component Catalog](/components/)
- [Build an IM App](/app-kit/)
- [Customization](/customization/)

## 真实 SDK 参考应用

以下应用位于 `flare-im-core-client-sdk`，保留真实 SDK 初始化、认证、事件订阅、同步、发送、重试、媒体、生命周期和平台桥，同时仅通过各设计包公共 API 组装 UI。

这些 Reference Apps 专注会话与消息，不提供联系人目录、群目录或关系链入口。群会话仍可作为消息目标出现在会话列表中。

- [Web / Vue](https://github.com/flare-im/flare-im-core-client-sdk/tree/main/examples/flare-core-web-app)
- [Tauri / Vue](https://github.com/flare-im/flare-im-core-client-sdk/tree/main/examples/flare-core-tauri-app)
- [Flutter](https://github.com/flare-im/flare-im-core-client-sdk/tree/main/examples/flare-core-flutter-app)
- [Android / Jetpack Compose](https://github.com/flare-im/flare-im-core-client-sdk/tree/main/examples/flare-core-android-app)
- [iOS / SwiftUI](https://github.com/flare-im/flare-im-core-client-sdk/tree/main/examples/flare-core-ios-app)

需要验证组件视觉时使用组件示例；需要复制真实 SDK 装配、状态流或平台桥时使用参考应用。
