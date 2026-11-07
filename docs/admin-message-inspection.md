# 管理端消息正文与附件

Vue 管理端公开入口 `@flare-im/vue-ui/admin` 提供 `FlareAdminMessageBody`、
`FlareAdminAttachmentPreview`、`FlareAdminAttachment` 和
`downloadAuthorizedAttachment`。它们是 Naive UI 的通用展示组合，不持有
SDK、业务权限、租户或文件授权逻辑；不改变 Flutter／其他原生 Kit。

`FlareAdminMessageBody` 接收纯文本、类型化附件元数据、`available/recalled/unavailable`
状态及宿主翻译。纯文本插值，不使用 HTML；隐藏状态不渲染正文或附件按钮。
`compact` 截为三行，服务端摘要被裁剪时通过 `truncated` 显示完整正文入口。
附件只发出 `preview(id)`／`download(id)` 意图，不从消息里的 URL 自动加载资源。
名称换行，按钮 small，间距使用 tokens。

宿主收到意图后必须重新检查当前权限、应用与消息，并向权威服务按需解析短时地址。
`FlareAdminAttachmentPreview` 用 NModal／NCard／NImage 及原生 video/audio 展示；
不自动播放、不嵌套第二个图片弹层。它提供加载、失败和关闭／下载入口；
关闭时立即卸载媒体，原生加载失败显示宿主提供的 `failedText`。
组件自身不申请或保存 URL，也不决定哪种业务身份有权访问。

`downloadAuthorizedAttachment(url, name, signal, isCurrent)` 只接受无凭据、无 fragment
的 HTTPS 地址，省略 Cookie，拒绝重定向与超过128MiB的响应，不在失败时降级为导航。
下载过程中持续检查 AbortSignal 和宿主代次，在点击保存之前再次检查；文件名去路径及
危险字符。宿主切换身份／范围、撤权、销毁或取消时必须 abort 并清空预览地址。
浏览器不能解码的媒体仍可在授权有效时下载原文件；不能把视频元数据加载当作完整播放验收。

相关验证：真实 Naive UI 的正文、XSS转义、隐藏态、媒体错误与关闭卸载；下载工具的
协议／凭据拒绝、CORS失败不导航、取消／范围切换、精确字节和超限取消。
Console 负责独立测试范围隔离、迟到响应、权限撤回与真实服务读链。
