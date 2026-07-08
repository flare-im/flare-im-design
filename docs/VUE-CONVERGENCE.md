# Phase 3 — 三套 Vue 收敛为一（convergence map）

> **破坏性、跨 app**。`flare-social-tauri-app` 依赖 A′（本轮刚修好消息收发的那份），re-point + 删除必须逐 app 重建 + 重测。
> 本文件把收敛做成**turnkey 迁移清单**；执行时每步后重建对应 app 验证，任一 build 挂即停。

## 三份现状
| 代号 | 包 | 位置 | 角色 |
|---|---|---|---|
| A | `@flare/shared-im-ui` | `examples/shared-im-ui` | 参考（reference-only） |
| A′ | `@flare/shared-im-ui`（=A 拷贝） | `flare-social/.../examples/apps/shared-im-ui` | **flare-social-tauri-app 在用**（本轮修过 send-ack/信封/hub） |
| **B** | `flare-core-vue-im-ui` | `flare-im-core-client-sdk/packages/` | **canonical 目标**（core 示例 web/electron/tauri/uni 已在用） |

## 组件对应（A/A′ → B）
**大量重叠、直接归 B**：MessageBubble · MessageList · EnhancedComposer · ConversationList(→FlareConversationList) ·
Avatar(→FlareAvatar) · MessageStatus · PinnedMessageBar · TimeStamp · ImagePreviewModal · VideoPlayerModal ·
MarkdownPreview · PlainTextEmojiRich · ContentView · ChatConversationHeader(+Identity) · MessageBubbleHoverToolbar。

**A 独有 → 并入 B**：
- Pinned 套件：`PinnedMessagesSidePanel` / `PinnedMessagesDrawer` / `PinnedMessagesList` / `ChatConversationPinnedLayout`
- 会话 tab：`ChatConversationViewTabs`（B 无）
- Composer 拆件：`ComposerReplyStrip` / `ComposerSendSplit` / `ComposerFlareFormatBar` / `ComposerPlainInputWithEmoji`（B 的 composer 更整块，按需吸收拆件能力）
- Bubble 拆件：`MessageBubbleFooterMeta` / `MessageBubbleUploadState` / `MessageBubbleReactions` / `MessageBubbleBody`
- `BusinessSystemCard`

**B 独有（保留，A 侧缺）**：业务消息视图 `FlareVoteMessageView`/`Task`/`Schedule`/`MiniProgram`/`Announcement`/`LinkCardView`/`StickerView`/`PlaceholderView` · `FlareWorkbenchShell` · `FlareAuthScreen` · `FlareDiagnosticsConsole` · `FlareStartConversationDialog/Sheet` · `design-system`（tokens 已抽到 L3）。

## 接线层（非 UI，**剥离为独立复用基建包**，不进 B 的组件层）
A 的 `sdk-host/` · `events/`(createImEventHub — 本轮修过 send-ack 信封) · `session/` · `hub/` → 提为
`packages/flare-im-client-runtime`（或类似）。flare-im-spec：可复用 client 基建沉 packages，与 UI 组件解耦。
**注意**：本轮三处修复（send-ack `payload.ack` 拆包、`IM_UNWRAP` response 信封、ChatPanel）要一并带入，别回退。

## turnkey 迁移步骤（逐步验证）
1. 剥离接线层 → `flare-im-client-runtime` 包（含本轮修复）；`examples/shared-im-ui` 与 flare-social app 先改依赖此包，**重建两处验证**。
2. 把 A 独有组件（pinned 套件 / tabs / composer·bubble 拆件 / BusinessSystemCard）搬进 B，命名对齐（Flare 前缀/spec 符号）。
3. flare-social-tauri-app：import 从 `@flare/shared-im-ui` → `flare-core-vue-im-ui` + `flare-im-client-runtime`；**yarn tauri build + computer-use 重测注册/登录/加好友/收发消息**（复用本轮验证脚本）。
4. core 示例（web/electron/tauri/uni）逐个 build 验证仍绿。
5. **删除** `examples/shared-im-ui` 与 flare-social 的 A′ 拷贝（no-compat）。
6. 组件对齐 L2 spec（扩 validate 覆盖新增组件）。

## 风险
- flare-social app 的 chat 装配（ChatPanel/loadMessages/信封拆包）与 A′ 深耦合 → 迁到 B 需保住本轮修复的语义，逐条对照。
- A 的 composer/bubble 是「多拆件」，B 是「较整块」→ 合并需决定粒度，避免双实现（no-compat）。
- 必须每步重建 + 重测，不可一把梭。
