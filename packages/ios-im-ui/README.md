# FlareIMUI

`IMAppKitView` is the public adaptive shell. Its primary pane is optional for
full-width workspaces, and `hideMobileNavigation` removes the bottom bar while
a compact conversation route is open.

Flare IM UI Kit — **iOS / SwiftUI** component package (L1).

One framework-neutral contract
([`@flare-im/ui-spec`](https://github.com/flare-im/flare-im-design/tree/main/spec)),
realised natively. Design tokens are generated from
[`@flare-im/tokens`](https://github.com/flare-im/flare-im-design/tree/main/tokens)
into `Sources/FlareIMUI/Tokens/FlareTokens.swift` (do not edit by hand — re-run the
tokens generator). Components are **pure/presentational**: data in, callbacks out. The
host owns its backend, persistence, permissions, and side effects.

## Install (Swift Package Manager)

本目录是自包含 Swift package。从 monorepo 开发时使用本地路径；远程发布必须将此目录作为独立 Swift package 产物发布，不依赖仓库根转发清单。

```swift
// Package.swift
dependencies: [
    .package(path: "../flare-im-design/packages/ios-im-ui"),
],
// target deps: .product(name: "FlareIMUI", package: "ios-im-ui")
```

Xcode 使用 Add Local Package 时选择 `packages/ios-im-ui`。其他引入方式见
[手动引入指南](https://github.com/flare-im/flare-im-design/blob/main/docs/MANUAL-INSTALL-ANDROID-IOS.md)。

```swift
import FlareIMUI
```

> The package declares `macOS(.v13)` alongside `iOS(.v16)` so it can be built and
> smoke-tested on a Mac host (`swift build` / `swift test`) without a simulator; the
> components use cross-platform SwiftUI only.

## 从仓库克隆后首次构建

表情/贴纸资源镜像（`Sources/FlareIMUI/Resources/emoji-sticker`）是 `assets/emoji-sticker`
的副本（SwiftPM 不跟随符号链接）。它分两层：

- **文本契约**（`manifest.json`、`emoji-locales.json`、`stickers/*/manifest.json`）
  **在版本控制里**。有它们目录就存在，SwiftPM 才生成 `Bundle.module`，干净检出
  `swift build` / `swift test` 直接能过。
- **webp 二进制**（250 个，67MB）**不在版本控制里**。两份都入库曾让仓库多扛 134MB，
  实测导致完整 `git clone` 失败，而 SPM 只能完整克隆。

所以克隆后编译不需要任何前置步骤；要在界面上看到表情/贴纸图片则要拉一次二进制：

```bash
../../assets/emoji-sticker/fetch-assets.sh   # 从 GitHub Release assets-v1 拉 webp
./sync-resources.sh                       # 镜像进本包
```

不拉的表现是 `FlareEmojiStickerCatalog` 能列出全部 key/pack，但 `emojiImageURL` /
`stickerImageURL` 返回 nil、图片位置空白；`testBundledWebpDecodesToFrames` 会以
skip 报告而不是失败。

改了 `assets/emoji-sticker` 里的契约文件后要重跑 `./sync-resources.sh` 并把镜像一起
提交，`spec/validate.mjs` 校验两边字节一致。

## Components

The current symbols and their Vue/Flutter/Compose equivalents are generated in
[`spec/public-export-map.json`](../../spec/public-export-map.json). The package
includes General, Conversation, Message, Composer, Media, Contacts, Call,
Profile, Form, Layout, and Pattern components.

## Examples

```swift
// The inbox
ConversationListView(items: rows, activeId: openId) { row in open(row.id) }

// The thread
MessageListView(
    messages: timeline,                 // [FlareMessageData]
    currentUserId: me.id,
    conversationKind: .group,
    mediaDownloadStates: mediaStates,   // [id: FlareMediaDownloadState]
    onMessageLongPress: { showActions(for: $0) },
    onMediaAction: { _, content in open(content) },
    onResend: { resend($0.id) }
)

// The composer (optimistic send)
ComposerView(rich: false) { text in sendOptimistic(text) }

// Tokens
let colors = FlareColors.of(colorScheme)   // .light / .dark
Rectangle().fill(colors.messageOutgoingBackground)
```

Content types (`MessageContentView` / bubble bodies): text, image, video, audio, file,
location, card, sticker, emoji, notification, placeholder — plus `FlareGenericContent`
for product types and `FlareContentRegistry.register(type) { content, ctx in AnyView(…) }`.

## Develop

```bash
swift build     # compiles on the Mac host
swift test      # smoke tests

# regenerate tokens after editing tokens.json
cd ../../tokens && npm run build
```
