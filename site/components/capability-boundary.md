---
title: CapabilityBoundary 可选能力边界
---

# CapabilityBoundary 可选能力边界

state 为 loading/available/unavailable/denied/failed。只有 available 渲染可选内容，其余状态显示原因和宿主恢复入口。Web 捕获子组件渲染错误、阻止向父组件传播，显式 resetKey 才重新挂载。原生组件负责状态隔离，不捕获任意进程崩溃或 Swift fatalError；SDK 插件异常应在适配器映射为 failed。不要把基础聊天放在可选能力边界内。

<div class="flare-demo flare-demo--stack"><ScenePanelsDemo mode="CapabilityBoundary" /></div>

<ComponentApi name="CapabilityBoundary" />

## 接入与状态所有权

Vue 入口为 `FlareCapabilityBoundary`，Flutter 为 `FlareCapabilityBoundary`，SwiftUI 为 `CapabilityBoundaryView`，Compose 为 `CapabilityBoundary`。原生回调使用 on 前缀；Vue 事件用模板监听。

Vue 的 `action` 事件无参数，`error` 事件携带捕获的子组件异常；宿主收到 error 后更新说明文案。恢复成功后更新 resetKey 以重新挂载插件。原生通过 onAction 交给宿主恢复，其 state 必须反映真实能力，不捕获进程级异常。

## 布局与能力边界

available 才呈现插件内容，其余状态展示 StatusBanner；首次加载同时提供进度语义。宿主为实际插件视图提供有界布局，核心聊天放在边界之外。

控件至少 48 逻辑单位，长文案允许换行，危险操作同时使用明确文案与危险色。场景组合复用 StatusBanner 与共享列表布局；业务角色、操作权限、RTC、系统通知和文件授权仍属于 SDK/宿主。

本地演示不证明后台功能已接入。真机权限、读屏、键盘与真实 SDK 场景必须单独验收。
