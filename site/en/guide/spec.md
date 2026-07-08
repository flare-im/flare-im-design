# Component spec (L2)

The component contract is the **single source of truth** for this UI kit: [`spec/components.json`](https://github.com/flare-im/flare-im-design) describes each component's `props` / `states` / `events` and its **core data source**, in a framework-neutral way. This site's component pages, sidebar and API tables are all generated from it.

## What a contract looks like

Prose fields (`summary`, `dataSource`, `notes`) and each prop's `description` are bilingual (`{ en, zh }`), so both language sites are generated from the same source:

```json
{
  "name": "MessageBubble",
  "category": "Message",
  "summary": {
    "en": "One message in a thread — content, sender, grouping, delivery status.",
    "zh": "线程里的一条消息 —— 内容、发送者、分组、送达状态。"
  },
  "dataSource": {
    "en": "client.views.openTimeline(conversationId); status drives state",
    "zh": "取 client.views.openTimeline(conversationId) 的一条；status 驱动状态"
  },
  "props": [
    {
      "name": "message",
      "type": "Message",
      "required": true,
      "description": { "en": "The message to render.", "zh": "要渲染的消息。" }
    }
  ],
  "states": ["pending", "sent", "read", "failed"],
  "events": ["react", "reply", "edit", "delete", "pin", "mark", "preview"],
  "platforms": {
    "vue": { "package": "flare-core-vue-im-ui", "symbol": "MessageBubble" },
    "flutter": { "package": "flare_im_ui", "symbol": "FlareMessageBubble" },
    "ios": { "package": "FlareIMUI", "symbol": "MessageBubbleView" },
    "compose": { "package": "com.flare.im:im-ui-compose", "symbol": "MessageBubble" }
  }
}
```

## Content-type registry

`MessageBubble` / `MessageContentView` dispatch body rendering to a view **registered by content type**. 17 are built in:

`text` · `image` · `video` · `audio` · `file` · `location` · `card` · `linkCard` · `sticker` · `emoji` · `vote` · `task` · `schedule` · `announcement` · `miniProgram` · `notification` · `placeholder`

Products can register custom types:

::: code-group

```ts [Vue]
// register a vote renderer from the product side
registerContentType("vote", VotePanel);
```

```dart [Flutter]
FlareContentRegistry.register("vote", (ctx, content, c) => VotePanel(content));
```

```swift [iOS]
FlareContentRegistry.register("vote") { content, ctx in AnyView(VotePanel(content)) }
```

```kotlin [Android]
FlareContentRegistry.register("vote") { content, ctx -> VotePanel(content) }
```

:::

## Drift-prevention check

`spec/validate.mjs` checks: ① every contract is complete (summary/dataSource/props with bilingual descriptions + four-platform package+symbol); ② **each component's reference symbol really exists on all four platforms** (Vue `.vue` file, Flutter `class`, iOS `struct`, Compose `fun`); ③ the docs' component/category counts match the spec.

```bash
cd flare-im-design/spec && node validate.mjs
# ✓ spec valid — 34 components … all 4 platforms' reference symbols exist
```

If the contract changes, the four implementations must follow or validation fails — this is the gatekeeper for "one contract, four consistent platforms".
