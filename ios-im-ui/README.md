# FlareIMUI

Flare IM UI Kit — **iOS / SwiftUI** component package (L1).

One framework-neutral contract ([`flare-im-ui-spec`](../spec)), realised natively.
Design tokens are generated from [`flare-im-design-tokens`](../tokens) into
`Sources/FlareIMUI/Tokens/FlareTokens.swift` (do not edit by hand — re-run the tokens
generator). Components are **pure/presentational** — data in, callbacks out; IM behaviour
and state live in the Rust core's observable views and are fed in by the host app.

## Install (Swift Package Manager)

```swift
// Package.swift
dependencies: [
    .package(path: "../../flare-im-design/ios-im-ui"),
],
// target deps: .product(name: "FlareIMUI", package: "FlareIMUI")
```

```swift
import FlareIMUI
```

> The package declares `macOS(.v13)` alongside `iOS(.v16)` so it can be built and
> smoke-tested on a Mac host (`swift build` / `swift test`) without a simulator; the
> components use cross-platform SwiftUI only.

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
