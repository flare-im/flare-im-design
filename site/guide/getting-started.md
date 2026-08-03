# 快速开始

Flare IM Design 是一套**独立可用的跨端 IM UI 组件库**：一份框架中立的组件契约，在 Vue、Flutter、iOS、Android 上各自原生实现，共享同一套设计 Tokens 与同名同语义的组件。组件是**纯展示**——props 进、事件出，**不绑定任何 SDK**，接你现有的 IM 后端即可跑。

## 架构分层

组件库本身是 **L1–L3，独立可用**；数据从哪来（L4）由你决定。

| 层 | 内容 | 位置 |
|---|---|---|
| **L4 · 可选** | 数据源：你的 IM 后端 / SDK，或 Flare core 的可观察视图（可靠发送 / 同步 / 排序 / 乐观 UI） | 你的后端 · 或 Rust `flare-im-core-sdk`（`client.views`） |
| **L3** | 设计 Tokens（颜色 / 间距 / 字号 / 圆角 / 阴影，明暗双主题，运行时可换肤） | `flare-im-design/tokens` |
| **L2** | 组件契约（props / states / events + 数据形状） | `flare-im-design/spec` |
| **L1** | 各端组件包（纯展示） | Vue / Flutter / iOS / Android |

你把数据（会话、消息、联系人…）用 props 喂给组件、监听它抛出的交互事件即可。数据可以来自你现有的 IM 后端 / SDK；也可以**可选**接 Flare core 的可观察视图，直接拿到可靠收发与多端同步——但组件本身不依赖它。

## 安装

::: code-group

```bash [Vue]
npm i @flare-im/vue-ui vue naive-ui vue-router
```

```yaml [Flutter]
# pubspec.yaml
dependencies:
  flare_im_ui:
    path: ../../flare-im-design/flutter-im-ui
```

```swift [iOS]
// Package.swift
dependencies: [ .package(path: "../flare-im-design/ios-im-ui") ]
// target: .product(name: "FlareIMUI", package: "FlareIMUI")
```

```kotlin [Android]
// settings.gradle.kts
include(":flare-im-ui-compose")
project(":flare-im-ui-compose").projectDir =
    file("../../flare-im-design/android-im-ui")
```

:::

## 最小示例：一条消息气泡

::: code-group

```vue [Vue]
<script setup>
import { MessageBubble } from "@flare-im/vue-ui";
import "@flare-im/vue-ui/style.css";
</script>
<template>
  <MessageBubble :message="msg" current-user-id="me" />
</template>
```

```dart [Flutter]
FlareMessageBubble(
  message: msg,               // FlareMessageData
  currentUserId: 'me',
);
```

```swift [iOS]
MessageBubbleView(message: msg, currentUserId: "me")
```

```kotlin [Android]
MessageBubble(message = msg, currentUserId = "me")
```

:::

## 下一步

- [设计 Tokens](/guide/tokens) — 颜色、间距、字号的单一源与四端生成物。
- [组件](/components/) — 全部 107 个组件的契约、示例与四端用法。
- [组件契约](/guide/spec) — L2 spec 的结构与防漂移校验。
