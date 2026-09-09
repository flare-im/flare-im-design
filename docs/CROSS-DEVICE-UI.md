# 跨设备 IM 视觉与布局契约

本规范适用于 Vue（含 Web/Tauri）、Flutter、Compose 和 SwiftUI。目标是相同的视觉层级、品牌色、布局规则与交互结果。不同系统的字体栅格化、emoji 和原生弹窗存在差异，不能承诺逐物理像素相同，也不能通过关闭系统字体缩放来追求截图一致。

## 设计判断与本轮处理

消息内容是页面主体。主色用于发送气泡、选中态与主要操作；列表、搜索和详情采用中性表面。未读数字使用平面色胶囊，去除与消息争夺注意力的渐变和光晕。头像基准统一为 44；原生会话标题统一为 15 并保留系统缩放。对话标题与摘要允许单行省略，消息正文必须换行且完整可读。

原有问题包括各端 300/320 栏宽互换、不同断点、Web 按窗口而非容器宽度判断、双栏吞掉详情、Android 库与应用主题独立选择，以及过小的返回/清空点击区域。这些问题已在基础组件层处理。

## 单一真源与布局

修改 `tokens/tokens.json`，运行 `node tokens/build.mjs`。禁止直接修改生成的 CSS、Dart、Swift、Kotlin 和 Web layout-policy 文件。CI 使用 `node tokens/build.mjs --check` 检查所有平台生成产物，而非只检查 Web CSS。

| 项目 | 逻辑尺寸 | 使用方式 |
|---|---:|---|
| 会话头像 | 44 | 可由业务显式覆盖；默认跨端统一 |
| 列表栏 | 320 | `listWidth` |
| 详情栏 | 300 | `detailWidth` |
| 聊天区最小宽度 | 360 | 大字号时增加预留宽度 |
| 双栏起点 | 720 | 同时必须容纳列表、聊天及分隔线 |
| 三栏起点 | 1100 | 同时必须容纳三栏及分隔线 |
| 返回按钮最小触控区域 | 48 × 48 | 图标可以更小，点击区域不能跟着缩小 |

Web 使用 CSS px、Flutter 使用 logical pixel、Android 使用 dp、iOS 使用 pt。不要再乘设备像素比。可用宽度应扣除导航轨、安全区及父容器占用，平板分屏、桌面缩窗与嵌入面板遵循同一规则。

聊天宽度预算为 `360 × clamp(textScale, 1, 2)`。这里的上限仅用于分栏预算，不限制实际字体缩放。系统字号更大时组件仍尊重系统设置。SwiftUI 通过 ScaledMetric、Compose 通过 fontScale、Flutter 通过 TextScaler 取得缩放；Web 浏览器缩放会改变可用 CSS 宽度，另有应用字号功能时传入 `textScale`。

| 可用宽度 | 字号倍率 | 有详情时栏数 |
|---:|---:|---:|
| 390 | 1 | 1 |
| 720 | 1 | 2 |
| 1100 | 1 | 3 |
| 720 | 2 | 1 |
| 1100 | 2 | 2 |
| 1342 | 2 | 3 |

单栏显示 `activePane`；双栏的右侧显示聊天或请求打开的详情；三栏同时显示三者。单栏返回顺序为详情 → 聊天 → 列表。业务头部已有返回按钮时传 `hideMobileBar`，并自行实现同样的导航顺序。原生库没有回调时不显示无效返回按钮。双栏详情由宿主提供关闭操作。

## 安全区、键盘与主题接入

**Android**：`FlareThemeProvider(dark = resolvedDark)` 与应用 `MaterialTheme` 使用同一个解析后的主题值。默认才跟随系统；示例应用已经接入。`FlareScreen` 默认消费 `WindowInsets.safeDrawing`。父 Scaffold 已应用并消费 inset 时不会重复；如果宿主自行用普通 padding 处理，应传 `windowInsets = WindowInsets(0, 0, 0, 0)`。输入页只在一个层级处理 IME，不能在根、聊天区、输入框各加一遍键盘高度。

**Flutter**：由 `MaterialApp.theme/darkTheme/themeMode` 驱动组件。`FlareScreen` 内含 SafeArea，页面外用 `Scaffold(resizeToAvoidBottomInset: true)` 处理键盘。聊天列表用 Expanded，输入区留在可见高度内；不要再叠加 `viewInsets.bottom`。不要固定整个页面高度，也不要替换 TextScaler 来禁用辅助字号。

**iOS**：用宿主 `.preferredColorScheme(...)` 控制主题。`FlareScreen` 只让背景延伸到安全区，内容保留 SwiftUI 默认安全区与键盘避让。输入栏用 `safeAreaInset(edge: .bottom)` 集成；不要对整个聊天页面使用 `.ignoresSafeArea(.keyboard)`。动态字号可能增加行高，应允许滚动。

