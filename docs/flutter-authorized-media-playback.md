# Flutter：经 SDK 授权的本地媒体播放

`FlareAudioContent.localPath`、`FlareVideoContent.localPath` 和播放器的同名参数只接收宿主通过 SDK 媒体访问契约返回的绝对缓存路径。不要从收到的消息 URL、附件名或用户输入构造它们。消息中的 `file:`／`content:` URL 仍被拒绝。

宿主先以真实会话和消息序号调用 SDK 的媒体访问入口。SDK 完成可见性授权后才读取或填充缓存；Kit 只根据显式 `localPath` 使用原生文件播放器，不执行权限判断、下载或租户业务规则。Web 不支持原生文件播放器，继续使用合法 HTTP(S) 来源。

Core SDK 缓存对已知音视频 MIME 使用固定格式扩展名，以便 AVFoundation 识别；不使用发送方文件名。已有无扩展名缓存仅由 SDK 规范化并更新其缓存索引，原上传、消息和用户下载文件不移动。不能用系统信任修改或关闭 TLS 校验替代这条访问链。

可解码／进入播放状态不代表全编码格式、拖动、后台或播放完成生命周期均已验收。
