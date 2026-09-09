---
title: UnknownUserPlaceholder 未知用户占位
---

# UnknownUserPlaceholder 未知用户占位

联系人、群成员、消息发送者这些位置上，宿主并不总能拿到一个可展示的人。ID 解析不到、账号已注销、被屏蔽、当前不可联系——这些情况必须有一个可理解的呈现，而不是留空、或者把一串 user id 顶到标题位。本组件就是这个占位：中性头像、一句说明原因的主标题、一枚该状态专属的图标，以及放在次要位置的诊断 ID。纯展示，无动作、无回调、无网络请求。

<div class="flare-demo flare-demo--stack"><UnknownUserPlaceholderDemo /></div>

<ComponentApi name="UnknownUserPlaceholder" />

## 状态与规则

| kind | 默认主标题 | 图标 | 语气 |
|---|---|---|---|
| `unknown` | 未知用户 | 人像轮廓 | 中性 |
| `deactivated` | 该账号已注销 | 人像划除 | 中性 |
| `blocked` | 该账号已被屏蔽 | 禁止 | 危险 |
| `unreachable` | 暂时无法联系该账号 | 锁 | 警告 |

规则由共享纯函数 `unknownUserPresentation(kind)` 与 `shortenUserId(userId, maxLength)` 决定，四端各自实现同一套：

| 情况 | 展示 |
|---|---|
| `kind` 缺省或取到未知值 | 降级为 `unknown`，绝不空白 |
| user id 超过 `idMaxLength`（默认 24） | 中间省略，头 12 尾 11 加一个省略号 |
| user id 为空或全是空白 | 整行诊断位不出现，不留一个空的 `ID` 标签 |
| `density = "row"` | 头像 44、单行主标题，供列表使用，最小高度 48 |
| `density = "card"` | 头像 64、居中，带次级表面背景，供详情页使用 |
| `detail` 有值 | 在主标题与 ID 之间插入一行宿主补充说明 |

状态不只靠颜色：每个 kind 有自己的图标和自己的文字，语气色只是叠加在图标上。头像位使用中性人像轮廓，不用 emoji。

## 宿主接入

宿主自己决定 kind：查无此人给 `unknown`，账号注销给 `deactivated`，本地黑名单或对方屏蔽给 `blocked`，权限/隐私设置导致暂时不可联系给 `unreachable`。组件不猜、不请求、不重试。

::: code-group

```vue [Vue / Tauri]
<FlareUnknownUserPlaceholder
  v-if="!profile"
  :user-id="member.userId"
  kind="deactivated"
  density="row"
  detail="来自群成员列表" />
```

```dart [Flutter]
FlareUnknownUserPlaceholder(
  userId: member.userId,
  kind: FlareUnknownUserKind.deactivated,
  density: FlareUnknownUserDensity.row,
  detail: '来自群成员列表',
);
```

```swift [SwiftUI]
UnknownUserPlaceholderView(userId: member.userId,
                           kind: .deactivated,
                           density: .row,
                           detail: "来自群成员列表")
```

```kotlin [Compose]
UnknownUserPlaceholder(
    userId = member.userId,
    kind = FlareUnknownUserKind.Deactivated,
    density = FlareUnknownUserDensity.Row,
    detail = "来自群成员列表",
)
```

:::

所有文案通过 props 传入并带默认值，宿主按语言替换；`idLabel` 与 `idMaxLength` 同样可调。

## 布局、规模与可访问性

`row` 是固定高度的一行，可直接放进 `LazyColumn` / `ListView.builder` / `List`；`card` 是一个自撑高的块，放在详情页顶部。行内主标题长文案换行，诊断 ID 单行省略——ID 是不可翻译的标识串，因此用 `bdi dir="ltr"`（Web）、`Directionality`（Flutter）、`layoutDirection` 环境值（SwiftUI）强制 LTR，RTL 布局下不会被拆散。

读屏把整块合并成一个元素，名称顺序是「原因 · 补充说明 · ID 全量值」——先说明为什么看不到这个人，ID 放最后，且读出的是完整 ID 而不是省略后的字符串。组件不含可聚焦控件，Tab 不会在这里停留。示例使用本地状态，不能替代 SDK 与真机读屏验收。
