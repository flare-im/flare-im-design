# flare_im_ui

Flare IM UI Kit — **Flutter** component package (L1).

One framework-neutral contract
([`flare-im-ui-spec`](https://github.com/flare-im/flare-im-design/tree/main/spec)),
realised natively per platform. Design tokens are generated from
[`flare-im-design-tokens`](https://github.com/flare-im/flare-im-design/tree/main/tokens)
into `lib/src/tokens/flare_tokens.dart` (do not edit by hand — re-run the tokens
generator).

Components are **pure / presentational**: props in, callbacks out. IM behaviour and
state live in the Rust core's observable views and are fed in by the host app — the
same model as the Vue package
[`flare-core-vue-im-ui`](https://github.com/flare-im/flare-im-design/tree/main/vue-im-ui).

## Install

```bash
flutter pub add flare_im_ui
```

```yaml
# pubspec.yaml
dependencies:
  flare_im_ui: ^1.0.5
```

```dart
import 'package:flare_im_ui/flare_im_ui.dart';
```

## Components (all 18 spec components)

| Category | Component | Symbol |
|---|---|---|
| General | Avatar | `FlareAvatar` |
| General | TimeStamp | `FlareTimeStamp` |
| General | MessageStatus | `FlareMessageStatus` |
| Conversation | ConversationRow | `FlareConversationRow` |
| Conversation | ConversationList | `FlareConversationList` |
| Conversation | ConversationDetails | `FlareConversationDetails` |
| Conversation | StartConversation | `FlareStartConversationSheet` |
| Message | MessageBubble | `FlareMessageBubble` |
| Message | MessageList | `FlareMessageList` |
| Message | MessageContentView | `FlareMessageContentView` |
| Message | ChatHeader | `FlareChatHeader` |
| Message | PinnedMessageBar | `FlarePinnedMessageBar` |
| Composer | Composer | `FlareComposer` |
| Composer | RichMarkdownInput | `FlareRichMarkdownInput` |
| Composer | MessageActionSheet | `FlareMessageActionSheet` |
| Media | ImagePreview | `FlareImagePreview` |
| Media | VideoPlayer | `FlareVideoPlayer` |
| Media | MarkdownPreview | `FlareMarkdownPreview` |

Content types (`FlareMessageContentView` / bubble bodies): text, image, video, audio,
file, location, card, linkCard, sticker, emoji, notification, placeholder — plus
`FlareGenericContent` for product types and `FlareContentRegistry.register(type, builder)`
to add/override a renderer.

### FlareAvatar

Image, or deterministic initials fallback, plus an optional presence dot.

```dart
FlareAvatar(
  userId: user.id,
  displayName: user.name,
  avatarUrl: user.avatarUrl,   // omit/empty → initials
  size: 42,                    // defaults to FlareSizes.avatarSize
  presence: FlarePresence.online,
)
```

### FlareTimeStamp

Muted timestamp label — you format the string upstream.

```dart
FlareTimeStamp(label: formatRelative(message.sentAt)) // "刚刚", "14:32", "昨天"…
```

### FlareMessageStatus

Delivery state for outgoing bubbles.

```dart
FlareMessageStatus(
  status: FlareMessageDeliveryStatus.read, // pending | sent | read | failed
  variant: FlareMessageStatusVariant.tick, // tick | compact
)
```

### FlareConversationRow / FlareConversationList

The inbox. Map each core conversation-list-view item into a `ConversationRowData`
(product formatting — emoji/sticker inlining, i18n, group sender prefix — resolved
upstream into the plain `preview` string). The list virtualises (`ListView.builder`).

```dart
FlareConversationList(
  items: rows,                 // List<ConversationRowData>
  activeId: openId,
  loading: firstLoad,
  onSelect: (row) => openConversation(row.id),
  onLongPress: (row) => showRowMenu(row),   // host owns pin/delete/mute
  onLoadMore: loadOlderPage,
)

ConversationRowData(
  id: c.id,
  title: c.title,
  avatarUrl: c.avatarUrl,
  preview: formattedPreview,   // plain text
  timestampLabel: '14:32',
  unreadCount: c.unread,
  pinned: c.pinned, muted: c.muted, mentioned: c.mentioned,
  draftPreview: c.draft,       // takes precedence over preview
  presence: FlarePresence.online,
)
```

### The chat screen (MessageList + ChatHeader + Composer)

```dart
Scaffold(
  appBar: FlareChatHeader(
    title: peer.name,
    subtitle: peer.online ? '在线' : '离线',
    presence: peer.online ? FlarePresence.online : FlarePresence.offline,
    avatarUserId: peer.id,
    onDetails: openDetails,
  ),
  body: Column(children: [
    FlarePinnedMessageBar(items: pinned, onFocus: (p) => scrollTo(p.id)),
    Expanded(
      child: FlareMessageList(
        currentUserId: me.id,
        conversationKind: FlareConversationKind.group,
        messages: timeline,                 // List<FlareMessageData>
        mediaDownloadStates: mediaStates,   // Map<id, FlareMediaDownloadState>
        onMessageLongPress: (m) => FlareMessageActionSheet.show(context),
        onMediaAction: (m, content) => openMedia(content),
        onResend: (m) => resend(m.id),
        onLoadOlder: loadOlder,
      ),
    ),
    FlareComposer(
      rich: false,
      onSend: (text) => sendOptimistic(text),   // local echo < 16ms, core write async
      onAttach: () => FlareMessageActionSheet.show(context),
    ),
  ]),
)
```

`FlareMessageData.content` is a `FlareMessageContent` (e.g. `FlareTextContent`,
`FlareImageContent`, `FlareFileContent`, `FlareNotificationContent` for system lines).

## Design tokens

```dart
final colors = FlareColors.of(Theme.of(context).brightness); // light / dark
Container(color: colors.bubbleSelf);
SizedBox(height: FlareSizes.spacingMd);   // spacing / radius / fontSize / layout
```

## Develop

```bash
flutter pub get
flutter analyze   # 0 issues
flutter test      # widget smoke tests

# regenerate tokens after editing tokens.json
cd ../tokens && npm run build
```
