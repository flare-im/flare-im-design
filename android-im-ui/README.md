# flare-im-ui-compose

Flare IM UI Kit — **Android / Jetpack Compose** component library (L1).

One framework-neutral contract
([`flare-im-ui-spec`](https://github.com/flare-im/flare-im-design/tree/main/spec)),
realised natively. Design tokens are generated from
[`flare-im-design-tokens`](https://github.com/flare-im/flare-im-design/tree/main/tokens)
into `src/main/kotlin/com/flare/im/ui/FlareTokens.kt` (do not edit by hand — re-run the
tokens generator). Composables are **pure/presentational** — data in, callbacks out; IM
behaviour and state live in the Rust core's observable views and are fed in by the host
app.

- Package: `com.flare.im.ui` · namespace `com.flare.im.ui`
- Min SDK 26 · compileSdk 35 · Kotlin 2.2.20 · Compose BOM 2024.12.01 · JDK 17

## Install

不发布到 Maven Central，产物放 GitHub。完整说明见
[手动引入指南](https://github.com/flare-im/flare-im-design/blob/main/docs/MANUAL-INSTALL-ANDROID-IOS.md)。

**源码依赖（推荐，依赖自动传递）** —— `settings.gradle.kts`：

```kotlin
include(":im-ui-compose")
project(":im-ui-compose").projectDir = file("vendor/flare-im-design/android-im-ui")
```

**AAR** —— 从 [Releases](https://github.com/flare-im/flare-im-design/releases) 下载
`im-ui-compose-1.0.5.aar`。⚠️ AAR 不带 POM，必须自己补 Compose BOM / material3 /
material-icons-extended / coil 等 8 个依赖，否则运行时 `NoClassDefFoundError`。

```kotlin
import com.flare.im.ui.*
```

## Components (all 18 spec components)

| Category | Composables |
|---|---|
| General | `Avatar` · `TimeStamp` · `MessageStatus` |
| Conversation | `ConversationRow` · `ConversationList` · `ConversationDetails` · `StartConversationDialog` |
| Message | `MessageBubble` · `MessageList` · `MessageContentView` · `ChatHeader` · `PinnedMessageBar` |
| Composer | `Composer` · `RichMarkdownInput` · `MessageActionSheet` |
| Media | `ImagePreview` · `VideoPlayer` · `MarkdownPreview` |

## Examples

```kotlin
// The thread
MessageList(
    messages = timeline,                 // List<FlareMessageData>
    currentUserId = me.id,
    conversationKind = FlareConversationKind.Group,
    mediaDownloadStates = mediaStates,   // Map<id, FlareMediaDownloadState>
    onMessageLongPress = { showActions(it) },
    onMediaAction = { _, content -> open(content) },
    onResend = { resend(it.id) },
)

// The composer (optimistic send)
Composer(rich = false, onSend = { text -> sendOptimistic(text) })

// Tokens
val colors = flareColors()               // theme-aware (isSystemInDarkTheme)
Box(Modifier.background(colors.bubbleSelf))
```

Content types (`MessageContentView` / bubble bodies): text, image, video, audio, file,
location, card, sticker, emoji, notification, placeholder — plus `FlareGenericContent`
for product types and `FlareContentRegistry.register(type) { content, ctx -> … }`.

> **Media loading**: the library bundles no image loader. `Avatar`, `ImagePreview` and
> `VideoPlayer` accept a composable slot for a real image/player (e.g. Coil `AsyncImage`,
> ExoPlayer `AndroidView`); `MessageContentView` shows placeholders for image/video and
> defers real loading to a registered content builder or the host.

## Develop

```bash
JAVA_HOME=/path/to/jdk17 ./gradlew compileDebugKotlin   # compile gate
JAVA_HOME=/path/to/jdk17 ./gradlew testDebugUnitTest     # unit tests

# regenerate tokens after editing tokens.json
cd ../tokens && npm run build
```
