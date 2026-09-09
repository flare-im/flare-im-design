---
title: CallDevicePicker
---

# CallDevicePicker

RTC 设备选择器：按 microphone / speaker / camera 分组，宿主提供设备 ID、标签、已确认的 selectedId 和 busy。没有权限或没有可选设备时禁用。设备消失时显示占位，不自动改用另一台设备；空 ID 和重复 ID 被过滤。

<div class="flare-demo flare-demo--stack"><CallDevicePickerDemo /></div>

<ComponentApi name="CallDevicePicker" />

## 状态与事件

Vue select 发出 `{ kind, deviceId }`；Flutter/Swift/Compose 使用 onSelect(kind,deviceId)。回调之前不会改变已确认值；宿主开始切换时同步设 busy，成功后更新 selectedId，失败保留旧值并显示原因。切换结果必须与当前账号、通话和请求序号一致。

permissionAction/onPermissionAction 不带参数，由宿主申请权限或打开设置。组件不在挂载时访问硬件，也不启动 RTC 引擎。

## 四端数据类型

Vue 使用 CallDeviceGroup / CallDeviceKind / CallDevice；原生对应 FlareCallDeviceGroup / FlareCallDeviceKind / FlareCallDevice。Vue/Flutter/Swift 枚举值为 microphone / speaker / camera，Compose 为 Microphone / Speaker / Camera。每个 kind 只传一个分组；每台设备 ID 来自 RTC 枚举，不能用翻译后的名称当 ID。

Swift 入口 CallDevicePickerView，Compose 入口 CallDevicePicker，Vue/Flutter 入口 FlareCallDevicePicker。原生由宿主提供纵向滚动区域；每个选择操作至少 48 逻辑单位。RTL 使用逻辑方向布局；设备标签允许本地化。

## 屏幕共享边界

屏幕共享不是摄像头设备选择。宿主使用独立的开始/停止共享操作与系统选择器；只有用户确认系统共享授权且 RTC 发布轨道成功后才显示“共享中”。拒绝或取消保留当前通话；结束共享只停止共享轨道，不关闭麦克风和主会话。使用 CapabilityBoundary 展示不支持/权限拒绝/失败，并始终保留挂断。

本示例只验证交互契约，真实设备切换、权限和屏幕共享需要接入 RTC 插件后验证。
