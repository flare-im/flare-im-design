## 未发布

- 通话记录卡片：新增 `FlareCallRecordCard`（props `media`、`scope`、`state`、`endReason`、`durationSeconds`、`joinedCount`、`viewerIsInitiator`、`canJoin`、`canCallBack`、`disabled`、`busy`；事件 `join`、`callBack`），`./contracts` 新增 `FlareCallRecordScope`、`FlareCallRecordState`、`FlareCallEndReason`、`FlareCallRecordStatus` 与 `flareCallRecordStatus` / `flareCallRecordTone` / `flareCallRecordAction` / `flareCallDurationLabel`（`spec/call-record-vectors.json`），i18n 新增 `callRecord.*`。

- `displayTextFromStoredPreview` 可注入 `StoredPreviewOptions.resolveSystemText` 解析产品自己的系统消息键、参数与回退文案；通用预览与引用的解码继续由 Kit 提供。

- 已读名单的分页持有者与抽屉里自带页头的页面：
  - 新增 `useFlareReadReceiptList(key, page)`（`./composables`）：宿主只给按栏取一页的 `page(column, cursor?)`（名单不开放时返回 null），两栏第一页、按栏翻页、整张名单的状态与每栏的忙 / 失败标记都由 Kit 持有；`sheet` 直接 `v-bind` 给 `FlareReadReceiptSheet`，标签数字仍由宿主传这条消息当前的摘要。规则与步骤向量见 `spec/read-receipt-list-vectors.json`，四端同名。
  - `FlareDrawer` 认得自带页头的页面：带返回键的 `FlareScreen`（如 `FlarePluginPage`）推进抽屉时声明自带页头，抽屉不再画页头行（`title` 只作可及名称），Escape 与平台返回先在那一页里退一页，里面没有能返回的页时才关抽屉。`useFlareSheetOwnHeader` 新增可选的 `{ active, back }`。

- 「我」页内置项副标题、合并转发条目文字与抽屉头像：
  - `flareMeMenuSections` 的 `summaries` 按项 id 对内置项同样生效（宿主给「我的邀请」的副标题）。
  - 合并转发条目的 `plainText` 是核心给的可读文字，按正文摘要的读法画（Markdown 转纯文本、表情包键按读者语言）；抽屉头像首字取发送者名字，没有名字画「?」（原来取「未知发送者」的「未」），新增 `flareForwardSenderInitial`。

