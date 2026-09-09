---
title: MediaCenter 文件与媒体
---

# MediaCenter 文件与媒体

MediaEntry 增加 kind(image/video/audio/file) 和 availability(available/expired/unavailable)。过期或不可用条目隐藏 id=open 的操作，保留宿主明确提供的 refresh/download 等恢复入口；没有 SDK 能力就不要传标签。可选 transfers 组合现有 TransferQueue。媒体预览需要宿主先取有效授权地址，禁止无限重试过期 URL。

<div class="flare-demo flare-demo--stack"><ScenePanelsDemo mode="MediaCenter" /></div>

<ComponentApi name="MediaCenter" />

## 接入与状态所有权

Vue 入口为 `FlareMediaCenter`，Flutter 为 `FlareMediaCenter`，SwiftUI 为 `MediaCenterView`，Compose 为 `MediaCenter`。原生回调使用 on 前缀；Vue 事件用模板监听。

所有数据来自宿主快照，组件不请求网络、不读取设备会话或修改权限。列表动作通过 `action(id, action)` 返回稳定对象 ID 和操作 ID（Vue 为一个对象参数）。宿主必须在异步请求前同步设置 busy，并按对象独立处理部分失败；切换账号时清理订阅与旧响应。

## 布局与能力边界

列表使用有界数据窗口，推荐不超过 50 项；长历史和远程检索通过宿主分页。原生场景内容由宿主 ScrollView/SingleChildScrollView/verticalScroll 承载，MediaCenter 内的任务队列已有独立有界高度。不得把全量成员或媒体历史一次传入。

控件至少 48 逻辑单位，长文案允许换行，危险操作同时使用明确文案与危险色。场景组合复用 StatusBanner 与共享列表布局；业务角色、操作权限、RTC、系统通知和文件授权仍属于 SDK/宿主。

本地演示不证明后台功能已接入。真机权限、读屏、键盘与真实 SDK 场景必须单独验收。
