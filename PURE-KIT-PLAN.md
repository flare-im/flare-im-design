# 组件库补全 + demo 纯 kit 化

## Status: DONE

## 起因
demo（示例 app）用起来「不像组件展示」。分析后是 **app 自己的问题**：
1. app 硬编码 12 个颜色字面量，大半是 kit token 的复制品（`0xFF111318`=textPrimary ×4、`0xFF6B7280`=textSecondary…），
   还发明了 kit 没有的 `0xFFFAF9FF` 品牌底色 —— 最大的视觉分歧源。
2. **kit 早就有的组件，app 全手搓了一遍**：`AppShell` / `ChatHeader` / `ProfilePanel` / `SettingsList` / `Input` / `SearchBar`
   一个都没用，全是 Material 原生 + 自定义样式。

## 做完的事

### A. 两端 app 纯 kit 化（零硬编码色）
- 颜色全部走 `flareColors()` / `FlareSizes`；删掉 FAF9FF 与渐变按钮。
- 组件换成 kit 的：`AppShell`(Android 导航) / `ChatHeader` / `ProfilePanel` / `Input`。
- 品牌只保留 `FlareMark`（产品 logo，也是 app icon 的来源，是资产不是"样式"）。

### B. 纯 kit 反而照出 kit 的真 bug —— 全部已修（两端对齐）
| 缺陷 | 修法 |
|---|---|
| `Input`/`InputView` **完全不支持密码遮罩** | 加 `secure` 参数 |
| **`ProfilePanel` 重复实现行渲染，丢掉全部逻辑**：`SettingsItem.kind`(Toggle/Value/Navigation) 与 `detail` 不渲染、`UserProfile.signature` 不渲染（而兄弟组件 `SettingsList` 是对的） | **抽出共享 `SettingsRow`/`FlareSettingsRow`**，两个组件都用；补渲染 signature |
| `Composer` 无 `modifier` 参数（通用组件必须暴露） | 加 `modifier` |
| `Composer` 内嵌回复条硬编码 "Reply" | 加 `replyLabel` |
| `ConversationRow` 硬编码 `[Draft]` / `[@me]` | 加 `draftLabel` / `mentionLabel`（并由 `ConversationList` 透传） |
| iOS `ConversationRowView` 缺 `onSelect`/`onLongPress`（Android 有） | 补齐 |
| **暗色 4 个 token 是亮色值**（bgDisabled/bubbleSystem/borderHover/textDisabled 在 `dark.colors` 里压根没写 → 生成器回落亮色） | **改 `tokens/tokens.json` 源 + `node build.mjs` 重生成**（禁止手改 kt/swift） |

### C. 修掉重构引入的回归
`AppShell` 外渲染聊天页时，`ConversationsScreen` 的 `openId` 是局部 `remember` ——
**组件在树中两个位置之间移动会丢失 remember 状态** → openId 归零、导航栏来回抖。
把 openId 上提到 `MainShell` 持有，`ConversationsScreen` 退化为纯列表。

### D. 四端拉平（原生两端的缺陷 Vue/Flutter 同样存在，已一并修）
起因：只深审了 native 两端，怀疑 Vue/Flutter 有同款漂移 —— 一审全中。

| 缺陷 | Android | iOS | Vue | Flutter |
|---|---|---|---|---|
| ProfilePanel 重复实现行渲染、丢 kind/detail、不渲染 signature | 修（抽 `SettingsRow`） | 修（`FlareSettingsRow`） | 修（新建 `FlareSettingsRow.vue`，两组件共用） | 修（新建 `FlareSettingsRow` widget，两组件共用） |
| Input 无密码遮罩 | `secure` | `secure` | `secure`→`type=password` | `secure`→`obscureText` |
| ConversationRow 硬编码 `[Draft]`/`[@me]` | 修 | 修 | 已 i18n | `draftLabel`/`mentionLabel` |
| Composer 不透传 reply / voice 文案 | 修 | 修 | 已 i18n | `replyLabel`/`voiceLabel`/`voiceRecordingLabel`/`voiceCancelLabel` |
| 语音取消宿主感知不到 | 有 | 补 `onVoiceCancel` | 补 `voice-cancel` 事件（含"太短"/"失败"两条也发） | 已有 |
| 语音浮层文案硬编码英文 | — | — | 走 `t()`（新增 6 个 i18n key，中英齐） | — |
| ConversationDetails / ProfileEditor / StartConversationDialog 全英文写死 | 加 `FlareConversationDetailsLabels` / `FlareProfileEditorLabels` / `searchPlaceholder` | 同 | 走自带 i18n（新增 `profileEditor` / `conversationDetails` / `startConversation` 三个命名空间，中英齐） | 加 `FlareConversationDetailsLabels` / `FlareProfileEditorLabels` / `searchPlaceholder`+`emptyText`+`confirmLabel` |

规则：**一律新增可选参数 + 保留现有文案为默认值** → 5 个 example app 零破坏。
**Vue 走 i18n 而不是 props** —— 它自己已经有 `t()` 体系，塞 label props 等于开第二条路（违反"一条路"约束）。原生三端没有 i18n 运行时，所以用 labels 参数。

### 环境坑（非代码）
`~/.gradle/caches/8.14/kotlin-dsl/*/metadata.bin` 损坏 → 必须删掉重建；重建后 Gradle 要重下
`kotlin-compiler-embeddable-2.2.20.jar`（57MB），而 Maven Central 在本机网络下**会截断连接**（"Premature end of Content-Length"）。
解法：镜像断点续传 (`curl -C -`) 下好，装进 `~/.m2`，并把 `mavenLocal()` 加到 kit 的 `settings.gradle.kts` 仓库列表首位。

## 验证
- Android：kit `publishToMavenLocal` 成功 + app `:app:compileDebugKotlin` 成功；实机全流程（纯 kit 登录 / AppShell 导航 / 消息 / ProfilePanel 我页(detail+signature 正确) / ChatHeader 聊天页无导航栏 / 富消息全渲染）。
- iOS：kit `swift build` 成功 + app `xcodebuild` (iPhone 17 Pro sim) **BUILD SUCCEEDED**；模拟器实机（登录 / ProfilePanel / ChatHeader 聊天页无 tab bar / 富消息）。
- Flutter：`flutter analyze` 净 + 65/65 测试通过。
- Vue：`vue-tsc` 净 + 107 个 SFC 全量编译 0 失败 + 14/14 测试通过（另 2 个 suite 因缺外部 manifest / 未装 core SDK 包而失败，与本次改动无关，属既有问题）。

## 教训
**同一种行在两个组件里各写一遍 → 必然漂移。kit 内部的重复要抽共享。**（四端全中，无一例外。）
**生成的 token 文件别手改，改源重生成。**
**只审两端不算审完 —— 同一个契约有四套实现，缺陷会在没看的那两套里原样复现。**
