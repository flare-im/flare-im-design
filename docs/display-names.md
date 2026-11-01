# 名字渲染：`FlareDisplayName` 与 `flareDisplayNameText`

会话标题、末条发送者、时间线发送者、成员与联系人的名字，由核心 SDK 投影成结构化的 `DisplayName`：有名字时给名字；没有名字时不给 id，而是给「无名」加 id 末四位，或给未命名群的成员名单。核心与社交 SDK 不带任何本地化文案，文字只在 Kit：四端读同一份 `spec/display-name-vectors.json`，把同一个值渲染成同一段文字。

展示名字的组件（会话行标题、聊天头、发送者名、成员行、@ 候选、好友申请行、名片标题）**签名不变**，属性仍是字符串。无名值没有专门的视觉（不加斜体、不弱化），读屏文本就是渲染出的文字，所以由宿主在接线处调用一次 `flareDisplayNameText`，再把字符串交给组件。资料页那种「整张卡片都没有资料」的场景仍用 `UnknownUserPlaceholder`，不走这里。

## 值的形状

wire 为 camelCase JSON，三种形态：

```jsonc
{ "kind": "named",   "text": "Alice", "source": "alias" }
{ "kind": "members", "names": ["张三", "李四", "王五"], "total": 12 }
{ "kind": "unnamed", "entity": "person", "idTail": "9876" }
```

- `source`：`alias` | `memberNickname` | `profile` | `snapshot` | `remark` | `name`。只用于测试与诊断，渲染不区分；Kit 类型里是可选的。
- `entity`：`person` | `group` | `system` | `ai` | `customer` | `channel` | `broadcast` | `temp`。
- `members.names`：核心给最多 3 个有真名字的成员，不含本人；`total` 是会话成员总数，含本人。
- `idTail`：见下文「id 末四位」。

| 端 | 类型 | 渲染 | id 末四位 | 读 wire |
| --- | --- | --- | --- | --- |
| Vue | `FlareDisplayName`（`./contracts`，联合类型就是 wire 形状） | `flareDisplayNameText(name, strings?)`（`./utils`） | `flareIdTail(id)`（`./contracts`） | 直接用 JSON 对象 |
| SwiftUI | `FlareDisplayName`（`Codable` 枚举：`.named` / `.members` / `.unnamed`） | `flareDisplayNameText(_:strings:)` | `flareIdTail(_:)` | `JSONDecoder`；已解码的 JSON 用 `FlareDisplayName(json:)` |
| Compose | `FlareDisplayName`（sealed：`Named` / `Members` / `Unnamed`） | `flareDisplayNameText(name, strings)` | `flareIdTail(id)` | `FlareDisplayName.fromMap` / `fromJson` |
| Flutter | `FlareDisplayName`（sealed：`FlareNamedDisplayName` / `FlareMembersDisplayName` / `FlareUnnamedDisplayName`） | `flareDisplayNameText(name, strings)` | `flareIdTail(id)` | `FlareDisplayName.fromJson` / `toJson` |

枚举四端同名：`FlareDisplayNameSource`、`FlareDisplayNameEntity`。读 wire 四端都不失败（核心比 Kit 新时会遇到不认识的值）：不认识的 `entity` 按 `person` 读；不认识的 `kind`、缺 `text` 的 `named`、不是对象的值，按 `idTail` 为空的无名的人读，渲染为「未知用户」。Compose `fromMap` / `fromJson` 与 Flutter `fromJson` 返回非空值，SwiftUI 的 `Codable` 不抛错，`FlareDisplayName(json:)` 按同样的规则读已解码的 JSON（字典、数组、字符串、数字），只有没有值（nil 或 `NSNull`）时为 nil，Vue 用 `flareDisplayNameFrom(value)` 做同样的整理，`flareDisplayNameText` 也先经它。

Vue 的 `strings` 可以是 `useFlareI18n().t`（宿主覆盖的 `displayName.*` 生效），也可以是 locale 字符串；不传时用运行时语言。原生端传 `FlareStrings`（Compose `flareStrings()`、SwiftUI 环境里的 `flareStrings`、Flutter `FlareStrings.of(context)`）。

## 渲染规则与对照表

- `named`：原文，不裁剪、不改写。`0401`、`2am_club` 这类像 id 的字符串也是真名字，Kit 不按形状猜。
- `members`：去掉空白的名字后用分隔符拼接；成员多于「名字数 + 本人」（`total > names.length + 1`）时加后缀，两种语言各按自己的读法计数：
  - 中文「等 N 人」的 **N = total**，即含本人的群成员总数（「张三、李四、王五等 12 人」）；
  - 英文 "and N others" 的 **N = total − names.length − 1**，即名字以外、不含本人的其他成员（"and 8 others"），N 为 1 时用单数 "and 1 other"；
  - `total ≤ names.length + 1` 时两种语言都不加后缀；
  - 一个名字都不剩时按未命名群读。
- `unnamed`：按 `entity` 读。`person` 有 `idTail` 时为「用户 末四位」，没有时为「未知用户」；其余类型各有一个词，与 `idTail` 无关。