- 已读名单分页、渲染器拿到发送者、红包已退回与币种小数位、「我」页菜单、图标回落、合并转发记录与复数（契约与向量四端共用）：
  - **已读名单**：`FlareReadReceiptSheet` 新增 `readCount` / `unreadCount`（标签数字只取宿主传的摘要人数，不再取名单长度；不传时标签不带数字）、`state`（ready / loading / error / unavailable：读取中转圈，失败可重试并发 `retry`，不可查看只给提示）、两栏各自分页（`readHasMore` / `unreadHasMore`、`loadingMore`、`loadMoreFailed`，名单末尾「加载更多」或「加载失败，点按重试」发 `loadMore(column)`）与 `initialTab`。宽度随容器：不在 Kit 浮层里时自画卡片，最宽 320；放进 `FlareBottomSheet` 时不画外壳并声明自带标题，宿主用 `fill` 打开，面板标题不再重复。新增 `./contracts` 的 `flareReadReceiptPresentation`（`spec/read-receipt-vectors.json`）与内部的 `useFlareInsideSheet`。
  - **自定义渲染器拿得到发送者**：渲染器 props 新增 `senderId` 与 `senderName`（宿主给的显示名，去空白，没有就不传，不回落到 id）；`FlareMessageContentView` 新增 `senderId`、`senderDisplayName`，`FlareMessageBubble` 自动传入。
  - **红包**：`FlareRedPacketOpenSheet` 的 `state` 新增 `refunded`（「红包已退回」，与 expired 一样按 `canViewDetails` 给详情键）；`FlareRedPacketComposer` 新增 `currencyExponent`（默认 2）：金额框最多保留这么多位小数（0 位时不收小数点、数字键盘），占位按小数位写，换成小数位更少的币种时裁掉已输入的多余小数。`sanitizeRedPacketAmount(raw, exponent = 2)`，新增 `flareRedPacketAmountMinor(text, exponent)`（输入换成最小单位整数字符串，不经浮点）与 `flareRedPacketExponent`。
  - **「我」页菜单**：新增 `flareMeMenuSections(menu, labels?, summaries?, locale?)`（`./utils`）：社交 SDK `features.meMenu` 的结果原样传入，内置项文案（`meMenu.*`）、插件项标题与回落、图标回落、插件副标题、设置单独成组都由 Kit 给出（`spec/me-menu-vectors.json`）。
  - **图标**：注册表追加 `wallet`（109 个）。不认识的图标名四端统一画 `plugin` 字形（开发构建每个名字告警一次），不再留空；新增 `flareIconNameOrFallback` 与 `FLARE_ICON_FALLBACK`，`FlareGlyph` 经它解析（emoji 与单个字符仍原样画）。
  - **合并转发记录**：`ForwardView` 的标题、条数、预览、「还有 N 条」与抽屉标题由新的 `utils/forwardRecord.ts`（`flareForwardRecordView`）给出，原生三端照同一份 `spec/message-forward-vectors.json` 实现；卡片读屏名中文用「，」（`forward.cardLabel`），多选时卡片不可点，抽屉里的时间跟 Kit locale。
  - **复数**：消息树的值可以是复数形态 `{one?, other, …}`，`t(key, {count})` 按 `Intl.PluralRules` 选形态，缺的形态用 other；宿主注册的语言可带任意 CLDR 形态，注册时整组替换。英文计数文案补上单数（投票「1 vote」、合并转发、成员数、选项数、图片数、置顶条数、邀请人数、文件数）。新增 `flarePluralCategory`、`flarePluralForm`、`isFlarePluralMessage`；`flarePluginEntryGroupHeader` 的第二个参数改为 `(count) => string`（破坏性）。
  - **投票卡片不再重复**：choices 块的页脚不再画 total（它只是百分比的分母，可能是人数也可能是票数之和）：页脚只有多选上限提示与「已结束」，「N 票」只用于选项；参与人数由插件自己的行给出。
  - `useFlareContentSelection` 从公共入口（composables）导出。

