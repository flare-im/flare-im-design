# 登录后业务页面检查（2026-09-09，进行中）

本记录区分真实模拟器检查、编译/静态检查和待验证，不以登录成功或引用组件库代替业务验收。

## Social iOS 原生：已登录真实 QA 账号检查

环境：iPhone 17 Pro / iOS 26.4；本地 Social HTTP 服务启动后可加载业务数据。IM 连接仍周期性断开重连，消息收发链路未通过。未发送消息、发布动态、修改好友/群/隐私、撤销登录设备。

| 页面/流程 | 检查结果与处理 | 验证状态 |
|---|---|---|
| 消息列表 | QA 好友及七个群可见 | 模拟器已检查 |
| 联系人/群列表 | 可切换、进入详情 | 模拟器已检查 |
| 联系人详情 | 接通发消息路由；没有回调的音视频操作禁用 | 更新后二次实测通过 |
| 备注/描述编辑 | 原生 alert 改共享 FormSheetView + InputView；保存失败保留草稿并报错 | 表单显示/取消实测；失败分支尚未注入 |
| 群资料/入群申请 | 资料和成员可见；空申请页可关闭；名称/公告/昵称改共享表单 | 资料实测；新版编辑页待复测 |
| 全局搜索 | 250ms 防抖、取消过期任务、清空状态；群结果使用 SDK 解析会话 ID | 编译通过，快速输入待实测 |
| 空会话 | MessageListView 空态原先收缩，标题和输入框漂浮在中间；已修复占满剩余空间 | 最新模拟器截图通过 |
| 语音输入 | 无框图标模式可进入、切回键盘 | 未录音/发送 |
| 更多面板 | 打开/收起可用；现有位置/名片/投票是示例直发回调 | 未点击直发，业务编辑流程仍待完善 |
| 表情/贴纸 | 原先图片/分类只有手势、无按钮语义；改 Button、标签、44pt 热区、可变高度 | 编译/复测进行中 |
| 个人中心/资料编辑 | 保存/取消改共享 ButtonView，忙状态禁用；无头像选择回调不显示相机入口 | 个人中心实测，编辑忙状态待注入 |
| 设置 | 使用共享设置行，退出登录标记 danger | 实测已检查 |
| 登录设备 | 改共享 DeviceSessionsView；日期格式化；加载/撤销失败显式反馈；撤销确认 | 实测已检查，紧凑行二次复测待完成 |
| 当前设备标识 | 后端所有 isCurrent=false，禁止猜测；警告并禁用设备撤销 | 模拟器确认；后端根因仍待处理 |
| 朋友圈权限 | 选择好友改 ContactListView，补关闭按钮 | 旧页缺关闭已确认，新页待复测 |
| 圈子列表 | 姓名/签名位置调整，避免白字落到封面外白底 | 二次复测待完成 |
| 发布动态草稿 | 空内容不能发表；可见范围面板正常展开/关闭 | 模拟器已检查，未发表 |
| 发布可见范围 | 选项/联系人改系统按钮和 selected 语义，保留原回调 | 编译通过，二次 AX 复测待完成 |
| 加好友/加群/建群/黑名单/新请求/二维码 | 尚未全部深入实测；通讯录粘贴输入改共享 InputView | 待继续 |

## 本轮验证

- Social iOS Debug arm64 模拟器构建通过（最新表情改动仍在构建）。
- Swift kit 154 个现有测试通过（最新表情改动前）。这些不代表 UI 端到端验收。
- check-ui-reuse.mjs 已登记文件检查通过。
- check-composer-consumers.mjs 九个输入组件引用检查通过。
- 截图：social-ios-empty-chat.png（修复后空态布局）。

## 其他端范围

Core iOS/Android/Flutter/Tauri 和 Social Android/Flutter/Web/Tauri 的登录后全页面，本轮尚未完成真实操作验收。Android 模拟器进程存在，但 adb 调用响应慢；启动 intent 被投递给已有 Activity，尚未确认自动登录执行。上一轮的编译与启动结果见 ../reuse-simulator/README.md，不混算为本轮页面验收。

## 追加检查（23:39）

