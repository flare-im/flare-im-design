# Getting started

Flare IM Design is a **standalone, cross-platform IM UI kit**: one framework-neutral component contract, implemented natively on Vue, Flutter, iOS and Android, sharing the same design tokens and same-name, same-semantics components. Components receive state through properties and emit interaction intents without selecting a backend implementation.

## Architecture layers

The kit itself is **L1–L3, usable on its own**; where the data (L4) comes from is up to you.

| Layer | Content | Location |
|---|---|---|
| **L4 · host application** | Data adapters, state management, sending, sync, ordering, and persistence | Consumer code |
| **L3** | Design tokens (color / spacing / type / radius / shadow, light + dark, re-themeable at runtime) | `flare-im-design/tokens` |
| **L2** | Component contract (props / states / events + the data it takes) | `flare-im-design/spec` |
| **L1** | Per-platform component packages (pure presentation) | Vue / Flutter / iOS / Android |

Pass conversations, messages, contacts, and other state into the components, then handle the interaction intents they emit. The library does not select a network protocol, state container, or backend SDK.

## Install

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

## Minimal example: one message bubble

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

## Five-minute path

1. Install the package and connect generated tokens/theme.
2. Render [Button](/en/components/button) and verify theme, focus, and disabled state.
3. Render the first conversation with [ConversationRow](/en/components/conversation-row).
4. Render message content and lifecycle projection with [MessageBubble](/en/components/message-bubble) and [MessageMeta](/en/components/message-meta).
5. Use [Composer](/en/components/composer) for controlled input and handle its `send` intent.
6. Follow [Chat Workspace](/en/patterns/chat-workspace) to compose Header, MessageList, Composer, loading/empty/error/offline, and retry.

This path does not require reading repository architecture first. Open [Foundations](/en/foundations/) and the [IM UI Guide](/en/im/) when you need customization or extension.

## Next steps

- [Design tokens](/en/guide/tokens) — the single source for color, spacing and type, and its four platform outputs.
- [Components](/en/components/) — contracts, examples, and four-platform usage for every public component.
- [Component spec](/en/guide/spec) — the L2 spec structure and its drift-prevention check.
