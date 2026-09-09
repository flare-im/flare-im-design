---
title: UnknownMessage 未知消息
---

# UnknownMessage 未知消息

本端无法渲染的消息体。规划要求「未知扩展消息保留可理解的占位和诊断信息」——把原始 `contentType` 直接当正文印出来(`[flare.poll.v2]`)读者什么也读不懂，而且看起来像渲染坏了。所以这里把呈现拆成三层：人能读的标题、人能读的正文、以及保留给排查和报障用的原始类型诊断行。

<div class="flare-demo flare-demo--stack"><UnknownMessageDemo /></div>

<ComponentApi name="UnknownMessage" />

## 三层取值规则

纯函数 `unknownMessagePresentation({ contentType, label, summary, hint, unsupportedText })` 决定四端显示什么，四端各有同名实现与单测，不会漂移：

| 层 | 取值顺序 | 说明 |
|---|---|---|
| 标题 | `label` → `unsupportedText` | 宿主认识这个类型就用它的名字（如「投票」），否则用通用的「不支持的消息类型」 |
| 正文 | `summary` → `hint` | 发送端附带了纯文本兜底就显示它（最有用），否则给通用说明 |
| 诊断 | `contentType` | 原始类型，等宽字体、强制 LTR；为空则整行不渲染 |

所有输入都会 trim，空白字符串不算有值。`hasSummary` 告诉宿主当前正文是真兜底还是通用说明，便于埋点统计有多少扩展消息真的带了兜底。

动作按钮只在**宿主既传了回调又传了文案**时出现——没有升级路径就不显示点了没用的按钮，这是「功能不可用不显示无效按钮」的直接落实。

## 四端接线位置

这个组件已经接在四端 `MessageContentView` 的兜底分支上：注册表没命中、内置类型也不匹配时走它。三端原生此前是 `chip("[type]")`，Vue 此前是 `[Unknown message type]`，现在四端统一。

Vue 的兜底还会把 `getContentDecodedPreview(decoded)` 作为 `summary` 传入，所以发送端塞在消息里的预览文本会自动成为正文。原生宿主如果能从自己的消息模型里取出同样的兜底文本，应当同样传进 `summary`。

::: code-group

```vue [Vue / Tauri]
<FlareUnknownMessage :content-type="msg.contentType" :label="knownTypeName(msg.contentType)"
  :summary="msg.fallbackText" :self="isSelf" action-text="了解如何升级" @action="openUpgrade" />
```

```dart [Flutter]
FlareUnknownMessage(contentType: msg.contentType, label: knownTypeName(msg.contentType),
  summary: msg.fallbackText, isSelf: isSelf, actionText: '了解如何升级', onAction: openUpgrade)
```

```swift [SwiftUI]
UnknownMessageView(contentType: msg.contentType, label: knownTypeName(msg.contentType),
    summary: msg.fallbackText, isSelf: isSelf, actionText: "了解如何升级", onAction: openUpgrade)
```

```kotlin [Compose]
UnknownMessage(contentType = msg.contentType, label = knownTypeName(msg.contentType),
    summary = msg.fallbackText, isSelf = isSelf, actionText = "了解如何升级", onAction = ::openUpgrade)
```

:::

## 与内容注册表的关系

能渲染的扩展类型应该走 `FlareContentRegistry`(四端都有)注册自己的渲染器，而不是靠这个组件。它只负责**注册表也没有**的情况：对端版本更新、灰度中的新类型、或者插件没装。因此它不做能力探测、不发网络请求、也不缓存任何东西。

## 布局、规模与可访问性

在气泡里渲染，宽度随气泡；正文与诊断文本换行，超长类型名不会撑破气泡。`self=true` 时文字继承气泡前景色，不再单独用次要色，保证在主色气泡上仍有对比度。诊断行强制 LTR，RTL 界面下类型名的阅读方向不会被打乱。动作按钮至少 48 逻辑单位、可键盘聚焦并有焦点环。状态用图标 + 文字表达，不依赖颜色。示例使用本地状态，不代表真实扩展消息的端到端验收。
