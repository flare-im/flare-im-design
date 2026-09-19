# Native Gesture Matrix（2.0 认证）

行为契约：[../gesture-contract.md](../gesture-contract.md)。本表逐动作记录组件、平台、期望行为、结果与冲突规则。**Result** 分两列：已有自动化（L3，模拟环境里的 widget / instrumented / 浏览器测试，只作辅证）与真机结果（L5，`GESTURE-IOS` / `GESTURE-ANDROID` 的销项依据）。契约原文：模拟器执行只算诊断证据。

2026-09-14 在 iOS 模拟器与 Android 模拟机上对本地真服务端观察到的结果写在各行「冲突规则」之后的备注里（L4，不能销真机行，但 FAIL 是有效的）：Android 长按消息弹出零宽空菜单（FAIL）、系统返回从聊天页直接退出应用（FAIL）、键盘弹出时发送键被遮住（FAIL，对应 `GEST-COMPOSER-KEYBOARD`）；iOS 长按消息打开完整动作面板，但执行动作后面板不关闭（P1）。证据：`artifacts/release-2.0/native/NATIVE-{ANDROID,IOS}-RUNTIME.json`。

真机列当前全部是 `NOT_RUN`：本机没有接入 iPhone 或 Android 手机（`xcrun xctrace list devices` 只有本机 Mac，`adb devices` 为空）。执行规程见 [2.0-external-validation.md](2.0-external-validation.md) 的 GESTURE 一节，证据格式见 [2.0-manual-evidence-checklist.md](2.0-manual-evidence-checklist.md) §4。

## 1. 逐动作

| 动作 | 组件 | 平台 | 期望行为 | 实现 | 自动化结果（L3） | 真机结果（L5） | 冲突规则 |
|---|---|---|---|---|---|---|---|
| tap | ConversationRow / MessageBubble / Button | iOS / Android / Flutter / Vue | 激活；多选模式下切换选中 | 各端原生点击 | Flutter `tester.tap` 115 处；iOS `MessageSelectionTests.testBubbleRowTapOnlyInMultiSelectMode…`；Compose `SceneInteractionTest` / `SharedFormInteractionTest`；Vue vitest | NOT_RUN | 命中区粗指针 ≥ 44×44（`accessibility-touch-targets.spec.ts`） |
| double tap | ImagePreview | Android | 缩放切换 | `detectTapGestures(onDoubleTap)`（`ImagePreview.kt`） | 无 | NOT_RUN | 仅查看器内；不与单击关闭冲突 |
| double click | MessageBubble（图片 / 视频） | Vue 桌面 | 打开预览 | `@dblclick` | 无专门用例 | 不适用（桌面） | 单击仍选择 / 聚焦 |
| long press | MessageBubble | iOS / Android / Flutter / Vue H5 | 打开可用消息动作 | iOS `onLongPressGesture`；Compose `combinedClickable`；Flutter `onLongPress`；Vue `useLongPress` | Flutter `message_test.dart` longPress；iOS `testListSuspendsLongPressInMultiSelectMode` | NOT_RUN | 识别前不得阻断纵向滚动；多选模式下挂起 |
| long press | ConversationRow | iOS / Android / Flutter / Vue H5 | 打开会话动作 | 同上 | Flutter `conversation_test.dart` longPress | NOT_RUN | 能力不可用的动作不得出现 |
| swipe（reply） | MessageList 行 | iOS / Android / Flutter | 仅当宿主提供回复时，横向拖动 ≥ 56pt 且横向分量占优触发回复 | iOS `DragGesture(minimumDistance: 12)` + 56pt + 1.25 横纵比；Compose 56dp 阈值；Flutter `swipe-reply-*` | Flutter `message_test.dart` drag 420px → onSwipeReply | NOT_RUN（`GEST-MESSAGE-REPLY`） | 纵向优先；RTL 翻转方向；不得误发送 |
| swipe（actions） | ConversationRow | Flutter | 露出 pin / mute 等动作；一次只开一行 | `Slidable` | `conversation_presentation_test.dart` drag -220px → Pin | NOT_RUN（`GEST-CONVERSATION-ACTIONS`） | 纵向滚动先于横向锁定 |
| swipe（actions） | ConversationRow | iOS / Android | 契约写"platform-supported"；两端 kit **未实现**行滑动，走长按动作面板（契约规定的 fallback） | 无 | 无 | NOT_RUN（验证 fallback 可达） | — |
| scroll | ConversationList / MessageList | 四端 | 平滑；prepend 保持阅读锚点 | Vue 窗口化 / Flutter builder / Compose `LazyColumn` / SwiftUI `List`·`LazyVStack` | `performance-budget`（Vue 挂载计数）；长时间线静止见 `visual-regression.spec.ts` 的 `composed workspace stays still while resizing and reading a long timeline`；prepend 锚点无专门自动化 | NOT_RUN（帧率归 `PERF-*`） | 长按识别前不抢滚动 |
| back gesture | Dialog / Sheet / 查看器 | Android（系统返回）/ iOS（边缘返回）/ Flutter | 关闭最上层覆盖物并恢复焦点；有未保存破坏性内容时先确认 | Flutter `PopScope`（`flare_dialog.dart`、`flare_scene_panels.dart`）；Compose / iOS 由宿主导航承担，平台契约 `nativeBack` 在 iOS 与各宿主为 UNSUPPORTED | 无 | NOT_RUN（`GEST-VIEWER-ZOOM-BACK`） | 边缘系统返回优先 |
| sheet drag | FormSheet / BottomSheet | iOS / Android | 拖动在 detent 间切换或关闭 | iOS `presentationDetents([.medium, .large])`；Compose `ModalBottomSheet` | 无 | NOT_RUN | 表内滚动到顶后才把拖动交给 sheet |
| pinch / pan | ImagePreview | iOS / Android / Flutter | 在媒体边界内缩放；缩放后平移，禁用左右切换 | iOS `MagnificationGesture`；Compose `detectTransformGestures`；Flutter `InteractiveViewer` | Web 浏览器缩放 `native-zoom.spec.ts`（只证 composer 表面，不是图片手势） | NOT_RUN（`GEST-VIEWER-ZOOM-BACK`） | 查看器只在捏合开始后接管多指 |
| hold / slide | 语音 composer | iOS / Android | 按住录音，越过取消区松手取消并播报 | iOS `DragGesture(minimumDistance: 0)`（`ComposerParts.swift`）；Compose `pointerInput(cancelThreshold)` | 无 | NOT_RUN（`GEST-VOICE-CANCEL`） | 仅录音期间禁用列表滚动 |
| keyboard avoidance | Composer | iOS / Android / Flutter | 草稿与主要按钮可见 | 各端 inset | 无 | NOT_RUN（`GEST-COMPOSER-KEYBOARD`） | 调整内容尺寸，不把控件移出安全区 |

## 2. 五条手工用例 × 平台

| 用例 | iOS | Android |
|---|---|---|
| GEST-MESSAGE-REPLY | NOT_RUN | NOT_RUN |
| GEST-CONVERSATION-ACTIONS | NOT_RUN（验证长按 fallback） | NOT_RUN（验证长按 fallback） |
| GEST-VIEWER-ZOOM-BACK | NOT_RUN | NOT_RUN |
| GEST-COMPOSER-KEYBOARD | NOT_RUN | NOT_RUN |
| GEST-VOICE-CANCEL | NOT_RUN | NOT_RUN |

`GESTURE-IOS` / `GESTURE-ANDROID` 在五条全部 PASS 前保持未销。