- 第八轮消息表面与插件体验（`docs/design/message-surface-and-meta.md`、投票第二版 §6、红包第五版 §1–§3、插件平台第二版 §4）：
  - **消息表面**：`./contracts` 新增 `FlareMessageSurface`（bubble / bareMedia / card / centered）与 `flareMessageSurface(input)`，`./utils` 新增 `messageSurfaceOf(message, registry)`（规则见 `spec/message-surface-vectors.json`）。一切 custom / 插件内容（含红包、投票、`custom:flare.plugin.message.v1`）默认是 card：`FlareMessageBubble` 不在外面画底色、边框、内边距、尾角和阴影，卡片外壳就是表面；引用回复的卡片仍是卡片，引用画在外壳顶部（`FlarePluginView` 新增 `quote` 插槽，时间线经注入自动放进去；其余卡片由行画同一条引用）。`FlareMessageBubble` 新增 `surface`（MessageList 传入它分组用的表面）。**删除**内容渲染器登记的 `bare`，改为 `surface: "card" | "bareMedia"`，只给 Kit 不认识的内容类型用；删除 `utils/messageBubbleChromeless`（`isChromelessMediaBubble` / `isChromelessCardBubble`）。
  - **元信息位置**：`FlareMessageMeta` 新增 `placement`（inline / bubbleFooter / below / none，`spec/message-meta-placement-vectors.json`）。**删除** `overlay` 叠加胶囊：卡片与图片的时间都在表面下方、尾侧、默认色板；失败时在下方显示「发送失败，重试」文字键，气泡内仍是失败图标即重试键，命中区都不小于 `layout.touchTarget`；没有 resend 监听时不可点。
  - **回执**：`MessageStatusState` 收为五态 pending / sending / sent / read / failed，**删除** delivered 与 retrying（`lifecycleToMessageStatus` 对 delivered 返回 sent），`FlareMessageStatus` 删除 `bubbleOverlay` 变体。`MessageLike` 新增 `readSummary {readCount, unreadCount, total}`（SDK 的群已读摘要）；群聊本人消息在 sent / read 时以「N 人未读 / 全部已读」替代勾形，宿主监听 `readReceiptOpen` 时可点（`FlareMessageMeta`、`FlareMessageBubble`、`FlareMessageList` 新增该事件）。规则见 `spec/message-receipt-vectors.json`。
  - **分组**：`./contracts` 的分组函数改为读 `FlareMessageGroupingItem {id, senderId, atMs, surface}`，新增 `flareTimelineRows`（日期胶囊、未读分隔线、位置与呈现一次给出）与 `flareTimelineDateLabel`；撤回、删除、系统提示与 card ↔ 其他表面的切换都会断组，`FlareMessageRowPresentation` 新增 `tail`（只有 bubble 画尾角）。`FlareMessageList` 改用它，规则见 `spec/message-grouping-vectors.json`。
  - **多选**：`FlareMessageContentView` 新增 `selectionMode`；多选时内容区 `inert`，点整行任意处切换选中；自定义渲染器收到 `selectionMode: true`，Kit 内容组件经 `useFlareContentSelection()` 得知并禁用自身控件。
  - **无障碍**：消息行的读屏名改为「发送者，内容摘要，时间，状态或已读摘要」（`flareMessageAccessibilityLabel`）。已删除的消息（lifecycle mutation deleted）显示居中「消息已删除」。
  - **插件卡片**：`FlarePluginView` 渲染 `view.menuActions`（标题行末尾的 ⋯ 键，用 `FlareActionMenu`；embedded 时作为按钮排在动作之后）、分组 entries（组头「选项 · N 票 · P%」，新增 `flarePluginEntryGroupHeader`，`viewerId` 那一行带「我」）、`view.unavailableReason` 的七种原因文案（`pluginView.unavailable.*`，新增 `displayName` 作为前缀），unbound_copy 只读并注明「副本，仅供查看」。`FlarePluginDetailSheet` 新增 `viewerId`。
  - **新组件 `FlarePluginPage`**：插件 page 贡献的通用页面宿主（钱包等）：Screen 页头与返回、触屏下拉刷新、指针设备刷新键、内嵌 PluginView、「加载更多」（同一游标只请求一次），有文档页与 demo。
  - **插件页面的数据与动作**（`spec/plugin-view-vectors.json` 的 `rules.page`、`pageRows`、`pagePaging`、`pageFilters` 与同名四段）：
    - `FlarePluginPage` 新增必填的 `page: FlarePluginPageRef`（`{pluginId, page}`）；`view` 改为 `FlarePluginPageViewModel`，带 `data`。
    - 页面里执行的每个动作都发出 `action(id, FlarePluginPageActionPayload)`，载荷为 `{page, data?, row?, selection?, formValues?}`，在确认与表单之后。它就是 `invokePageAction` 的请求。
    - 新增 `filters` 与 `filter(values)`：rows 块列出的 select 输入画成 FilterTabs，「全部」在前。
    - 不可用的页面显示原因空态，只有 catalog_unreachable 带重试；页头保留宿主标题。
    - **删除** `openDetail`，页面视图没有详情。
  - **rows 的列表画法**：`FlarePluginView` 新增 `rowsLayout`（`table` 为默认，用于控制台；`list` 用于插件页面）。
    - 列表的每一项是徽标加第一格，其下是其余单元格（以「 · 」连接），行尾是动作键。
    - 两种画法都按 key 去重，保留第一次出现的行。
  - **收尾（四端对齐）**：
    - 刷新结束（`refreshing` 由真变假）也会忘掉已请求的游标，刷新回第一页拿到同一游标时「加载更多」不会一直转圈。
    - 行动作只有发起的那一行转圈，同一动作 id 的其余行禁用但不转。
    - `FlareFilterTabs` 新增 `enabled`（默认 true）：为假时整行变淡、每个标签禁用、不报告选择；页面筛选改用它，不再包 fieldset。
    - `FlareFilterTabs` 的 filled 行（md 与 sm）保持胶囊画出来的高度，命中区用 `::after` 补到 `layout.touchTarget`，滚动行以内距给出空间、负外距收回，版面不变高；粗指针下不再把胶囊撑到 48。grid 与 quiet 行不变。
  - **徽标**：entries 的条目与 rows 的行支持 `badge {text, tone}`，用 `FlareTag` 画；未知 tone 按 neutral（`flarePluginBadgeTone`）。
  - **多选上限**：choices 支持 `maxSelections`。草稿选满后，草稿以外的选项 `aria-disabled` 且变灰；提交要求不超过上限；页脚显示「最多选 {n} 项」。新增 `flarePluginChoiceCap`、`flarePluginChoiceCapped`、`flarePluginWithinCap`。
  - 新增纯函数 `flarePluginRowsOnce`、`flarePluginRowLines`、`flarePluginPageState`、`flarePluginPageFilters`、`flarePluginPageFilterValues`、`flarePluginPagePayload`，以及文案 `pluginView.all`、`pluginView.maxSelections`。
  - **红包第五版**：`FlareRedPacketCard` **删除** `amount` 与 `kindLabel`，新增 `kind`（拼手气、专属角标）与 `recipientName`（「给 某某」），`state` 改为 `FlareRedPacketCardState`（unopened / viewable / claimed / finished / expired / refunded；`flareRedPacketCardState` 由公开层与本人层得出），卡片永不显示金额。`FlareRedPacketOpenSheet` 新增 `canViewDetails`，notEligible 永不给详情入口。`FlareRedPacketDetail` 改为按 `viewerRole` 渲染服务端结果：新增 `details: FlareRedPacketDetailsView` 与 `designatedName`，**删除** `blessing`、`kindLabel`、`amount`、`amountNote`、`summary`、`note`；`FlareRedPacketClaim` 改为 `{id, name, avatar?, amountMinor, claimedAtMs, best}`。新增 `flareRedPacketAmountText` / `flareRedPacketMoney`（按 `currencyExponent` 整数运算）、`flareRedPacketDetailTexts`、`flareRedPacketTime` 等纯函数，规则见 `spec/red-packet-vectors.json`。
