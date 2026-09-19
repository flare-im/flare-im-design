# 快速开始

Flare IM Design 是一套**独立可用的跨端 IM UI 组件库**：一份框架中立的组件契约，在 Vue、Flutter、iOS、Android 上各自原生实现，共享同一套设计 Tokens 与同名同语义的组件。组件是**纯展示**，由属性接收状态并通过事件表达意图，不绑定后端实现。

## 架构分层

组件库本身是 **L1–L3，独立可用**；数据从哪来（L4）由你决定。

| 层 | 内容 | 位置 |
|---|---|---|
| **L4 · 宿主应用** | 数据适配、状态管理、发送、同步、排序和持久化 | 使用方代码 |
| **L3** | 设计 Tokens（颜色 / 间距 / 字号 / 圆角 / 阴影，明暗双主题，运行时可换肤） | `flare-im-design/tokens` |
| **L2** | 组件契约（props / states / events + 数据形状） | `flare-im-design/spec` |
| **L1** | 各端组件包（纯展示） | Vue / Flutter / iOS / Android |

使用方将会话、消息和联系人等状态传给组件，并处理组件发出的交互意图。组件库不选择网络协议、状态容器或后端 SDK。

## 安装

::: code-group

```bash [Vue]
npm i @flare-im/vue-ui vue naive-ui
```

```yaml [Flutter]
# pubspec.yaml
dependencies:
  flare_im_ui:
    path: ../../flare-im-design/packages/flutter-im-ui
```

```swift [iOS]
// Package.swift
dependencies: [ .package(path: "../flare-im-design/packages/ios-im-ui") ]
// target: .product(name: "FlareIMUI", package: "ios-im-ui")
```

```kotlin [Android]
// settings.gradle.kts
include(":flare-im-ui-compose")
project(":flare-im-ui-compose").projectDir =
    file("../../flare-im-design/packages/android-im-ui")
```

:::

## 最小示例：一条消息气泡

::: code-group

```vue [Vue]
<script setup>
import { FlareMessageBubble } from "@flare-im/vue-ui";
import "@flare-im/vue-ui/style.css";
</script>
<template>
  <FlareMessageBubble :message="msg" current-user-id="me" />
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

## 5 分钟路径

1. 安装 package 并接入生成 tokens / theme。
2. 渲染 [Button](/components/button)，确认主题、focus 和 disabled 状态。
3. 用 [ConversationRow](/components/conversation-row) 渲染第一条会话。
4. 用 [MessageBubble](/components/message-bubble) 与 [MessageMeta](/components/message-meta) 渲染消息和生命周期投影。
5. 用 [Composer](/components/composer) 接收受控输入并处理 `send` intent。
6. 按 [Chat Workspace](/patterns/chat-workspace) 组合 Header、MessageList、Composer、loading/empty/error/offline 和 retry。

这条路径不需要先理解仓库架构；需要定制或扩展时再进入 [Foundations](/foundations/) 与 [IM UI Guide](/im/)。

## 下一步

- [设计 Tokens](/guide/tokens) — 颜色、间距、字号的单一源与四端生成物。
- [组件](/components/) — 全部公共组件的契约、示例与四端用法。
- [组件契约](/guide/spec) — L2 spec 的结构与防漂移校验。
