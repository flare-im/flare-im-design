# 组件契约 (L2 spec)

组件契约是这套 UI Kit 的**单一真源**：[`spec/components.json`](https://github.com/flare-im/flare-im-design) 用框架中立的方式描述每个组件的 `props` / `states` / `events`，以及它**需要的数据形状**。本站的组件页、侧边栏、API 表全部由它生成。

## 一个组件契约长什么样

文案字段（`summary`/`dataSource`/`notes`）与每个 prop 的 `description` 都是双语（`{ en, zh }`），中英两套站点由同一份契约生成：

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

## 内容类型注册表

`MessageBubble` / `MessageContentView` 把消息体的渲染分派给**按内容类型注册**的视图。内建 17 种：

`text` · `image` · `video` · `audio` · `file` · `location` · `card` · `linkCard` · `sticker` · `emoji` · `vote` · `task` · `schedule` · `announcement` · `miniProgram` · `notification` · `placeholder`

产品可注册自定义类型：

::: code-group

```ts [Vue]
// 业务侧注册一个 vote 渲染器
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

## 防漂移校验

`spec/validate.mjs` 校验：① 每个组件契约完整（summary/dataSource/props 双语描述 + 四端 package+symbol）；② **每个组件在四端的参考符号都真实存在**（Vue `.vue` 文件、Flutter `class`、iOS `struct`、Compose `fun`）；③ 文档里的组件 / 分类计数与 spec 一致。

```bash
cd flare-im-design/spec && node validate.mjs
# ✓ spec valid — 34 components … all 4 platforms' reference symbols exist
```

契约变了，四端实现必须跟上，否则校验红 —— 这就是"一套契约、四端一致"的守门人。
