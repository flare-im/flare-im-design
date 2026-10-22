# 位置与名片组件

发送位置、选人发名片、点开名片进资料页。Kit 只画和管状态：定位、逆地址、周边搜索和静态图由宿主经回调提供（社交服务的地图代理），能分享谁、能不能加好友由宿主和服务端决定。设计见根仓 `docs/design/composer-panel-v2-plugins-location-card.md` 的「位置」「名片」两节。

## 四端组件

| 用途 | Vue / Web / Tauri | SwiftUI | Compose | Flutter |
|---|---|---|---|---|
| 位置消息卡片 | `FlareLocationMessage` | `LocationMessageView` | `LocationMessage` | `FlareLocationMessage` |
| 位置选点（面板内容） | `FlareLocationPicker` | `LocationPickerView` | `LocationPicker` | `FlareLocationPicker` |
| 选择联系人 | `FlareContactPicker` | `ContactPickerView` | `ContactPicker` | `FlareContactPicker` |
| 名片消息卡片 | `FlareContactMessage` | `ContactMessageView` | `ContactMessage` | `FlareContactMessage` |

四端 props、回调与数据类型以 `spec/components.json` 为准（`LocationMessage`、`LocationPicker`、`ContactPicker`、`ContactMessage`，数据类型 `LocationProvider`、`LocationCoordinate`、`LocationAddress`、`LocationPlace`、`ContactPickerEntry`、`ContactPickerGroup`），签名门禁逐端比对。共享规则表是 `spec/location-vectors.json`，四端测试读同一份。

## 位置消息卡片 `LocationMessage`

`latitude`、`longitude`（WGS-84）、`title`、`address?`、`snapshotUrl?`、`provider`（`osm` / `amap`，默认 `osm`）；回调 `open`。

- 上方地图区 264 × 132：有 `snapshotUrl` 时画静态图（地图代理签名、自带中心点），没有或加载失败时画地图底纹（街区网格加两条路，取主题面色）和中心点，不留空白。静态图按两倍尺寸请求。
- 下方地点名一行、地址一行；没有地址时显示坐标行（vectors → `label`，如「39.90870, 116.39750」）。
- **破坏性**：`mapImage` 改名为 `snapshotUrl`。
- 点击：宿主处理 `open` 时交给宿主。不处理时按 vectors → `links` 打开默认链接：

| 端 | 默认链接 |
|---|---|
| Vue | `web`：osm 为 `https://www.openstreetmap.org/?mlat=…&mlon=…#map=17/…/…`，amap 为 `https://uri.amap.com/marker?position=经,纬&name=…&coordinate=wgs84&callnative=0` |
| SwiftUI | `apple`：`http://maps.apple.com/?ll=纬,经&q=标题`（没有标题时 q 为坐标） |
| Compose | `geo`：`geo:纬,经?q=纬,经(标题)`（没有标题时不带括号） |
| Flutter | 按运行平台（vectors → `flutterTargets`）：iOS、macOS 用 `apple`，Android 用 `geo`，其余与 Web 用 `web`。Flutter Kit 不自带 URL 启动器，`FlareMessageContentView` 把链接交给宿主的 `onOpenLink` |

- 坐标：保留 6 位小数，去掉末尾的 0 和小数点，负零写作 0；坐标不是有限数或超出范围时不生成链接，卡片不可点。标题去掉首尾空白后按 UTF-8 百分号编码，只保留 `A-Z a-z 0-9 - . _ ~`，空格写作 `%20`。消息里一律是 WGS-84，高德链接用 `coordinate=wgs84` 告诉对方。
- 时间线适配层把线上的 0, 0 当作没有坐标（proto3 不写坐标时就是 0）。

## 位置选点 `LocationPicker`

放进带 `fill` 的 Kit 底部面板（Vue `<FlareBottomSheet fill>`，Flutter `FlareBottomSheet.show(fill: true)`，iOS `flareBottomSheet(..., fill: true)`，Compose `BottomSheet(fill = true)`）。面板占满高度上限，组件声明自带标题栏，面板不再画第二个标题，宿主也不用写定高容器。宿主回调：

| 回调 | 说明 |
|---|---|
| `requestCurrentLocation()` | 设备位置；失败（无权限、定位不到）转为手动搜索。权限申请和平台定位适配在应用里 |
| `ensurePermission()`（可选） | 宿主的权限步骤，返回 bool，每次定位前先等它。系统权限弹框的等待不计入 `locateTimeoutMs`，返回 true 后才开始计时；返回 false 时直接进入 `denied` |
| `reverseGeocode(lat, lng)` | 「当前位置」行的名称与地址；不传时该行显示坐标 |
| `searchNearby(lat, lng, query)` | query 为空是附近列表，否则是搜索；不知道位置时坐标为 null |
| `previewUrl(lat, lng, zoom, w, h)` | 地图区静态图，宽高为设备像素：逻辑尺寸乘屏幕倍率（限制在 1 到 2 之间）后取整，四端一致（vectors → `previewSize`）；返回 null、失败或图片加载失败时为「地图暂不可用」 |
| `send(place)` / `cancel` | 回传选中的 `LocationPlace`；宿主据此构造位置消息和卡片用的静态图 |

