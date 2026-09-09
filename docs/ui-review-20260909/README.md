# Flare IM 跨端 UI 整理 · 2026-09-09

## 目标与取舍
面向日常消息沟通，核心工作是快速找到会话、读消息、完成操作。保留 Flare 紫色识别，使用中性底色与清晰文字。删除消息发光、列表卡片套边和详情大面积紫底。独特元素保留在当前会话左侧的细紫色标记，与消息流的方向呼应；不把 IM 工作台做成营销页。

色板：纸白 #FFFFFF、画布灰 #F7F8FA、分隔灰 #E3E5EB、墨灰 #20232D、说明灰 #626978、Flare 紫 #7047D6。细节文字 #687182。颜色由 tokens/tokens.json 生成 CSS/TS、Dart、Swift、Kotlin。
字体：桌面标题 SF Pro Display / Segoe UI Variable Display，正文各平台原生字体及中文回退；Android Roboto，iOS SF。标题 18–25、正文 14–15、辅助 12；标题 600，正文 400–500；时间使用等宽数字。不加载远程字体。

桌面布局：
```
导航 56 | 会话 288–336 | 聊天自适应 | 详情 300（足够宽时）
手机：会话列表 → 聊天 → 详情/搜索抽屉
```
对比过全居中菜单文字与固定图标列：选择固定图标列、文字左对齐、每行垂直居中，长短标签更容易扫描。普通操作与破坏操作保留分隔。

## 实施范围
- 共用 Vue 菜单：修正两列 Grid 容纳三个子节点导致的隐式第二行；改为单行 Flex，图标 20px 固定槽，正文自适应，空尾部隐藏。添加 Shift+F10、Escape 及焦点轮廓。桌面 40px 行高，触摸 44px。
- 共用色板与气泡：中性浅/深底色、提高辅助文字可读性，四套 UI 的发送气泡改为纯色紫，保留消息方向与发送状态。
- Web/Tauri：本地设计库搭配本地 token，缩减列表宽度、平整会话行、详情双列操作、搜索面板减装饰，保留响应式导航和减少动态效果偏好；修复跟随系统主题时计算值未更新，以及 Naive UI 未应用深色主题的问题。详情 ID 收入可展开的 SDK 诊断区。
- Flutter：移除复制的基础色值，通过生成的 const palette 引用设计 token；菜单主题统一，附件网格根据宽度采用 3/4 列并为两行标签及字体缩放预留高度；消息正文最大宽度 560，亮暗颜色保留。
- Android：原生主题字重减轻，圆点导航换为语义图标；900dp 以上导航栏 + 320dp 会话列表 + 聊天双栏，窄屏保留单页导航。存在同级设计仓库时通过 Gradle composite build 使用最新组件，独立检出仍可用发布包。
- iOS：主题色随系统/用户选择解析；关闭详情时采用双栏而非空详情列；去掉发送气泡光晕，调整栏宽与标题字重。

## 状态与可访问性
不改变 SDK 状态及业务操作。空、加载、错误、离线、重连、发送失败、权限和能力不可用仍沿用现有提示及恢复入口；危险操作保留红色。菜单支持键盘，正文不改写，触摸菜单目标至少 44px。视口与主题视觉验证结果见下文。

## 验证记录
- Web `npm run build:web` 通过，TypeScript 与 800 KiB 单 chunk 门禁通过。深色主题样式独立分块，保留原预算。
- Tauri `npm run build`（renderer）通过，1400 KiB 门禁通过；本轮未重新打包原生安装程序。
- Vue UI `npm run check:sfc`：170 个 SFC 编译通过。
- Android `./gradlew :app:compileDebugKotlin --console=plain` 通过，包含本地设计库与宽屏布局。
- Swift macOS `swift build` 及 iOS simulator `swift build --target FlareImApp --triple arm64-apple-ios16.0-simulator --sdk …` 通过。
- Flutter 设计库改动组件和 app 主题/消息尺寸 `flutter analyze --no-pub …` 通过。
- Chromium 生产包 + 已有测试账号：七个菜单行高均为 40px，图标及文字中心偏差均为 0px；Shift+F10 打开及 Escape 关闭通过。
- 1600×1000、1024×768、390×844（浅色及深色）无页面横向溢出，系统主题切换成功。详见 browser-check.json。
- 对比度：正文 15.67:1、说明文字 5.51:1、辅助文字在聊天底色 4.62:1、紫色气泡白字 5.90:1。
- 构建中仍有既有 SDK 未使用变量、Compose 弃用 API 等警告，不影响构建通过。
- 没有进行 Android/iOS 真机视觉测试；Flutter 本轮是静态分析与共享样式修改，未打包并运行设备端。
- UI 已按用户后续要求发布到 https://118-107-9-221.sslip.io ，未发布 npm/Maven 包。

## 截图

[桌面菜单](desktop-menu.png) · [桌面](desktop.png) · [平板](tablet.png) · [手机](mobile.png) · [手机深色](mobile-dark.png)

复测脚本：flare-im-core-client-sdk/scripts/check-ui-layout.mjs。传入本地站点、测试网关、已有用户 ID 和截图目录；只登录、打开会话和菜单，不发送、编辑或删除消息。

## 线上发布验证

- 发布版本：`ui-20260909-130415`，279 个文件校验后原子交换。
- 上一版备份：`/var/www/flare-web.backup-ui-20260909-130415`。
- 首页、入口 JS、WASM 公网返回 200，内容 SHA256 与本地构建一致。
- 公网浏览器：七个菜单项目居中偏差 0px，键盘打开/关闭通过；1600、1024、390px 无横向溢出，深色切换通过。
- 线上截图与检查数据保存在 [online](online/browser-check.json)。
- 公网真实会话 `11111` 搜索 `11`：文本 3 条、文件 1 条，筛选回归通过。
