---
title: MemberRoleSheet 成员管理菜单
---

# MemberRoleSheet 成员管理菜单

对单个群成员的管理菜单：改角色、禁言、移出、转让群主。宿主传入成员快照、自己的角色与可承接的能力，组件用共享的 `memberRoleActions(member, viewerRole, capabilities)` 计算可显示动作——先按身份等级裁剪，再按能力开关收窄，四端得到同一集合、同一顺序、同一危险分组。组件不自带弹层定位，只输出菜单内容，宿主放进 bottom sheet 或 popover。

<div class="flare-demo flare-demo--stack"><MemberRoleSheetDemo /></div>

<ComponentApi name="MemberRoleSheet" />

## 权限矩阵与状态

| 情况 | 可见动作 |
|---|---|
| 目标是群主（`role = owner`） | 全部不显示——群主不可被 promote / demote / mute / remove / transferOwner；菜单显示「群主不可被管理」 |
| `viewerRole = member` | 无任何管理动作，显示「你没有管理权限」 |
| `viewerRole = admin`，目标是 admin | 平级，不显示任何动作 |
| `viewerRole = admin`，目标是 member | promote / mute / unmute / remove（受能力开关），**永远没有 transferOwner** |
| `viewerRole = owner` | 可管 member 与 admin：promote（仅 member）、demote（仅 admin）、mute/unmute、transferOwner、remove |
| `member.muted` | mute 与 unmute 互斥，只出现其中一个 |
| `muteDurations` 为空 | 不显示 mute——组件不内置任何时长 |
| `busy` | 全部行与时长按钮禁用；Escape 仍可关闭（若时长已展开，先收起） |

动作枚举固定为 `promote | demote | mute | unmute | transferOwner | remove`，顺序即此。`transferOwner` 与 `remove` 是危险动作，单独分组置底，用 `--flare-color-danger` / error token 加图标（不只靠颜色）。mute 点击后在原位展开宿主给的时长，选中某一项才派发 `{ memberId, action: "mute", durationId }`；unmute 直接派发。其余动作派发 `{ memberId, action }`。

**二次确认不在组件内**：移出成员与转让群主必须由宿主用 DangerConfirm 承接，组件只表达意图。组件不改快照、不发网络请求，角色与禁言状态由宿主在 SDK 确认后更新。

## 宿主接入

宿主在发命令**之前同步置 busy**，避免重复提交；命令结束后更新成员快照并解除 busy。`close` 在 Escape 时触发（时长展开时先收起），宿主负责收起弹层。

::: code-group

```vue [Vue / Tauri]
<FlareBottomSheet :open="open" @close="open = false">
  <FlareMemberRoleSheet :member="member" :viewer-role="myRole" :capabilities="caps"
    :mute-durations="durations" :busy="busy"
    @action="(p) => confirmThenRun(p)" @close="open = false" />
</FlareBottomSheet>
```

```dart [Flutter]
showModalBottomSheet(context: context, builder: (ctx) => FlareMemberRoleSheet(
  member: member, viewerRole: myRole, capabilities: caps,
  muteDurations: durations, busy: busy,
  onAction: (id, action, durationId) => confirmThenRun(id, action, durationId),
  onClose: () => Navigator.of(ctx).pop()));
```

```swift [SwiftUI]
.sheet(isPresented: $open) {
    MemberRoleSheetView(member: member, viewerRole: myRole, capabilities: caps,
        muteDurations: durations, busy: busy,
        onAction: { id, action, durationId in confirmThenRun(id, action, durationId) },
        onClose: { open = false })
        .presentationDetents([.medium])
}
```

```kotlin [Compose]
ModalBottomSheet(onDismissRequest = { open = false }) {
    MemberRoleSheet(member = member, viewerRole = myRole, capabilities = caps,
        muteDurations = durations, busy = busy,
        onAction = ::confirmThenRun, onClose = { open = false })
}
```

:::

原生端未传 `onAction` 时所有行按禁用渲染；Vue 接入方必须监听 `action`。所有文案通过 props 传入并带默认值，宿主按语言替换。能力开关表达的是「宿主能不能承接」，身份等级规则在组件内恒定生效——即使宿主错误地开了 `transferOwner`，管理员视角也不会出现它。

## 布局、规模与可访问性

最多 5 行加一组时长按钮，无需内部滚动；宿主弹层负责高度上限与安全区。每行最小高度 48 逻辑单位，图标列 44，时长按钮触控区同样不低于 48。`role="menu"` 以成员名作为读屏名称，每行 `menuitem` 读出完整文案，mute 行带 `aria-expanded`；Tab/Enter/Escape 可用，focus-visible 有焦点环。头部把角色与「已禁言」同时用文字和图标表达。长成员名省略，长文案换行，RTL 下图标与文字随书写方向翻转。示例使用本地状态，不能替代 SDK 与真机读屏验收。
