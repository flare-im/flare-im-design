# 快速开始

Flare IM Design 是一套**跨端 IM UI 组件库**：一份框架中立的组件契约，在 Vue、Flutter、iOS、Android 上各自原生实现，共享同一套设计 Tokens 与同名同语义的组件。

## 架构分层

| 层 | 内容 | 位置 |
|---|---|---|
| **L4** | 可观察视图（行为：发送/同步/排序/乐观 UI） | Rust `flare-im-core-sdk`（`client.views`） |
| **L3** | 设计 Tokens（颜色/间距/字号/圆角/阴影，明暗双主题） | `flare-im-design/tokens` |
| **L2** | 组件契约（props/states/events + 数据源） | `flare-im-design/spec` |
| **L1** | 各端组件包 | Vue / Flutter / iOS / Android |

组件是**纯展示**：props 进、回调出。IM 行为与状态来自 core 的可观察视图，由宿主应用喂给组件。

## 安装

::: code-group

```bash [Vue]
npm i flare-core-vue-im-ui vue naive-ui vue-router
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
import { MessageBubble } from "flare-core-vue-im-ui";
import "flare-core-vue-im-ui/style.css";
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
- [组件](/components/) — 全部 51 个组件的契约、示例与四端用法。
- [组件契约](/guide/spec) — L2 spec 的结构与防漂移校验。
