---
title: DangerConfirm 危险操作确认
---

# DangerConfirm 危险操作确认

显示 title、description、target；宿主绑定稳定操作 ID，禁止仅凭展示文案决定删除对象。busy 时确认/取消禁用；失败后设置 error、busy=false，保留界面。取消只关闭界面，不提交操作；确认回调后也不自动关闭，只有宿主确认成功才关闭。Vue 内置 NModal；Compose 调用即显示 AlertDialog；Flutter 放在 showDialog 内并设置 barrierDismissible=false；SwiftUI 放入 sheet。

<div class="flare-demo flare-demo--stack"><ScenePanelsDemo mode="DangerConfirm" /></div>

<ComponentApi name="DangerConfirm" />

## 接入与状态所有权

Vue 入口为 `FlareDangerConfirm`，Flutter 为 `FlareDangerConfirm`，SwiftUI 为 `DangerConfirmView`，Compose 为 `DangerConfirm`。原生回调使用 on 前缀；Vue 事件用模板监听。

Vue 发出无参数的 `confirm` / `cancel`；原生使用 `onConfirm` / `onCancel`。组件不携带服务端目标 ID，宿主应在打开时捕获账号、目标 ID 和操作，并在提交前检查它们仍有效。busy 期间关闭和重复提交被阻止，失败后由宿主更新 error。

## 布局与能力边界

Vue/Compose 使用弹窗，Flutter/SwiftUI 由宿主展示模态容器。长描述可滚动，取消与确认按钮保持可达；不要再套列表容器或依赖横向滚动。

控件至少 48 逻辑单位，长文案允许换行，危险操作同时使用明确文案与危险色。场景组合复用 StatusBanner 与共享列表布局；业务角色、操作权限、RTC、系统通知和文件授权仍属于 SDK/宿主。

本地演示不证明后台功能已接入。真机权限、读屏、键盘与真实 SDK 场景必须单独验收。
