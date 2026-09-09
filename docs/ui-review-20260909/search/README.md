# SearchPanel 与时间线验收 · 2026-09-09

## 本批验证

- Vue 190 单元测试、173 SFC 编译、TypeScript 检查通过。
- Flutter 125 测试通过；包含时间线前插/并发追加/上方编辑的位置保持、分页防重、失败重试、搜索旧条件隐藏、Unicode 高亮与 320 宽/200% 字号。
- Swift 26 测试、iOS 16 模拟器目标编译通过。
- Android 示例 Kotlin 编译与组件单元测试通过；新增 Unicode 原文索引回归。
- 文档站构建、113 组件契约、14 领域覆盖矩阵校验通过。
- Web 时间线交互验证：前插+追加保持可见行偏移，分页请求防重，失败手动重试，切换会话取消旧恢复。
- Web 搜索交互验证：320/390/1280 × 深浅色六组；旧筛选结果隐藏、明确重试、Unicode 高亮、按钮至少 48px、容器无横向溢出。检查数据见 checks.json，截图为放大控件文案后的最终状态。

## 复现

```sh
node scripts/check-search-panel-browser.mjs http://127.0.0.1:5189 ../flare-im-core-client-sdk/examples/flare-core-web-app/package.json
node scripts/check-timeline-recovery-browser.mjs http://127.0.0.1:5189 ../flare-im-core-client-sdk/examples/flare-core-web-app/package.json
```

## 验收边界

SearchPanel 实验室使用本地快照，不证明 SDK 或服务器已完成类型过滤。没有重新部署示例应用。Android/iOS 真机键盘、旋转、读屏、原生列表精确滚动偏移尚未验收；原生编译通过不能替代这些检查。Web 文案放大检查也不等同于浏览器全页缩放或 OS 字体放大。完整 P0/P1 仍有后续组件和 SDK 往返场景。