其余参数：`initialLocation`（上次位置，立即显示）、`zoom`（默认 16）、`locateTimeoutMs`（默认 5000）、`sending`（宿主发送中：发送键转圈并禁用，防止重复发送）。

- 布局：标题栏（取消、「位置」）；地图区高 168，右下角「定位到当前位置」键（图标 `locate`，准星）；搜索框；地点列表单选打勾，第一项是当前位置（id `current`）；底部「发送」。
- 首屏：有 `initialLocation` 时立即显示它和它的地图，否则显示骨架行，不等网络。
- 状态（四端同名）：`locating` 定位中；`located` 已定位；`denied` 无权限或失败，提示「无法获取定位，可以搜索地点」；`searching` 搜索中；`noResults`「附近没有找到地点」；`mapUnavailable` 地图区显示「地图暂不可用」和坐标，照样可以发送。
- 定位超时：从 `ensurePermission` 返回 true 起（没有它时从发起定位起）到 `locateTimeoutMs` 先用 `initialLocation`（没有时转手动搜索），之后到达的定位照样更新「当前位置」。
- 搜索防抖 300 ms，回车立即搜索；选中某行时地图跟着移动；POI 的距离按 vectors → `distance`（「240m」「1.2km」）。
- 无障碍：地点列表是单选组，定位中、无权限、无结果是礼貌播报区，地图是以所选地点命名的图片。

## 选择联系人 `ContactPicker`

`groups`（`ContactPickerGroup[]`）、`searchable`（默认 true）、`multiple`（默认 false）、`title?`；回调 `select(entries)`、`cancel`。和位置选点一样，放进带 `fill` 的 Kit 底部面板：组件自带标题栏（取消、标题、多选时的确认），面板只把 title 当可及名称。

- 分组标签：多于一组时显示；`friends`、`groupMembers` 用 Kit 文案「好友」「群成员」，其他 id 需要 `label`。
- 搜索匹配姓名和副标题，不区分大小写。空分组或没有匹配时显示「没有联系人」。
- 列表只构建屏幕上的行：Vue 超过 60 行开窗，原生与 Flutter 用各自的懒加载列表。
- 自己（`isSelf`）显示「（我）」，可以选。
- `select` 总是列表：单选时点一行回传一项；多选时点行切换，标题栏右侧「确定 (n)」按选中顺序回传。
- 能分享谁（`chat.card` 的 `scope`）由宿主过滤分组、服务端校验，Kit 不判断。

## 名片消息卡片 `ContactMessage`

新增 `userId`。宿主处理 `open` 时卡片可点，回传 `userId`（宿主进入资料页，来源记为名片，带上消息 ID 和推荐人）；不处理时只展示，不画右箭头。时间线：`MessageList` / `MessageBubble` / `MessageContentView` 四端都有 `cardOpen(消息, userId)` 和 `locationOpen(消息, 位置)`。Vue 时间线从载荷取 `userId`，或 `cardType` 为 `user`（或未写类型）时的 `id`，群名片等其他类型不可点；Flutter 与原生由宿主把 userId 放进名片内容（Flutter 为 `FlareCardContent.userId`），没有 userId 的名片不可点。

## 「+」面板

内置默认集（`composerActions.defaults`）四端同序：图片 `image`、拍摄 `camera`、视频 `video`、文件 `file`、语音 `voice`（图标 `mic`）、位置 `location`、名片 `card`、投票 `poll`。拍摄与位置由宿主处理（拍摄只在移动端出现，由 Social 的 composerMenu 按平台和功能开关决定）。

## 文案

原生 `FlareStrings`：`locationTitle`、`locationSend`、`locationLocateMe`、`locationLocating`、`locationDenied`、`locationSearchPlaceholder`、`locationNoResults`、`locationMapUnavailable`、`locationOpenInMaps`、`locationCurrent`、`contactPickerTitle`、`contactPickerFriends`、`contactPickerGroupMembers`、`contactPickerSearch`、`contactPickerEmpty`、`contactPickerSelfSuffix`；多选确认复用 `confirm`，取消复用 `cancel`；「+」面板用 `actionCamera`、`actionLocation`。英文见 `strings/en.json`。Vue 用 `location.*` 与 `contactPicker.*`。
