# FlareIMUI

Flare IM UI Kit — **iOS / SwiftUI** component package (L1).

One framework-neutral contract
([`@flare-im/ui-spec`](https://github.com/flare-im/flare-im-design/tree/main/spec)),
realised natively. Design tokens are generated from
[`@flare-im/tokens`](https://github.com/flare-im/flare-im-design/tree/main/tokens)
into `Sources/FlareIMUI/Tokens/FlareTokens.swift` (do not edit by hand — re-run the
tokens generator). Components are **pure/presentational** — data in, callbacks out; IM
behaviour and state live in the Rust core's observable views and are fed in by the host
app.

## Install (Swift Package Manager)

不发布到 CocoaPods，直接从 GitHub 引入；版本由 git tag 决定。

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/flare-im/flare-im-design.git", from: "1.0.5"),
],
// target deps: .product(name: "FlareIMUI", package: "flare-im-design")
```

SPM 消费的是**仓库根目录**的 `Package.swift`（本目录下的那份仅供在此目录内
`swift build` / `swift test`）。其他引入方式（本地路径、submodule）见
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
../assets/emoji-sticker/fetch-assets.sh   # 从 GitHub Release assets-v1 拉 webp
./sync-resources.sh                       # 镜像进本包
```

不拉的表现是 `FlareEmojiStickerCatalog` 能列出全部 key/pack，但 `emojiImageURL` /
`stickerImageURL` 返回 nil、图片位置空白；`testBundledWebpDecodesToFrames` 会以
skip 报告而不是失败。

改了 `assets/emoji-sticker` 里的契约文件后要重跑 `./sync-resources.sh` 并把镜像一起
提交，`spec/validate.mjs` 校验两边字节一致。

## Components (all 18 spec components)

| Category | Symbols |
|---|---|
| General | `AvatarView` · `TimeStampView` · `MessageStatusView` |
| Conversation | `ConversationRowView` · `ConversationListView` · `ConversationDetailsView` · `StartConversationView` |
| Message | `MessageBubbleView` · `MessageListView` · `MessageContentView` · `ChatHeaderView` · `PinnedMessageBarView` |
| Composer | `ComposerView` · `RichMarkdownInputView` · `MessageActionSheetView` |
| Media | `ImagePreviewView` · `VideoPlayerView` · `MarkdownPreviewView` |

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
Rectangle().fill(colors.bubbleSelf)
```

Content types (`MessageContentView` / bubble bodies): text, image, video, audio, file,
location, card, sticker, emoji, notification, placeholder — plus `FlareGenericContent`
for product types and `FlareContentRegistry.register(type) { content, ctx in AnyView(…) }`.

## Develop

```bash
swift build     # compiles on the Mac host
swift test      # smoke tests

# regenerate tokens after editing tokens.json
cd ../tokens && npm run build
```
