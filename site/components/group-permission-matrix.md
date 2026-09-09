---
title: GroupPermissionMatrix 群权限设置
---

# GroupPermissionMatrix 群权限设置

群管理页里的「群设置」段：加群方式、全员禁言、仅管理员可 @所有人、仅管理员可置顶消息、允许分享群名片。五项各自对应群模型上真实存在的字段（`joinPolicy`、`muteAll`、`onlyAdminCanAtAll`、`onlyAdminCanPin`、`shareCardPermission`），组件不发明后端没有的权限。可见行与状态由共享的 `groupPermissionRows(settings, canManage, busyKeys, errors)` 计算，四端得到同一集合、同一顺序、同一读写形态。

<div class="flare-demo flare-demo--stack"><GroupPermissionMatrixDemo /></div>

<ComponentApi name="GroupPermissionMatrix" />

## 状态与恢复规则

| 情况 | 展示与操作 |
|---|---|
| `canManage = true` | 四个开关可切换，加群方式是三选一单选组 |
| `canManage = false` | 全部渲染为只读值行（已开启/已关闭、加群方式文案），**不出现禁用开关**，标题右侧说明「仅群主和管理员可修改」 |
| `busyKeys` 含某键 | 该行显示「提交中」并锁定，其余行照常可用 |
| `errors` 含某键 | 该行下方显示失败原因（图标 + 文字 + danger 色），提供「重试」与「忽略此错误」 |
| 部分失败 | 成功的行保持新值，失败的行保持旧值并各自显示原因；不用一个全局提示覆盖 |
| `joinPolicy` 不在 1/2/3 中 | 原样保留，不猜测；单选组无选中项并提示「当前加群方式未知，请重新选择」 |

切换只派发 `change`，组件**不自己翻转值**：宿主拿到 SDK 确认后写回 `settings`，值才变。因此失败时界面天然回到旧值，不需要额外回滚。`change` 的载荷是 `{ key, value }`，`value` 对开关是布尔、对加群方式是数字（SwiftUI 用 `FlareGroupPermissionValue.flag/.policy` 表达同一联合类型，Flutter/Compose 用 `Object`/`Any`）。`dismissError` 只带 key，由宿主清掉自己的错误表。

「重试」重发本组件上一次派发的意图；若组件没记录过（例如刷新后错误由宿主注入），开关行退化为「取反当前值」，单选行不显示重试按钮——三个选项本来就在旁边可直接再点。

## 宿主接入

宿主在发命令**之前同步把该键放进 `busyKeys`**，命令返回后移除，成功则写回 `settings`，失败则写进 `errors`。每键独立，一次失败不影响其他键。`busyKeys` / `errors` 的键名四端一致：`joinPolicy` `muteAll` `onlyAdminCanAtAll` `onlyAdminCanPin` `shareCardPermission`。

::: code-group

```vue [Vue / Tauri]
<FlareGroupPermissionMatrix
  :settings="settings" :can-manage="model.canManage"
  :busy-keys="busyKeys" :errors="errors"
  @change="({ key, value }) => save(key, value)"
  @dismiss-error="(key) => clearError(key)" />
```

```dart [Flutter]
FlareGroupPermissionMatrix(
  settings: settings,
  canManage: model.canManage,
  busyKeys: busyKeys,
  errors: errors,
  onChange: (key, value) => save(key, value),
  onDismissError: clearError,
)
```

```swift [SwiftUI]
GroupPermissionMatrixView(settings: settings,
                          canManage: model.canManage,
                          busyKeys: busyKeys,
                          errors: errors,
                          onChange: { key, value in save(key, value) },
                          onDismissError: clearError)
```

```kotlin [Compose]
GroupPermissionMatrix(
    settings = settings,
    canManage = model.canManage,
    busyKeys = busyKeys,
    errors = errors,
    onChange = { key, value -> save(key, value) },
    onDismissError = ::clearError,
)
```

:::

原生端未传 `onChange` 时整个面板按只读渲染（不显示无法生效的开关）；Vue 接入方必须监听 `change`。所有文案通过 props 传入并带默认值，宿主按语言替换。

## 布局、规模与可访问性

固定 5 行，无内部滚动，宿主把它放进设置页的纵向流即可；原生端本身是有界内容，不需要嵌套滚动容器。每行主区最小高度 48 逻辑单位，开关 44×26，单选项与「重试」按钮触控区同样不低于 48（桌面指针下可收窄到 40）。状态不只靠颜色：只读用文字值、忙碌用「提交中」+ 进度指示、失败用图标 + 文案 + danger 色。开关是 `role="switch"` 并带 `aria-checked`，单选组是 `role="radiogroup"` / `role="radio"`，读屏能读出「标题 + 当前值」；键盘 Tab 可达、Enter 触发、focus-visible 有焦点环。长文案换行，超长错误原因按字符换行不撑破布局。示例使用本地状态，不能替代 SDK 与真机读屏验收。
