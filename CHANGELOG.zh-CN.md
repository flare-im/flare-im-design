# 更新日志

[English](CHANGELOG.md) · 中文

记录 Flare IM UI Kit(`flare-im-design`)的所有重要变更。

本 kit 是「一套契约、四端实现」—— Flutter(`flare_im_ui`)、iOS/SwiftUI(`FlareIMUI`)、Android/Compose(`com.flare.im:im-ui-compose`)、Vue(`@flare-im/vue-ui`)—— 统一版本。格式基于 [Keep a Changelog](https://keepachangelog.com),遵循[语义化版本](https://semver.org)。

## [未发布]

### 变更
- **契约真实性**——契约改为记录四端实现真实暴露的东西:Vue 符号即 `components/index.ts` 导出名,事件统一 camelCase 并按端派生,表单控件带 `model` 字段,`lexicon` / `eventAliases` / `eventPlatforms` / `platformAliases` 把平台惯用名与平台专属面写成显式事实。`spec/validate.mjs` 逐项比对每个 prop 与事件在 Vue、Flutter、SwiftUI、Compose 的签名(双向);剩余差异记在 `spec/signature-baseline.json`,只允许缩小。
- **Composer / ChatHeader / MessageActionSheet** 契约按实现重写。`MessageActionSheet` 四端共用一张动作 id 表(`image`、`camera`、`file`、`location`、`card`、`vote`、`task`、`schedule`…);Vue 的 `build(op)`、Flutter 的 `key` 与 `create_*` 保留为 deprecated 别名。
- **ConversationDetails** 改用 `tone: FlareTone`(`connectionTone` 弃用),不再引入 `@flare-im/sdk` 类型;**Toast** 在 `variant` 之外接受 `tone`。
- **GroupDetail** `openChat` 四端均为位置参数 `(userIds, name)`。

### 新增
- Vue **ChatHeader** `title` / `subtitle` / `presence` / `avatarUserId` / `avatarUrl` / `showBack` 与 `search` / `call` / `details` 事件;**Avatar** `presence`(含 `away`)与 `id` / `name` 别名。
- iOS 与 Compose 的 **MessageBubble / MessageList** 多选(`multiSelectMode`、`selected` / `selectedIds`、`onToggleSelect`)、**NewFriendRequests** `onView`、**Toast** `onClose`、**MessageStatus** `onResend`;Compose **Avatar** `avatarUrl`;Flutter **ConversationRow** `onLongPress`(`onAction` 弃用)。

### 弃用
- Vue `Avatar.status` / `showStatus`、`ChatHeader.back`、`MessageActionSheet.build`、`ConversationDetails.connectionTone`;Flutter `FlareConversationRow.onAction`、`FlareComposerAction.key`;iOS `ContactDetailView`(改用 `FlareContactDetail`)。

## [1.0.14] - 2026-09-08

纯增量、向后兼容的发布:每个新增参数都默认沿用旧行为,现有调用点不受影响。

### 新增
- **BrandLogo**(`FlareBrandLogo`)四端组件 —— 共享的 Flare 标识,含 `plate` / 纯图两种变体,接入认证/登录屏。
- **会话列表 host-rows 容器** —— Flutter `FlareConversationSliverList`(返回 sliver:宿主自持滚动视图、下拉刷新与按-id 的逐行订阅)和 iOS/Android `ConversationListContainer`(自带行构建器,kit 统一空态 / 加载 / 懒加载外壳)。与自足的 `FlareConversationList` 互补。
- **消息列表 host-rows sliver** —— Flutter `FlareMessageSliverList`,与自足的 `FlareMessageList` 互补,供自持滚动控制器与逐条消息行的聊天屏使用。
- **`FlareConversationRow.previewSpansBuilder`**(Flutter)—— 会话行内的富预览片段(媒体胶囊、@提及)。
- **EmptyState 富变体**(四端)—— `loading`(以 spinner 替代图标)、`onTap`(整块占位可点,区别于操作按钮)、自定义图标槽(Flutter `iconWidget`、Android `iconContent`、Vue `#icon`;iOS 仍用 `systemImage`),以及 `tone`(`normal` / `error`:error 用 danger 色渲染标题与图标,并让长错误文本自由换行)。
- **IconButton 覆盖项**(四端)—— `tintColor`(前景)、`backgroundColor`、`customSize`,用于任意着色的圆形 / 头部按钮;`customSize` 下字形按 `size * 0.46` 推导。
- **Input**(Flutter)—— 字段内可选前置 `prefix` 组件(如搜索图标)及 `autofocus`。
- **FilterTabs `padding`**(Flutter)—— 由宿主控制 tab 行留白。
- **SettingsList `select` 行类型**(Flutter `FlareSettingKind.select`)—— 单选行,在选中项尾部显示勾选并加粗其标签。
- **`notifications` i18n 命名空间**(Vue `messages.ts`,zh-CN / en-US)。

### 变更
- **SegmentedControl**(Flutter、iOS)分段改为全宽布局,不再使用固定最小宽度。

### 分发
- 各通道版本统一为 `1.0.14`:npm `@flare-im/vue-ui@1.0.14`、GitHub tag `1.0.14`(iOS SPM 与 Android JitPack `com.flare.im:im-ui-compose:1.0.14`)、Flutter `flare_im_ui: 1.0.14`。

## [1.0.9] 及更早

更新日志建立之前的版本,详见 git 历史与 tag(`1.0.4`–`1.0.9`)。
