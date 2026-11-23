# Flutter目录与活动列表

`FlareScreen`为被push的独立页提供Material绘制面与明确的默认正文样式，避免继承WidgetsApp调试下划线。
可选`contentMaxWidth`统一限制整个页头/内容/底栏；目录使用tokens真源的`directoryContentMaxWidth`，宽屏880、窄屏自然满宽。
不自行更换字体体系、不建立业务色表；导航返回、安全区和主题仍由原Kit负责。

`FlareGroupList`文字列Expanded、群名单行省略；有点击动作时显示详情箭头。不负责检索API、群权限或成员变更。
App将`FlareSearchBar`与既有目录加载/错误/空态组合，本地搜索不改变已加载源数据。

`FlareActivityList`接收纯展示`FlareActivityItem`（标题/摘要/时间/头像/未读），复用Avatar和UnreadBadge。
业务受众、分类标签、应用范围、绝对计数和已读写入由Social SDK/宿主提供，Kit不自行加减计数或标记已读。
长文本限定行数；footer用于有界分页或重试。跨端tokens已正常生成；Vue/Swift/Compose的对应互动收件箱UI未在此轮实现。

本轮为共享组件与受控夹具验证，尚无新运行App电脑截图，不把390px组件测试称为真机或已发布验收。

## 圈子连续阅读面

`FlareMomentCard.presentation`支持`FlareMomentPresentation.feed`：动态、点赞和评论统一使用`bgPrimary`，
没有外层圆角/阴影或内层深色互动卡片；帖子以主题分隔线和统一内边距区分。默认`card`仍用于独立详情。
App仅选择展示模式并铺满相同背景，封面继续使用原`FlareMomentsCoverHeader`，不自建视觉规则。

时间与更多按钮单独一行，展开的动作组在下一行按可用宽度换行；动作复用`FlareButton`，保持键盘焦点和触控区。
未提供的回调为禁用态，不用空包装回调伪装可用。删除/举报的业务归属和宿主确认流程不变。
Flutter为本轮范围，Vue/SwiftUI/Compose对应卡片已核对，未自动改变其现有外观。

验证：320/390/768/1360宽、明暗主题、1.3倍文字、长作者/正文/评论、动作展开及回调等10项新测试，
既有人员控件7项和相关图标无障碍1项通过；App四个明暗/宽度组合、空/错态6项与发布保存保护3项通过。
定向Dart分析通过。受控源码渲染图（非运行栈、非真机）位于`/private/tmp/flare-moments-flat-final.6n1io9/`。

2026-10-19补充：仅圈子feed视觉组件与页面选择已窄更新原Alice App，1360×932桌面及391×932手机宽度的
明暗真实界面、更多动作、发布及可见范围弹层已电脑检查。目录/活动业务增量不随本次发布；手机宽度不等于真机。
原会话/业务数据、FFI、原生Runner、entitlements和原bundle完整备份保留；见
[运行验收§8.14](../../flare-deploy/docs/flutter-console-full-acceptance-2026-10-18.md)。

## 圈子对齐 Vue（2026-11-18）

Flutter 圈子组件以 Vue kit 为准收敛（社交 app 的 web 对齐，清单见 `flare-social-examples/docs/web-parity/flutter.md` DM-15..18）：

- `FlareMomentCard`：动作只画宿主接了的（取代上文「未提供的回调为禁用态」）；一个都没有就不画「···」。展开的动作横排在键左侧、盖住时间，Esc 收起、焦点回到键。正文超过 280 字或 6 行折叠；评论超过 3 行（detail 5 行）折叠。`FlareMomentPresentation.detail` 给单独打开的一条动态用：正文不折叠，「评论 N」小标题与空评论说明，`focusCommentId` 标出并滚到那条评论。
- `FlareMomentComposer layout: page`：抽屉或整页里的发布页；`submitError` 横幅、就地编辑位置、`imagesSlot` 放 `FlareMediaUpload`。
- 新组件 `FlareMediaUpload`（图片网格上传位，宿主管选择、上传与预览）与 `FlareCommentComposer`（动态详情底部的评论框）。
- `FlareActivityList` 的 `compact`、`disabled` 与空态说明/动作；`FlareIconButton.dot`；`FlareMomentsCoverHeader.coverImage`。

本轮只写代码，未跑分析与测试；kit 里断言旧「禁用态」的两个测试已改为新规则。