- Social Web 已使用现有 QA 账号真实登录，检查通讯录、联系人详情、备注草稿取消、设置、设备列表、朋友圈权限、圈子列表、发布草稿输入/取消。未提交业务写操作。
- Web/Tauri ContactDetailPanel 共用新 FlareFormSheet，移除重复 footer/form 样式；禁用未接线音视频；编辑失败保留草稿，星标失败显式反馈。
- Vue FlareBottomSheet 增加 dismissible、对话框名称、初始 open 生效、嵌套弹层键盘只交最上层；FlareFormSheet 忙状态/Escape/submit/错误状态 2 个测试通过。
- TypeScript SDK UserModule.listLoginSessions 修复 HTTP snake_case 到 camelCase 适配、严格当前设备布尔值和稳定 ID；3 个契约测试通过。Web 实际设备时间已显示，设备 ID 可作为无名称时的回退。仍无后端当前会话标识，撤销禁用。
- Social Web 设置设备列表改用 FlareDeviceSessions；删除失效 time 图标映射，使用库内 calendar。权限列表补添加按钮名称和成员按钮键盘语义。
- Social Web 生产构建通过；Social Tauri 前端生产构建及原有三个检查通过。未打包/启动 Tauri 原生壳，也未部署。
- iOS 更新后真实截图确认空聊天贴底布局、圈子封面姓名/签名对比度已修复；历史消息恢复后也已看到真实 QA 消息。最新表情代码编译通过，但模拟器 CUA 窗口间歇 noWindowsAvailable，最新表情 AX 复测尚未完成。
- 测试环境根因：接入网关存活，但多数依赖服务停止；已只补启动缺失进程，保留现有服务。进程记录 /tmp/flare-ui-internal-services/core-started.json（包含实际名 flare-orchestrator）。网关出现连接注册成功，历史摘要恢复；旧重连横幅/RouteAck 链路仍待确认，不能宣称完整消息闭环通过。
- Social Android 联系人详情缺失发消息回调已接通 SDK resolvePeerConversation；Kit ContactDetail 的 nil 回调禁用。APK assembleDebug 通过。新增登录后导航 instrumentation 测试正在执行，初次离线运行因 coroutines-test 未缓存失败，已改联网补依赖。
- Social Flutter 联系人页原将 peer ID 当 conversation ID，已改 SDK conversation.get_one，失败提示且防重复点击；未实现通话不再传占位回调。Kit ContactDetail 操作改用 FlareButton。应用定向 analyze 通过；320px 布局测试发现按钮内边距导致溢出，已加共享 Button contentPadding 进行修复，测试复跑中。

以上均为进行中记录；Core 各端和其他 Social 页面尚未完成全量真实业务验收。

## 验证更新（23:44）

- Android 登录后仪器测试确实进入了业务 UI，发现 ContactDetail 内 verticalScroll 嵌套 SettingsList LazyColumn 导致无限高度崩溃。已在库提供 SettingsList(scrollable=false) 并应用，更新后的 app 和测试 APK 均编译成功。复测遭遇 adb 设备属性/安装超时，尚不能宣称崩溃的模拟器回归已通过。
- Swift 最新 154 个测试通过（23:43）；修复了当前主题 token 改动中 ProfileViews.header 缺失局部 colors 导致的编译失败。
- Flutter 联系人 320px 禁用语义与布局测试通过，按钮/设置行累计 4 项定向测试通过；内容 padding 与子图标主题统一由 FlareButton 提供。
- Vue kit typecheck、Social Web typecheck、TypeScript SDK check 通过。更新后的 13 个已迁移页面引用检查通过。
- Android / Flutter 的新增同类修复尚未完成全业务页视觉矩阵，Core 各端仍待后续实测。

## 验证更新（23:52）

- Android 重启现有模拟器后恢复 adb，登录后 instrumentation 回归通过（1/1）。覆盖联系人详情消息可用/通话禁用、通讯录/圈子/个人中心/消息导航，确认嵌套滚动崩溃已消除。此前两个断言错误（圈子必有 QA Alice、个人页必有“设置”字样）已改为页面真实入口断言。日志 /tmp/flare-social-android-pages-test.log。
- Android 个人页 QR 图标补接已有二维码弹层。
- Vue 群资料编辑改共用 FlareFormSheet；增加可选 submitEdit 异步保存契约，Web/Tauri 对接。空群名禁止提交，忙时禁止重复提交/关闭，失败保留草稿。Web 实际输入空白确认保存禁用并取消；未写群数据。3 项表单与群编辑测试通过；Web typecheck、Tauri 最新前端 build 通过。
- Web 继续检查新的好友空态、黑名单空态、7 个群的目录、群资料、入群申请空态。补齐服务后新快照已无重连横幅，尚未验证真实发送闭环。
- Flutter 最新共享按钮/联系人测试 3 项通过（包含子图标主题与窄屏 padding）。
- 开始检查 Core Web，本地 1430 已运行，当前使用现有 QA 身份登录。

## Core Web 进入检查结果

- 使用现有本地 1430 服务尝试 QA ID 登录，网关日志明确为 authorization token is missing；api-gateway 的 dev_issue=false。当前不能进入其内部业务页面，未绕过鉴权。
- 修复组件库 tokenRejected 中英提示：不再要求用户检查已经删除的签名密钥输入，改为核对服务地址/有效业务 Token，SDK 托管场景检查网关授权配置；清理对应过时注释。
- 本轮实际内部运行覆盖 Social iOS、Social Web 和 Social Android 导航回归；其他端只按前述编译/定向测试范围记录，不能等同九端所有业务页面验收完成。
