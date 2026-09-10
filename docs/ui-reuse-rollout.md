# 共享 UI 落地记录 · 2026-09-09

规则见 [UI 组件复用规则](ui-component-reuse-policy.md)。此记录区分“聊天输入组件已接入”和“全部业务页面已统一”；后者尚未完成。

## 已落实范围

| 范围 | 共享组件与实际迁移 |
| --- | --- |
| Core Tauri / iOS / Android / Flutter，Social Web / Tauri / iOS / Android / Flutter | 九个主聊天输入入口直接组合设计库 Composer。应用保留 SDK、录音与文件平台适配、路由和业务数据映射，主编辑器不再重复绘制。 |
| Social Flutter | 资料编辑、动态评论、好友与群操作、基础导航相关页面中的按钮、文本输入和表单弹窗改用 FlareButton、FlareInput、FlareFormField、FlareDialog。 |
| Social Tauri | 联系人聊天设置、群聊天设置、应用设置直接使用 FlareSettingsRow；相关操作按钮和输入框使用 FlareButton、FlareIconButton、FlareInput。删除独立 SettingsMenuItem / SettingsToggleRow。 |
| Core iOS | 设置操作按钮、发送业务表单的字段和底部操作改用 ButtonView / FormFieldView / InputView；此前空态和状态条已接入共享组件。 |
| Social iOS | 设备下线操作使用共享危险按钮。 |
| Core Android | Composer 业务表单确认、取消使用共享按钮。 |
| Social Android | 设备下线、好友备注与描述、动态评论输入使用共享组件；删除失去用途的 UiHelpers 按钮实现。 |

## 设计库补齐

- Vue 输入框支持 autofocus、原生 maxlength、中文输入法组合期间禁止提交、可键盘操作且已本地化的清空按钮。
- Flutter 按钮支持 Enter / Space、焦点反馈、加载及禁用语义，并修复内联按钮意外撑满宽度。
- Flutter FlareDialog 提供统一表面、最大宽度、可滚动内容、始终可见的底部操作。showDialog 的路由与业务回调留在应用；busy 阻止返回。
- Vue / SwiftUI / Compose / Flutter 设置项统一补充 disabled 和 danger。开关整行激活，禁用不触发事件，状态由宿主回写。Web 支持图标插槽，应用无需复制行样式。
- 原生文件选择器、权限、系统键盘仍使用平台能力；跨端共享组件契约，不将业务和 SDK 放进视觉组件。

## 验证

本轮已验证：

- Flutter 组件库完整测试 310 项通过；追加设置行单独测试通过，验证整行和开关区域只触发一次，禁用不触发。
- Social Flutter 修改的 screens 静态分析无问题；弹窗测试覆盖 320 / 1024 宽度及明暗主题。
- Vue 输入框与设置行 4 项测试通过，覆盖输入法、清空、禁用和回调。
- 浏览器 390 / 1280 宽度明暗主题检查：设置行高至少 48px、无横向溢出、无页面异常。组件文档示例为受控数据，实际回写由应用处理。
- Core iOS Swift 构建、Social iOS 模拟器构建通过；Social iOS 构建在最后一轮设置行改动前完成，共享 Swift 修改由 Core 构建再次覆盖。
- Core / Social Android Kotlin 编译通过；最后一轮共享设置行修改由 Social Android 编译覆盖。
- Core / Social Tauri、Social Web 的此前接入构建通过；本轮 Social Tauri 设置与输入迁移后构建通过。

Flutter Android 安装包此前仍受 Maven TLS / 缓存缺失阻塞，不能将静态分析和组件测试视为真机验收。未声称所有原生场景已完成截图或端到端验证。

## 防回退检查

在工作区根目录执行：

```sh
node flare-im-design/scripts/check-composer-consumers.mjs
node flare-im-design/scripts/check-ui-reuse.mjs
```

第一项覆盖九个聊天入口；第二项只约束已迁移的业务页面及已删除的重复组件，不扫描或禁止合理的业务组合和系统控件。这些是架构检查，不能替代交互测试。

## 仍待收敛

- 其余历史业务页面、设置分区与应用壳层继续逐页检查已有组件，不能以已依赖设计库替代实际复用。
- 原生业务表单的通用弹窗容器、剩余搜索栏与局部菜单仍存在平台自绘实现；迁移需保留原业务校验、权限和 SDK 回调。
- 九端真机 / 模拟器视觉矩阵及录音权限、前后台、失败恢复的完整联调尚未全部完成。

本轮未发布服务器；当前任务为各端组件复用落地。

## 后续模拟器验证

继续改造了 Android 六个业务弹窗和 iOS 登录表单，并完成 Android 两项仪器测试及三种客户端启动验证。详细结果、截图和明确未完成项见 [模拟器记录](ui-review-20260909/reuse-simulator/README.md)。

## 登录后业务检查

已继续进入 Social iOS / Web 真实 QA 业务页，修复联系人聊天跳转、空会话布局、编辑草稿失败处理、设备信息适配和圈子可访问性；同类修复同步至 Social Android / Flutter / Tauri。逐页证据和待办见 [内部业务检查](ui-review-20260909/internal-pages/README.md)。

本次新增组件契约：

- SwiftUI `FormSheetView` 与 Vue `FlareFormSheet` 负责通用表单布局和忙状态；业务保存及错误文本由宿主提供。
- Vue `FlareBottomSheet.dismissible` 默认为 true；提交中设置 false，阻止遮罩和 Escape 关闭。嵌套弹层仅最上层处理键盘，初始 open 同样建立焦点与滚动锁。
- Compose `SettingsList.scrollable` 默认 true；放进父级滚动布局时设 false，保持同样设置行外观而不嵌套 LazyColumn。
- Flutter `FlareButton.contentPadding` 可用于组合紧凑图标操作；保留统一焦点、禁用和键盘行为。
- Vue `FlareContactDetail.disabledActions` 可明确停用 message/call/video；原生与 Flutter 的缺失回调呈禁用状态。
- SwiftUI `FlareEmojiStickerPicker.height` 默认 300；宿主弹层需要撑满可用区域时传 nil。

群资料编辑增量：Vue FlareGroupDetail.submitEdit(kind, value) 可等待业务保存；底层使用 FlareFormSheet 管理 busy/error/空群名校验，失败保留草稿。Social Web/Tauri 已接线。Android SettingsList(scrollable=false) 用于已有滚动容器，Social 联系人页嵌套滚动崩溃的模拟器回归已通过。