**Web/Tauri**：容器需要明确可用高度与 `min-height: 0`。移动页面声明 viewport，并由最外层应用 `env(safe-area-inset-*)`；组件内部不重复增加系统 inset。ResizeObserver 根据组件宽度重新分栏。主题由 Flare provider 统一设置，避免局部硬编码背景。软键盘的视觉视口变化仍需移动 Safari/Android WebView 验收。

## 组件评审清单

- 会话列表：头像对齐、标题/时间主次分明；长标题、草稿、@提醒、静音与 99+ 未读不挤出屏幕。72 为常规行高目标，不应强制锁住大字号行高。
- 消息：文字正文换行，媒体保持比例，失败/重试与发送中状态可辨，不能只用颜色表达状态。
- 菜单：图标列与文本垂直居中，危险操作单独分组，桌面保留键盘与焦点反馈；触屏菜单保持足够点击区域。
- 搜索：筛选、加载、空结果、失败分别表达；清空控件具有可访问名称和 48 点击区域（Flutter 已实现）。
- 详情：窄屏可单独进入并返回；宽屏不抢占聊天阅读宽度；长 ID 放诊断信息中。
- 标题与操作：提供本地化返回文本，不把可见图标当作唯一无障碍名称。

## 可执行验证与真机验收

共同边界数据位于 `spec/device-layout-vectors.json`。Vue、Flutter、Swift 测试直接读取；Kotlin 测试覆盖同样边界。改断点必须同步验证四端，不允许仅修改某个示例的常量。

```sh
node tokens/build.mjs --check
(cd vue-im-ui && npm test -- src/design-system/theme/layout-policy.test.ts && npm run check:sfc)
(cd flutter-im-ui && flutter test)
(cd ios-im-ui && swift test)
(cd android-im-ui && ./gradlew testDebugUnitTest)
```

本轮自动测试覆盖：320/390/720/1100 可用宽度，1×/2× 字号、深浅主题、3× DPR、顶部 59/底部 34 安全区、嵌套窄容器、详情可见性、返回顺序、返回点击高度、长会话标题及 99+ 未读。测试中的安全区数值是模拟条件，不等于已经在对应手机运行。

发布前的真机矩阵：

| 设备类型 | 必测场景 | 验收标准 |
|---|---|---|
| 小屏 iPhone / 320–375 宽 | 大字号、键盘、横屏 | 无溢出、输入栏可见、正文可滚动 |
| 刘海/灵动岛 iPhone | 顶部安全区、底部手势区、深色 | 控件不被遮挡，背景连续 |
| 小屏 Android / 360 宽 | 1×/1.3×/2× 字号、三键导航 | 返回/发送可点击，菜单完整 |
| 大屏 Android / 412–430 宽 | 手势导航、软键盘、暗色 | 无重复 inset、无输入区跳动 |
| iPad / Android 平板 | 分屏缩放、横竖屏、打开详情 | 按实际可用宽度分栏且保留选中会话 |
| 任一设备 | TalkBack/VoiceOver、长中文英文、emoji | 按钮有名称、焦点顺序正确 |

保存同一测试数据下的截图，记录设备、OS、逻辑尺寸、DPR、字号、主题、语言和应用/kit 版本。截图按平台分别建基线；几何位置允许约 1 逻辑单位取整差异，字体与 emoji 不做跨系统像素相等断言。任何文字裁切、不可点击或键盘遮挡都判失败。

本轮尚未完成上述真机矩阵，不能把单元测试或构建通过当作所有设备显示一致的证明。安装已发布包的消费者还需要同步升级 kit/tokens；工作区源码变化不会自动更新商店中的应用。

## 2026-09-09 验证记录

- Vue 188 项测试通过；TypeScript 检查通过。
- Flutter 106 项测试通过，其中本轮新增设备布局验证 20 项；修改组件的静态分析通过。
- Swift 24 项测试通过，iOS 模拟器 arm64 目标编译通过。
- Android 10 项单元测试与示例 app Kotlin 编译通过。
- 111 项契约校验通过，文档站生产构建通过（存在既有 chunk 大小提示）。
- 补齐缺失的 Vue MentionPicker：搜索、所有人、空结果、键盘方向键/Enter/Escape、可访问输入名称与触控尺寸。
- 文档演示的主题容器增加可收缩约束，修复 390 宽度溢出。
- Chromium 真实浏览器回归通过：390px/3× DPR 提及选择器、48px 触控区域、搜索/方向键/Enter/Escape，以及单/双/三栏容器切换和 200% 字号退回单栏。171 个 Vue SFC 编译通过。

浏览器回归脚本：`scripts/check-device-ui-browser.mjs`。先在 site 启动 `npm run dev -- --host 127.0.0.1 --port 5189`，再运行 `node scripts/check-device-ui-browser.mjs http://127.0.0.1:5189 <已安装@playwright/test的消费项目package.json绝对路径>`。它验证真实组件的搜索、选择、关闭、触控尺寸、容器缩放和大字号分栏。
