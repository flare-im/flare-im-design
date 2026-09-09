---
title: NotificationPreferences 通知偏好
---

# NotificationPreferences 通知偏好

每项使用 id、title、detail、value、enabled、busy。组件只提交期望值；宿主同步设置 busy，成功后更新 value，失败后保留原值并展示错误。permission 不是 available 时所有开关禁用；请求权限与打开系统设置通过 permissionAction 回调，不能在渲染时自动申请。

<div class="flare-demo flare-demo--stack"><ScenePanelsDemo mode="NotificationPreferences" /></div>

<ComponentApi name="NotificationPreferences" />

## 接入与状态所有权

Vue 入口为 `FlareNotificationPreferences`，Flutter 为 `FlareNotificationPreferences`，SwiftUI 为 `NotificationPreferencesView`，Compose 为 `NotificationPreferences`。原生回调使用 on 前缀；Vue 事件用模板监听。

Vue `change` 携带 `{ id, value }`，`permissionAction` 无参数；原生回调是 onChange(id,value) / onPermissionAction。开关是受控值，宿主保存成功后更新快照，失败保留旧值并显示原因。permission 非 available、enabled=false 或 busy=true 都禁止提交。

## 布局与能力边界

每一项以完整标题和说明标识开关。长文本换行，开关不压缩；小屏由宿主提供纵向滚动。系统权限申请与打开设置由宿主接管，不在组件挂载时自动弹出。

控件至少 48 逻辑单位，长文案允许换行，危险操作同时使用明确文案与危险色。场景组合复用 StatusBanner 与共享列表布局；业务角色、操作权限、RTC、系统通知和文件授权仍属于 SDK/宿主。

本地演示不证明后台功能已接入。真机权限、读屏、键盘与真实 SDK 场景必须单独验收。
