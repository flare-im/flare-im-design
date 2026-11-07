# 管理端单行查询与抽屉留白

## 查询区

Naive UI业务列表的组合打样现见[标准列表规范](admin-naive-list.md)。两种呈现共享`useFirstRowCollapse`测量行为，既有消费者不批量改动。

共享 Vue `FlareFilterBar` 的 `collapseOverflow` 模式适用于高频列表：把重要条件按顺序放入默认插槽，低频条件随后；宿主拥有字段值、查询、分页和权限。

- 根据容器内真实字段行位置测量，不用字段个数或屏幕断点猜测是否溢出。默认只展示第一行，第二行起折叠；全部容纳在一行时不显示展开按钮。
- 查询／重置／展开的操作区独立；小容器将操作移至下一行，查询字段仍只显示一行。展开键保留小块占位但不可见／不可聚焦，避免显示它本身引起折叠状态振荡。
- 每个字段只挂载一次。折叠通过布局裁剪、visibility、inert和aria-hidden共同处理，值不丢失，隐藏条件仍参与宿主已提交的查询；宿主的重置应清除全部条件。
- 宽度变化会重新测量；如果当前键盘焦点落在将被折叠的字段上，保持展开，不能把焦点困在隐藏区。
- `size="sm"`用于紧凑后台，`disabled`用于宿主写入锁。Enter只处理单行输入，尊重IME、已处理按键、展开的组合框和多行文本；加载中不重复查询。
- `expandText`／`collapseText`可使用宿主词汇。没有开启自动模式的既有`more`插槽仍按原显式展开方式工作，不宣称所有消费端已经改版。

示例组合：

```vue
<FlareFilterBar collapse-overflow size="sm" :loading="loading" :disabled="writing"
  expand-text="展开" collapse-text="收起" @search="search" @reset="reset">
  <FlareFormField label="应用"><ApplicationControl /></FlareFormField>
  <FlareFormField label="用户 ID"><UserIdControl /></FlareFormField>
  <FlareFormField label="展示名"><DisplayNameControl /></FlareFormField>
  <FlareFormField label="状态"><StatusControl /></FlareFormField>
</FlareFilterBar>
```

字段业务含义和AND／OR、大小写、精确／子串匹配由实际API契约定义，不能将多个表单框拼回同一个歧义关键词或只过滤当前页。

## 抽屉

最新容器选择见[管理表单／模态框规范](admin-naive-form.md)：独立新增／编辑使用共享Naive Modal，用户／群等详情继续用抽屉。`FlareDrawer`默认`contentPadding="normal"`，内容区使用共享spacing token提供左右和上下留白，与标题／页脚对齐；底部安全区保留。

确需全出血工作区的宿主显式传`content-padding="none"`，自行组合既有页面组件；不在业务应用覆盖`.flare-drawer__body`内部样式。只有视觉留白变化，不改变关闭／保存锁、焦点陷阱、权限或回退语义。

详情／编辑面内的共享列表列设置，第一次Escape只关闭已打开的列设置并将焦点保留在触发按钮；焦点在触发按钮或传送后的选项内容均相同。列设置关闭后，下一次Escape才交给宿主Drawer／Modal。不要为列表另外注册全局Escape监听或在关闭状态无条件吞键。

本轮实际打样为Social Console“IM用户”，其他列表仍按已有模式。Web的共享能力不代表Flutter、SwiftUI或Compose管理页面已完成同样改版；跨平台跟进应保留同一语义，而不是复制CSS。

控制台的关系树使用 `FlareAdminRelationshipTree`。宿主传入带稳定 ID 的有限节点树和可选的 `details` 插槽。组件按层绘制曲线，宽图可横向滚动。详情节点支持鼠标悬停、键盘聚焦或触屏点按。节点权限和详情数据由宿主提供。
