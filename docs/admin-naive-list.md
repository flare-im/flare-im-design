# Naive UI 标准业务列表

`FlareAdminList`从`@flare-im/vue-ui/admin`导出，是控制台的标准列表页面框架。它组合真实Naive UI组件，不承接业务请求、鉴权、统计或数据切片。当前控制台28个文件、38处组件声明（41个逻辑列表）已采用，包括菜单主列表和抽屉列表；应用的`ListPage`仅负责翻译与插槽适配，没有第二套布局CSS。卡片、仪表盘、资料描述和业务编辑表单不伪装成数据表格。

## 布局规范

1. 页名沿用工作台面包屑；不在列表中重复标题、普通小字说明或统计。
2. 查询使用`NForm`与`NFormItem`，主条件在前。桌面短标签与控件同行，窄容器下自动改为上下排列。
3. 根据字段真实位置折叠第一行之后的条件；全部同排时隐藏展开。字段只挂载一次，收起保留值，隐藏项同时`inert`／`aria-hidden`／不可见；缩窄时不隐藏当前焦点。
4. 单一工具栏：左侧业务主操作／批量操作，右侧`tools`插槽及列设置。窄屏允许自然换行，不将设置单独占据一条空栏。
5. `NDataTable`负责表格，`NCheckbox`负责有明确名称的受控选择，`NPopover`负责列显隐。主标识、状态与操作列是否可隐藏由宿主`hideable`配置，至少保留一列。
6. 底栏左侧条数范围，右侧标准Naive分页。已知总数使用`NPagination`；未知总数只用Naive上一页／当前页／下一页，不估算末页；已加载快照显式`totalKind: 'loaded'`，文案不冒充服务端全量总数。窄屏紧凑显示，长表格仅在表格区域横向滚动。
7. 颜色直接取宿主Naive UI主题，间距沿用Kit令牌；不添加第二套品牌／字体或统计卡片。

## 组合示例

```vue
<FlareAdminList
  label="用户"
  :rows="page.items"
  :columns="columns"
  row-key="user_id"
  :pagination="paging"
  :loading="loading"
  :disabled="writing"
  :error="error"
  :selectable="canBatch"
  v-model:checked-row-keys="checked"
  v-model:visible-column-keys="visibleColumns"
  @search="search"
  @reset="reset"
  @update:pagination="paginate"
>
  <template #filters>
    <n-form-item label="用户 ID"><n-input v-model:value="filters.user_id" :input-props="{ 'aria-label': '用户 ID' }" /></n-form-item>
  </template>
  <template #actions><n-button v-if="canCreate" @click="create">创建用户</n-button></template>
  <template #empty><n-empty :description="emptyText" /></template>
</FlareAdminList>
```

宿主负责服务端分页与AND筛选、长ID字符串、应用上下文／权限复核、确认和写锁、翻页／查询后的本页选择清空及未知写入结果保护。组件拒绝loading／disabled、过期分页回调、过期行世代与非当前行选择；修改每页数量回到第一页。统计被移除后不再调用对应统计接口。

用户关系抽屉保留原服务端关键词查询契约；不将单一关键词接口伪装为多字段AND过滤。搜索框使用`NFormItem :show-label="false"`，去掉重复长说明行，但保留placeholder和真实input的可访问名称。好友申请的状态、方向仍是独立字段；仅在实际超过一行时折叠。业务新增操作与列设置同栏，长ID不换行；宿主提供有界高度，分页不随表格内容被挤出。

## 页面框架与扩展契约

- `filters`接收独立`NFormItem`。Console的`ListPageSearchField`仅适配这一Naive组件；组织／应用查询拆开，不将两个选择器堆在一个字段中。
- `actions`为左侧业务操作，`tools`为右侧工具，列设置由框架统一管理。`help`进入“列表说明”弹层；`notice`保留错误、未知写入及核对入口，不能藏起待处理写入结果。
- `columns`原生render与`cell-<key>`／显式`slot`均保留真实行对象，`row-actions`可添加业务行操作。不复制行来伪造ID；`rowKey`接受稳定字段或宿主函数。
- `surface="plain"`供卡片目录去掉外围重复面板；默认`panel`保持标准表格边界，分页、错误及业务插槽契约不变。
- `surface="plain"`配合`controls-surface="panel"`可给筛选与操作栏增加连续的主题底色、边界和内边距，资源卡片仍直接放在页面上；默认`inherit`沿用原来的表面。
- `layout="content"`给不是列表的页面（策略、分布图、健康读数、签名摘要）复用同一外框：查询栏、`notice`、工具栏的样式与间距不变，正文改为`content`插槽，在框内独立滚动。没有列设置；`actions`／`tools`／`help`都为空时不画工具栏。查询与重置仍只发`search`／`reset`，读写由宿主决定。
- `embedded`为抽屉／详情中的有界列表。`tableVisible`仅控制数据区，例如原错误状态不渲染旧行；错误及重试仍由宿主提供。
- `disabled`锁住整个列表交互；`searchDisabled`、`paginationDisabled`、`selectionDisabled`分别锁住对应入口。`rowSelectable`可排除群主等不可选行；列显隐不是业务授权。
- 计数分页例：`{page: 1, pageSize: 20, total: 300}`；加载快照例：`{page: 1, pageSize: 20, total: loaded.length, totalKind: 'loaded'}`；游标例：`{page: 2, pageSize: 20, hasNext: true}`。后者不传虚构total，旧分页回调在快照改变后失效。
- `query-actions`支持有权限／写锁约束的专用查询动作，不能为了统一外观丢掉业务守卫。查询框普通Enter统一派发一次，输入法确认不误提交。

实装与相关验证范围见工作区Deploy的`docs/platform-console-naive-list-standard-2026-10-17.md`。不把组件／SSR通过当作全部角色写流程已通过。

`columns`是平面`FlareAdminColumn[]`，保留Naive基础列的render，不是分组表头。树形行复用Naive原生`children`，宿主以`v-model:expanded-row-keys`控制展开；组件不扁平化或自动级联选择子节点。未提供展开模型时保持原生默认，loading／disabled拒绝展开更新。注册中心仅使用只读树，不把这一支持扩大为树形批量选择或授权。

树形分页由宿主按根节点切片，子树保持完整；搜索保留命中节点的祖先。根节点计数不能冒充全树节点数或权限总数。层级、展开和列显隐都不授予业务权限，权限绑定与保存仍归宿主拥有。

## 表单取舍

| 场景 | 推荐 | 原因 |
| --- | --- | --- |
| 桌面高频查询、短标签 | 标签与控件同行 | 节省纵向空间，查询与工具栏的阅读路径稳定 |
| 创建／编辑、长标签或校验说明 | 标签在上 | 为输入和错误信息保留完整宽度，避免强塞一行 |
| 手机窄容器 | 标签在上 | 避免压缩输入宽度，沿用相同字段和查询语义 |

Naive官方支持`label-placement="left" | "top"`；本组件仅按实际容器宽度选择，不将所有表单强制一种布局。参考：[Form API](https://github.com/tusen-ai/naive-ui/blob/main/src/form/demos/zhCN/index.demo-entry.md)、[Pagination API](https://github.com/tusen-ai/naive-ui/blob/main/src/pagination/demos/zhCN/index.demo-entry.md)。
