# Example Parity（2.0.0-rc.1）

五个参考应用对同一套任务的覆盖，每格只允许 `PASS_RUNTIME` / `PASS_TEST` / `PASS_BUILD` / `SIMULATED` /
`UNSUPPORTED` / `FAIL`（`2.0-release-criteria.md` §3）。Web 是 Golden Reference，其余四端与之对照。

## 这份表怎么读

值只说**证据到哪一级**，不说功能好不好。判定规则，逐格可核：

- `PASS_TEST` —— 这个 app 自己的自动化测试里有一条**断言这件事本身**的用例。括号里是那个文件；
  每一格都对着用例标题核过，文件名对得上但断言的是别的行为，不算。
- `PASS_BUILD` —— 代码接好了、这一端能构建，但没有任何测试断言这个行为。
- `SIMULATED` —— 只在组件库自己的 fixture 内核上验过（website 的 Playwright 套件），没有真服务端。
- `UNSUPPORTED` —— 这一端**故意**不提供，见 `platform-fallback-policy.md`。
- `PASS_RUNTIME` —— 对真服务端、用真账号跑通过。**本表没有任何一格是它。**

**为什么没有 PASS_RUNTIME**：这一轮没有登录态通路 —— 不注册账号、不输凭据、不跑已登录测试是这个程序的约束，
所以五端的证据天花板就是 `PASS_TEST`。历史上有过一次 Web 生产同源登录与双向文本的实测记录
（见 `2.0-reference-app-feature-matrix.md` 的 Evidence 段），但那份证据已经 STALE（`LIVE-WEB-SDK` 当前状态即是），
把它写成今天的 `PASS_RUNTIME` 是拿旧条子当新证据。`native-capability-matrix.md` 对原生能力也采同一口径。

各端证据来源：Web 8 个测试文件、Tauri 5 个校验脚本（`check:message-order` / `check:session-title` /
`check:session-mention` / `check:image-send` / `check:kit-reference`）、Flutter 16 个测试文件、
Android 11 个测试文件（JVM 单测 + 仪器化）、iOS 只有 `xcodebuild` 模拟器构建（app 层测试在 macOS 上必然链接失败，
因为 Rust FFI 只交叉编译了模拟器切片，见 app 自己的 README）。

## 任务 × 应用

