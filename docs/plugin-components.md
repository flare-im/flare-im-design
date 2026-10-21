# 插件 UI 组件复用

插件只提交数据与动作 ID。SDK 持有授权目录、参数绑定、会话隔离和业务分发；应用组合页面、回调与平台 Bridge；Kit 负责呈现及无障碍交互。不要把钱包、网络、权限判断或插件脚本放进组件库。

## 四端组件

| 用途 | Vue / Web / Tauri | SwiftUI | Compose | Flutter |
|---|---|---|---|---|
| 红包封面 | `FlareRedPacketCard` | `RedPacketCardView` | `RedPacketCard` | `FlareRedPacketCard` |
| 通用插件结果/字段/动作 | `FlarePluginView` | `PluginView` | `PluginView` | `FlarePluginView` |
| 加载/错误/权限说明 | `FlareStatusBanner` | `StatusBannerView` | `StatusBanner` | `FlareStatusBanner` |
| 页面与表单 | `FlareScreen`、`FlareSchemaForm` | Kit Screen/Drawer/Form 组件 | Kit Screen/Drawer/Form 组件 | Kit Screen/Drawer/Form 组件 |

红包 Vue 面板由可选业务 SDK 拥有，组合 Kit 表单、按钮、状态条、钱包字段和红包卡片。Web/Tauri 复用同一面板。原生聊天插件视图组合通用 Kit 卡片与页面，不在应用复制视觉控件。

## 红包状态合同

四端共享 `blessing`、`amount`、`opened`、`finished`、`disabled`、`busy`、`statusLabel`；回调为 `open` / `onOpen`。宽度最多 248，服从父约束；品牌使用独立底行，不能覆盖状态。封面交互区至少 48，支持本端键盘/触控和按钮语义。

- `busy`：原命令尚未确认，显示进度并禁止再次触发。
- `disabled`：插件不可用或只读预览；不应伪装成已领完。
- `finished`：领完/过期，禁止打开。
- `statusLabel`：业务状态的纯文本，如“已创建，请在会话中领取”；不授予权限。忙碌文案优先于该值。
- 原生端缺少回调也不可交互；Vue 无动作的预览显式传入 `disabled`。
- 文案优先级：忙碌、宿主状态、已领取金额、领完、禁用、待领取。金额由宿主格式化，组件不做资金计算。

默认文案读取 Kit 语言环境。原生英文预设来自 `strings/en.json` 与 `strings/build.mjs`；`appendArgumentKits` 支持把动态金额追加到相应平台的函数字段，不能手改生成预设。Flutter Kit 声明 Material 图标资源；截图测试显式加载字体，避免把缺失字形当成有效视觉证据。

## 业务与生命周期

通用 `PluginView` 只渲染 SDK 返回的当前视图；不可用时不显示字段或动作。动作只回传不透明 ID，禁止在 Kit 中解释目标、请求上游或执行动态脚本。

红包面板通过 SDK journal 固定原命令。未知结果锁定输入，重试核对原命令；卡片投递失败只重发原红包。组件卸载后不继续把迟到结果投递到旧会话，SDK 仍保留结果供恢复核对。停用时包括投递重试在内的所有业务按钮均禁用；服务端权限检查仍独立执行。

## 验证入口

工作区根目录：

```sh
python3 scripts/verify-plugin-platform.py --group client --group apps --group native --group ui-kit
python3 scripts/verify-plugin-apple-ui.py
```

`ui-kit` 包含语言生成一致性、硬编码文案棘轮、Apple 实际组件消费者、Flutter 插件/消息合同和 Android Kit 编译/JVM/交互测试源码编译。部分分组的报告在重试时保持原分组，不自动扩展为所有后端构建。

Apple 消费者使用 Kit 原测试文件的符号链接，创建并清理自己的临时项目，只编译依赖库和插件测试，不把依赖包的全部测试拉入。iOS 模拟器用 Xcode 对同一组件测试执行补验。Android 交互源码编译不代表设备执行；需要设备后运行 `connectedDebugAndroidTest`，可以按类筛选 `PluginComponentsInteractionTest`。

浏览器隔离入口：Web 示例目录执行 `node scripts/preview-plugin-kit.mjs`，只监听 `127.0.0.1:5198`，`/mobile` 使用 390px iframe。它组合真实 SDK/Kit 与显式内存沙箱，没有业务 API、真实钱包或支付。最终边界及证据见工作区的插件 UI 验证报告。
