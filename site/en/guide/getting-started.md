# Getting started

Flare IM Design is a **standalone, cross-platform IM UI kit**: one framework-neutral component contract, implemented natively on Vue, Flutter, iOS and Android, sharing the same design tokens and same-name / same-semantics components. Components are **pure presentation** — props in, events out, **no SDK lock-in** — so they drop onto your existing IM backend.

## Architecture layers

The kit itself is **L1–L3, usable on its own**; where the data (L4) comes from is up to you.

| Layer | Content | Location |
|---|---|---|
| **L4 · optional** | Data source: your IM backend / SDK, or the Flare core's observable views (reliable send / sync / ordering / optimistic UI) | Your backend · or Rust `flare-im-core-sdk` (`client.views`) |
| **L3** | Design tokens (color / spacing / type / radius / shadow, light + dark, re-themeable at runtime) | `flare-im-design/tokens` |
| **L2** | Component contract (props / states / events + the data it takes) | `flare-im-design/spec` |
| **L1** | Per-platform component packages (pure presentation) | Vue / Flutter / iOS / Android |

Feed data (conversations, messages, contacts…) to the components via props and listen for the interaction events they emit. That data can come from your existing IM backend / SDK; or you can **optionally** wire the Flare core's observable views for reliable send and multi-device sync — but the components don't depend on it.

## Install

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

## Minimal example: one message bubble

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

## Next steps

- [Design tokens](/en/guide/tokens) — the single source for color, spacing and type, and its four platform outputs.
- [Components](/en/components/) — the contract, examples and four-platform usage for all 107 components.
- [Component spec](/en/guide/spec) — the L2 spec structure and its drift-prevention check.
