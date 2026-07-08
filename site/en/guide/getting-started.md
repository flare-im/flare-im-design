# Getting started

Flare IM Design is a **cross-platform IM UI kit**: one framework-neutral component contract, implemented natively on Vue, Flutter, iOS and Android, sharing the same design tokens and same-name / same-semantics components.

## Architecture layers

| Layer | Content | Location |
|---|---|---|
| **L4** | Observable views (behavior: send / sync / ordering / optimistic UI) | Rust `flare-im-core-sdk` (`client.views`) |
| **L3** | Design tokens (color / spacing / type / radius / shadow, light + dark) | `flare-im-design/tokens` |
| **L2** | Component contract (props / states / events + data source) | `flare-im-design/spec` |
| **L1** | Per-platform component packages | Vue / Flutter / iOS / Android |

Components are **pure presentation**: props in, callbacks out. IM behavior and state come from the core's observable views and are fed to components by the host app.

## Install

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

## Minimal example: one message bubble

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

## Next steps

- [Design tokens](/en/guide/tokens) — the single source for color, spacing and type, and its four platform outputs.
- [Components](/en/components/) — the contract, examples and four-platform usage for all 51 components.
- [Component spec](/en/guide/spec) — the L2 spec structure and its drift-prevention check.
