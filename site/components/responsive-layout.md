---
title: ResponsiveLayout
---

# ResponsiveLayout

<p><span class="flare-tag">布局</span></p>

> 自适应会话布局 —— 手机单栏（列表↔聊天切换）、平板双栏（列表+聊天）、PC 三栏（列表+聊天+详情）。

**数据源**：纯布局；三个 slot（list/chat/detail）由产品填充

## 预览

在 **PC** 与 **App** 间切换：宽屏是**三栏**（会话列表 + 聊天 + 详情），平板降为**双栏**，手机是**单栏**逐页切换。可交互。

<ClientOnly>
  <ResponsivePreview embed="/embed/responsive-layout-frame" pc-hint="桌面 · 三栏" app-hint="移动 · 单栏" :pc-height="420" :app-height="560" />
</ClientOnly>

## 实际容器与大字号

下面演示使用真实组件，文档栏本身较窄时即使电脑屏幕很宽也保持单栏。点击详情可验证返回顺序；200% 字号会增加聊天宽度预算。

<div class="flare-demo flare-demo--stack"><ResponsiveLayoutDemo /></div>

<ComponentApi name="ResponsiveLayout" />

完整布局规则及安全区接入见[跨设备一致性](/guide/cross-device)。

## States

<span class="flare-tag">single</span> <span class="flare-tag">dual</span> <span class="flare-tag">triple</span>

## Events

<span class="flare-tag">paneChange</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareResponsiveLayout</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareResponsiveLayout</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ResponsiveLayoutView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ResponsiveLayout</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 示例

### 自适应三栏

PC 三栏（列表+聊天+详情），平板双栏，手机单栏按 activePane 切换并显示返回。

::: code-group

```vue [Vue]
<FlareResponsiveLayout :has-detail="true" :active-pane="pane" @pane-change="p => pane = p">
  <template #list><FlareConversationList :items="rows" /></template>
  <template #chat><FlareMessageList v-bind="thread" /></template>
  <template #detail><FlareConversationDetails :conversation="conv" /></template>
</FlareResponsiveLayout>
```

```dart [Flutter]
FlareResponsiveLayout(
  activePane: pane,
  onPaneChange: (p) => setState(() => pane = p),
  list: FlareConversationList(items: rows),
  chat: FlareMessageList(messages: timeline, currentUserId: me.id),
  detail: FlareConversationDetails(conversation: conv),
)
```

```swift [iOS]
ResponsiveLayoutView(
  activePane: pane, onPaneChange: { pane = $0 },
  list: AnyView(ConversationListView(items: rows)),
  chat: AnyView(MessageListView(messages: timeline, currentUserId: me.id)),
  detail: AnyView(ConversationDetailsView(conversation: conv))
)
```

```kotlin [Android]
ResponsiveLayout(
  activePane = pane,
  onPaneChange = { pane = it },
  list = { ConversationList(items = rows) },
  chat = { MessageList(messages = timeline, currentUserId = me.id) },
  detail = { ConversationDetails(conversation = conv) },
)
```

:::
