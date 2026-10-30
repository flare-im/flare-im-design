# 管理后台用户身份

`@flare-im/vue-ui/admin` 提供 `FlareUserIdentity`。它仅接收展示数据，不读取服务、角色或租户状态。

## 用户身份

`FlareUserIdentity` 的 `user` 接收 `name`、`account`、`avatarUrl` 和可选 `state`（ready/loading/unavailable）。复用 FlareAvatar，加载失败保留首字头像；loading/unavailable 显示中性头像，不取提示文字的首字。昵称与账号完整换行；组件不接收也不会生成内部 ID。loading/unavailable 不显示旧身份资料。宿主负责作用域、真实查询、最小字段投影和失效处理。

插件行单元格 `FlarePluginRowCell.user` 与详情字段 `FlarePluginField.user` 可附加同一展示值。通用插件表格完整展示并换行；小屏在表格容器内横向滚动。宿主仅在展示副本附加 user，原始行操作 input 和详情 previous 不携带这些展示字段。

Console 的钱包/红包页面由 Platform 按已授权页面的可见行与规范 userId/senderId/receiverId/recipientId 引用补充 `userSummaries`。每页最多 100 个引用、并发 5、总超时 3 秒；Social 公共适配器按应用读取。只返回昵称、一个账号和头像；不返回邮箱/手机号字段、会话或其他资料。账号优先用户名，其次一个已配置登录账号，过滤与内部 user_id 相同的值。缺失或失败引用为 null，业务数据仍可查看。宿主更换用户、应用或插件时清空展示缓存，晚到数据不得填入新作用域。

仅 Vue 设计库提供该组件；原生客户端没有插件管理后台入口，SwiftUI、Compose、Flutter 没有对应实现。