| 任务 | Web | Tauri | Flutter | Android | iOS |
| --- | --- | --- | --- | --- | --- |
| 登录与会话恢复 | PASS_TEST (session-restore.test.ts) | PASS_BUILD | PASS_TEST (search_states_test.dart) | PASS_TEST (SignedInPagesTest.kt) | PASS_BUILD |
| 会话列表 | PASS_BUILD | PASS_TEST (check:session-title) | PASS_TEST (base_shell_test.dart) | PASS_TEST (SignedInPagesTest.kt) | PASS_BUILD |
| 打开会话与翻历史 | PASS_TEST (timeline.test.ts) | PASS_TEST (check:message-order) | PASS_TEST (chat_timeline_view_model_test.dart) | PASS_TEST (TimelinePagingTest.kt) | PASS_BUILD |
| 收发文本 | PASS_BUILD | PASS_TEST (check:message-order) | PASS_TEST (im_client_test.dart) | PASS_TEST (MessageContentMappingTest.kt) | PASS_BUILD |
| 图片发送 | PASS_BUILD | PASS_TEST (check:image-send) | PASS_TEST (picture_send_test.dart) | PASS_TEST (ImageSendTest.kt) | PASS_BUILD |
| 文件发送与保存 | SIMULATED | SIMULATED | PASS_TEST (gallery_save_test.dart) | PASS_TEST (GallerySaveTest.kt) | PASS_BUILD |
| 已读 | PASS_BUILD | PASS_BUILD | PASS_TEST (chat_screen_test.dart) | PASS_BUILD | PASS_BUILD |
| 置顶 | PASS_BUILD | PASS_BUILD | PASS_BUILD | PASS_TEST (FacadesTest.kt) | PASS_BUILD |
| 撤回与编辑 | PASS_BUILD | PASS_BUILD | PASS_TEST (im_client_test.dart) | PASS_BUILD | PASS_BUILD |
| 转发与合并转发 | PASS_TEST (chat-operations.test.ts) | PASS_BUILD | PASS_BUILD | PASS_BUILD | PASS_BUILD |
| @ 提及 | PASS_BUILD | PASS_TEST (check:session-mention) | PASS_BUILD | PASS_BUILD | PASS_BUILD |
| 引用与定位 | PASS_TEST (timeline.test.ts) | PASS_BUILD | PASS_TEST (quote_time_mapping_test.dart) | PASS_TEST (QuoteLocateTest.kt) | PASS_BUILD |
| 富文本发送 | SIMULATED | SIMULATED | SIMULATED | PASS_TEST (RichDocSendTest.kt) | PASS_BUILD |
| 长按 / 右键菜单 | SIMULATED | SIMULATED | SIMULATED | SIMULATED | SIMULATED |
| 搜索 | PASS_TEST (directory-search.test.ts) | PASS_BUILD | PASS_BUILD | PASS_BUILD | PASS_BUILD |
| 来电 | SIMULATED | SIMULATED | UNSUPPORTED | SIMULATED | SIMULATED |
| 离线 / 重连 | PASS_TEST (sdk-events.test.ts) | PASS_BUILD | PASS_TEST (base_shell_test.dart) | PASS_TEST (PresenceProjectionTest.kt) | PASS_BUILD |
| 失败与重试 | PASS_TEST (directory-failures.test.ts) | PASS_BUILD | PASS_TEST (social_failures_test.dart) | PASS_BUILD | PASS_BUILD |
| 暗色 | SIMULATED | SIMULATED | SIMULATED | SIMULATED | SIMULATED |
| 断点与窄栏 | SIMULATED | SIMULATED | SIMULATED | SIMULATED | SIMULATED |
| 安全区 | SIMULATED | UNSUPPORTED | PASS_BUILD | PASS_BUILD | PASS_BUILD |
| 原生能力：文件 / 图片 / 相机 | SIMULATED | SIMULATED | PASS_TEST (gallery_save_test.dart) | PASS_TEST (GallerySaveTest.kt) | PASS_BUILD |
| 原生能力：分享 / 剪贴板 / 返回 | SIMULATED | SIMULATED | PASS_BUILD | PASS_BUILD | PASS_BUILD |
| 媒体预览与文件条 | PASS_BUILD | PASS_BUILD | PASS_TEST (chat_media_test.dart) | PASS_BUILD | PASS_BUILD |
| 圈子 / Moments | PASS_TEST (report.test.ts) | PASS_BUILD | PASS_TEST (moments_view_model_test.dart) | PASS_BUILD | PASS_BUILD |
| 群资料与成员 | PASS_TEST (directory-failures.test.ts) | PASS_BUILD | PASS_TEST (group_detail_screen_test.dart) | PASS_TEST (PersonDisplayTest.kt) | PASS_BUILD |
| 好友资料与申请 | PASS_TEST (directory-search.test.ts) | PASS_BUILD | PASS_TEST (friend_requests_screen_test.dart) | PASS_BUILD | PASS_BUILD |

## UNSUPPORTED 的两格

- **Flutter 来电**：Flutter 端捆绑的 RTC 桩明确声明不可用并拒绝 start —— 它绝不假装建立了通话。
  对应 `platform-fallback-policy.md` 的「能力不可用时如实拒绝」。
- **Tauri 安全区**：桌面窗口没有刘海与手势条，安全区不是这一端存在的概念。

## 这张表说明不了什么

- 它不证明任何一格在真设备、真服务端上成立 —— 天花板是 `PASS_TEST`，理由在上面。
- `SIMULATED` 的格子只说明组件库这一层验过；应用那一层是否接对了，没有证据。
- `PASS_BUILD` 是「构建得出来」，不是「跑得对」。一格从 `PASS_BUILD` 升到 `PASS_TEST` 的唯一方式是给它写测试。
