# 插件成员选择与专属红包

共享 PluginPage、PluginView、PluginForm、AccountView 将同一组成员参数交给 ContactPicker。Kit 不调用 SDK，不猜群成员可见权限；名单只来自宿主通过当前账号和当前会话查询到的授权目录。

| 参数／事件 | Flutter、SwiftUI、Compose | 语义 |
|---|---|---|
| `members` | 既有成员模型数组 | 当前候选结果；远程搜索时是结果页，不是全群名单 |
| `membersLoading` | Bool／bool，默认 false | 查询进行中；选择器显示进度，不能新增选择 |
| `membersError` | 可选 String | 查询失败；显示错误与重试，不显示为空群 |
| `membersRevision` | Int／int，默认 0 | 权威成员、可见性或权限失效；只清成员选择和旧选择器，保留金额、祝福等其他草稿 |
| `memberSearch(query)` | `onMemberSearch(String)` | 打开选择器只请求一次空查询；后续查询编辑交给宿主 |
| `membersRetry` | `onMembersRetry()` | 宿主重试其当前查询 |

ContactPicker 本身使用 `loading`、`error`、`onSearch`、`onRetry`（Vue 为 search/retry 事件）。提供远程搜索回调后，返回结果不再按本地姓名或副标题二次过滤；SDK 可以按账号或其他允许的条件匹配成员。没有回调时维持原本的本地搜索。

宿主负责查询去抖和请求所有权：账号、路由会话或 query 改变后，旧结果不得写入新目录。群管理同样使用 Social SDK 的成员查询和可见范围。不要把首屏 50／200 条当作全群。Root 页面须按账号和会话身份隔离 Kit 草稿；不以普通搜索结果变化重建整个钱包流程。

服务端部分结果中没有已选人，不代表该人已退出群。已选成员保留原名字，直至用户显式清除或 `membersRevision` 改变；真正的成员/权限事件应增加 revision，而普通搜索响应不可增加。提交时后端重新权威校验成员资格，Kit 的可见选择不是长期授权。

专属红包只在权威 `presentation.props.conversationType="group"` 下提供。`single` 只提供普通红包且份数为 1，类型未知时表单不可提交。专属收件人复用 ContactPicker 单选，不允许手输 ID；既有 `members` 输入的标准输出仍为数组：`designatedUserIds: [userId]`。非专属为 `[]`，不保留旧标量 UI 字段。只允许从成功结果选择；取消保留原选择，清除后恢复必填状态。

支付确认的退出顺序也属于共享 UI 生命周期：确认先捕获一份内存凭据快照并清空输入，等自己支付面板真正退出后才派发一次动作。Flutter 等待该 route.completed；SwiftUI 在标准 sheet onDismiss 中消费 pending。取消、原页面被替换或离开时丢弃快照；不重试资金动作，不将凭据写入日志。成功后的聊天导航由收到可信 `data.posted` 的宿主负责；错误和未知结果继续保留原支付/恢复页面。
