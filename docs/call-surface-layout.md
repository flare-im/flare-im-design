# 通话布局与设备浮层

Web 与 Flutter 的 CallSurface 使用共享 Modal 的 edgeToEdge 模式。只有内容自行绘制表面的场景使用该属性：移除通用浅色内边距、边线和背景，保留圆角裁切、遮罩、焦点与退出语义，其他通用弹窗不变。

单聊 CallView 分为顶部名称/状态、可伸缩媒体舞台、底部操作栏。画中画占顶部尾端，标题预留其宽度；媒体上增加上下渐变以维持文字对比。群通话继续使用顶部群信息、中间网格、底部操作栏。

设备浮层由组件库拥有；插件只映射设备、权限、选中值和切换回调。

- Vue：CallControls 接收 devices 插槽；CallView / GroupCallView 透传。扬声器触发上方 Popover，CallDevicePicker 直接显示设备名与选中标记；不嵌套 Select。Escape 收起并返回触发按钮焦点。
- Flutter：CallControls 的 onPickDevices 提供实际按钮 BuildContext；单聊/群聊视图透传。插件将锚点交给 FlareCallDevicePicker.showAnchored，组件库处理定位、暗色面、滚动、外部点击和键盘退出。手机扬声器/听筒切换保留平台行为。
- 设备列表去重，禁用和切换中不可选择；空/加载/权限失败保留状态信息。长列表在可用高度内滚动，窄屏留出窗口边距。

本轮覆盖 Vue 与 Flutter 组件及 Social 插件引用。已检查 SwiftUI / Compose 对应组件；它们仍有独立实现，此次未迁移其宿主弹出策略，也未声明跨全部平台视觉已统一。