- 第七轮 Kit 小缺口（app 接线反馈）：
  - `FlareContactDetail` 新增 `primaryActionBusy`：宿主执行主操作（如发送好友申请）期间，主按钮以转圈代替图标、禁用并带 `aria-busy`，颜色不变；发消息、通话、资料行和页脚照常可用。`busy` 仍禁用全部。
  - `FlareContactPicker` 新增 `sending`（与 `FlareLocationPicker` 的 `sending` 同义）：单选时被点的那一行高亮转圈（`aria-busy`、`aria-selected`），多选时确认键转圈；各行与确认键禁用，取消、搜索和标签照常。清掉后单选忘掉那一行，多选保留已选供重发。
  - `./contracts` 新增 `flareLocationWebMapUrl(location, provider?)`（宿主自己打开地点时的网页地图地址：参数优先、其次内容、默认 osm；缺坐标、超范围或线上的 0, 0 返回 null）和 `flareLocationProviderFrom(value)`（`chat.location` 配置值转服务商：`amap` 去空白不区分大小写为高德，其余为 osm）。规则见 `spec/location-vectors.json` 的 `webMapUrl`、`providerFrom`。时间线的位置适配层改用后者读载荷的 provider。
  - `./utils` 新增 `createFlareBrowserLocationHost(options?)`：浏览器 / webview 的 `ensurePermission` 与 `requestCurrentLocation`。Permissions API 能答就照答；prompt 或答不上来时发起一次定位弹出授权框，只有拒绝算 false；非安全上下文或没有 geolocation 直接 false；授权那一步拿到的定位留给下一次定位。导入时不读 `navigator`。
- 第六轮验收修复（插件卡片详情入口、inset）：
  - `FlarePluginView` 卡片级「查看详情」：`view.detail` 为真、没有 entries 块在显示「查看全部」、可用、非 embedded、没有 rows 块，并且宿主监听了 `openDetail` 时，在动作区下方画整宽的 quiet 文字按钮（size sm，文案 `pluginView.detail`），点击发出不带 row 的 `openDetail`；`busy` / `busyActionId` 时禁用。投票、日程、任务、公告卡片因此能打开详情。
  - `FlarePluginViewInset` 新增 `sheetTop`（上 md、左右 lg、下不留），用于 PluginForm 上方的前言，两者之间只剩表单自己的 md。
  - `inset` 现在作用于所有状态：embedded 的内容（含不可用态），以及宿主留在面板里的卡片外壳（加在外壳外面）。不可用的 embedded 视图把标题显示为一行次要文字。
