# 跨端组件签名对齐 · 2026-11-16

在 `dev` 处理前次规格检查记录的 24 项差异，优先验证 Web，未修改校验器或放宽基线。

| 组件 | 原差异数 | 最终约定 |
| --- | ---: | --- |
| InviteCodeField | 3 | `scannable` 是 Vue 的扫码开关；原生端以 `onScan` 是否存在决定入口，明确平台范围，不增加无行为参数。 |
| AccountView | 6 | Vue 声明 `memberSearch`、`membersRetry` 事件；四端已有的 `fileAction` / `onFileAction` 补入规格；补齐 `fileStates` 的宿主状态契约。 |
| ContactPicker | 2 | Vue 使用 `search`、`retry` 事件；无监听器时保留本地筛选，不凭空提供服务重试。 |
| Flutter FileUpload | 13 | 补齐受控状态、文案与上传意图；DOM `File`、accept、URL 和 picker 参数限定 Vue，Flutter 仍委托宿主选择本地文件。 |

Flutter FileUpload 的状态文本由宿主提供；`image` 控制本地 Widget 预览，`previewLabel` 明确声明私密预览操作。
上传、替换、重试、取消、删除仅在对应状态且提供文案时出现；没有处理器或禁用时不触发操作。
插件表单已迁移，保留原 scope / generation 及过期回执失效规则，不在组件内上传或获取私密 URL。

同时修复两个行为问题：

- Vue 联系人多选保存已选条目，远程结果翻页后仍完整提交，直到用户明确移除或父级使选择失效。
- Flutter 账户详情将路由间通知合并到帧结束，避免在宿主构建期间通知详情页；卸载后不访问 notifier。

验证覆盖实际事件负载、远程分页保留选择、无监听器能力、文件状态、禁止隐式上传，以及账户详情更新与关闭。
规格验证结果为 **24 → 0**，198 个组件通过四平台符号检查。此次没有运行 iOS / Android 设备测试。
