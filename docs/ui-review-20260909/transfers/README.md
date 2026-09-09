# IM 组件系统：传输与恢复验收

日期：2026-09-09。对应 `docs/IM-COMPONENT-SYSTEM.md` 的第一批实现。

## 自动验证

| 检查 | 结果 |
|---|---|
| Vue 测试 | 190 项通过 |
| Vue TypeScript / SFC | 类型检查通过；172 个 SFC 编译通过 |
| Flutter 测试 | 121 项通过，含 15 项新增传输/状态提示验证 |
| Flutter 静态分析 | 修改组件及新增测试无问题 |
| Swift 测试 | 26 项通过 |
| Android 测试 | 12 项通过 |
| 原生构建 | Android 示例 Kotlin 编译、iOS 模拟器 arm64 编译通过 |
| 文档站 | 生产构建通过；保留既有大 chunk 提示 |
| 契约与覆盖矩阵 | 112 项组件校验通过；14 个场景引用校验通过 |
| 文档目录 | 从 spec 生成并通过漂移检查 |
| Chromium 交互 | 320 / 390 / 1280 × 深浅色 × 六种状态通过 |

浏览器验证包括操作集合、点击事件、busy 防重复、未知进度与零进度区别、48 触控尺寸以及小屏组件边界。详见 `transfer-browser-check.json` 和同目录六张截图。

复现：启动文档站后，从仓根执行：

```sh
node scripts/check-transfer-ui-browser.mjs http://127.0.0.1:5189 /absolute/path/to/consumer/package.json docs/ui-review-20260909/transfers
```

消费项目需已安装 `@playwright/test`。此测试不连接业务服务器、不上传文件。

Flutter 大字号用例为 320 逻辑宽度 × 1/2 倍字体，状态提示还验证减少动画时能稳定停帧。

## 验证范围

这些结果证明组件展示、状态映射与受测交互通过，不证明真实上传/下载、断点续传或全部手机兼容。传输后台与文件打开由宿主 SDK 负责；真机键盘、读屏、权限、旋转和后台恢复按跨设备矩阵单独验收。
