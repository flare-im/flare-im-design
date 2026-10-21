## 未发布

- 自定义内容渲染器：`flareContentRenderers(_:bare:)` 列出的类型不画气泡（保留头像、昵称、时间、多选和长按菜单）；`FlareContentContext` 新增 `messageId`（服务端 ID，没有时用 client ID）与 `conversationId`（来自 `MessageListView` 的 `conversationId`）。
- 图标 `red-packet`（注册表最后一项，共 106 个）：`IconView`、按钮、「+」面板、菜单和消息操作面板画 Kit 自绘的线性小信封；直接 `Image(systemName:)` 的地方退为 `envelope`。
- `RedPacketDetailView` 新增可选 `title`、`onBack`（自带红色标题栏）；`RedPacketComposerView` 新增 `locked`；`SegmentedControlView` 新增可选 `accent`。
- 红包组件族：新增 `RedPacketOpenSheet`（`flareRedPacketOpenSheet(isPresented:onDismiss:sheet:)` 呈现）、`RedPacketDetailView`、`RedPacketComposerView`、`RedPacketPayConfirmView`，四端合同见 `docs/plugin-components.md`。
- **破坏性**：`RedPacketCardView` 去掉 `opened` / `finished`，改为 `state`（`FlareRedPacketState`：unopened / claimed / finished / expired）并新增 `kindLabel`；已领完、已过期的卡片仍可点击（查看详情），只有 `busy` / `disabled` 不可点。
- `SegmentedControlView` 的命中区覆盖整条轨道高度，轨道高度提到触控目标（44）。
- 图片、视频、文件保存后，下载键变成「在文件夹中显示」；宿主发现文件被删后传回 idle，键回到下载。收发两侧的消息时间都在右侧。详见仓库根 CHANGELOG。
- `FileMessageView` 新增 `downloadState` / `onReveal`，图标与文案改用 kit 的；`ImagePreviewView` / `VideoPlayerView` 新增 `saved` / `onReveal`；列表、气泡、分发器新增 `onMediaReveal`。
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
