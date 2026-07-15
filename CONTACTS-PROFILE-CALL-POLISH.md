# 通讯录 / 个人中心 / 音视频通话 / 布局 —— 充实美化 + 通话图标换线性

## 立意（frontend-design）
延续「考究的紫」token 体系:这四组组件目前偏简陋/用 emoji 当图标。目标——
- **音视频图标换成 @vicons/ionicons5 线性图标**（现用 emoji 🎙️🎥🔄📞💬 等"复杂图片"）。
- 通话界面从"平黑框"升级为有景深的通话屏（渐变底 + 头像光环 + 玻璃感控制条 + 状态/时长层次）。
- 通讯录/个人中心充实信息层次（ContactDetail 信息行、ContactList 字母索引、GroupList 等）。
- 布局（AppShell/ResponsiveLayout）视觉打磨。
- 全部走 token（色/圆角/阴影/动效），零硬编码色，保持 API 不破坏。

## 已知（浏览器实测）
- **CallControls**: emoji `🎙️`麦/`🎥`摄/`🔄`翻转/`📞`挂断（`<span class="ico">`）→ 换 Mic/Videocam/CameraReverse/Call 线性图标 + 开关态（MicOff/VideocamOff）。
- **ContactDetail**: 操作键 emoji `💬`Message/`📞`Voice/`🎥`Video；整体简陋（仅头像+名+签名+3键）。

## Status: 核心完成（通话+通讯录+个人中心+布局图标线性化 + 通话/ContactDetail 美化充实，浏览器验证）

## 已完成（逐一浏览器实测）
- **通话三件套**(`components/call/`)全重写:所有 emoji(🎙️🎥🔄🔊📞📵📹)→ @vicons/ionicons5 线性图标(Mic/MicOff、Videocam/VideocamOff、CameraReverse、VolumeHigh/Mute、Call 旋转 135° 作挂断);硬编码色 + 玻璃感控制键(backdrop-blur)+ 紫调渐变夜色底(radial 紫光 + linear 深色)+ 头像光环/呼吸动画(ringing/calling 脉冲、来电 bob)+ 加密标签 + 最小化键;IncomingCall 用 `<button>`(a11y);i18n `call.*` 命名空间(中英)。
- **ContactDetail** 充实 + 线性化:emoji(💬📞📹)→ ChatbubbleEllipses/Call/Videocam;新增在线态徽标(presence 点)、标签胶囊、信息卡(Flare ID/备注/地区/电话,有值才显)、次要操作(编辑/拉黑/删除,删除红);发消息键用品牌渐变;i18n `contact.*`;契约 `FlareContact` 补可选 remark/region/phone/tags(仅 Vue kit,零破坏)。
- **ContactItem**:补 presence 圆点(`showPresence` 声明了却没画)+ hover 底色 + 圆角。
- **个人中心/布局装饰字符 → @vicons**(host 传入的 string 图标不动):ProfilePanel `▦`→QrCode、SettingsRow `›`→ChevronForward、ProfileEditor `📷`→Camera、ResponsiveLayout `‹Back`→ChevronBack。
- **Demo 真 bug 修复**:SettingsListDemo `kind:"switch"`→`"toggle"`(契约无 switch,开关此前根本不渲染,现 3 个 toggle 正常)。
- 验证:vue-tsc 净 + 9 SFC 编译 + 14/14 测试;CallView/IncomingCall/ContactDetail/SettingsList 浏览器实测(SVG 图标数/无 emoji/toggle 数确认)。

## 追加：视频通话完善 + 群聊多人通话
- 新契约 `shared/contracts/call.ts`:`FlareCallMode/FlareCallState/FlareCallParticipant{id,name,avatarUrl?,muted?,cameraOff?,speaking?,isSelf?}`,进 contracts barrel + components barrel。
- 新组件 **`FlareGroupCallView.vue`**(群聊多人通话):参与者网格随人数自适应列数(≤1→1、≤4→2、≤9→3、else 4);每格画面经 `#tile="{ participant }"` scoped slot 由宿主注入,回退头像;静音/关摄像头角标(MicOff/VideocamOff)、**正在说话**绿框高亮、自己格紫底;头部=群名+人数+时长+加密+最小化;底部 CallControls 带**加人**。紫调渐变夜色底同单聊。
- `FlareCallControls`:加 `showAddMember` prop + `addMember` emit + PersonAddOutline 按钮(群聊时显示,挂断前)。
- i18n:`call.addMember/groupCall/participants`。
- 导出 `FlareGroupCallView` + 类型;demo `GroupCallViewDemo.vue`(5 人,1 说话/1 静音/1 关摄像头/自己)已注册;call-view.md 加"群聊多人通话"段。
- 验证:vue-tsc 净 + 109 SFC 全编译 + 14/14;DOM 确证 5 格/1 说话高亮/2 角标/5 控制键(含加人)/"5 人 · 12:07"、无 console 错误。单聊 CallView(紫调渐变+头像光环+加密标签)已截图确认。

## 后续（未做，可选）
- GroupList/NewFriendRequests 更深充实(群类型/最近活跃、accept 后 done 态)。
- AppShell 支持 @vicons **组件**图标(现 `FlareNavItem.icon` 是 string,demo 退化圆点)——需扩 icon 类型为 string|Component。
- ProfilePanel 默认 entries emoji(⭐🖼️⚙️)是 host 数据,同上受 string 类型限制。
- 各 call demo 多状态(audio/video、calling/ringing、静音/关摄像头)对比展示。

## 旧 Status 存档

## Steps
- [ ] 收 audit 报告：三通话组件所有 emoji/图片图标位置 + 建议 @vicons 名；四组"简陋点"。
- [ ] 通话三组件图标换线性（CallControls/CallView/IncomingCall）+ 通话屏景深美化。
- [ ] ContactDetail/ContactList/GroupList/NewFriendRequests 充实美化 + Voice/Video 图标换线性。
- [ ] 个人中心 ProfilePanel/ProfileEditor/SettingsList 打磨。
- [ ] 布局 AppShell/ResponsiveLayout 打磨。
- [ ] demo 充实（更真实数据/状态）。
- [ ] 浏览器逐一验证 + vue-tsc + SFC 编译 + 测试。

## Notes
- @vicons/ionicons5 通话候选：CallOutline/Call、VideocamOutline/VideocamOffOutline、MicOutline/MicOffOutline、CameraReverseOutline、VolumeHighOutline/VolumeMuteOutline、ContractOutline（挂断可用 Call 旋转 135°）。