- 插件卡片结算信号：`FlarePluginView` 新增 `settleToken`（整数，宿主每完成一次动作加 1，并且先设好这次结果的 `error` / `formErrors`）。每次变化都结算：没有错误时关闭已提交的表单面板，乐观选中保留到新视图；有 `error` 时撤回乐观选中，表单留着并显示它；有 `formErrors` 时表单留着，表单携带的选中一并撤回。`busyActionId` 离开该动作仍作为兜底。宿主在同一帧里设上又清掉 `busyActionId` 时，只能靠 `settleToken` 结算。规则见 `spec/plugin-view-vectors.json` 的 `rules.settle` 和新增的 optimistic 场景。
- `FlarePluginView` 新增 `inset`（`FlarePluginViewInset`：`none` / `sheet`）：embedded 加 `inset="sheet"` 时，按底部面板留白（上 md、左右 lg、下 xl，与 `FlarePluginForm` 一致），直接放进 `FlareBottomSheet` 时不用再包一层。
- `FlarePluginDetailSheet` 新增 `actionError`、`formErrors`、`members`、`settleToken`，原样交给内嵌 PluginView。详情里的动作在面板内转圈、出错、收表单、结算，失败不会落到面板下面的卡片上。已有的 `error` 仍表示加载失败。
- `FlarePluginDetailSheet` 支持 detail 分页：
  - 视图带 `nextCursor` 时，在内嵌视图下方显示「加载更多」，点击发出 `loadMore(cursor)`。新增 prop `loadingMore`。
  - 已请求的页在游标换掉之前不会再请求；`loadingMore` 由真变假、`settleToken` 变化或 `actionError` 变为非空后允许重试。
  - `FlarePluginViewModel` 新增 `nextCursor`，rows 块新增 `filters`。
  - 新增纯函数 `flarePluginNextCursor`、`flarePluginFilterInputs`（`./contracts`，后者也从 `./admin` 导出）。管理页筛选栏只显示 `filters` 列出的输入，不带 filters 时显示全部输入。
- `FlareBottomSheet` 新增 `fill`（定高模式，同 `FlareModal` 的 `fill`）：面板占满整个 `maxHeight`，内容撑满剩余高度并自己滚动。新增 `useFlareSheetOwnHeader()`（`./composables`）：自带标题栏的内容在 setup 里声明后，fill 面板只把 `title` 当可及名称，不画第二个标题。`FlareLocationPicker`、`FlareContactPicker` 已声明。`FlarePluginForm` 的成员选择改用 fill。
- `FlareLocationPicker` 新增：
  - `sending`：发送键转圈并禁用，不会重复发送。
  - `ensurePermission`：返回 `Promise<boolean>`，每次定位前先等它；系统权限弹框的等待不计入 `locateTimeoutMs`，返回 false 时直接进入 denied。
  - previewUrl 的宽高按 `flareLocationPreviewSize`（新导出，`./contracts`）计算：逻辑尺寸乘屏幕倍率（限制在 1 到 2 之间）后取整，见 `spec/location-vectors.json` 的 `previewSize`。
