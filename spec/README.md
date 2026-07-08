# flare-im-ui-spec — L2 组件契约

框架中立的 IM 组件契约：**一个组件 = 一份契约（props / states / events + 数据源 core view），各端原生实现**。
是「类 Ant Design 组件 API」中立化的部分——各端 L1 包按此实现，一致性靠本 spec 锁定。

## 契约格式（每个组件）
| 字段 | 含义 |
|---|---|
| `name` | 组件名（各端符号见 `platforms`） |
| `summary` | 一句话职责 |
| `dataSource` | 数据来自哪个 **core 可观察视图**（L4）——所有端消费同一个 |
| `props[]` | `{ name, type, required?, default?, desc? }` |
| `states[]` | 可能的状态（如 pending/sent/read/failed） |
| `events[]` | 回调/事件名 |
| `platforms` | `vue / flutter / ios / compose` → `{ package, symbol }`（各端依赖与符号） |

## 组件目录（18 个 / 5 类，源见 [`components.json`](./components.json)，props/events 从 `flare-core-vue-im-ui` 源码抽取校准）
- **General**：`Avatar` · `TimeStamp` · `MessageStatus`
- **Conversation**：`ConversationList` · `ConversationRow` · `ConversationDetails` · `StartConversationDialog`
- **Message**：`MessageBubble` · `MessageList` · `ChatHeader` · `PinnedMessageBar` · `MessageContentView`
- **Composer**：`Composer` · `RichMarkdownInput` · `MessageActionSheet`
- **Media**：`ImagePreviewModal` · `VideoPlayerModal` · `MarkdownPreview`

**内容类型注册表**（`contentTypes.registered`）：`MessageBubble`/`MessageContentView` 按 content-type 分发到各渲染器
（text/image/video/audio/file/location/card/linkCard/sticker/emoji/vote/task/schedule/announcement/miniProgram/notification/placeholder），产品可注册新类型。

## 校验（防漂移，仿 sdk-spec 双向覆盖）
```bash
node validate.mjs
```
检查：① 每个组件契约字段完整；② 四端都有 package+symbol；③ **Vue 参考符号（如 `MessageBubble.vue`）确实存在于
`flare-core-vue-im-ui`**——spec 与参考实现对不上就报错。各端 L1 包落地后，扩展校验为「该端符号存在且 props 覆盖」。

## 关系
- **L4** 数据/行为：`flare-im-core-sdk` client.views（已有）——`dataSource` 指向它。
- **L3** tokens：[`../tokens`](../tokens)——组件视觉走 `--flare-*`。
- **L1** 各端包：Vue 已在 `flare-core-vue-im-ui`；Flutter/iOS/Compose 待从各端 app 抽取（Phase 4）。
