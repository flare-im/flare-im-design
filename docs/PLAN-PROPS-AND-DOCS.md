# 完善 props + 文档网站

## Goal
让 props 文档"真正有用":为对象型 props（`Contact`/`UserProfile`/`GroupSummary`…）文档化其**字段结构**；给过薄的展示组件补真正有用的宿主控制 props；官网生成"数据类型/Data Types"参考页并从组件 prop 表交叉链接。中英双语；validate + vitepress build 绿；preview 实测。

## Constraints & decisions
- 数据类型源真值 = `vue-im-ui/src/shared/contracts/*.ts`（+ PinnedMessageBar 内联 `PinnedMessageItem`）。文档必须与之一致。
- 单一"Data Types 参考页"（避免 FlareContact 在 ContactItem/List/Detail 三处重复），组件 prop 表里对象型 type 链接到该页锚点（类 TypeDoc）。
- spec 加 `dataTypes` 顶层块（bilingual field descriptions）；生成器扩展产两语参考页 + prop type 链接。
- 补 props 要**真加到 Vue 组件 + spec**（validate 只查符号存在，不查 prop 契约，故须诚实）；跨端 parity 若不同步则在计划注明留后续，不谎报。
- 语言自称名、既有 i18n 不动。

## Status: 数据类型参考页 DONE ✅（docs 里程碑，已验证）
Current focus: 提交里程碑；评估是否再做一轮真·新增 props（跨端）

## Steps
- [x] 读生成器/config ✅
- [x] spec 加 `dataTypes` ✅：11 接口(Contact/FriendRequest/GroupSummary/UserProfile/SettingsItem/SettingsSection/NavItem/ConversationRowModel/PinnedMessageItem/VoteOption/MediaResolveRequest) + 8 枚举/联合(SettingKind/ConversationAction/ConversationFilter/ComposerState/MediaKind/ViewportKind/LayoutMode/DensityMode)，字段双语。修正 spec 里不准的 prop type：`ConversationRow[]`→`ConversationRowModel[]`、`PinnedMessage[]`→`PinnedMessageItem[]`（对齐真 TS 符号）。
- [x] 生成器 ✅：产 `reference/data-types.md`(zh)+`en/reference/data-types.md`；`typeCell()` 把 prop/字段的对象型 type 链接到 `#锚点`（自定义 `{#slug}`）；`usedByComponents()` 反查"被使用于"。propsTable 接入 typeCell。13 组件页现有 type→数据类型链接。
- [x] config.mts sidebar+nav ✅：两语加"数据类型/Data Types"（nav + 组件总览组 + 独立 `/reference/` sidebar）。
- [x] 验证 ✅：validate 51/9 绿、vitepress build 绿（自定义锚点+跨页链接全解析）、Claude_Preview 实测：数据类型页 11 表 + 锚点(contact/conversation-row-model/setting-kind)全在、"被使用于"链有效、组件页 prop type 反链到 `#contact`、明暗双色、无横向溢出、控制台净、EN 页 Interfaces+Enums 齐。
- [x] **真·新增 props（第一批）✅**：给 GroupList + NewFriendRequests 加 `emptyText`（宿主可覆盖空态标题，默认英文），**四端 + spec 全落**：Vue(`emptyText?: string` + `:title="emptyText || 'No groups yet'"`)、Flutter(`this.emptyText = '...'`)、iOS(init `emptyText: String = "..."`)、Compose(`emptyText: String = "..."`)。**vue-tsc / flutter analyze0 / swift build / compileDebugKotlin / validate 51/9 / vitepress build 全绿**；doc 页 prop 表 + 四端 usage 示例均现 emptyText。
- [ ] （后续可继续）更多宿主控制 props（如 ContactDetail 动作按钮 label、SettingsList title）——同款四端 parity 流程。

## Notes
- 现状薄组件多因传"1 个对象 prop"（contact: Contact 等），真值在对象字段里 → 文档化字段是主要杠杆。
- 51 组件 / 9 类;validate 计数漂移门槛会查 4 文档文件的"N 个组件"字样——加参考页别触发误报（参考页不计入组件数）。
