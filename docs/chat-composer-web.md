# 聊天输入组件 · Web 实现契约

实现：`packages/vue-im-ui/src/components/composer/EnhancedComposer.vue`（公共导出 `FlareComposer`）。
样式随组件加载：`composer-studio.css`。Web 示例 ChatView 已接入；Android/iOS/Flutter 原生组件未在本次修改。

## 视觉与布局

沿用 Flare 主题 token，白色表面、灰色描边、紫色活动图标。主工具图标 20px；桌面按钮宽 32px，触屏按钮 44px。选中仅变色，键盘焦点保留轮廓。

桌面（900px 起）：短文本与右侧工具同一行；多行及展开时工具靠右下。输入组件自身宽度不足 460px 时工具换行。富文本在正文上方，28px 高、14px 图标，所有格式直接横向滚动，无更多菜单；触摸设备保留 44px 点击区域。正文保留内部滚动，隐藏视觉滚动条。

表情/贴纸、@、语音和更多使用统一面板外壳。桌面位于输入框正上方，等宽对齐，不增加底部输入区占用高度；窄屏在输入工具下方展开。面板高度受视口限制。更多打开时隐藏正文及富文本工具，非空草稿以单行入口保留，点击恢复原编辑状态。

## 接入

```vue
<FlareComposer
  v-model="draft"
  :conversation-key="conversationId"
  :active-panel="panel"
  :rich-mode="rich"
  :read-only="cannotEdit"
  :send-blocked="cannotSendTemporarily"
  :status-hint="localizedReason"
  :actions="configuredActions"
  :send-voice-handler="sendVoice"
  @toggle-panel="panel = $event"
  @toggle-rich-mode="rich = $event"
  @send="sendText"
  @build="openAction"
>
  <template #media-panel>
    <FlareEmojiStickerPicker
      :active-tab="panel === 'sticker' ? 'sticker' : 'emoji'"
      :show-send-button="false"
      :disabled="cannotSendTemporarily || cannotEdit"
      @insert-emoji="insertEmojiAtSelection"
      @send-sticker="sendSticker"
      @update:active-tab="panel = $event"
    />
  </template>
</FlareComposer>
```

组件沿用受控草稿、现有 markdown 编辑器及 `send/build` 事件；宿主仍负责 SDK、持久化草稿、附件上传和发送失败恢复。图片入口发出 `build('image')`，Web 宿主直接打开原生文件选择器，再进入现有附件预览/上传链路。

## 可扩展配置

- `actions: undefined` 使用图片、文件、语音、位置、联系人默认项；`[]` 明确表示空列表。宿主数组决定排序和可见性，每页 8 项。`id/label/icon/enabled/disabledReason/intent` 支持自定义功能、能力限制及本地化提示。
- `moreSearchVisible / moreTitleVisible / moreCloseVisible` 默认 false，各自独立控制。关闭搜索配置时同时清理过滤词。
- 面板互斥；点外部或 Escape 关闭面板，下一次 Escape 收起展开编辑器。文字内容保持。
- `conversationKey` 改变时取消待授权/进行中的录音、清理录音预览并关闭临时面板，防止跨会话误发。

## 受限状态映射

| 场景 | 属性 | 行为 |
| --- | --- | --- |
| 未选会话/不可用 | disabled | 禁止编辑和发送 |
| 禁言、全员禁言、移出群、只读会话 | readOnly + statusHint | 保留草稿，禁止编辑和发送，展示原因 |
| 离线、重连、慢速模式等待 | sendBlocked + statusHint | 允许编辑草稿，禁止发送 |
| 发送中 | sending | 防止重复提交，允许继续编辑 |
| 某个功能无权限 | action.disabled + disabledReason | 仅限制该功能 |
| 麦克风不可用 | 运行时错误提示 | 不影响文字编辑 |

状态由宿主真实权限和连接数据提供，组件不猜测禁言权限。本次 Web 应用接入已有连接状态；群禁言等状态通过 readOnly/statusHint 契约供后续真实群权限数据接入。

## 录音

点击麦克风打开面板，开始/停止、试听、删除、明确发送。最长 65 秒；短于 250ms 不发送。关闭时取消正在录制的内容；已完成试听内容在同会话面板切换中保留。取消待授权请求后若系统才返回媒体流，立即停止其轨道。卸载释放流、计时器和对象 URL。`sendVoiceHandler` 拒绝时保留预览供重试；SDK 接受后的投递失败继续由消息气泡处理。发送语音保留文字草稿。

## 验收入口

启动 `flare-core-web-app` 的 `npm run dev:web`，打开 `/composer-preview.html`。页面直接引用正式组件，提供正常/离线/禁言、可选搜索和空功能配置；为独立开发入口，不进入生产路由、不发送真实消息。

验证：共享 UI 类型检查、187 个 SFC 编译、输入组件与提及共 12 项测试；Web 生产构建及 800KiB chunk 预算。浏览器检查桌面面板等宽、390px 窄屏、@ 插入、草稿恢复、禁言禁用和原生图片选择器。真实会话端到端发送需登录账号；真实麦克风设备录音需在目标浏览器验收。
