# 可排序列表

`FlareAdminSortableList`从`@flare-im/vue-ui/admin`导出，是控制台里调整条目顺序的列表，例如「+」面板布局编辑器。它只负责排列与交互：数据、每行显示什么、行尾控件、是否保存，都由宿主决定。

## 交互

1. 拖动行首手柄，把行放到另一行的位置。
2. 焦点在手柄上时按 Alt+↑ / Alt+↓ 上移、下移一位；移动后焦点留在原来那一行的手柄上，可以连续移动。
3. 每行的菜单提供「上移」「下移」「移到最前」，到头的项不可用。
4. 每次移动都发出整份新顺序（`update:items`），并在礼貌型播报区读出「「名称」已移到第 N 位，共 M 项」。
5. `disabled`时只读：不画手柄和菜单，不能拖动。

## 属性与插槽

| 名称 | 说明 |
| --- | --- |
| `items` | `{ id, label }[]`，按当前顺序。`label`用于手柄、菜单和播报的名称 |
| `label` | 列表的可访问名称 |
| `disabled` | 只读 |
| `update:items` | 移动后的整份列表，配合`v-model:items`使用 |
| `item`插槽 | 行内容，参数`{ item, index }`；不传时显示`label` |
| `trailing`插槽 | 行尾控件，例如「在面板中显示」开关，参数`{ item, index }` |

## 组合示例

```vue
<FlareAdminSortableList v-model:items="rows" label="面板项" :disabled="!canWrite">
  <template #item="{ item }">
    <EntryRow :entry="entryOf(item.id)" />
  </template>
  <template #trailing="{ item }">
    <n-switch v-model:value="visible[item.id]" :aria-label="`在面板中显示${item.label}`" />
  </template>
</FlareAdminSortableList>
```

## 约定

- 颜色、间距、圆角取 Kit 令牌，暗色主题跟随宿主。
- 手柄与菜单按钮都是有名称的按钮，触控区不小于控件高度令牌；减少动态效果时不做背景过渡。
- 文案在`sortableList.*`下，中英两份。
