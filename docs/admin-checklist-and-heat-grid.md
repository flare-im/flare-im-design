# 发布检查清单与读数热力表

`FlareAdminChecklist`和`FlareAdminHeatGrid`从`@flare-im/vue-ui/admin`导出。两个都只负责展示：检查由谁跑、读数怎么算、文案写什么，都由宿主决定。

## 发布检查清单

`FlareAdminChecklist`展示一组检查的结果，例如发布前校验。它是只读列表，不带操作。

`status`有三种：`pass`、`fail`、`unknown`。`unknown`表示这条检查没能得出结论，既不是通过也不是失败，用单独的图标和颜色，宿主要写清楚原因。状态始终同时用文字说明，图标和颜色不单独表达含义。

| 名称 | 说明 |
| --- | --- |
| `label` | 列表的可访问名称 |
| `items` | `FlareAdminCheckItem[]`，按展示顺序 |

`FlareAdminCheckItem`：

| 字段 | 说明 |
| --- | --- |
| `id` | 这条检查的标识 |
| `title` | 检查内容 |
| `status` | `pass`、`fail`、`unknown` |
| `statusText` | 状态的文字 |
| `description` | 可选，一句话说明为什么是这个结果 |
| `details` | 可选，查到的问题，一行一条 |

```vue
<FlareAdminChecklist
  label="发布校验"
  :items="[
    { id: 'cert', title: '证书 30 天内不过期', status: 'unknown', statusText: '未知',
      description: '还没有探测结果', details: ['im.example.com 尚未探测'] },
  ]"
/>
```

## 读数热力表

`FlareAdminHeatGrid`按行列展示读数，并按好坏着色，例如接入点在各探测点的可用率。它是一张真实的`<table>`，屏幕阅读器能读出每个读数所在的行和列。列多时横向滚动，行标题固定在起始侧。

行列组合没有对应的格子时，显示`emptyText`和中性底色，不显示 0。读数和`tone`都由宿主算好传入，阈值不在组件里。

| 名称 | 说明 |
| --- | --- |
| `label` | 表格的可访问名称 |
| `rowHeader` | 行标题列的表头 |
| `rows`、`columns` | `{ key, label }[]` |
| `cells` | `{ row, column, text, tone, detail? }[]`，`tone`是`good`、`warn`、`bad`，`detail`进格子的提示 |
| `emptyText` | 没有数据的格子显示的文字 |

```vue
<FlareAdminHeatGrid
  label="接入点可用率"
  row-header="接入点"
  :rows="[{ key: 'ap-a', label: 'ap-a' }]"
  :columns="[{ key: 'cn', label: '华东' }, { key: 'us', label: '美西' }]"
  :cells="[{ row: 'ap-a', column: 'cn', text: '99.90%', tone: 'good', detail: '1200 次探测' }]"
  empty-text="暂无数据"
/>
```
