# IM 组件系统分发与迁移

## 包与入口

维持一个 Vue 包和四端锁步版本，不为 chat / contacts / calls / social 引入独立版本。现有源码子路径已能按需要导入组件；新增包会增加发布顺序和跨端矩阵成本，当前无证据表明它优于现有入口。

| 使用场景 | 入口 | SDK 要求 |
| --- | --- | --- |
| 纯视觉组件 | `@flare-im/vue-ui` 或 `components/...vue` | 构建时不要求安装 IM SDK |
| 设计 token / 主题 | `@flare-im/tokens`、`@flare-im/vue-ui/theme` | 无 SDK 运行时 |
| SDK 会话适配 | `@flare-im/vue-ui/composables/sdk` | 安装兼容的 `@flare-im/sdk` |
| 完整示例工作台 | `@flare-im/vue-ui/app` | SDK、路由与平台运行时 |
| 可选社交/通话 UI | 对应组件子路径 | 数据和 RTC 插件由宿主注入 |

纯 UI 消费通过真实 tarball + 独立 node_modules + 无 alias 的 Vite 构建验证，不代表所有 SDK 相关类型可在未安装 SDK 时被 TypeScript 使用。涉及 SDK DTO 的契约需要对应 SDK 类型依赖。RTC、支付等插件不随 UI 包隐式安装。

## 自动检查

- `node spec/validate.mjs`：契约与四端符号。
- `node spec/gen-readme-catalog.mjs --check`：生成目录。
- `node spec/build-im-coverage.mjs --check`：能力矩阵。
- `node scripts/check-kit-distribution.mjs`：版本、SPM 清单。
- `node scripts/check-package-exports.mjs`：打包内导出文件。
- `node scripts/check-optional-sdk-consumer.mjs`：独立安装且不安装 IM SDK 的 UI 构建。
- 工作区 `scripts/verify-published-kit.mjs`：Web/Tauri 真装包消费；临时去除 workspace TypeScript paths，启用 published 构建，结束恢复配置。
- CI site job：`check-im-browser.mjs` 统一执行七组交互回归，覆盖场景、通话、设备布局、传输、队列、搜索和时间线；320/1280、深浅色/大字号截图归档。截图目前供审查，不宣称已建立逐像素差异阈值。
- CI Android job：单测、编译及 API35 模拟器场景交互；Swift job：27 项当前单测与 iOS Simulator 目标编译。CI 配置已接入，本次证据来自相同命令的本地执行，尚未观察远程工作流运行。

## 本轮迁移

1. 危险操作改为宿主控制的 `DangerConfirm`：请求开始立即设置 busy；失败保持弹窗与原因；成功后由宿主关闭。当前账号与目标改变后旧确认不能继续提交。
2. `SearchPanel` 只管理提交条件；宿主仍须用请求序号与会话身份隔离响应。共享工作台已接入此保护。点击搜索结果会关闭搜索并定位到聊天记录；定位最多加载 48 页历史，切换会话/账号、离开页面或新定位会使旧操作失效，找不到时提供明确反馈。
3. 媒体 resolver 不永久保存签名 URL，只合并进行中的同一请求。SDK 负责有效期；失效后重新解析，不能复用旧地址。
4. `CallView` 新增 reconnecting / failed。原生调用方的穷举 switch 要补齐分支；`recoveryText` 与 `recover/onRecover` 由宿主接入 RTC 重试。Web `encrypted` 默认 false，只有经过提供方确认才能开启。
5. 场景列表使用稳定 ID；角色、设备权限和分页来自宿主。当前设备默认隐藏退出动作；不要把当前会话退出放入远程设备撤销流程。
6. `CapabilityBoundary` 的原生实现是状态边界；Vue 额外隔离子组件渲染异常。异步 SDK 异常仍由宿主捕获并更新状态。

本轮未发布新的 npm/Maven/SPM 版本。发布前须按版本策略统一变更，运行完整门禁，记录实际设备/RTC 验收结果；不能只打一个平台的标签。

## 原生 SDK 产物最低系统版本

UI 包最低 iOS16；Apple SDK 底层 FFI 最低 iOS15。core-sdk 的 `cargo xtask build ios-sim ios-device ios-universal` 固定 `IPHONEOS_DEPLOYMENT_TARGET=15.0`，并逐对象检查 archive 的 load command，拒绝任何最低系统版本较新的对象，不能用当前 Xcode SDK 版本代替最低部署版本。重新构建后在 client-sdk 运行 `make sync-ios sync-flutter` 更新示例产物。
