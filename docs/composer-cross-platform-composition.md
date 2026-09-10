# 聊天输入组件跨端组合约定

更新：2026-09-09。范围：Core Tauri / iOS / Android / Flutter，Social Web / Tauri / iOS / Android / Flutter 的主聊天输入入口。

## 单一组件来源

| 渲染技术 | 设计库入口 | 消费应用 |
| --- | --- | --- |
| Vue | `vue-im-ui/src/components/composer/EnhancedComposer.vue`，公开名称 `FlareComposer` | Core Tauri、Social Web、Social Tauri |
| SwiftUI | `ios-im-ui/Sources/FlareIMUI/Components/ComposerView.swift` | Core iOS、Social iOS |
| Compose | `android-im-ui/src/main/kotlin/com/flare/im/ui/Composer.kt` | Core Android、Social Android |
| Flutter | `flutter-im-ui/lib/src/components/flare_composer.dart` | Core Flutter、Social Flutter |

应用中的 ComposerBar / MessageComposer / ComposerView 是业务适配器，调用设计库组件，不再自行绘制主文本编辑器、富文本工具条、发送按钮和录音行。Flutter 的 ExtendedTextField 包装与富文本序列化已下沉设计库；旧应用导入位置仅转导出，避免另一份实现。

应用负责：会话/草稿/回复数据，SDK 构建与发送，上传，权限与平台文件选择器，发送结果处理，按能力配置更多操作。设计库负责：布局、图标、主题、面板切换、编辑器和录音交互。业务表单通过设计库基础控件组合；禁止为了某个 app 的截图修改另一套输入框 CSS/尺寸。

## 视觉与交互

- 主控件图标视觉尺寸 20，移动端触控区 44；不使用选中方块，选中状态用主题强调色。
- 输入面板 12 圆角、细边线；文本 15；原生富文本条高 32，横向滚动，无“更多格式”按钮。
- 手机工具按序平铺：表情、提及、语音、图片、富文本、更多、发送。桌面工具靠右；Web 的单行模式保留行内排列。
- 输入默认随文本增长，展开/收起为对角箭头。打开更多隐藏编辑区，草稿保留；原生更多内容上限 240，内容可滚动，避免扩展操作无限撑高聊天区。
- 语音使用设计库紧凑录音行；键盘切换终止并清理录音，不清除文字草稿。取消未完成的权限请求不应在返回后启动录音。
- 格式开关只改变编辑预览；提交时序列化。段落格式互斥，普通文本不插入格式标记。
- Shared Composer 的 disabled 必须由应用权限/连接/业务状态驱动；状态解释使用 StatusBanner 等共享组件。组件不自行推断群禁言权限。
- Emoji/Sticker 使用设计库资源及选择器；上传/发送失败由应用保留重试语义。Web 图片直接触发文件选择器。

## 本轮验证

| 项目 | 结果 |
| --- | --- |
| 9 个主输入入口依赖检查 | `node scripts/check-composer-consumers.mjs` 通过 |
| Core Tauri / Social Tauri | Vue 类型检查和生产构建通过；Core bundle budget 通过 |
| Social Web | 类型检查和生产构建通过 |
| Core iOS | Swift Package 编译通过 |
| Social iOS | arm64 iOS Simulator Xcode 构建通过 |
| Core Android / Social Android | `:app:compileDebugKotlin` 通过 |
| Core Flutter / Social Flutter | 修改入口及 SDK 适配的定向 analyzer 通过 |
| Flutter 共享组件 | 25 项测试通过：录音、基础操作、320/390/1024 明暗主题布局、44 触控区、面板草稿保留、禁用发送、替换 controller |
| Core Flutter 富文本 | 4 项测试通过 |

依赖检查只证明入口使用设计库，不代替视觉或端到端验证。未在这轮向真实联系人发送测试消息。Flutter APK 仍受 Google Maven / Maven Central TLS 与本地依赖缓存不完整限制，详见 `voice-cross-platform-rollout.md`。原生实机键盘、权限弹窗和逐像素对照尚未完成，不能将编译通过理解为所有端像素完全一致。

本轮收敛的是聊天输入组件及其周边交互；各应用其他业务页面仍需按组件规范持续审查。平台能力和业务菜单可以不同，组件样式与基础交互不能由应用分叉维护。
