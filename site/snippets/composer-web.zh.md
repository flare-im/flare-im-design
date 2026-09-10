## Web 组件接入（本轮实现）

上方演示直接引用正式 `FlareComposer`，支持 PC / App、富文本、等宽表情 / @ / 语音面板，以及正常 / 离线 / 禁言状态切换。图片按钮直接打开本地文件选择器。

- `v-model` 保存草稿；`rich-mode` + `toggle-rich-mode` 控制富文本。
- `conversation-key` 在会话切换时清理录音与面板；`active-panel` + `toggle-panel` 控制表情 / 贴纸 / 更多。
- `media-panel` 插槽承载 `FlareComposerEmojiStickerPanel`，设置 `show-send-button=false`，统一使用输入组件发送入口。
- `read-only` 禁止编辑及发送；`send-blocked` 允许编辑但禁止发送；`status-hint` 显示宿主提供的本地化原因。
- `attach-actions` 支持自定义排序、图标、`disabled / disabledReason`。空数组表示没有功能；默认每页 8 项。
- `more-search-visible / more-title-visible / more-close-visible` 默认关闭，可按产品配置。
- `send-voice-handler` 接收试听后确认的录音；拒绝时保留预览供重试。语音发送保留文字草稿。

下方跨平台规格与平台无关；Vue 的实际接入属性以上述接口为准。

