---
title: SearchPanel 搜索面板
---

# SearchPanel 搜索面板

组合搜索输入、类型选择、结果、等待和失败恢复。四端共用 `criteria(query, filterId)` 与 `snapshot(criteria, state, groups, error)` 契约。`filterId` 是宿主定义的稳定类型标识，不能用“文件”等翻译文案作为 SDK 类型。

## 筛选与结果实验室

选择“文件”后旧文本结果立即隐藏；点击“返回当前结果”才显示文件结果。可以模拟失败并重试。演示没有网络请求。

<div class="flare-demo flare-demo--stack"><SearchPanelDemo /></div>

<ComponentApi name="SearchPanel" />

## 状态规则

| 状态 | 显示与交互 |
|---|---|
| idle | 提示输入关键词或选择类型 |
| loading | 等待指示；允许修改条件发起下一次搜索 |
| success | 同一已提交条件的结果；空分组显示无结果 |
| failure | 面向用户的错误与重试；重试保持已提交条件 |
| 条件不匹配 | 隐藏旧结果并等待当前条件，禁止把上一个类型的结果显示在新筛选下 |

输入草稿不会改变已提交结果的高亮。提交会去除关键词首尾空白；选择类型会同时提交当前关键词。清空关键词也允许提交，以支持仅按类型检索。后端不支持空关键词时，宿主必须给出明确提示。

## 宿主边界与请求竞态

组件不执行检索、不猜测消息类型，也不修复后端过滤。宿主必须把 `filterId` 映射到 SDK 的类型过滤，并传回相同的 criteria。禁止用文件名后缀推断消息类型。

每次搜索使用递增请求代号；开始时同步发布 loading 快照。只接受最后一次请求的响应，包含同关键词、同类型的重复请求。criteria 匹配只防止不同条件混显，不能取代宿主的 latest-request 检查。切换会话时，使用 Vue `:key="conversationId"`、Flutter `ValueKey(conversationId)`、SwiftUI `.id(conversationId)`、Compose `key(conversationId)` 重置面板，并使旧请求失效。

```ts
let generation = 0;
async function search(criteria: FlareSearchCriteria) {
  const own = ++generation;
  snapshot.value = { criteria, state: 'loading', groups: [] };
  try {
    const groups = await adapter.search(criteria); // SDK 类型过滤在适配器中处理
    if (own === generation) snapshot.value = { criteria, state: 'success', groups };
  } catch {
    if (own === generation) snapshot.value = {
      criteria, state: 'failure', groups: [], error: '搜索未完成，请重试',
    };
  }
}
```

错误文案来自宿主的用户错误映射，不能直接显示 SDK JSON、内部路径或凭证。`open` 只返回结果条目；加载未缓存消息、定位时间线和搜索翻页仍由 SDK/宿主实现。

## 四端入口

| 平台 | 入口 | 回调 |
|---|---|---|
| Vue / Tauri | FlareSearchPanel | search、open、viewAll |
| Flutter | FlareSearchPanel | onSearch、onOpen、onViewAll |
| SwiftUI | SearchPanelView | onSearch、onOpen、onViewAll |
| Compose | SearchPanel | onSearch、onOpen、onViewAll |

Vue 的过滤标签来自 `Record<string,string>`，Flutter/Compose 为 Map，SwiftUI 为 Dictionary（按 key 排序）。需要统一显示顺序时使用同一有序 ID，如 `01-all`、`02-text`；宿主显式映射到 SDK 类型。

结果面板不拥有无限滚动。传入有界结果组，长结果由宿主滚动容器承载；大量结果使用“查看全部”进入虚拟列表。控件使用至少 48 逻辑单位的点击区域，过滤项换行，搜索框具有读屏名称。小屏、大字号和深浅主题需随宿主一起验收。

## 时间范围

四端的 `SearchCriteria` 均包含可选 `fromTime`、`toTime`，单位为 Unix 毫秒，包含边界。范围随查询和消息类型共同组成请求身份，旧范围的响应不得覆盖新查询。`timeRanges` 可由宿主提供“不限、今天、最近七天”等选项；不合法的范围禁用。今天按用户本地时区的午夜计算，最近七天为滚动七天。组件不自行决定服务器时区。

Web SDK 适配层直接传递原有搜索协议的时间字段；无需新增服务接口。切换账号、会话时应重置宿主请求状态。
