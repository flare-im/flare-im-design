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
[运行验收§8.14](/Users/hg/workspace/flare/flare-im/flare-deploy/docs/flutter-console-full-acceptance-2026-10-18.md)。
