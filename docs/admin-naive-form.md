# 管理表单、模态框与详情抽屉标准

Console通过`@flare-im/vue-ui/admin`复用`FlareAdminForm`，不再在每个CRUD页面复制标签布局。它实际渲染Naive `NForm`，没有自己的输入／校验／业务实现。

## 表单

- 默认`size="small"`、`label-placement="responsive"`：实际表单容器宽度至少520px时标签在左、宽128px；小于520px时标签在上。按容器而不是屏幕选择，适用于窄抽屉和页面。
- 套餐配额、公告时间网格和复杂规则编辑器显式`label-placement="top"`，避免将多列里的输入压缩到不可用。已有字段分组、校验和错误反馈保留。
- 长 JSON 默认值、ID 和校验反馈在字段内完整换行，不截断；反馈正文底部保留8px，避免紧贴后续字段。该规则也覆盖表单里组合的原生结构化编辑器，不修改字段值或业务校验。
- `disabled`转交Naive表单；`model`／`rules`／校验设置、class／style／可访问属性和原生submit监听直接透传；组件不添加提交、确认、重试或权限判断。实际Naive实例可通过暴露的`form`访问。
- ResizeObserver只改变标签展示；不克隆model、不重挂载字段、不创建业务状态；卸载时断开观察器。宿主仍须保留原签名／范围／权限／写锁及未知结果核对流程。

```vue
<FlareAdminForm :disabled="editorLocked" @submit.prevent="save">
  <n-form-item label="名称" path="name">
    <n-input v-model:value="form.name" :input-props="{ 'aria-label': '名称' }" />
  </n-form-item>
</FlareAdminForm>
```

## 容器选择（2026-10-17最新裁定）

| 场景 | 共享容器 |
| --- | --- |
| 独立新增、编辑、配置、角色／权限分配 | `FlareAdminModal`（真实Naive `NModal`＋`NCard`） |
| 用户／群详情、多页签浏览、历史、凭据详情、接入指南 | `FlareDrawer` |
| 持久危险操作确认 | 既有`FlareAdminPopconfirm`与业务确认控制器，不另建每页弹窗 |
| 页面查询、页面内配置 | 保留共享查询／配置框架，不为每个输入再开模态框 |

模态框不占整屏空白。短表单按内容居中；长表单限制视口高度，标题／底部操作不随正文滚走。宽度由宿主选择（默认560px），手机左右各至少12px，最大高度保留上下边距，正文可纵向滚动。控件与操作仍使用Naive small、32px／8px；标签依实际布局宽度在桌面同行／手机上下切换，不以进入动画缩放后的矩形宽度判断。

`FlareAdminModal`只接`open`／`title`／`width`／`dismissible`／`showClose`，以及正文、`actions`、`footer`插槽；只发`close`，不拥有model或提交。原校验、权限、请求世代、保存锁与未知结果仍由宿主控制。Native负责遮罩／动画／Card呈现，复用Kit已有浮层栈统一焦点、Tab、Escape、滚动锁及平台返回，因此不并行启用两个焦点陷阱。嵌套编辑只关闭上层；原生日期与Popconfirm仍可先消费Escape。

## 详情抽屉

沿用Kit `FlareDrawer`的模态栈、键盘、焦点、关闭保护及安全区，不在业务页新增另一套NDrawer。正文左右内边距由抽屉唯一提供，删除各页内容wrapper的第二层padding。只有真正全幅工作区才显式退出共享内边距。

模态框和详情抽屉的操作仍放`#footer`，与滚动正文分离。Console抽屉显式compact底栏，其他通信客户端继续原默认触控规格。原取消／保存／授权／写入未知的disabled和loading表达式不由组件猜测或替换；`dismissible`仍由业务pending状态决定。

## 采用与边界

当前Console共22文件27处共享表单声明保持；最新21文件的26个独立编辑入口采用Modal（24静态＋通知／JIT两个按模式选择），12个静态详情入口保留抽屉，通知预览／JIT详情也保留抽屉。用户专属策略是配置任务，连同其上下文列表采用Modal；不把用户或群详情改为模态框。Media原确认请求不变。

个人资料使用共享配置工作区的四个页签并保留草稿，资料／PAT操作固定底栏；工作与运营概览只统一范围工具栏／页面外框，原指标／图表和业务读控制器不改。不是将所有卡片、详情、认证入口或其他平台UI一律改成同一表单。未触及Vue以外原生Kit或Core／SDK业务边界。
