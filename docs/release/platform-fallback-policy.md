# Platform Fallback Policy（2.0.0-rc.1 · Layer 5）

真源：`spec/platform-contract.json`。四端各有一份实现（Vue `shared/platform`、Flutter `FlarePlatformScope`、Compose `FlarePlatformProvider`、iOS `.flarePlatform(_:)`），门禁 `node tooling/check-platform-contract.mjs`（release-check 的 `native-contract`）。

## 1. 规则

1. 组件只读 `PlatformCapabilities`，不判断平台身份；`navigator.userAgent`、`defaultTargetPlatform`、`Build.VERSION`、`UIDevice` 等只允许出现在平台模块（门禁的 sniffLint 白名单）。
2. 宿主实现 `PlatformAdapter`，只覆写自己能做的操作，并在 `capabilities` 里声明；没覆写的操作调用时得到 `UNSUPPORTED`，绝不抛异常。
3. 每个能力只有三种级别：`supported`（原生能力）、`fallback`（kit 或宿主提供替代路径）、`unsupported`（不提供，UI 不展示入口）。
4. 错误模型只有五个码：`UNSUPPORTED` / `CANCELLED` / `PERMISSION_DENIED` / `TIMEOUT` / `FAILED`。用户取消是 `CANCELLED`，UI 静默；空选择也是 `CANCELLED`，绝不返回空成功。
5. 所有原生调用经 `callPlatform` / `callFlarePlatform` 包一层：抛错归一化、可选超时；宿主不需要 try/catch。

## 2. 能力矩阵（默认值，宿主 capabilities 可覆写）

| 能力 | Web | Tauri | Flutter | iOS | Android | 未支持时 UI 行为 |
|---|---|---|---|---|---|---|
| pointer | 媒体查询检测（fine/coarse/mixed） | fine | 目标平台：桌面/Web fine，移动 coarse | coarse；iPad 指针为 mixed | coarse；有指针为 mixed | — |
| hover | 检测 `(hover: hover)` | true | 桌面/Web | 有指针才 true | 有指针才 true | 悬停工具条不显示，改长按 / 更多入口 |
| contextMenu | pointer fine/mixed | true | 桌面/Web | 有指针才 true | 有指针才 true | 右键不打开菜单，长按打开面板 |
| keyboardShortcut | pointer fine 或 hover | true | 桌面/Web | 有指针才 true | 有指针才 true | 不展示快捷键提示 |
| bottomSheet | 视口 h5（<600） | false | 宽度 <600 | 宽度 <600 | 宽度 <600 dp | 用下拉 / 弹出层 |
| nativeBack | 适配器实现 `onNativeBack` 时为 true（`createWebPlatformAdapter({ historyBack: true })` 用 History API） | false | Android | false | true | 无返回拦截；关闭靠显式按钮 |
| safeArea | true（`--flare-safe-area-*`） | false | 非桌面 | true | true | 贴边表面不加内边距 |
| filePicker | **supported**（DOM `<input type=file>`） | **supported**（dialog 插件） | **supported**（file_picker，宿主适配器） | **supported**（`UIDocumentPickerViewController(asCopy:)`，宿主适配器）；无 UIKit 的构建为 unsupported | **supported**（`OpenMultipleDocuments`，宿主适配器） | 宿主从 composer 动作里去掉 file |
| imagePicker | **supported**（DOM input，image/* [+video/*]） | **supported**（dialog 插件按扩展名过滤） | **supported**（image_picker，宿主适配器） | **supported**（PHPicker，宿主适配器）；无 UIKit 的构建降为 fallback（宿主自己的输入表单） | **supported**（`PickMultipleVisualMedia`，宿主适配器） | 同上去掉 image |
| share | **fallback**（无 `navigator.share` 时宿主复制链接） | unsupported | unsupported | unsupported（ShareLink 仍是视图，未包成适配器操作） | unsupported（ACTION_SEND 未接） | 不展示分享入口 |

三个级别不是三种写法而是三种事实：`supported` 有原生实现，`fallback` 是宿主用别的路径做同一件事（iOS 没有相册时改用输入表单，入口保留），`unsupported` 是连替代路径都没有、入口直接消失。

## 3. 各端实现位置

| 平台 | 模块 | 提供者 | 默认适配器 | 契约测试 |
|---|---|---|---|---|
| Vue | `packages/vue-im-ui/src/shared/platform/` | `FlareUiProvider` / `FlareConfigProvider` 的 `platform` prop → `useFlarePlatformProvider` | `createWebPlatformAdapter()` | `contract.test.ts`（22 例，真实 DOM input + navigator.share） |
| Flutter | `lib/src/platform/flare_platform.dart` | `FlarePlatformScope` / `FlarePlatform.of` | `FlareUnsupportedPlatformAdapter` | `test/platform_contract_test.dart`（23 例） |
| Compose | `ui/FlarePlatform.kt` | `FlarePlatformProvider` / `LocalFlarePlatform` | `FlareUnsupportedPlatformAdapter` | `FlarePlatformTest.kt`（4 例，18 向量） |
| iOS | `Platform/FlarePlatform.swift` | `.flarePlatform(_:)` / `@Environment(\.flarePlatform)` | `FlareUnsupportedPlatformAdapter` | `PlatformContractTests.swift`（4 例，18 向量） |

宿主实现：Web `flare-core-web-app` 用 kit 的 `createWebPlatformAdapter`；Tauri `flare-core-tauri-app/src/integration/platformAdapter.ts`；Flutter `flare-core-flutter-app/lib/infrastructure/platform/app_platform_adapter.dart`（`FlarePlatformScope` 装在 `app.dart`，聊天页四个选择入口全部经适配器）；iOS `flare-core-ios-app/Sources/FlareImApp/Core/Platform/IosPlatformAdapter.swift`（装在 `FlareImRootView`，宽度来自根视图所以 iPad 分屏会改断点；选择器用 UIKit 呈现而不是 `.photosPicker` / `.fileImporter` 视图状态——后者分不清「选中」和「关闭」，只能和选择变更赛跑）；Android `flare-core-android-app/.../core/platform/AndroidPlatformAdapter.kt`（在 `MainActivity.onCreate` 用 `ActivityResultRegistry` 注册，配置变更后结果仍能回到新实例）。共享 Vue 参考实现 `FlareChatWorkspace.openMediaComposer` 只走 `callPlatform(pickImages | pickFiles)`，删除了自带 `<input type=file>` 与 `configureAppMediaPathPicker` 双路径。

## 4. 已迁移的平台判断

- `useMessageMenuInteraction` 不再自己读 `(pointer: fine)`，改读 `useFlarePlatformSafe().capabilities.pointer`。
- `createWebPlatformAdapter` / `detectWebCapabilities` 是 kit 里唯一读 pointer / hover 媒体查询的地方。
- 仍保留的形态判断：`useFlareAdaptive`（h5/ipad/pc）与 `useViewport`（mobile/tablet/desktop）——两套断点（599/1023 vs 600/900）是一处待合并的重复，登记到 P0-4。
