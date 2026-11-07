# 原生私有图片预览组合

适用Flutter、Compose与SwiftUI。Kit只负责图片区域、状态、触控及全屏查看，不读取SDK、不申请授权、不持有短时链接，也不写文件。

## 上传槽的独立查看意图

三个平台的图片上传槽新增可选`previewLabel`、`previewLoading`、`previewDisabled`和`onPreview`。仅uploaded且非空previewLabel进入只读查看模式；默认无此属性时保持原uploaded不可交互。上传disabled仅控制上传/选择，查看由previewDisabled独立控制。previewLoading显示进度并阻止重复意图，读屏使用共享loading与host状态文案。上传/重试回调不会在只读查看时被调用，Kit不创造移除或替换动作。

## 私有内容

Flutter的ImagePreview已有imageBuilder，Compose已有image内容插槽；SwiftUI ImagePreviewView新增可选AnyView imageContent，让host传入受控内存图像，同时保留Kit缩放、关闭、键盘/无障碍和gallery控制。不为此把受限URL转公开源或临时写入磁盘。

Host应使用SDK规范方法取得经过校验的内容，只在可见且已授权的资料页保留受限尺寸解码结果。下载授权到期不会隐藏已经成功读取的图片；离页、切换记录、失权或切后台仍立即释放并关闭查看器。读取时已过期或失败才由用户显式重读，不自动续租。避免标准图片全局缓存跨会话持有证件内容。服务授权、网络取图、MIME/大小/摘要校验及nonce重放语义归SDK，不进Kit或业务页。

本文对应能力当前处于源实现/待构建验收，不能作为GUI验证通过记录。

Flutter另提供FlarePrivateMemoryImage：host传入内存bytes与最大像素边，组件保比例限制codec目标尺寸，不经ImageProvider/ImageCache，替换或卸载释放自有ui.Image；source bytes与可见页面生命周期由host控制，下载授权仍由SDK控制。组件本身不读取服务端数据。新增交互/释放widget测试已通过；该结果不代替真实服务与原生GUI验收。

最终SDK为单次grant，未知结果nonce重放不延长租约；显式重试是新intent，不做自动重租。状态-only事件只更新资料，不清合法照片缓存；图片请求以owner/app/materialId+sha/ready指纹和可见性控制，防止状态流量冲读图限额。