- `FlareFriendRequest` 新增 `source`，`FlareNewFriendRequests` 把它画在验证消息下方单独一行（次要文本、单行省略）。
- `FlareContactDetail` 新增 `primaryActionLabel` 与 `primaryAction` 事件：给陌生人的主操作（如「添加到通讯录」）排在操作行首位，作为主按钮；此时「发消息」改为次要键。它不放进页脚的 `extraActions`。
- 「+」面板默认集去掉 poll，改为 image、camera、video、file、voice、location、card。投票改由插件提供；`FlarePollComposer`、`FlareVoteMessage` 保留，用于显示历史消息。
- `registerFlareMessages` 合并时复制子树，Kit 的文案树不再引用宿主的对象。
- `@flare-im/vue-ui/admin` 新增导出 `FlarePluginView`、`FlarePluginForm`、`FlarePluginDetailSheet` 和插件视图类型。
- 包的 `tsconfig.json` 打开 `noUnusedLocals`、`noUnusedParameters`。开了这两项的宿主现在可以直接编译 Kit 源码，清掉了 13 处未用到的局部变量和导入，`FlareRadioGroup` 的 `props` 是其中之一；`EnhancedComposer` 的 `v-model:richTitle` 保留。
- 插件卡片 v2：`FlarePluginView` 渲染核心 SDK 的 ResolvedPluginView v2——外壳与 Kit 业务卡片一致（宽 richCardWidth，标题行图标位 `icon`），块 text（`maxLines` 加「展开」）、fields、choices（单选点即提交、多选键名取块动作的 label、结果条 / 百分比 / 票数、打勾、「已结束」、乐观选中与失败撤回）、entries（「查看全部（total）」发 `openDetail`）、people、status、progress、time（本地时区格式化与倒计时）、divider、note、rows（控制台管理页：FlareDataTable、行动作、点行打开详情、`loadMore(cursor, source)`）；动作 `style`、`confirm`（Kit DangerConfirm）、`form`（底部面板里的 `FlarePluginForm`）。新增 prop `busyActionId`、`embedded`、`resolveUser`、`members`、`formErrors`；**破坏性**：`action` 改为 `(actionId, payload)`，payload 为 `{selection?, formValues?, row?}`。v1 视图照旧显示。
- 新增 `FlarePluginForm`（text、textarea 带计数，number，toggle，select 单选列表，datetime 用 Kit DatePicker 与 TimePicker，options 可增删的行，members 用 `FlareContactPicker`；客户端只查必填和长度，宿主 `errors` 优先）与 `FlarePluginDetailSheet`（加载中、出错重试、内嵌 PluginView）。新增 `FlarePluginViewModel` 等 v2 类型与 `flarePluginTimeText`、`flarePluginCountdown`、`flarePluginCheckForm`、`flarePluginFormValues`、`flarePluginIssueText`、`flarePluginFallbackName` 等纯函数（`./contracts`），规则见 `spec/plugin-view-vectors.json`。新增文案 `pluginView.*`、`pluginForm.*`。
- 位置：provider 为 osm 时，`FlareLocationMessage` 与 `FlareLocationPicker` 在静态图右下角显示「© OpenStreetMap contributors」（`location.osmAttribution`），amap 时不显示；`FlareLocationPicker` 新增 `provider`（默认 osm）。
- 位置：新增 `FlareLocationPicker`（选点面板内容：静态地图加中心点与「定位到当前位置」键、搜索框、首行为当前位置的地点列表、发送键）。定位、逆地址、周边搜索和静态图都由宿主回调提供（`requestCurrentLocation`、`reverseGeocode`、`searchNearby`、`previewUrl`），`initialLocation` 立即显示上次位置，`locateTimeoutMs`（默认 5000）后先用它；状态 locating / located / denied / searching / noResults / mapUnavailable。
- **破坏性**：`FlareLocationMessage` 的 `mapImage` 改名为 `snapshotUrl`，新增 `latitude`、`longitude`、`provider`（osm / amap）；没有静态图或加载失败时画地图底纹加中心点；不监听 `open` 时按服务商链接到 OpenStreetMap 或高德网页地图（`spec/location-vectors.json`），不再链接 Google 地图。新增 `flareLocationMapLinks`、`flareLocationCoordinateLabel`、`flareLocationDistanceLabel` 与类型 `FlareLocationProvider` / `FlareLocationCoordinate` / `FlareLocationAddress` / `FlareLocationPlace` / `FlareLocationValue`（`./contracts`）。
- 名片：新增 `FlareContactPicker`（分组标签、搜索、超过 60 行开窗的列表、空态，自己的行带「（我）」；单选点一行即 `select`，多选由「确定」回传，按勾选顺序）与 `FlareContactPickerEntry`、`FlareContactPickerGroup`、`matchesFlareContactPickerEntry`。`FlareContactMessage` 新增 `userId`，`open` 回传它；不监听时只展示，不画箭头。
- `MessageList`、`MessageBubble`、`MessageContentView` 新增 `cardOpen`（消息 ID、用户 ID）与 `locationOpen`（消息 ID、`FlareLocationValue`）；时间线把线上的 0, 0 当作没有坐标。
- 「+」面板默认集改为 image、camera、video、file、voice、location、card、poll（`FLARE_DEFAULT_COMPOSER_ACTION_IDS`）。
- 图标 `locate`（注册表最后一项，共 108 个，Lucide `LocateFixed`）：选点面板「定位到当前位置」键的准星，与地图钉 `location` 区分。新增文案 `location.*`、`contactPicker.*`。
- 输入栏：`FlareComposerCapabilities` 新增 `availableToolIds`（`FlareComposerToolId`：`emoji` / `mention` / `voice` / `image` / `richText` / `attachments`，`attachments` 即「+」按钮），不传时全部显示，传了只显示列出的工具，语义与 Flutter 一致；收回某个工具时同时关掉它打开的面板，草稿保留，`richMode` 也不再呈现。新增 `composerToolAvailable`、`FLARE_COMPOSER_TOOL_IDS`（`./contracts`）。
- 「+」面板默认集改为内置功能 image、video、file、voice、card、poll（图标 image / video / file / mic / card / poll），去掉 location 与 contact；`FlareComposer` 与 `FlareComposerActionPanel` 共用 `FLARE_DEFAULT_COMPOSER_ACTION_IDS` / `FLARE_COMPOSER_ACTION_ICONS`。**破坏性**：`FlareComposerAction.label` 改为可选，不传时按 id 取 Kit 文案（`labelComposerActions`、`FLARE_COMPOSER_ACTION_LABEL_KEYS`，新增 `composer.poll`）；新增可选 `kind`（`FlareComposerActionKind`：feature / plugin）。
- 图标 `plugin`（注册表最后一项，共 107 个，Lucide `Puzzle`）：「+」面板里图标名不在注册表里的项画它（`resolveComposerActionIcon`）。
- 新增 `FlareFilterBar`、`FlareDescriptionList`、`FlareCodeBlock`、`FlareTag` 与类型 `FlareDescriptionItem` / `FlareDescriptionLabelPlacement` / `FlareDescriptionValue`（`./components`）、`FlareConfirmReason` / `FlareConfirmInput` 与 `confirmReasonBytes`（`./contracts`）：控制台查询栏、详情描述列表、原始报文代码块与状态标签；`FlareDataTablePagination.total` 可省略并新增 `hasNext`（游标分页）；`FlareDangerConfirm` / `useFlareConfirm` 新增 `reason` 与 `confirmPhrase`，`confirm` 上报 `{ reason }` 并交给 `action`；`FlareConfirmRequest` 新增 `id`；`FlareStatusBanner` 新增 `title`、`dismissible` 与 `dismiss` 事件；`FlareNavigationItem.href` 让导航项成为链接（修饰键点击交给浏览器，href 过新增的 `safeNavigationHref`）。详见仓库根 CHANGELOG。
- 新增 `FlareDataTable`、`FlarePermissionTree` 与类型 `FlareDataTableColumn` / `FlareDataTablePagination` / `FlareDataTableSort` / `FlarePermissionNode`（`./components`）：控制台数据表格（排序 / 分页只上报意图、跨页三态多选与批量工具条、列设置、窄容器堆叠）与三态权限树（只接叶子权限码、搜索保留祖先、WAI-ARIA 树键盘）。详见仓库根 CHANGELOG。
- 新增 `FlareMetricTile`、`FlareChartCard` 与类型 `FlareChartPoint`（`./components`）：仪表盘指标卡与柱状 / 折线图卡片，纯 SVG、只用 token，数值同时以文字提供。详见仓库根 CHANGELOG。
- 图片、视频、文件保存后，下载键变成「在文件夹中显示」；宿主发现文件被删后传回 idle，键回到下载。收发两侧的消息时间都在右侧。详见仓库根 CHANGELOG。
- 新增 `useMessageMediaSaves`（宿主只接 save / isSaved / reveal）；`FlareFileMessage` 新增 `reveal` 事件，`VideoPlayerModal` 新增 `saved` + `reveal`；`MessageMediaDownloadUiState` 从 `./contracts` 导出。
- **许可证由 MIT 变更为 Apache-2.0。** 已发布的 1.0.5 及更早版本仍按 MIT 授权，
  本次变更仅对之后的版本生效。Apache-2.0 含显式专利授权条款。

## 1.0.5

- 修正 README 引入说明：改为从公共仓库/GitHub 引入，不再是 monorepo 本地路径。
- 修正 README 内指向仓库其他目录的相对链接（发布产物中为死链），改为 GitHub 绝对地址。

## 1.0.4

首个公开发布版本。

### 组件文案可覆盖
- 组件不再把界面语言写死：默认文案为中文，宿主可整体覆盖。
- Android 新增 `FlareStrings` 环境值，用 `CompositionLocalProvider` 一处覆盖；
  取值方式与 `flareColors()` 一致，组件内无需逐层传参。
- Flutter 沿用该端既有惯例（构造默认值 / `?? 回退` / `labels`），补齐尚未可覆盖的项。
- 两端日期组件的星期名与年月标题改用各自框架的区域数据，随宿主 locale 自动切换。