| 形态 | zh-CN | en-US |
| --- | --- | --- |
| `named` | 原文 | 原文 |
| `members`，`total ≤ names.length + 1` | `张三、李四` | `张三, 李四` |
| `members`，`["张三","李四","王五"]`，`total` 4（names + 1） | `张三、李四、王五` | `张三, 李四, 王五` |
| `members`，`["张三","李四","王五"]`，`total` 5（names + 2） | `张三、李四、王五等 5 人` | `张三, 李四, 王五 and 1 other` |
| `members`，`["张三","李四","王五"]`，`total` 12 | `张三、李四、王五等 12 人` | `张三, 李四, 王五 and 8 others` |
| `members`，`["林夏"]`，`total` 100 | `林夏等 100 人` | `林夏 and 98 others` |
| `members`，没有可用的名字 | `群聊` | `Group chat` |
| `unnamed person`，`idTail` 非空 | `用户 9876` | `User 9876` |
| `unnamed person`，`idTail` 为空 | `未知用户` | `Unknown user` |
| `unnamed group` | `群聊` | `Group chat` |
| `unnamed system` | `系统通知` | `System notifications` |
| `unnamed ai` | `AI 助手` | `AI assistant` |
| `unnamed customer` | `客服` | `Customer service` |
| `unnamed channel` | `频道` | `Channel` |
| `unnamed broadcast` | `广播` | `Broadcast` |
| `unnamed temp` | `临时会话` | `Temporary chat` |
| `unnamed`，不认识的 `entity`，`idTail` 9876 | `用户 9876` | `User 9876` |
| 不认识的 `kind`，或缺 `text` 的 `named` | `未知用户` | `Unknown user` |

英文在 N 为 1 时用单数（`and 1 other`），与 `spec/plural-vectors.json` 的规则一致。

## 引用的发送者

引用块与回复条上的发送者用 `flareQuoteSenderText`，四端同一条规则（`spec/display-name-vectors.json` 的 `quoteSender`），从不显示 id，也从不留空：

1. 引用带投影名字时（Vue 引用内容的 `quotedSender`，原生 `FlareReplyTarget.sender`，wire 是 `FlareDisplayName`），按上面的规则写出来；
2. 否则用宿主给的名字（Vue `quotedSenderName`，原生 `FlareReplyTarget.senderName`），去首尾空白后不为空时；
3. 否则是无名的人：用 `quotedSenderId` / `FlareReplyTarget.senderId` 的末四位写「用户 9876」/「User 9876」，没有 id 时「未知用户」/「Unknown user」。

投影名字写出来是空白时同样往下取。原生 `flareReplyTarget`（Compose）、`FlareReplyTarget(replyingTo:strings:)`（SwiftUI）、`flareReplyTargetFor`（Flutter）从被引用的行构造目标时已经带上 `senderId`。

| 引用 | zh-CN | en-US |
| --- | --- | --- |
| `senderName` Alice | `Alice` | `Alice` |
| 只有 `senderId` u_dave9876 | `用户 9876` | `User 9876` |
| `senderName` 全空白，`senderId` u_dave9876 | `用户 9876` | `User 9876` |
| 什么都没有 | `未知用户` | `Unknown user` |
| `sender` 为 `named` 林夏，`senderName` 旧名字 | `林夏` | `林夏` |
| `sender` 为 `unnamed person` 4321，`senderId` u_dave9876 | `用户 4321` | `User 4321` |

## id 末四位

`flareIdTail(id)`：id 去首尾空白后的末 4 个 Unicode 标量；不足 4 个时取整串；为空时为空串。按标量数，不按 UTF-16 码元（emoji 算一个）也不按字形簇（组合附加符号单独算一个）。核心 SDK 生成 `idTail` 用同一条规则；插件视图里解析不到的用户名（`flarePluginFallbackName`，原生 `PluginViewFormat.fallbackName`）四端都改为调用它，`spec/plugin-view-vectors.json` 的 `fallbackNames` 照旧通过。

## 文案

| 用途 | Vue 键（zh-CN / en-US） | 原生 `FlareStrings` 字段 |
| --- | --- | --- |
| 无名的人 | `displayName.user`：`用户 {idTail}` / `User {idTail}` | `displayNameUser(idTail)` |
| 没有 id 的人 | `displayName.unknownUser`：`未知用户` / `Unknown user` | `displayNameUnknownUser` |
| 未命名群 | `displayName.group`：`群聊` / `Group chat` | `displayNameGroup` |
| 系统会话 | `displayName.system`：`系统通知` / `System notifications` | `displayNameSystem` |
| AI、客服、频道、广播、临时会话 | `displayName.ai` / `customer` / `channel` / `broadcast` / `temp` | `displayNameAi`、`displayNameCustomer`、`displayNameChannel`、`displayNameBroadcast`、`displayNameTemp` |
| 成员分隔符 | `displayName.separator`：`、` / `, ` | `displayNameSeparator` |
| 其余成员 | `displayName.membersMore`：`{names}等 {total} 人` / `{names} and {others} other(s)`（参数 `names`、`total`、`others`，`count` = `others` 用于选复数） | `displayNameMembersMore(names, total, others)`：中文默认用 `total`，英文预设用 `others` |

原生英文预设由 `strings/en.json` 生成，函数字段的英文写在各端 `EnglishFormats`，与 `strings/en-formats.json` 对账。

## 宿主接线

把投影值转成字符串，交给 Kit 组件，不在 app 里再写「像不像 id」的判断或兜底文案：

```ts
import { flareDisplayNameText } from "@flare-im/vue-ui/utils";
const { t } = useFlareI18n();
const title = flareDisplayNameText(conversation.title, t);
```

```swift
let title = flareDisplayNameText(conversation.title, strings: strings)
```

```kotlin
val title = flareDisplayNameText(conversation.title, flareStrings())
```

```dart
final title = flareDisplayNameText(conversation.title, FlareStrings.of(context));
```

社交包与核心生成包把 wire 读成各自的类型后，原生宿主在接线处转成 Kit 类型：Compose 用 `FlareDisplayName.fromMap`，Flutter 用 `FlareDisplayName.fromJson`，SwiftUI 读 JSON 文本用 `JSONDecoder().decode(FlareDisplayName.self, …)`，读桥上已解码的字典用 `FlareDisplayName(json: row["title"])`（字段缺省时为 nil，宿主据此退回旧字段），Vue 的 wire 对象就是 `FlareDisplayName`。
