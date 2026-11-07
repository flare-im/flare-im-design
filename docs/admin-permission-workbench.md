# 菜单／按钮权限分配工作台

`FlarePermissionWorkbench` 从 `@flare-im/vue-ui/admin` 导出，供权限编辑 Modal 组合。使用真实 Naive UI Input、Radio、Select、Checkbox、Button、Tag；不访问 API，不理解业务权限码，不提供第二套保存栏。

- 桌面：模块导航 → 菜单及按需展开的按钮 → 本次新增／移除预览。
- 手机：模块选择器和单列列表；通过“本次变更”查看改动，外层 Modal 保留固定操作栏。
- 菜单按钮默认收起；搜索自动显示匹配按钮及其菜单。全部／已选／本次变更只影响显示，不影响选择。
- `groups` 是分组、菜单、按钮显示数据；目录不提供授权勾选。`checkedKeys` 是受控 UI key，`baselineKeys` 是打开时的不可变基线。组件只发送单项 key 的变化，菜单查询包／依赖／别名规则由宿主编译。
- 禁用菜单及其按钮不可改，未知 key 不擅自删除；空筛选不残留原模块编码。没有匹配项时显示空态。
- `reset` 事件由宿主恢复原始业务数据，不能用显示 keys 反推并替换原始权限码，否则可能丢失部分或未登记旧权限。
- 宿主拥有权限池、组织范围、撤权、加载／失败／重试、保存锁和未知写入结果处理。加载失败不得用空基线冒充成功；只在权威读取成功后显示编辑器。

示例：

```vue
<FlarePermissionWorkbench
  v-model:checked-keys="displayKeys"
  :groups="groups"
  :baseline-keys="originalDisplayKeys"
  :disabled="saving || !canAssign"
  @reset="restoreOriginalPermissionCodes"
>
  <template #help>菜单包含基础查询，按钮附带所属菜单查询。</template>
</FlarePermissionWorkbench>
```

密度使用现有 tokens、单一轻边框和有界局部滚动。键盘／焦点沿用 Naive 控件，标签允许长文换行；模块按钮有当前态，折叠按钮有展开状态，选择计数有 live-region。当前是管理端 Vue 组件，不把它宣称为 Flutter／原生授权页面。

定向验证见组件测试；实际 Console 1920、390、320×560 检查包括单项选择、自动菜单依赖、变更筛选、撤销和取消。角色写入／服务端授权仍须由业务层验证。
