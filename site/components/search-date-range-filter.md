---
title: SearchDateRangeFilter 时间范围筛选
---

# SearchDateRangeFilter 时间范围筛选

检索的时间范围筛选器。宿主传入预设区间（今天 / 近 7 天 / 近 30 天……），组件用 chips 呈现，再用「自定义」展开一对起止日期；输出统一为 `FlareSearchTimeRange`（含端的 UTC epoch 毫秒），由宿主拼进检索条件。组件不持有时钟：它从不自己算「今天」，避免时区与宿主不一致。

<div class="flare-demo flare-demo--stack"><SearchDateRangeFilterDemo /></div>

<ComponentApi name="SearchDateRangeFilter" />

## 状态与恢复规则

| 状态 | 呈现 | 可用操作 |
|---|---|---|
| 无限制（两端都空） | 摘要显示 `unlimitedText`，不显示清除 | 选预设、展开自定义 |
| 命中预设 | 对应 chip 选中（图标/文字 + 选中态边框，不只靠颜色），摘要显示该 chip 文案 | 换预设、展开自定义、清除 |
| 自定义区间 | 自动展开自定义区并回填两个 DatePicker，摘要显示「起始日期 X · 结束日期 Y」 | 改起止、清除单端、清除全部 |
| 只有起始 / 只有结束 | 另一端留空，摘要只显示已设置的一端 | 补另一端、清除 |
| 非法区间（from > to） | 警告图标 + `invalidText`，**不派发 change**，用户已选的日期保留在界面上 | 改任一端修正 |
| disabled | 全部 chips、日期选择、清除按钮禁用 | 无 |

选中判定用 `sameSearchTimeRange(value, option)` 比**数值**，不是比 `id`——宿主每次渲染都可能重建预设对象，比 id 会漏选中态。

## 日期到时间戳的转换

纯逻辑在 `shared/contracts/search-date-range.ts`，四端各有同名实现与单测：

| 函数 | 语义 |
|---|---|
| `dayStartMs(date, tzOffsetMinutes?)` | 该日 **00:00:00.000**；不是合法日期返回 null |
| `dayEndMs(date, tzOffsetMinutes?)` | 该日 **23:59:59.999**；不是合法日期返回 null |
| `rangeFromDates(from, to, tzOffsetMinutes?)` | 组装 `FlareSearchTimeRange`；两端都空 = 无限制 `{}`；日期非法、早于 epoch 或 from > to 返回 null |
| `datesFromRange(range, tzOffsetMinutes?)` | 回填 DatePicker 的 `{ from, to }`，缺失的一端为 `''` |
| `matchedOptionId(value, options)` | 命中的预设 id，按值匹配 |
| `unrestrictedRange(range)` | 两端都空 |
| `shouldOpenCustomRange(value, options, allowCustom, customActive)` | 自定义区是否展开 |

两端都是**含端**：同一天的起止得到 `86 399 999` 毫秒的区间，而不是 0。`tzOffsetMinutes` 是 **UTC 以东的分钟数**（UTC+8 → 480，UTC-5 → -300）；注意 JavaScript 的 `Date#getTimezoneOffset()` 符号相反，要传 `-new Date().getTimezoneOffset()`。不传则按查看者所在时区解析该日历日（由平台处理夏令时）。日期字符串按严格 `YYYY-MM-DD` 校验，`2026-02-30`、`2026-13-01` 一律判为非法。

## 宿主接入

组件受控：`value` 由宿主持有，`change` 只带回新的时间范围，`clear` 只表达「清空时间条件」的意图；组件不发请求、不重试、不改宿主状态。

**关键词、类型与时间范围是不可分割的提交条件。** 宿主把 `change` 合进 `FlareSearchCriteria` 后必须重新发起检索，并保证旧条件的结果快照不会显示在新筛选下——SearchPanel 用 `sameSearchCriteria(submitted, snapshot.criteria)` 判定快照是否属于当前条件，不匹配就按「等待中」渲染。典型接线：

```ts
function onRangeChange(range: FlareSearchTimeRange) {
  criteria.value = { query: criteria.value.query, filterId: criteria.value.filterId, ...range };
  search(criteria.value); // 竞态仲裁仍由宿主负责：只接受最后一次请求的结果
}
```

本组件**不修改 SearchPanel**。它既可以放在 SearchPanel 上方作为独立筛选条，也可以放进检索工作台的侧栏；SearchPanel 已支持的 `timeRanges` 预设与本组件互不冲突，但同一界面只应有一个时间范围的真源。

::: code-group

```vue [Vue / Tauri]
<FlareSearchDateRangeFilter :value="range" :options="presets" :min-date="minDate" :max-date="maxDate"
  :disabled="busy" @change="onRangeChange" @clear="onRangeClear" />
```

```dart [Flutter]
FlareSearchDateRangeFilter(value: range, options: presets, minDate: minDate, maxDate: maxDate,
    disabled: busy, onChange: onRangeChange, onClear: onRangeClear)
```

```swift [SwiftUI]
SearchDateRangeFilterView(value: range, options: presets, minDate: minDate, maxDate: maxDate,
                          disabled: busy, onChange: onRangeChange, onClear: onRangeClear)
```

```kotlin [Compose]
SearchDateRangeFilter(value = range, onChange = ::onRangeChange, options = presets,
    minDate = minDate, maxDate = maxDate, disabled = busy, onClear = ::onRangeClear)
```

:::

Vue 用 `@change` / `@clear`，并用 `has-clear`（默认 true）声明宿主能处理清除；Flutter / SwiftUI / Compose 用 `onChange`（必传）与 `onClear`（可选，没传就不显示清除按钮）。`allowCustom=false` 时自定义入口整体消失，只剩预设——用于宿主不希望用户任意翻历史的场景。

## 布局、规模与可访问性

预设数量由宿主控制，chips 自动换行，超长文案换行不截断；组件本身不滚动，放进设置页或筛选面板的滚动容器即可。日期选择复用各端既有的 DatePicker（Web 桌面为浮层、移动与原生为底部弹层），不新造日历。chip、清除、单端清除按钮均不小于 48 逻辑单位；chip 用 `aria-pressed` / `isSelected` 表达选中，自定义入口另有 `aria-expanded`；非法区间提示是 `role="alert"`，摘要是 polite 实时区域，读屏能听到当前范围。日期文本用等宽数字、RTL 下不倒序。示例为本地状态，不能代替真实检索链路与真机读屏验收。
