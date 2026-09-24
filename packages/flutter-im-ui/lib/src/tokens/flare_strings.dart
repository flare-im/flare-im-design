import 'package:flutter/widgets.dart';

/// 组件内联文案（无障碍标签、状态提示、空态等）。
///
/// 这些串原先直接写死在组件 build 里，宿主无法覆盖——对一个跨端组件库而言等于把
/// 界面语言焊死。改为环境值后默认仍是中文，需要其他语言的宿主在根部覆盖一次即可：
///
/// ```dart
/// FlareStringsScope(
///   strings: const FlareStrings().copyWith(send: 'Send'),
///   child: const MyApp(),
/// )
/// ```
///
/// 与 Android 的 `FlareStrings` / `LocalFlareStrings` 字段一一对应，方便两端对照。
/// 已有 `FlareXxxLabels` 参数的组件不受影响，两者可共存：组件优先用宿主传入的
/// labels，未传时回落到这里。
@immutable
class FlareStrings {
  /// The legacy labels object uses this value as its const default. Components
  /// treat that default as "use the environment string", while an explicit
  /// different label still wins.
  static const groupDetailDiscoverableDefault = '允许搜索到本群';

  const FlareStrings({
    // 通话
    this.microphone = '麦克风',
    this.camera = '摄像头',
    this.flipCamera = '翻转',
    this.speaker = '扬声器',
    this.hangUp = '挂断',
    this.callWaitingAnswer = '等待对方接听…',
    this.callCalling = '正在呼叫…',
    this.callRinging = '正在响铃…',
    this.callConnected = '已接通',
    this.callReconnecting = '正在恢复通话…',
    this.callFailed = '通话连接失败',
    this.callReturn = '返回通话', // en: Return to call
    this.callMinimize = '最小化', // en: Minimize
    // 输入区
    this.send = '发送',
    this.cancelReply = '取消回复',
    // 空态
    this.noContacts = '暂无联系人', // en: No contacts yet
    this.noResults = '未找到结果',
    this.noMessages = '暂无消息',
    this.noContent = '暂无内容',
    // 通用动作
    this.close = '关闭',
    this.closePreview = '关闭预览', // en: Close preview
    this.imagePreviewPrevious = '上一张', // en: Previous image
    this.imagePreviewNext = '下一张', // en: Next image
    this.imagePreviewPosition = _imagePreviewPosition, // en: {index} of {count}
    this.delete = '删除',
    this.report = '举报',
    this.manage = '管理',
    this.selectAll = '全选',
    this.retry = '重试',
    this.loading = '加载中',
    this.messagePending = '等待发送',
    this.messageSending = '发送中',
    this.messageSent = '已发送',
    this.messageDelivered = '已送达',
    this.messageRead = '已读',
    this.messageFailed = '发送失败',
    this.messageRetrying = '正在重试',
    this.messageEdited = '已编辑',
    this.messageReadOnce = '仅可查看一次',
    this.messageBurnAfterRead = '阅后即焚',
    this.messageExpired = '已过期',
    // 消息操作
    this.addReaction = '添加表情回复',
    this.readReceipt = '已读回执',
    this.readTab = _readTab,
    this.unreadTab = _unreadTab,
    this.noReadersYet = '还没有人读过',
    this.everyoneHasRead = '所有人都已读',
    this.selectedSuffix = '已选',
    this.forwardEach = '逐条转发',
    this.forwardMerged = '合并转发',
    this.messageBatchPin = '置顶', // en: Pin
    this.messageBatchPinSelf = '仅自己置顶', // en: Pin for me
    this.messageBatchClear = '清除选择', // en: Clear selection
    this.messageBatchExit = '退出多选', // en: Exit multi-select
    // 提及
    this.searchMembers = '搜索成员',
    this.everyone = '所有人',
    this.notifyEveryone = '通知所有成员',
    this.noMatchingMembers = '没有匹配的成员',
    // 快捷短语
    this.quickPhrases = '快捷短语',
    this.viewAll = _viewAll,
    // 正在输入 / 新消息
    this.typing = '正在输入…',
    this.typingOne = _typingOne,
    this.typingMany = _typingMany,
    this.newMessages = _newMessages,
    this.scrollToLatest = '回到最新', // en: Back to latest
    // 名片 / 群通话
    this.sendMessage = '发消息',
    this.groupCall = '群通话',
    this.joinedCount = _joinedCount,
    this.selfSuffix = _selfSuffix,
    // 转发选择
    this.forwardTo = '转发给',
    this.searchConversations = '搜索会话',
    this.noMatchingConversations = '没有匹配的会话',
    this.selectedCount = _selectedCount,
    // 群公告
    this.groupAnnouncement = '群公告',
    this.collapse = '收起',
    this.expand = '展开',
    // 红包
    this.packetClaimed = _packetClaimed,
    this.packetFinished = '已被领完',
    this.packetTapToClaim = '点击领取',
    this.packetBrand = 'Flare 红包',
    // 命令 / 翻译 / 名片码
    this.commands = '命令',
    this.noMatchingCommands = '没有匹配的命令',
    this.translating = '翻译中…',
    this.translatedBy = _translatedBy,
    this.translated = '已翻译',
    this.hideOriginal = '隐藏原文',
    this.showOriginal = '显示原文',
    this.scanToAddMe = '扫一扫加我',
    // 录音 / 投票
    this.cancel = '取消',
    this.releaseToCancel = '松开取消',
    this.voiceRecordingCancel = '取消录音', // en: Cancel recording
    this.voiceRecordingSend = '发送语音', // en: Send voice message
    this.conversationRowDraft = '[草稿] ',
    this.conversationRowMention = '[@我] ',
    this.createPoll = '发起投票',
    this.pollQuestionHint = '请输入问题',
    this.pollOptionHint = _pollOptionHint,
    this.removeOption = '删除选项',
    this.addOption = '添加选项',
    this.allowMultiple = '允许多选',
    this.submitPoll = '创建投票',
    this.chatBackground = '聊天背景',
    // 步进 / 日历
    this.decrease = '减少',
    this.increase = '增加',
    this.previousMonth = '上个月',
    this.nextMonth = '下个月',
    this.yearMonth = _yearMonth,
    this.ratingStars = _ratingStars, // en: {count} stars
    // 朋友圈
    this.unlike = '取消赞',
    this.like = '赞',
    this.comment = '评论',
    this.changeCover = '换封面',
    this.post = '发表',
    this.momentTextHint = '这一刻的想法…',
    this.addImage = '添加图片',
    this.pickLocation = '所在位置',
    this.pickVisibility = '谁可以看',
    this.more = '更多',
    this.momentActions = '动态操作', // en: Moment actions
    this.removeImage = '移除图片', // en: Remove image
    // 语音转文字 / 表情贴纸
    this.hideTranscript = '隐藏文字',
    this.showTranscript = '转文字',
    this.recent = '最近',
    this.searchEmoji = '搜索表情',
    this.noMatchingEmoji = '没有匹配的表情',
    this.emptyStickerPack = '该表情包暂无贴纸',
    this.sticker = '贴纸',
    // 加号面板
    this.actionImage = '图片',
    this.actionCamera = '拍摄',
    this.actionFile = '文件',
    this.actionLocation = '位置',
    this.actionCard = '名片',
    this.actionVote = '投票',
    this.actionTask = '任务',
    this.actionSchedule = '日程',
    this.actionVideo = '视频',
    this.actionLink = '链接',
    this.actionAnnouncement = '公告',
    this.actionNotification = '通知',
    this.actionMiniProgram = '小程序',
    this.actionTranslate = '翻译',
    // 来电
    this.incomingVideoCall = '邀请你进行视频通话',
    this.incomingVoiceCall = '邀请你进行语音通话',
    this.reject = '拒绝',
    this.accept = '接听',
    // 通用
    this.back = '返回',
    this.confirm = '确定',
    this.confirmCount = _confirmCount,
    this.memberCount = _memberCount,
    this.clear = '清除',
    this.wordCharCount = _wordCharCount,
    this.changeAvatar = '更换头像',
    this.qrCode = '二维码',
    this.myQrCode = '我的二维码', // en: My QR code
    this.play = '播放',
    this.pause = '暂停', // en: Pause
    this.download = '下载', // en: Download
    this.voicePlaybackFailed = '播放失败', // en: Playback failed
    this.videoLoadFailed = '视频无法播放', // en: This video can't be played
    // 权限提示（名词 / 动词短语 / 状态 / 说明）
    this.permissionNotifications = '通知',
    this.permissionStorage = '存储空间',
    this.permissionPhotos = '相册',
    this.permissionContacts = '通讯录',
    this.permissionLocation = '位置信息',
    this.permissionScreen = '屏幕录制',
    this.permissionVerbMicrophone = '使用麦克风',
    this.permissionVerbCamera = '使用摄像头',
    this.permissionVerbNotifications = '发送通知',
    this.permissionVerbStorage = '访问存储空间',
    this.permissionVerbPhotos = '访问相册',
    this.permissionVerbContacts = '访问通讯录',
    this.permissionVerbLocation = '获取位置信息',
    this.permissionVerbScreen = '录制屏幕内容',
    this.permissionThisFeature = '此功能',
    this.permissionTitle = _permissionTitle,
    this.permissionUndeterminedDescription = _permissionUndeterminedDescription,
    this.permissionDeniedDescription = _permissionDeniedDescription,
    this.permissionRestrictedDescription = _permissionRestrictedDescription,
    this.permissionUnavailableDescription = _permissionUnavailableDescription,
    this.permissionAllow = '允许',
    this.permissionOpenSettings = '前往设置',
    this.permissionStateUndetermined = '未授权',
    this.permissionStateDenied = '已拒绝',
    this.permissionStateRestricted = '受限制',
    this.permissionStateUnavailable = '不可用',
    // iOS 同名通用字段（Flutter 此前缺失）
    this.search = '搜索',
    this.noGroups = '暂无群聊',
    this.noConversations = '暂无会话', // en: No conversations
    this.groupMembers = '群成员',
    this.groupOwner = '群主',
    this.groupAdmin = '管理员',
    this.addMember = '加成员',
    this.loginDevices = '登录设备',
    this.currentDevice = '当前设备',
    this.filesAndMedia = '文件与媒体',
    this.notificationSettings = '通知设置',
    this.confirmAction = '确认',
    this.transferQueue = '传输队列',
    this.noTransfers = '暂无传输任务',
    this.retryFailedTransfers = '重试失败任务',
    this.reload = '重新加载',
    this.today = '今天',
    this.yesterday = '昨天', // en: Yesterday
    this.timeRange = '时间范围',
    this.searchIdleHint = '输入关键词或选择类型',
    this.permissionDismiss = '知道了',
    // Composer（输入区工具 / 富文本工具条 / 按住说话）
    this.composerPlaceholder = '发送消息',
    this.composerReply = '回复',
    this.composerVoice = '按住 说话',
    this.composerVoiceRecording = '松开发送 · 上滑取消',
    this.composerVoiceCancel = '松开手指，取消发送',
    this.composerBold = '粗体',
    this.composerItalic = '斜体',
    this.composerStrike = '删除线',
    this.composerUnderline = '下划线',
    this.composerCode = '代码',
    this.composerCodeBlock = '代码块',
    this.composerLink = '链接',
    this.composerParagraph = '正文',
    this.composerDivider = '分隔线',
    this.composerHeading = '标题',
    this.composerQuote = '引用',
    this.composerList = '列表',
    this.composerOrderedList = '有序列表',
    this.composerEmoji = '表情',
    this.composerMention = '提及',
    this.composerVoiceInput = '语音',
    this.composerRichText = '富文本',
    this.composerExpandInput = '展开输入',
    // InlineVoice（录音条）
    this.inlineVoiceMicrophoneUnavailable = '无法使用麦克风，请检查权限',
    this.inlineVoiceSendFailed = '发送失败，可重试',
    this.inlineVoiceKeyboard = '返回键盘并删除录音',
    this.inlineVoicePause = '暂停录音',
    this.inlineVoiceStart = '开始录音',
    this.inlineVoicePreview = '试听 / 暂停',
    this.inlineVoiceResume = '继续录音',
    this.inlineVoiceDiscard = '删除录音',
    // MessageList / UnknownMessage / EmojiPicker / StickerPanel / QuickPhrases / QrCard
    this.messageListLoadOlder = '加载更早消息',
    this.messageRecalledSelf = '你撤回了一条消息',
    this.messageRecalledPeer = '对方撤回了一条消息',
    this.messageRecalledGroupOther = _messageRecalledGroupOther,
    this.quotedMessage = _quotedMessage, // en: Quoted {name}: {summary}
    this.jumpedToMessage =
        _jumpedToMessage, // en: Jumped to {name}'s message: {summary}
    // 一句话摘要（会话行 / 回复条 / 气泡引用块）。与 Vue 的 `preview.*` 同名同义，
    // 规则见 spec/message-preview-vectors.json。
    this.previewMessage = '[消息]', // en: [Message]
    this.previewRichText = '[富文本]', // en: [Rich text]
    this.previewGif = '[动图]', // en: [GIF]
    this.previewImage = '[图片]', // en: [Image]
    this.previewImageNamed = _previewImageNamed, // en: [Image] {label}
    this.previewVideo = '[视频]', // en: [Video]
    this.previewAudio = '[语音]', // en: [Voice]
    this.previewFile = '[文件]', // en: [File]
    this.previewFileNamed = _previewFileNamed, // en: [File] {name}
    this.previewLocation = '[位置]', // en: [Location]
    this.previewLocationNamed = _previewLocationNamed, // en: [Location] {label}
    this.previewCard = '[名片]', // en: [Contact]
    this.previewCardNamed = _previewCardNamed, // en: [Contact] {label}
    this.previewSticker = '[贴纸]', // en: [Sticker]
    this.previewEmoji = '[表情]', // en: [Emoji]
    this.previewQuote = '[引用]', // en: [Quote]
    this.previewLink = '[链接]', // en: [Link]
    this.previewForward = '[转发]', // en: [Forward]
    this.previewForwardCount =
        _previewForwardCount, // en: [Forward] {count} messages
    this.previewMiniProgram = '[小程序]', // en: [Mini Program]
    this.previewImageGroup = '[多图]', // en: [Album]
    this.previewImageGroupCount =
        _previewImageGroupCount, // en: [Album] {count}
    this.previewSystem = '[系统消息]', // en: [System]
    this.previewNotification = '[通知]', // en: [Notification]
    this.previewVote = '[投票]', // en: [Poll]
    this.previewTask = '[任务]', // en: [Task]
    this.previewSchedule = '[日程]', // en: [Schedule]
    this.previewAnnouncement = '[公告]', // en: [Announcement]
    this.previewCustom = '[自定义]', // en: [Custom]
    this.previewPlaceholder = '[占位]', // en: [Placeholder]
    this.previewUnknown = '[未知]', // en: [Unknown]
    this.unknownMessageHint = '当前版本无法显示这条消息',
    this.unknownMessageUnsupported = '不支持的消息类型',
    this.unknownMessageDiagnostic = '消息类型',
    this.emojiPickerEmpty = '暂无表情',
    this.stickerPanelEmpty = '暂无贴纸',
    this.quickPhrasesTitle = '常用语',
    this.qrCardHint = '扫一扫，加我为好友',
    this.qrCardUnavailable = '二维码暂不可用',
    // ReadReceiptSheet / AnnouncementReadBar
    this.readReceiptSheetReadEmpty = '还没有人查看',
    this.readReceiptSheetUnreadEmpty = '所有人都已查看',
    this.announcementReadBarConfirmRead = '已读',
    this.announcementReadBarViewUnread = '查看未读',
    this.announcementReadBarReadCount = _announcementReadBarReadCount,
    // Contacts：NewFriendRequests / ContactMatchList / StartConversationSheet / UnknownUserPlaceholder
    this.newFriendRequestsEmpty = '暂无新的好友申请',
    this.newFriendRequestsAccept = '接受',
    this.newFriendRequestsReject = '拒绝', // en: Decline
    this.newFriendRequestsPending = '等待验证', // en: Pending
    this.newFriendRequestsWithdraw = '撤回', // en: Withdraw
    this.contactMatchListAdd = '添加',
    this.contactMatchListEmpty = '通讯录里还没有已注册的联系人',
    this.startConversationSheetSearchPlaceholder = '搜索联系人',
    this.startConversationSheetEmpty = '未找到联系人',
    this.unknownUserPlaceholderUnknown = '未知用户',
    this.unknownUserPlaceholderDeactivated = '该账号已注销',
    this.unknownUserPlaceholderBlocked = '该账号已被屏蔽',
    this.unknownUserPlaceholderUnreachable = '暂时无法联系该账号',
    // ContactDetail
    this.contactDetailInfo = '资料',
    this.contactDetailRemark = '备注',
    this.contactDetailDescription = '描述',
    this.contactDetailStar = '星标好友',
    this.contactDetailNotSet = '未设置',
    this.contactDetailVoice = '语音通话',
    this.contactDetailVideo = '视频通话',
    this.contactDetailBlock = '加入黑名单',
    this.contactDetailRemove = '删除好友',
    // RelationActionBar
    this.relationActionBarAdd = '添加好友',
    this.relationActionBarAccept = '接受',
    this.relationActionBarRemove = '删除好友',
    this.relationActionBarBlock = '加入黑名单',
    this.relationActionBarUnblock = '移出黑名单',
    this.relationActionBarPending = '等待对方验证',
    this.relationActionBarBusy = '处理中',
    this.relationActionBarDismissError = '关闭错误提示',
    this.relationActionBarEmpty = '暂无可用操作',
    // MemberRoleSheet
    this.memberRoleSheetMemberRole = '成员',
    this.memberRoleSheetMuted = '已禁言',
    this.memberRoleSheetPromote = '设为管理员',
    this.memberRoleSheetDemote = '取消管理员',
    this.memberRoleSheetMute = '禁言',
    this.memberRoleSheetUnmute = '解除禁言',
    this.memberRoleSheetRemove = '移出群聊',
    this.memberRoleSheetTransferOwner = '转让群主',
    this.memberRoleSheetDangerGroup = '危险操作',
    this.memberRoleSheetEmpty = '你没有管理权限',
    this.memberRoleSheetOwnerProtected = '群主不可被管理',
    // GroupPermissionMatrix
    this.groupPermissionMatrixTitle = '群设置',
    this.groupPermissionMatrixReadOnlyHint = '仅群主和管理员可修改',
    this.groupPermissionMatrixJoinPolicy = '加群方式',
    this.groupPermissionMatrixJoinPolicyDescription = '决定他人如何加入本群',
    this.groupPermissionMatrixJoinInvite = '仅邀请',
    this.groupPermissionMatrixJoinApproval = '需管理员审批',
    this.groupPermissionMatrixJoinOpen = '允许直接加入',
    this.groupPermissionMatrixUnknownJoinPolicy = '当前加群方式未知，请重新选择',
    this.groupPermissionMatrixMuteAll = '全员禁言',
    this.groupPermissionMatrixMuteAllDescription = '开启后仅群主和管理员可发言',
    this.groupPermissionMatrixOnlyAdminCanAtAll = '仅管理员可 @所有人',
    this.groupPermissionMatrixOnlyAdminCanAtAllDescription = '限制 @所有人 的使用范围',
    this.groupPermissionMatrixOnlyAdminCanPin = '仅管理员可置顶消息',
    this.groupPermissionMatrixOnlyAdminCanPinDescription = '限制群内置顶消息的权限',
    this.groupPermissionMatrixShareCardPermission = '允许分享群名片',
    this.groupPermissionMatrixShareCardPermissionDescription =
        '关闭后成员不能把本群分享给他人',
    this.groupPermissionMatrixOn = '已开启',
    this.groupPermissionMatrixOff = '已关闭',
    this.groupPermissionMatrixBusy = '提交中',
    this.groupPermissionMatrixDismissError = '忽略此错误',
    // GroupDetail
    this.groupDetailGroupFallback = '群聊',
    this.groupDetailInfo = '群信息',
    this.groupDetailName = '群名称',
    this.groupDetailNotSet = '未设置',
    // "Unavailable right now": a setting the host could not read.
    this.groupDetailSettingUnavailable = '暂时无法读取',
    this.groupDetailMyInGroup = '我在本群',
    this.groupDetailMyNickname = '我的群昵称',
    this.groupDetailNicknamePlaceholder = '群内显示名',
    this.groupDetailMuteNotif = '消息免打扰',
    this.groupDetailPinGroup = '置顶该群',
    this.groupDetailManage = '群管理',
    this.groupDetailDiscoverable = groupDetailDiscoverableDefault,
    this.groupDetailJoinMode = '进群方式',
    this.groupDetailJoinOpen = '允许任何人加入',
    this.groupDetailJoinApproval = '需管理员审批',
    this.groupDetailJoinInvite = '仅邀请加入',
    this.groupDetailJoinRequests = '入群申请',
    this.groupDetailMuteAll = '全员禁言',
    this.groupDetailInviteLink = '群邀请链接',
    this.groupDetailInviteLinkHint = '将邀请码分享给好友，对方可凭码加入本群。',
    this.groupDetailCopyCode = '复制邀请码',
    this.groupDetailCannotGenerate = '暂无法生成邀请链接，请稍后重试。',
    this.groupDetailPerms = '群权限',
    this.groupDetailOnlyAdminAtAll = '仅管理员可@全体成员',
    this.groupDetailOnlyAdminPin = '仅管理员可置顶消息',
    this.groupDetailShareCard = '允许分享群名片',
    this.groupDetailLeave = '退出群聊',
    this.groupDetailDissolve = '解散群聊',
    this.groupDetailLeaveConfirm = '退出后将不再接收该群消息。',
    this.groupDetailDissolveConfirm = '解散后群聊将被永久删除，无法恢复。',
    this.groupDetailSave = '保存',
    this.groupDetailEditName = '修改群名称',
    this.groupDetailEditAnnouncement = '修改群公告',
    this.groupDetailMemberManage = '成员管理',
    this.groupDetailSetAdmin = '设为管理员',
    this.groupDetailUnsetAdmin = '取消管理员',
    this.groupDetailMute = '禁言',
    this.groupDetailUnmute = '解除禁言',
    this.groupDetailTransferOwner = '转让群主',
    this.groupDetailConfirmTransfer = '确认转让',
    this.groupDetailRemoveMember = '移出群聊',
    this.groupDetailInvite = '邀请成员',
    this.groupDetailInviteEmpty = '没有可邀请的好友。',
    this.groupDetailApprove = '通过',
    this.groupDetailLoading = '加载中…',
    this.groupDetailNoRequests = '暂无入群申请。',
    this.groupDetailUnavailable = '群信息不可用',
    this.groupDetailUnavailableHint = '未连接服务时无法加载。',
    this.groupDetailMemberCount = _groupDetailMemberCount,
    this.groupDetailInviteConfirm = _groupDetailInviteConfirm,
    this.groupDetailTransferConfirm = _groupDetailTransferConfirm,
    // Conversation：ActionSheet / Details / BatchToolbar / Workspace
    this.conversationActionSheetPin = '置顶',
    this.conversationActionSheetUnpin = '取消置顶',
    this.conversationActionSheetMute = '免打扰',
    this.conversationActionSheetUnmute = '取消免打扰',
    this.conversationActionSheetMarkRead = '标为已读',
    this.conversationActionSheetMarkUnread = '标为未读', // en: Mark as unread
    this.conversationActionSheetArchive = '归档',
    this.conversationActionSheetUnarchive = '取消归档',
    this.conversationActionSheetHide = '隐藏',
    this.conversationActionSheetClearHistory =
        '清空本地记录', // en: Clear local history
    this.conversationActionSheetEmpty = '暂无可用操作',
    this.conversationHeaderAddActions =
        '添加会话操作', // en: Add conversation actions
    this.conversationHeaderMoreActions =
        '更多会话操作', // en: More conversation actions
    this.messageActionSheetLabel = '消息操作',
    this.messageActionSheetEmpty = '暂无可用操作',
    this.messageSpoilerReveal = '剧透内容，点按显示', // en: Spoiler, select to reveal
    this.messageImageGroupLabel = _messageImageGroupLabel, // en: {count} images
    this.messageImageGroupItem =
        _messageImageGroupItem, // en: Image {index} of {count}
    this.messageImageGroupItemMore =
        _messageImageGroupItemMore, // en: Image {index} of {count}, {more} more not shown
    this.messageActionReply = '回复',
    this.messageActionForward = '转发',
    this.messageActionRecall = '撤回',
    this.messageActionResend = '重新发送',
    this.messageActionMultiSelect = '多选',
    this.messageActionMark = '标记',
    this.messageActionPin = '置顶消息',
    this.messageActionPinSelf = '仅自己置顶',
    this.messageActionUnpin = '取消置顶',
    this.messageActionCopy = '复制',
    this.messageActionPreview = '预览',
    this.messageActionSave = '保存',
    this.messageActionEdit = '编辑',
    this.messageActionDelete = '删除',
    this.conversationDetailsMessages = '消息',
    this.conversationDetailsMute = '消息免打扰',
    this.conversationDetailsPin = '置顶会话',
    this.conversationDetailsMarkRead = '标为已读',
    this.conversationDetailsMarkUnread = '标为未读',
    this.conversationDetailsSync = '同步会话',
    this.conversationDetailsArchive = '归档会话',
    this.conversationDetailsUnarchive = '取消归档',
    this.conversationDetailsClearHistory = '清空聊天记录',
    this.conversationDetailsDelete = '删除会话',
    this.conversationBatchToolbarSelected = '已选',
    this.conversationBatchToolbarEmpty = '请选择会话',
    this.conversationBatchToolbarMarkRead = '标为已读',
    this.conversationBatchToolbarMute = '免打扰',
    this.conversationBatchToolbarArchive = '归档',
    this.conversationBatchToolbarCancel = '取消选择',
    this.conversationBatchToolbarBusy = '处理中',
    this.conversationBatchToolbarSucceededSummary =
        _conversationBatchToolbarSucceededSummary,
    this.conversationBatchToolbarFailedSummary =
        _conversationBatchToolbarFailedSummary,
    this.conversationBatchToolbarRetryFailed = '重试失败项',
    this.conversationBatchToolbarDismiss = '关闭结果',
    this.conversationBatchToolbarExpand = '查看详情',
    this.conversationBatchToolbarMaxSelection =
        _conversationBatchToolbarMaxSelection,
    // 工作区外壳（WorkspaceFrame）——通用兜底，不能提“会话”
    this.workspaceFrameLoading = '正在加载',
    this.workspaceFrameEmpty = '暂无内容',
    this.workspaceFrameFailure = '加载失败',
    this.workspaceFrameRetry = '重试',
    this.conversationWorkspaceChatEmpty = '选择一个会话开始聊天',
    this.conversationWorkspaceDetailEmpty = '暂无详情',
    this.conversationWorkspaceListFailure = '会话列表加载失败',
    this.conversationWorkspaceChatFailure = '消息加载失败',
    this.conversationWorkspaceDetailFailure = '详情加载失败',
    this.conversationWorkspaceListLoading = '正在加载会话列表',
    this.conversationWorkspaceChatLoading = '正在加载消息',
    this.conversationWorkspaceDetailLoading = '正在加载详情',
    // General: SearchDateRangeFilter / StorageUsage / ScreenShare
    this.searchDateRangeFilterCustom = '自定义',
    this.searchDateRangeFilterFrom = '起始日期',
    this.searchDateRangeFilterTo = '结束日期',
    this.searchDateRangeFilterUnlimited = '不限时间',
    this.searchDateRangeFilterInvalid = '起始日期不能晚于结束日期',
    this.inviteCodeLabel = '邀请码',
    this.inviteCodePlaceholder = '请输入邀请码',
    this.inviteCodeOptional = '选填',
    this.inviteCodeChecking = '正在校验邀请码…',
    this.inviteCodeValid = '邀请码可用',
    this.inviteCodeInviter = '邀请人：{name}',
    this.inviteCodeInvalid = '邀请码无效',
    this.myInviteTitle = '我的邀请',
    this.myInviteCodeLabel = '我的邀请码',
    this.myInviteCodeUnavailable = '邀请码暂不可用',
    this.myInviteCopy = '复制',
    this.myInviteShare = '分享',
    this.myInviteRegenerate = '重新生成',
    this.myInviteRegenerating = '生成中…',
    this.myInviteCooldown = '{time} 后可重新生成',
    this.myInviteUnitMinutes = '{n} 分钟',
    this.myInviteUnitHours = '{n} 小时',
    this.myInviteUnitDays = '{n} 天',
    this.myInviteStatsTitle = '我的团队',
    this.myInviteDirect = '直接邀请',
    this.myInviteLevel2 = '二级',
    this.myInviteLevel3 = '三级',
    this.myInviteTotal = '团队总数',
    this.myInviteInviteesTitle = '直接邀请的人',
    this.myInviteEmpty = '还没有人通过你的邀请码加入',
    this.myInviteLoadMore = '加载更多',
    this.myInviteLoading = '正在加载邀请信息',
    this.myInviteJoined = '{date} 加入',
    this.myInviteCountOnly = '{count} 人',
    this.storageUsageTitle = '存储空间',
    this.storageUsageUnknownSize = '未知',
    this.storageUsageAtLeast = '至少',
    this.storageUsageClear = '清理',
    this.storageUsageClearing = '清理中',
    this.storageUsageTotal = '总计',
    this.storageUsageDeviceFree = '可用空间',
    this.storageUsageReload = '重新统计',
    this.storageUsageRetry = '失败重试',
    this.storageUsageDismissError = '忽略此错误',
    this.storageUsageLoading = '正在统计存储占用',
    this.storageUsageEmpty = '没有可统计的存储分类',
    this.storageUsageFileCount = _storageUsageFileCount,
    this.screenShareTitle = '屏幕共享',
    this.screenShareIdle = '未在共享',
    this.screenShareRequesting = '正在请求共享',
    this.screenShareSharing = '正在共享屏幕',
    this.screenShareViewing = '正在观看共享',
    this.screenShareUnavailable = '当前环境不支持屏幕共享',
    this.screenShareSourceRow = '共享内容',
    this.screenSharePresenterRow = '共享者',
    this.screenShareStart = '共享屏幕',
    this.screenShareStop = '停止共享',
    this.screenShareCancel = '取消请求',
    // Moments：AudienceSheet / VisibilityRuleList
    this.momentAudienceSheetPublic = '公开',
    this.momentAudienceSheetPublicHint = '所有人可见',
    this.momentAudienceSheetFriends = '朋友可见',
    this.momentAudienceSheetFriendsHint = '你的好友可见',
    this.momentAudienceSheetPrivate = '私密',
    this.momentAudienceSheetPrivateHint = '仅自己可见',
    this.momentAudienceSheetInclude = '部分可见',
    this.momentAudienceSheetIncludeHint = '仅选中的朋友可见',
    this.momentAudienceSheetExclude = '不给谁看',
    this.momentAudienceSheetExcludeHint = '选中的朋友看不到',
    this.momentAudienceSheetPick = '选择朋友',
    this.momentAudienceSheetDone = '完成',
    this.momentAudienceSheetSelected = _momentAudienceSheetSelected,
    this.momentsVisibilityHideFromTitle = '不让他看我的朋友圈',
    this.momentsVisibilityHideFromHint = '名单中的人看不到你发的内容',
    this.momentsVisibilityMuteTitle = '不看他的朋友圈',
    this.momentsVisibilityMuteHint = '你不会看到名单中的人发的内容',
    this.momentsVisibilityEmpty = '名单为空',
    this.momentsVisibilityRemove = '移出',
    this.momentsVisibilityAdd = '添加到名单', // en: Add to list
    this.conversationHeaderSearch = '搜索消息', // en: Search messages
    this.conversationHeaderAudioCall = '发起语音通话', // en: Start audio call
    this.conversationHeaderVideoCall = '发起视频通话', // en: Start video call
    this.conversationHeaderAddMember = '添加成员', // en: Add member
    this.conversationHeaderShare = '分享会话', // en: Share conversation
    this.conversationHeaderDetails = '会话详情', // en: Details
    this.conversationHeaderMemberCount =
        _conversationHeaderMemberCount, // en: {count} members
    this.presenceOnline = '在线', // en: Online
    this.presenceOffline = '离线', // en: Offline
    this.presenceBusy = '忙碌', // en: Busy
    this.presenceAway = '离开', // en: Away
    this.imageLoadFailed = '图片加载失败', // en: Image failed to load
    this.connectionConnecting = '正在连接…', // en: Connecting…
    this.connectionReconnecting =
        '连接已断开，正在重连…', // en: Connection lost. Reconnecting…
    this.connectionOffline =
        '网络不可用，恢复后会自动重连', // en: No network. Messages will sync when it is back.
    this.connectionDisconnected = '连接已断开', // en: Disconnected
    this.connectionDisconnectedReason =
        _connectionDisconnectedReason, // en: Disconnected: {reason}
    this.connectionKicked =
        '账号已在其他设备登录', // en: Your account signed in on another device
    this.connectionExpired = '登录已过期', // en: Your sign-in has expired
    this.connectionReconnect = '重新连接', // en: Reconnect
    this.connectionSignIn = '重新登录', // en: Sign in again
    this.groupDetailMembersTitle =
        _groupDetailMembersTitle, // en: Members ({count})
    this.groupDetailSearchMembers = '搜索群成员', // en: Search members
    this.groupDetailNoMatchingMembers = '没有匹配的群成员', // en: No matching members
    this.profilePanelEditProfile =
        _profilePanelEditProfile, // en: {name}, edit profile
    this.momentReplyTo = '回复', // en: replying to
    this.momentReplyToComment =
        _momentReplyToComment, // en: Reply to {name}: {text}
    this.favorites = '收藏', // en: Favorites
    this.moments = '圈子', // en: Moments
    this.settings = '设置', // en: Settings
    // 主题模式的三个选项，宿主的设置页画（`spec/theme-mode-vectors.json`）
    this.themeSystem = '跟随系统', // en: System
    this.themeLight = '浅色', // en: Light
    this.themeDark = '深色', // en: Dark
    // 密码框的显隐键（`revealable`）
    this.inputReveal = '显示密码', // en: Show password
    this.inputHide = '隐藏密码', // en: Hide password
    // 应用壳默认导航
    this.navigationChats = '消息', // en: Chats
    this.navigationContacts = '通讯录', // en: Contacts
    this.navigationProfile = '我', // en: Profile
    this.navigationFriends = '好友', // en: Friends
    this.navigationGroups = '群组', // en: Groups
    this.navigationNewFriends = '新的朋友', // en: New Friends
    // 设备选择器 / 资料编辑 / 表情面板：原来是英文默认值
    this.callDevicePickerPlaceholder = '选择设备', // en: Choose a device
    this.profileEditorNickname = '昵称', // en: Nickname
    this.profileEditorBio = '个性签名', // en: Bio
    this.profileEditorBioPlaceholder = '介绍一下自己', // en: Tell us about yourself
    this.profileEditorCancel = '取消', // en: Cancel
    this.profileEditorSave = '保存', // en: Save
    this.emojiPickerEmoji = '表情', // en: Emoji
  });

  // 通话
  final String microphone;
  final String camera;
  final String flipCamera;
  final String speaker;
  final String hangUp;
  final String callWaitingAnswer;
  final String callCalling;
  final String callRinging;
  final String callConnected;
  final String callReconnecting;
  final String callFailed;

  /// The call dock's main control, which returns to the full call.
  final String callReturn;

  /// The group call's minimize control.
  final String callMinimize;
  // 输入区
  final String send;
  final String cancelReply;
  // 空态
  final String noContacts;
  final String noResults;
  final String noMessages;
  final String noContent;
  // 通用动作
  final String close;

  /// The image preview's close control.
  final String closePreview;

  /// A gallery preview's paging keys, and where it is, as assistive
  /// technology names them.
  final String imagePreviewPrevious;
  final String imagePreviewNext;
  final String Function(int index, int count) imagePreviewPosition;
  final String delete;

  /// 举报这一条（他人的动态/消息/资料）。与 [delete] 同层：都是「对这一条动作」，二者互斥。
  final String report;
  final String manage;
  final String selectAll;
  final String retry;
  final String loading;
  final String messagePending;
  final String messageSending;
  final String messageSent;
  final String messageDelivered;
  final String messageRead;
  final String messageFailed;
  final String messageRetrying;
  final String messageEdited;
  final String messageReadOnce;
  final String messageBurnAfterRead;
  final String messageExpired;
  // 消息操作
  final String addReaction;
  final String readReceipt;
  final String Function(int count) readTab;
  final String Function(int count) unreadTab;
  final String noReadersYet;
  final String everyoneHasRead;
  final String selectedSuffix;
  final String forwardEach;
  final String forwardMerged;

  /// The message batch toolbar's exit control.
  final String messageBatchPin;
  final String messageBatchPinSelf;
  final String messageBatchClear;
  final String messageBatchExit;
  // 提及
  final String searchMembers;
  final String everyone;
  final String notifyEveryone;
  final String noMatchingMembers;
  // 快捷短语
  final String quickPhrases;
  final String Function(int total) viewAll;
  // 正在输入 / 新消息
  final String typing;
  final String Function(String name) typingOne;
  final String Function(int count) typingMany;
  final String Function(int count) newMessages;

  /// The timeline's go-to-newest control (`FlareScrollToLatest`).
  final String scrollToLatest;
  // 名片 / 群通话
  final String sendMessage;
  final String groupCall;
  final String Function(int count, String status) joinedCount;
  final String Function(String name) selfSuffix;
  // 转发选择
  final String forwardTo;
  final String searchConversations;
  final String noMatchingConversations;
  final String Function(int count) selectedCount;
  // 群公告
  final String groupAnnouncement;
  final String collapse;
  final String expand;
  // 红包
  final String Function(String amount) packetClaimed;
  final String packetFinished;
  final String packetTapToClaim;
  final String packetBrand;
  // 命令 / 翻译 / 名片码
  final String commands;
  final String noMatchingCommands;
  final String translating;
  final String Function(String provider) translatedBy;
  final String translated;
  final String hideOriginal;
  final String showOriginal;
  final String scanToAddMe;
  // 录音 / 投票
  final String cancel;
  final String releaseToCancel;

  /// The voice recording bar's cancel and send controls.
  final String voiceRecordingCancel;
  final String voiceRecordingSend;

  /// 会话行的草稿 / 被提及前缀（与 iOS `conversationRowDraft` / `conversationRowMention` 同名）。
  final String conversationRowDraft;
  final String conversationRowMention;
  final String createPoll;
  final String pollQuestionHint;
  final String Function(int index) pollOptionHint;
  final String removeOption;
  final String addOption;
  final String allowMultiple;
  final String submitPoll;
  final String chatBackground;
  // 步进 / 日历
  final String decrease;
  final String increase;
  final String previousMonth;
  final String nextMonth;
  final String Function(int year, int month) yearMonth;

  /// One star of a rating control, named by the value it sets.
  final String Function(int count) ratingStars;
  // 朋友圈
  final String unlike;
  final String like;
  final String comment;
  final String changeCover;
  final String post;
  final String momentTextHint;
  final String addImage;
  final String pickLocation;
  final String pickVisibility;
  final String more;

  /// The moment card's ··· control, which opens like / comment / delete.
  final String momentActions;

  /// The moment composer's control that removes one picked image.
  final String removeImage;
  // 语音转文字 / 表情贴纸
  final String hideTranscript;
  final String showTranscript;
  final String recent;
  final String searchEmoji;
  final String noMatchingEmoji;
  final String emptyStickerPack;
  final String sticker;
  // 加号面板
  final String actionImage;
  final String actionCamera;
  final String actionFile;
  final String actionLocation;
  final String actionCard;
  final String actionVote;
  final String actionTask;
  final String actionSchedule;
  final String actionVideo;
  final String actionLink;
  final String actionAnnouncement;
  final String actionNotification;
  final String actionMiniProgram;
  final String actionTranslate;
  // 来电
  final String incomingVideoCall;
  final String incomingVoiceCall;
  final String reject;
  final String accept;
  // 通用
  final String back;
  final String confirm;
  final String Function(int count) confirmCount;
  final String Function(int count) memberCount;
  final String clear;
  final String Function(int words, int chars) wordCharCount;
  final String changeAvatar;
  final String qrCode;

  /// The profile panel's control that opens the user's own QR code.
  final String myQrCode;
  final String play;
  final String pause;
  final String download;

  /// A voice message that could not be played; its control then retries.
  final String voicePlaybackFailed;

  /// The video player's failed state, shown above its retry and close keys.
  final String videoLoadFailed;
  // 权限提示（名词 / 动词短语 / 状态 / 说明）
  final String permissionNotifications;
  final String permissionStorage;
  final String permissionPhotos;
  final String permissionContacts;
  final String permissionLocation;
  final String permissionScreen;
  final String permissionVerbMicrophone;
  final String permissionVerbCamera;
  final String permissionVerbNotifications;
  final String permissionVerbStorage;
  final String permissionVerbPhotos;
  final String permissionVerbContacts;
  final String permissionVerbLocation;
  final String permissionVerbScreen;
  final String permissionThisFeature;
  final String Function(String noun) permissionTitle;
  final String Function(String feature, String verb)
  permissionUndeterminedDescription;
  final String Function(String feature, String verb)
  permissionDeniedDescription;
  final String Function(String feature, String verb)
  permissionRestrictedDescription;
  final String Function(String feature, String verb)
  permissionUnavailableDescription;
  final String permissionAllow;
  final String permissionOpenSettings;
  final String permissionStateUndetermined;
  final String permissionStateDenied;
  final String permissionStateRestricted;
  final String permissionStateUnavailable;
  // iOS 同名通用字段（Flutter 此前缺失）
  final String search;
  final String noGroups;
  final String noConversations;
  final String groupMembers;
  final String groupOwner;
  final String groupAdmin;
  final String addMember;
  final String loginDevices;
  final String currentDevice;
  final String filesAndMedia;
  final String notificationSettings;
  final String confirmAction;
  final String transferQueue;
  final String noTransfers;
  final String retryFailedTransfers;
  final String reload;
  final String today;
  final String yesterday;
  final String timeRange;
  final String searchIdleHint;
  final String permissionDismiss;
  // Composer（输入区工具 / 富文本工具条 / 按住说话）
  final String composerPlaceholder;
  final String composerReply;
  final String composerVoice;
  final String composerVoiceRecording;
  final String composerVoiceCancel;
  final String composerBold;
  final String composerItalic;
  final String composerStrike;
  final String composerUnderline;
  final String composerCode;
  final String composerCodeBlock;
  final String composerLink;
  final String composerParagraph;
  final String composerDivider;
  final String composerHeading;
  final String composerQuote;
  final String composerList;
  final String composerOrderedList;
  final String composerEmoji;
  final String composerMention;
  final String composerVoiceInput;
  final String composerRichText;
  final String composerExpandInput;
  // InlineVoice（录音条）
  final String inlineVoiceMicrophoneUnavailable;
  final String inlineVoiceSendFailed;
  final String inlineVoiceKeyboard;
  final String inlineVoicePause;
  final String inlineVoiceStart;
  final String inlineVoicePreview;
  final String inlineVoiceResume;
  final String inlineVoiceDiscard;
  // MessageList / UnknownMessage / EmojiPicker / StickerPanel / QuickPhrases / QrCard
  final String messageListLoadOlder;
  final String messageRecalledSelf;
  final String messageRecalledPeer;
  final String Function(String name) messageRecalledGroupOther;
  final String Function(String name, String summary) quotedMessage;

  /// What a screen reader is told once a jump lands: the ring says which row it is to everyone who
  /// can see it, and this says the same thing to a reader who cannot.
  final String Function(String name, String summary) jumpedToMessage;

  /// 一句话摘要词汇（`flareMessagePreviewText`）。内容自带文字时用那段文字，
  /// 没有时用这里的词；带名字的用 `…Named`，数量型用 `…Count`。
  final String previewMessage;
  final String previewRichText;
  final String previewGif;
  final String previewImage;

  /// An image named by its alt text inside a markdown line (`flareMarkdownToPlainText`).
  final String Function(String label) previewImageNamed;
  final String previewVideo;
  final String previewAudio;
  final String previewFile;
  final String Function(String name) previewFileNamed;
  final String previewLocation;
  final String Function(String label) previewLocationNamed;
  final String previewCard;
  final String Function(String label) previewCardNamed;
  final String previewSticker;
  final String previewEmoji;
  final String previewQuote;
  final String previewLink;
  final String previewForward;
  final String Function(int count) previewForwardCount;
  final String previewMiniProgram;

  /// An album with no images: it says what it is, never "0 of them".
  final String previewImageGroup;
  final String Function(int count) previewImageGroupCount;
  final String previewSystem;
  final String previewNotification;
  final String previewVote;
  final String previewTask;
  final String previewSchedule;
  final String previewAnnouncement;
  final String previewCustom;
  final String previewPlaceholder;
  final String previewUnknown;
  final String unknownMessageHint;
  final String unknownMessageUnsupported;
  final String unknownMessageDiagnostic;
  final String emojiPickerEmpty;
  final String stickerPanelEmpty;
  final String quickPhrasesTitle;
  final String qrCardHint;

  /// FlareQRCard frame without a code (en: "QR code unavailable").
  final String qrCardUnavailable;
  // ReadReceiptSheet / AnnouncementReadBar
  final String readReceiptSheetReadEmpty;
  final String readReceiptSheetUnreadEmpty;
  final String announcementReadBarConfirmRead;
  final String announcementReadBarViewUnread;
  final String Function(int read, int total) announcementReadBarReadCount;
  // Contacts：NewFriendRequests / ContactMatchList / StartConversationSheet / UnknownUserPlaceholder
  final String newFriendRequestsEmpty;
  final String newFriendRequestsAccept;
  final String newFriendRequestsReject;
  final String newFriendRequestsPending;
  final String newFriendRequestsWithdraw;
  final String contactMatchListAdd;
  final String contactMatchListEmpty;
  final String startConversationSheetSearchPlaceholder;
  final String startConversationSheetEmpty;
  final String unknownUserPlaceholderUnknown;
  final String unknownUserPlaceholderDeactivated;
  final String unknownUserPlaceholderBlocked;
  final String unknownUserPlaceholderUnreachable;
  // ContactDetail
  final String contactDetailInfo;
  final String contactDetailRemark;
  final String contactDetailDescription;
  final String contactDetailStar;
  final String contactDetailNotSet;
  final String contactDetailVoice;
  final String contactDetailVideo;
  final String contactDetailBlock;
  final String contactDetailRemove;
  // RelationActionBar
  final String relationActionBarAdd;
  final String relationActionBarAccept;
  final String relationActionBarRemove;
  final String relationActionBarBlock;
  final String relationActionBarUnblock;
  final String relationActionBarPending;
  final String relationActionBarBusy;
  final String relationActionBarDismissError;
  final String relationActionBarEmpty;
  // MemberRoleSheet
  final String memberRoleSheetMemberRole;
  final String memberRoleSheetMuted;
  final String memberRoleSheetPromote;
  final String memberRoleSheetDemote;
  final String memberRoleSheetMute;
  final String memberRoleSheetUnmute;
  final String memberRoleSheetRemove;
  final String memberRoleSheetTransferOwner;
  final String memberRoleSheetDangerGroup;
  final String memberRoleSheetEmpty;
  final String memberRoleSheetOwnerProtected;
  // GroupPermissionMatrix
  final String groupPermissionMatrixTitle;
  final String groupPermissionMatrixReadOnlyHint;
  final String groupPermissionMatrixJoinPolicy;
  final String groupPermissionMatrixJoinPolicyDescription;
  final String groupPermissionMatrixJoinInvite;
  final String groupPermissionMatrixJoinApproval;
  final String groupPermissionMatrixJoinOpen;
  final String groupPermissionMatrixUnknownJoinPolicy;
  final String groupPermissionMatrixMuteAll;
  final String groupPermissionMatrixMuteAllDescription;
  final String groupPermissionMatrixOnlyAdminCanAtAll;
  final String groupPermissionMatrixOnlyAdminCanAtAllDescription;
  final String groupPermissionMatrixOnlyAdminCanPin;
  final String groupPermissionMatrixOnlyAdminCanPinDescription;
  final String groupPermissionMatrixShareCardPermission;
  final String groupPermissionMatrixShareCardPermissionDescription;
  final String groupPermissionMatrixOn;
  final String groupPermissionMatrixOff;
  final String groupPermissionMatrixBusy;
  final String groupPermissionMatrixDismissError;
  // GroupDetail
  final String groupDetailGroupFallback;
  final String groupDetailInfo;
  final String groupDetailName;
  final String groupDetailNotSet;
  final String groupDetailSettingUnavailable;
  final String groupDetailMyInGroup;
  final String groupDetailMyNickname;
  final String groupDetailNicknamePlaceholder;
  final String groupDetailMuteNotif;
  final String groupDetailPinGroup;
  final String groupDetailManage;
  final String groupDetailDiscoverable;
  final String groupDetailJoinMode;
  final String groupDetailJoinOpen;
  final String groupDetailJoinApproval;
  final String groupDetailJoinInvite;
  final String groupDetailJoinRequests;
  final String groupDetailMuteAll;
  final String groupDetailInviteLink;
  final String groupDetailInviteLinkHint;
  final String groupDetailCopyCode;
  final String groupDetailCannotGenerate;
  final String groupDetailPerms;
  final String groupDetailOnlyAdminAtAll;
  final String groupDetailOnlyAdminPin;
  final String groupDetailShareCard;
  final String groupDetailLeave;
  final String groupDetailDissolve;
  final String groupDetailLeaveConfirm;
  final String groupDetailDissolveConfirm;
  final String groupDetailSave;
  final String groupDetailEditName;
  final String groupDetailEditAnnouncement;
  final String groupDetailMemberManage;
  final String groupDetailSetAdmin;
  final String groupDetailUnsetAdmin;
  final String groupDetailMute;
  final String groupDetailUnmute;
  final String groupDetailTransferOwner;
  final String groupDetailConfirmTransfer;
  final String groupDetailRemoveMember;
  final String groupDetailInvite;
  final String groupDetailInviteEmpty;
  final String groupDetailApprove;
  final String groupDetailLoading;
  final String groupDetailNoRequests;
  final String groupDetailUnavailable;
  final String groupDetailUnavailableHint;
  final String Function(int count) groupDetailMemberCount;
  final String Function(int count) groupDetailInviteConfirm;
  final String Function(String name) groupDetailTransferConfirm;
  // Conversation：ActionSheet / Details / BatchToolbar / Workspace
  final String conversationActionSheetPin;
  final String conversationActionSheetUnpin;
  final String conversationActionSheetMute;
  final String conversationActionSheetUnmute;
  final String conversationActionSheetMarkRead;
  final String conversationActionSheetMarkUnread;
  final String conversationActionSheetArchive;
  final String conversationActionSheetUnarchive;
  final String conversationActionSheetHide;
  final String conversationActionSheetClearHistory;
  final String conversationActionSheetEmpty;

  /// The conversation header's add and more menus: their accessible names and,
  /// on phones, their sheet titles.
  final String conversationHeaderAddActions;
  final String conversationHeaderMoreActions;
  final String messageActionSheetLabel;
  final String messageActionSheetEmpty;

  /// A covered spoiler in a rich-text body, as assistive technology names it.
  final String messageSpoilerReveal;

  /// An album body and its tiles, as assistive technology names them.
  final String Function(int count) messageImageGroupLabel;
  final String Function(int index, int count) messageImageGroupItem;
  final String Function(int index, int count, int more)
  messageImageGroupItemMore;
  final String messageActionReply;
  final String messageActionForward;
  final String messageActionRecall;
  final String messageActionResend;
  final String messageActionMultiSelect;
  final String messageActionMark;
  final String messageActionPin;
  final String messageActionPinSelf;
  final String messageActionUnpin;
  final String messageActionCopy;
  final String messageActionPreview;
  final String messageActionSave;
  final String messageActionEdit;
  final String messageActionDelete;
  final String conversationDetailsMessages;
  final String conversationDetailsMute;
  final String conversationDetailsPin;
  final String conversationDetailsMarkRead;
  final String conversationDetailsMarkUnread;
  final String conversationDetailsSync;
  final String conversationDetailsArchive;
  final String conversationDetailsUnarchive;
  final String conversationDetailsClearHistory;
  final String conversationDetailsDelete;
  final String conversationBatchToolbarSelected;
  final String conversationBatchToolbarEmpty;
  final String conversationBatchToolbarMarkRead;
  final String conversationBatchToolbarMute;
  final String conversationBatchToolbarArchive;
  final String conversationBatchToolbarCancel;
  final String conversationBatchToolbarBusy;
  final String Function(int count) conversationBatchToolbarSucceededSummary;
  final String Function(int count) conversationBatchToolbarFailedSummary;
  final String conversationBatchToolbarRetryFailed;
  final String conversationBatchToolbarDismiss;
  final String conversationBatchToolbarExpand;
  final String Function(int max) conversationBatchToolbarMaxSelection;
  final String workspaceFrameLoading;
  final String workspaceFrameEmpty;
  final String workspaceFrameFailure;
  final String workspaceFrameRetry;
  final String conversationWorkspaceChatEmpty;
  final String conversationWorkspaceDetailEmpty;
  final String conversationWorkspaceListFailure;
  final String conversationWorkspaceChatFailure;
  final String conversationWorkspaceDetailFailure;
  final String conversationWorkspaceListLoading;
  final String conversationWorkspaceChatLoading;
  final String conversationWorkspaceDetailLoading;
  // General: SearchDateRangeFilter / StorageUsage / ScreenShare
  final String searchDateRangeFilterCustom;
  final String searchDateRangeFilterFrom;
  final String searchDateRangeFilterTo;
  final String searchDateRangeFilterUnlimited;
  final String searchDateRangeFilterInvalid;
  final String inviteCodeLabel;
  final String inviteCodePlaceholder;
  final String inviteCodeOptional;
  final String inviteCodeChecking;
  final String inviteCodeValid;
  final String inviteCodeInviter;
  final String inviteCodeInvalid;
  final String myInviteTitle;
  final String myInviteCodeLabel;
  final String myInviteCodeUnavailable;
  final String myInviteCopy;
  final String myInviteShare;
  final String myInviteRegenerate;
  final String myInviteRegenerating;
  final String myInviteCooldown;
  final String myInviteUnitMinutes;
  final String myInviteUnitHours;
  final String myInviteUnitDays;
  final String myInviteStatsTitle;
  final String myInviteDirect;
  final String myInviteLevel2;
  final String myInviteLevel3;
  final String myInviteTotal;
  final String myInviteInviteesTitle;
  final String myInviteEmpty;
  final String myInviteLoadMore;
  final String myInviteLoading;
  final String myInviteJoined;
  final String myInviteCountOnly;
  final String storageUsageTitle;
  final String storageUsageUnknownSize;
  final String storageUsageAtLeast;
  final String storageUsageClear;
  final String storageUsageClearing;
  final String storageUsageTotal;
  final String storageUsageDeviceFree;
  final String storageUsageReload;
  final String storageUsageRetry;
  final String storageUsageDismissError;
  final String storageUsageLoading;
  final String storageUsageEmpty;
  final String Function(int count) storageUsageFileCount;
  final String screenShareTitle;
  final String screenShareIdle;
  final String screenShareRequesting;
  final String screenShareSharing;
  final String screenShareViewing;
  final String screenShareUnavailable;
  final String screenShareSourceRow;
  final String screenSharePresenterRow;
  final String screenShareStart;
  final String screenShareStop;
  final String screenShareCancel;
  // Moments：AudienceSheet / VisibilityRuleList
  final String momentAudienceSheetPublic;
  final String momentAudienceSheetPublicHint;
  final String momentAudienceSheetFriends;
  final String momentAudienceSheetFriendsHint;
  final String momentAudienceSheetPrivate;
  final String momentAudienceSheetPrivateHint;
  final String momentAudienceSheetInclude;
  final String momentAudienceSheetIncludeHint;
  final String momentAudienceSheetExclude;
  final String momentAudienceSheetExcludeHint;
  final String momentAudienceSheetPick;
  final String momentAudienceSheetDone;
  final String Function(int count) momentAudienceSheetSelected;
  final String momentsVisibilityHideFromTitle;
  final String momentsVisibilityHideFromHint;
  final String momentsVisibilityMuteTitle;
  final String momentsVisibilityMuteHint;
  final String momentsVisibilityEmpty;
  final String momentsVisibilityRemove;

  /// The visibility rule list's control that adds a person to the rule.
  final String momentsVisibilityAdd;
  final String conversationHeaderSearch;
  final String conversationHeaderAudioCall;
  final String conversationHeaderVideoCall;
  final String conversationHeaderAddMember;
  final String conversationHeaderShare;
  final String conversationHeaderDetails;
  final String Function(int count) conversationHeaderMemberCount;
  final String presenceOnline;
  final String presenceOffline;
  final String presenceBusy;
  final String presenceAway;
  final String imageLoadFailed;
  final String connectionConnecting;
  final String connectionReconnecting;
  final String connectionOffline;
  final String connectionDisconnected;
  final String Function(String reason) connectionDisconnectedReason;
  final String connectionKicked;
  final String connectionExpired;
  final String connectionReconnect;
  final String connectionSignIn;
  final String Function(int count) groupDetailMembersTitle;
  final String groupDetailSearchMembers;
  final String groupDetailNoMatchingMembers;

  /// The profile panel's identity control, which opens the profile editor.
  final String Function(String name) profilePanelEditProfile;

  /// Between a comment's author and the person it replies to.
  final String momentReplyTo;

  /// A moment comment row that replies to [name]'s comment [text].
  final String Function(String name, String text) momentReplyToComment;

  /// The profile panel's default entry for the user's favorites.
  final String favorites;

  /// The profile panel's default entry for the user's moments.
  final String moments;

  /// The profile panel's default entry for settings.
  final String settings;

  /// The theme mode options a host draws in its settings.
  final String themeSystem;
  final String themeLight;
  final String themeDark;

  /// The reveal key of a secure input (`FlareInput.revealable`).
  final String inputReveal;
  final String inputHide;

  /// The app shell's default navigation names.
  final String navigationChats;
  final String navigationContacts;
  final String navigationProfile;
  final String navigationFriends;
  final String navigationGroups;
  final String navigationNewFriends;

  /// The call device picker's empty selection.
  final String callDevicePickerPlaceholder;

  /// The profile editor's fields and buttons.
  final String profileEditorNickname;
  final String profileEditorBio;
  final String profileEditorBioPlaceholder;
  final String profileEditorCancel;
  final String profileEditorSave;

  /// The emoji tab of the emoji / sticker picker.
  final String emojiPickerEmoji;

  /// 只覆盖需要改的串，其余保持不变。
  FlareStrings copyWith({
    String? microphone,
    String? camera,
    String? flipCamera,
    String? speaker,
    String? hangUp,
    String? callWaitingAnswer,
    String? callCalling,
    String? callRinging,
    String? callConnected,
    String? callReconnecting,
    String? callFailed,
    String? callReturn,
    String? callMinimize,
    String? send,
    String? cancelReply,
    String? noContacts,
    String? noResults,
    String? noMessages,
    String? noContent,
    String? close,
    String? closePreview,
    String? imagePreviewPrevious,
    String? imagePreviewNext,
    String Function(int index, int count)? imagePreviewPosition,
    String? delete,
    String? manage,
    String? selectAll,
    String? retry,
    String? loading,
    String? messagePending,
    String? messageSending,
    String? messageSent,
    String? messageDelivered,
    String? messageRead,
    String? messageFailed,
    String? messageRetrying,
    String? messageEdited,
    String? messageReadOnce,
    String? messageBurnAfterRead,
    String? messageExpired,
    String? addReaction,
    String? readReceipt,
    String Function(int count)? readTab,
    String Function(int count)? unreadTab,
    String? noReadersYet,
    String? everyoneHasRead,
    String? selectedSuffix,
    String? forwardEach,
    String? forwardMerged,
    String? messageBatchPin,
    String? messageBatchPinSelf,
    String? messageBatchClear,
    String? messageBatchExit,
    String? searchMembers,
    String? everyone,
    String? notifyEveryone,
    String? noMatchingMembers,
    String? quickPhrases,
    String Function(int total)? viewAll,
    String? typing,
    String Function(String name)? typingOne,
    String Function(int count)? typingMany,
    String Function(int count)? newMessages,
    String? scrollToLatest,
    String? sendMessage,
    String? groupCall,
    String Function(int count, String status)? joinedCount,
    String Function(String name)? selfSuffix,
    String? forwardTo,
    String? searchConversations,
    String? noMatchingConversations,
    String Function(int count)? selectedCount,
    String? groupAnnouncement,
    String? collapse,
    String? expand,
    String Function(String amount)? packetClaimed,
    String? packetFinished,
    String? packetTapToClaim,
    String? packetBrand,
    String? commands,
    String? noMatchingCommands,
    String? translating,
    String Function(String provider)? translatedBy,
    String? translated,
    String? hideOriginal,
    String? showOriginal,
    String? scanToAddMe,
    String? cancel,
    String? releaseToCancel,
    String? voiceRecordingCancel,
    String? voiceRecordingSend,
    String? conversationRowDraft,
    String? conversationRowMention,
    String? createPoll,
    String? pollQuestionHint,
    String Function(int index)? pollOptionHint,
    String? removeOption,
    String? addOption,
    String? allowMultiple,
    String? submitPoll,
    String? chatBackground,
    String? decrease,
    String? increase,
    String? previousMonth,
    String? nextMonth,
    String Function(int year, int month)? yearMonth,
    String Function(int count)? ratingStars,
    String? unlike,
    String? like,
    String? comment,
    String? changeCover,
    String? post,
    String? momentTextHint,
    String? addImage,
    String? pickLocation,
    String? pickVisibility,
    String? more,
    String? momentActions,
    String? removeImage,
    String? hideTranscript,
    String? showTranscript,
    String? recent,
    String? searchEmoji,
    String? noMatchingEmoji,
    String? emptyStickerPack,
    String? sticker,
    String? actionImage,
    String? actionCamera,
    String? actionFile,
    String? actionLocation,
    String? actionCard,
    String? actionVote,
    String? actionTask,
    String? actionSchedule,
    String? actionVideo,
    String? actionLink,
    String? actionAnnouncement,
    String? actionNotification,
    String? actionMiniProgram,
    String? actionTranslate,
    String? incomingVideoCall,
    String? incomingVoiceCall,
    String? reject,
    String? accept,
    String? back,
    String? confirm,
    String Function(int count)? confirmCount,
    String Function(int count)? memberCount,
    String? clear,
    String Function(int words, int chars)? wordCharCount,
    String? changeAvatar,
    String? qrCode,
    String? myQrCode,
    String? play,
    String? pause,
    String? download,
    String? voicePlaybackFailed,
    String? videoLoadFailed,
    String? permissionNotifications,
    String? permissionStorage,
    String? permissionPhotos,
    String? permissionContacts,
    String? permissionLocation,
    String? permissionScreen,
    String? permissionVerbMicrophone,
    String? permissionVerbCamera,
    String? permissionVerbNotifications,
    String? permissionVerbStorage,
    String? permissionVerbPhotos,
    String? permissionVerbContacts,
    String? permissionVerbLocation,
    String? permissionVerbScreen,
    String? permissionThisFeature,
    String Function(String noun)? permissionTitle,
    String Function(String feature, String verb)?
    permissionUndeterminedDescription,
    String Function(String feature, String verb)? permissionDeniedDescription,
    String Function(String feature, String verb)?
    permissionRestrictedDescription,
    String Function(String feature, String verb)?
    permissionUnavailableDescription,
    String? permissionAllow,
    String? permissionOpenSettings,
    String? permissionStateUndetermined,
    String? permissionStateDenied,
    String? permissionStateRestricted,
    String? permissionStateUnavailable,
    String? search,
    String? noGroups,
    String? noConversations,
    String? groupMembers,
    String? groupOwner,
    String? groupAdmin,
    String? addMember,
    String? loginDevices,
    String? currentDevice,
    String? filesAndMedia,
    String? notificationSettings,
    String? confirmAction,
    String? transferQueue,
    String? noTransfers,
    String? retryFailedTransfers,
    String? reload,
    String? today,
    String? yesterday,
    String? timeRange,
    String? searchIdleHint,
    String? permissionDismiss,
    String? composerPlaceholder,
    String? composerReply,
    String? composerVoice,
    String? composerVoiceRecording,
    String? composerVoiceCancel,
    String? composerBold,
    String? composerItalic,
    String? composerStrike,
    String? composerUnderline,
    String? composerCode,
    String? composerCodeBlock,
    String? composerLink,
    String? composerParagraph,
    String? composerDivider,
    String? composerHeading,
    String? composerQuote,
    String? composerList,
    String? composerOrderedList,
    String? composerEmoji,
    String? composerMention,
    String? composerVoiceInput,
    String? composerRichText,
    String? composerExpandInput,
    String? inlineVoiceMicrophoneUnavailable,
    String? inlineVoiceSendFailed,
    String? inlineVoiceKeyboard,
    String? inlineVoicePause,
    String? inlineVoiceStart,
    String? inlineVoicePreview,
    String? inlineVoiceResume,
    String? inlineVoiceDiscard,
    String? messageListLoadOlder,
    String? messageRecalledSelf,
    String? messageRecalledPeer,
    String Function(String name)? messageRecalledGroupOther,
    String Function(String name, String summary)? quotedMessage,
    String Function(String name, String summary)? jumpedToMessage,
    String? previewMessage,
    String? previewRichText,
    String? previewGif,
    String? previewImage,
    String Function(String label)? previewImageNamed,
    String? previewVideo,
    String? previewAudio,
    String? previewFile,
    String Function(String name)? previewFileNamed,
    String? previewLocation,
    String Function(String label)? previewLocationNamed,
    String? previewCard,
    String Function(String label)? previewCardNamed,
    String? previewSticker,
    String? previewEmoji,
    String? previewQuote,
    String? previewLink,
    String? previewForward,
    String Function(int count)? previewForwardCount,
    String? previewMiniProgram,
    String? previewImageGroup,
    String Function(int count)? previewImageGroupCount,
    String? previewSystem,
    String? previewNotification,
    String? previewVote,
    String? previewTask,
    String? previewSchedule,
    String? previewAnnouncement,
    String? previewCustom,
    String? previewPlaceholder,
    String? previewUnknown,
    String? unknownMessageHint,
    String? unknownMessageUnsupported,
    String? unknownMessageDiagnostic,
    String? emojiPickerEmpty,
    String? stickerPanelEmpty,
    String? quickPhrasesTitle,
    String? qrCardHint,
    String? qrCardUnavailable,
    String? readReceiptSheetReadEmpty,
    String? readReceiptSheetUnreadEmpty,
    String? announcementReadBarConfirmRead,
    String? announcementReadBarViewUnread,
    String Function(int read, int total)? announcementReadBarReadCount,
    String? newFriendRequestsEmpty,
    String? newFriendRequestsAccept,
    String? newFriendRequestsReject,
    String? newFriendRequestsPending,
    String? newFriendRequestsWithdraw,
    String? contactMatchListAdd,
    String? contactMatchListEmpty,
    String? startConversationSheetSearchPlaceholder,
    String? startConversationSheetEmpty,
    String? unknownUserPlaceholderUnknown,
    String? unknownUserPlaceholderDeactivated,
    String? unknownUserPlaceholderBlocked,
    String? unknownUserPlaceholderUnreachable,
    String? contactDetailInfo,
    String? contactDetailRemark,
    String? contactDetailDescription,
    String? contactDetailStar,
    String? contactDetailNotSet,
    String? contactDetailVoice,
    String? contactDetailVideo,
    String? contactDetailBlock,
    String? contactDetailRemove,
    String? relationActionBarAdd,
    String? relationActionBarAccept,
    String? relationActionBarRemove,
    String? relationActionBarBlock,
    String? relationActionBarUnblock,
    String? relationActionBarPending,
    String? relationActionBarBusy,
    String? relationActionBarDismissError,
    String? relationActionBarEmpty,
    String? memberRoleSheetMemberRole,
    String? memberRoleSheetMuted,
    String? memberRoleSheetPromote,
    String? memberRoleSheetDemote,
    String? memberRoleSheetMute,
    String? memberRoleSheetUnmute,
    String? memberRoleSheetRemove,
    String? memberRoleSheetTransferOwner,
    String? memberRoleSheetDangerGroup,
    String? memberRoleSheetEmpty,
    String? memberRoleSheetOwnerProtected,
    String? groupPermissionMatrixTitle,
    String? groupPermissionMatrixReadOnlyHint,
    String? groupPermissionMatrixJoinPolicy,
    String? groupPermissionMatrixJoinPolicyDescription,
    String? groupPermissionMatrixJoinInvite,
    String? groupPermissionMatrixJoinApproval,
    String? groupPermissionMatrixJoinOpen,
    String? groupPermissionMatrixUnknownJoinPolicy,
    String? groupPermissionMatrixMuteAll,
    String? groupPermissionMatrixMuteAllDescription,
    String? groupPermissionMatrixOnlyAdminCanAtAll,
    String? groupPermissionMatrixOnlyAdminCanAtAllDescription,
    String? groupPermissionMatrixOnlyAdminCanPin,
    String? groupPermissionMatrixOnlyAdminCanPinDescription,
    String? groupPermissionMatrixShareCardPermission,
    String? groupPermissionMatrixShareCardPermissionDescription,
    String? groupPermissionMatrixOn,
    String? groupPermissionMatrixOff,
    String? groupPermissionMatrixBusy,
    String? groupPermissionMatrixDismissError,
    String? groupDetailGroupFallback,
    String? groupDetailInfo,
    String? groupDetailName,
    String? groupDetailNotSet,
    String? groupDetailSettingUnavailable,
    String? groupDetailMyInGroup,
    String? groupDetailMyNickname,
    String? groupDetailNicknamePlaceholder,
    String? groupDetailMuteNotif,
    String? groupDetailPinGroup,
    String? groupDetailManage,
    String? groupDetailDiscoverable,
    String? groupDetailJoinMode,
    String? groupDetailJoinOpen,
    String? groupDetailJoinApproval,
    String? groupDetailJoinInvite,
    String? groupDetailJoinRequests,
    String? groupDetailMuteAll,
    String? groupDetailInviteLink,
    String? groupDetailInviteLinkHint,
    String? groupDetailCopyCode,
    String? groupDetailCannotGenerate,
    String? groupDetailPerms,
    String? groupDetailOnlyAdminAtAll,
    String? groupDetailOnlyAdminPin,
    String? groupDetailShareCard,
    String? groupDetailLeave,
    String? groupDetailDissolve,
    String? groupDetailLeaveConfirm,
    String? groupDetailDissolveConfirm,
    String? groupDetailSave,
    String? groupDetailEditName,
    String? groupDetailEditAnnouncement,
    String? groupDetailMemberManage,
    String? groupDetailSetAdmin,
    String? groupDetailUnsetAdmin,
    String? groupDetailMute,
    String? groupDetailUnmute,
    String? groupDetailTransferOwner,
    String? groupDetailConfirmTransfer,
    String? groupDetailRemoveMember,
    String? groupDetailInvite,
    String? groupDetailInviteEmpty,
    String? groupDetailApprove,
    String? groupDetailLoading,
    String? groupDetailNoRequests,
    String? groupDetailUnavailable,
    String? groupDetailUnavailableHint,
    String Function(int count)? groupDetailMemberCount,
    String Function(int count)? groupDetailInviteConfirm,
    String Function(String name)? groupDetailTransferConfirm,
    String? conversationActionSheetPin,
    String? conversationActionSheetUnpin,
    String? conversationActionSheetMute,
    String? conversationActionSheetUnmute,
    String? conversationActionSheetMarkRead,
    String? conversationActionSheetMarkUnread,
    String? conversationActionSheetArchive,
    String? conversationActionSheetUnarchive,
    String? conversationActionSheetHide,
    String? conversationActionSheetClearHistory,
    String? conversationActionSheetEmpty,
    String? conversationHeaderAddActions,
    String? conversationHeaderMoreActions,
    String? messageActionSheetLabel,
    String? messageActionSheetEmpty,
    String? messageSpoilerReveal,
    String Function(int count)? messageImageGroupLabel,
    String Function(int index, int count)? messageImageGroupItem,
    String Function(int index, int count, int more)? messageImageGroupItemMore,
    String? messageActionReply,
    String? messageActionForward,
    String? messageActionRecall,
    String? messageActionResend,
    String? messageActionMultiSelect,
    String? messageActionMark,
    String? messageActionPin,
    String? messageActionPinSelf,
    String? messageActionUnpin,
    String? messageActionCopy,
    String? messageActionPreview,
    String? messageActionSave,
    String? messageActionEdit,
    String? messageActionDelete,
    String? conversationDetailsMessages,
    String? conversationDetailsMute,
    String? conversationDetailsPin,
    String? conversationDetailsMarkRead,
    String? conversationDetailsMarkUnread,
    String? conversationDetailsSync,
    String? conversationDetailsArchive,
    String? conversationDetailsUnarchive,
    String? conversationDetailsClearHistory,
    String? conversationDetailsDelete,
    String? conversationBatchToolbarSelected,
    String? conversationBatchToolbarEmpty,
    String? conversationBatchToolbarMarkRead,
    String? conversationBatchToolbarMute,
    String? conversationBatchToolbarArchive,
    String? conversationBatchToolbarCancel,
    String? conversationBatchToolbarBusy,
    String Function(int count)? conversationBatchToolbarSucceededSummary,
    String Function(int count)? conversationBatchToolbarFailedSummary,
    String? conversationBatchToolbarRetryFailed,
    String? conversationBatchToolbarDismiss,
    String? conversationBatchToolbarExpand,
    String Function(int max)? conversationBatchToolbarMaxSelection,
    String? workspaceFrameLoading,
    String? workspaceFrameEmpty,
    String? workspaceFrameFailure,
    String? workspaceFrameRetry,
    String? conversationWorkspaceChatEmpty,
    String? conversationWorkspaceDetailEmpty,
    String? conversationWorkspaceListFailure,
    String? conversationWorkspaceChatFailure,
    String? conversationWorkspaceDetailFailure,
    String? conversationWorkspaceListLoading,
    String? conversationWorkspaceChatLoading,
    String? conversationWorkspaceDetailLoading,
    String? searchDateRangeFilterCustom,
    String? searchDateRangeFilterFrom,
    String? searchDateRangeFilterTo,
    String? searchDateRangeFilterUnlimited,
    String? searchDateRangeFilterInvalid,
    String? inviteCodeLabel,
    String? inviteCodePlaceholder,
    String? inviteCodeOptional,
    String? inviteCodeChecking,
    String? inviteCodeValid,
    String? inviteCodeInviter,
    String? inviteCodeInvalid,
    String? myInviteTitle,
    String? myInviteCodeLabel,
    String? myInviteCodeUnavailable,
    String? myInviteCopy,
    String? myInviteShare,
    String? myInviteRegenerate,
    String? myInviteRegenerating,
    String? myInviteCooldown,
    String? myInviteUnitMinutes,
    String? myInviteUnitHours,
    String? myInviteUnitDays,
    String? myInviteStatsTitle,
    String? myInviteDirect,
    String? myInviteLevel2,
    String? myInviteLevel3,
    String? myInviteTotal,
    String? myInviteInviteesTitle,
    String? myInviteEmpty,
    String? myInviteLoadMore,
    String? myInviteLoading,
    String? myInviteJoined,
    String? myInviteCountOnly,
    String? storageUsageTitle,
    String? storageUsageUnknownSize,
    String? storageUsageAtLeast,
    String? storageUsageClear,
    String? storageUsageClearing,
    String? storageUsageTotal,
    String? storageUsageDeviceFree,
    String? storageUsageReload,
    String? storageUsageRetry,
    String? storageUsageDismissError,
    String? storageUsageLoading,
    String? storageUsageEmpty,
    String Function(int count)? storageUsageFileCount,
    String? screenShareTitle,
    String? screenShareIdle,
    String? screenShareRequesting,
    String? screenShareSharing,
    String? screenShareViewing,
    String? screenShareUnavailable,
    String? screenShareSourceRow,
    String? screenSharePresenterRow,
    String? screenShareStart,
    String? screenShareStop,
    String? screenShareCancel,
    String? momentAudienceSheetPublic,
    String? momentAudienceSheetPublicHint,
    String? momentAudienceSheetFriends,
    String? momentAudienceSheetFriendsHint,
    String? momentAudienceSheetPrivate,
    String? momentAudienceSheetPrivateHint,
    String? momentAudienceSheetInclude,
    String? momentAudienceSheetIncludeHint,
    String? momentAudienceSheetExclude,
    String? momentAudienceSheetExcludeHint,
    String? momentAudienceSheetPick,
    String? momentAudienceSheetDone,
    String Function(int count)? momentAudienceSheetSelected,
    String? momentsVisibilityHideFromTitle,
    String? momentsVisibilityHideFromHint,
    String? momentsVisibilityMuteTitle,
    String? momentsVisibilityMuteHint,
    String? momentsVisibilityEmpty,
    String? momentsVisibilityRemove,
    String? momentsVisibilityAdd,
    String? conversationHeaderSearch,
    String? conversationHeaderAudioCall,
    String? conversationHeaderVideoCall,
    String? conversationHeaderAddMember,
    String? conversationHeaderShare,
    String? conversationHeaderDetails,
    String Function(int count)? conversationHeaderMemberCount,
    String? presenceOnline,
    String? presenceOffline,
    String? presenceBusy,
    String? presenceAway,
    String? imageLoadFailed,
    String? connectionConnecting,
    String? connectionReconnecting,
    String? connectionOffline,
    String? connectionDisconnected,
    String Function(String reason)? connectionDisconnectedReason,
    String? connectionKicked,
    String? connectionExpired,
    String? connectionReconnect,
    String? connectionSignIn,
    String Function(int count)? groupDetailMembersTitle,
    String? groupDetailSearchMembers,
    String? groupDetailNoMatchingMembers,
    String Function(String name)? profilePanelEditProfile,
    String? momentReplyTo,
    String Function(String name, String text)? momentReplyToComment,
    String? favorites,
    String? moments,
    String? settings,
    String? themeSystem,
    String? themeLight,
    String? themeDark,
    String? inputReveal,
    String? inputHide,
    String? navigationChats,
    String? navigationContacts,
    String? navigationProfile,
    String? navigationFriends,
    String? navigationGroups,
    String? navigationNewFriends,
    String? callDevicePickerPlaceholder,
    String? profileEditorNickname,
    String? profileEditorBio,
    String? profileEditorBioPlaceholder,
    String? profileEditorCancel,
    String? profileEditorSave,
    String? emojiPickerEmoji,
  }) {
    return FlareStrings(
      microphone: microphone ?? this.microphone,
      camera: camera ?? this.camera,
      flipCamera: flipCamera ?? this.flipCamera,
      speaker: speaker ?? this.speaker,
      hangUp: hangUp ?? this.hangUp,
      callWaitingAnswer: callWaitingAnswer ?? this.callWaitingAnswer,
      callCalling: callCalling ?? this.callCalling,
      callRinging: callRinging ?? this.callRinging,
      callConnected: callConnected ?? this.callConnected,
      callReconnecting: callReconnecting ?? this.callReconnecting,
      callFailed: callFailed ?? this.callFailed,
      callReturn: callReturn ?? this.callReturn,
      callMinimize: callMinimize ?? this.callMinimize,
      send: send ?? this.send,
      cancelReply: cancelReply ?? this.cancelReply,
      noContacts: noContacts ?? this.noContacts,
      noResults: noResults ?? this.noResults,
      noMessages: noMessages ?? this.noMessages,
      noContent: noContent ?? this.noContent,
      close: close ?? this.close,
      closePreview: closePreview ?? this.closePreview,
      imagePreviewPrevious: imagePreviewPrevious ?? this.imagePreviewPrevious,
      imagePreviewNext: imagePreviewNext ?? this.imagePreviewNext,
      imagePreviewPosition: imagePreviewPosition ?? this.imagePreviewPosition,
      delete: delete ?? this.delete,
      manage: manage ?? this.manage,
      selectAll: selectAll ?? this.selectAll,
      retry: retry ?? this.retry,
      loading: loading ?? this.loading,
      messagePending: messagePending ?? this.messagePending,
      messageSending: messageSending ?? this.messageSending,
      messageSent: messageSent ?? this.messageSent,
      messageDelivered: messageDelivered ?? this.messageDelivered,
      messageRead: messageRead ?? this.messageRead,
      messageFailed: messageFailed ?? this.messageFailed,
      messageRetrying: messageRetrying ?? this.messageRetrying,
      messageEdited: messageEdited ?? this.messageEdited,
      messageReadOnce: messageReadOnce ?? this.messageReadOnce,
      messageBurnAfterRead: messageBurnAfterRead ?? this.messageBurnAfterRead,
      messageExpired: messageExpired ?? this.messageExpired,
      addReaction: addReaction ?? this.addReaction,
      readReceipt: readReceipt ?? this.readReceipt,
      readTab: readTab ?? this.readTab,
      unreadTab: unreadTab ?? this.unreadTab,
      noReadersYet: noReadersYet ?? this.noReadersYet,
      everyoneHasRead: everyoneHasRead ?? this.everyoneHasRead,
      selectedSuffix: selectedSuffix ?? this.selectedSuffix,
      forwardEach: forwardEach ?? this.forwardEach,
      forwardMerged: forwardMerged ?? this.forwardMerged,
      messageBatchPin: messageBatchPin ?? this.messageBatchPin,
      messageBatchPinSelf: messageBatchPinSelf ?? this.messageBatchPinSelf,
      messageBatchClear: messageBatchClear ?? this.messageBatchClear,
      messageBatchExit: messageBatchExit ?? this.messageBatchExit,
      searchMembers: searchMembers ?? this.searchMembers,
      everyone: everyone ?? this.everyone,
      notifyEveryone: notifyEveryone ?? this.notifyEveryone,
      noMatchingMembers: noMatchingMembers ?? this.noMatchingMembers,
      quickPhrases: quickPhrases ?? this.quickPhrases,
      viewAll: viewAll ?? this.viewAll,
      typing: typing ?? this.typing,
      typingOne: typingOne ?? this.typingOne,
      typingMany: typingMany ?? this.typingMany,
      newMessages: newMessages ?? this.newMessages,
      scrollToLatest: scrollToLatest ?? this.scrollToLatest,
      sendMessage: sendMessage ?? this.sendMessage,
      groupCall: groupCall ?? this.groupCall,
      joinedCount: joinedCount ?? this.joinedCount,
      selfSuffix: selfSuffix ?? this.selfSuffix,
      forwardTo: forwardTo ?? this.forwardTo,
      searchConversations: searchConversations ?? this.searchConversations,
      noMatchingConversations:
          noMatchingConversations ?? this.noMatchingConversations,
      selectedCount: selectedCount ?? this.selectedCount,
      groupAnnouncement: groupAnnouncement ?? this.groupAnnouncement,
      collapse: collapse ?? this.collapse,
      expand: expand ?? this.expand,
      packetClaimed: packetClaimed ?? this.packetClaimed,
      packetFinished: packetFinished ?? this.packetFinished,
      packetTapToClaim: packetTapToClaim ?? this.packetTapToClaim,
      packetBrand: packetBrand ?? this.packetBrand,
      commands: commands ?? this.commands,
      noMatchingCommands: noMatchingCommands ?? this.noMatchingCommands,
      translating: translating ?? this.translating,
      translatedBy: translatedBy ?? this.translatedBy,
      translated: translated ?? this.translated,
      hideOriginal: hideOriginal ?? this.hideOriginal,
      showOriginal: showOriginal ?? this.showOriginal,
      scanToAddMe: scanToAddMe ?? this.scanToAddMe,
      cancel: cancel ?? this.cancel,
      releaseToCancel: releaseToCancel ?? this.releaseToCancel,
      voiceRecordingCancel: voiceRecordingCancel ?? this.voiceRecordingCancel,
      voiceRecordingSend: voiceRecordingSend ?? this.voiceRecordingSend,
      conversationRowDraft: conversationRowDraft ?? this.conversationRowDraft,
      conversationRowMention:
          conversationRowMention ?? this.conversationRowMention,
      createPoll: createPoll ?? this.createPoll,
      pollQuestionHint: pollQuestionHint ?? this.pollQuestionHint,
      pollOptionHint: pollOptionHint ?? this.pollOptionHint,
      removeOption: removeOption ?? this.removeOption,
      addOption: addOption ?? this.addOption,
      allowMultiple: allowMultiple ?? this.allowMultiple,
      submitPoll: submitPoll ?? this.submitPoll,
      chatBackground: chatBackground ?? this.chatBackground,
      decrease: decrease ?? this.decrease,
      increase: increase ?? this.increase,
      previousMonth: previousMonth ?? this.previousMonth,
      nextMonth: nextMonth ?? this.nextMonth,
      yearMonth: yearMonth ?? this.yearMonth,
      ratingStars: ratingStars ?? this.ratingStars,
      unlike: unlike ?? this.unlike,
      like: like ?? this.like,
      comment: comment ?? this.comment,
      changeCover: changeCover ?? this.changeCover,
      post: post ?? this.post,
      momentTextHint: momentTextHint ?? this.momentTextHint,
      addImage: addImage ?? this.addImage,
      pickLocation: pickLocation ?? this.pickLocation,
      pickVisibility: pickVisibility ?? this.pickVisibility,
      more: more ?? this.more,
      momentActions: momentActions ?? this.momentActions,
      removeImage: removeImage ?? this.removeImage,
      hideTranscript: hideTranscript ?? this.hideTranscript,
      showTranscript: showTranscript ?? this.showTranscript,
      recent: recent ?? this.recent,
      searchEmoji: searchEmoji ?? this.searchEmoji,
      noMatchingEmoji: noMatchingEmoji ?? this.noMatchingEmoji,
      emptyStickerPack: emptyStickerPack ?? this.emptyStickerPack,
      sticker: sticker ?? this.sticker,
      actionImage: actionImage ?? this.actionImage,
      actionCamera: actionCamera ?? this.actionCamera,
      actionFile: actionFile ?? this.actionFile,
      actionLocation: actionLocation ?? this.actionLocation,
      actionCard: actionCard ?? this.actionCard,
      actionVote: actionVote ?? this.actionVote,
      actionTask: actionTask ?? this.actionTask,
      actionSchedule: actionSchedule ?? this.actionSchedule,
      actionVideo: actionVideo ?? this.actionVideo,
      actionLink: actionLink ?? this.actionLink,
      actionAnnouncement: actionAnnouncement ?? this.actionAnnouncement,
      actionNotification: actionNotification ?? this.actionNotification,
      actionMiniProgram: actionMiniProgram ?? this.actionMiniProgram,
      actionTranslate: actionTranslate ?? this.actionTranslate,
      incomingVideoCall: incomingVideoCall ?? this.incomingVideoCall,
      incomingVoiceCall: incomingVoiceCall ?? this.incomingVoiceCall,
      reject: reject ?? this.reject,
      accept: accept ?? this.accept,
      back: back ?? this.back,
      confirm: confirm ?? this.confirm,
      confirmCount: confirmCount ?? this.confirmCount,
      memberCount: memberCount ?? this.memberCount,
      clear: clear ?? this.clear,
      wordCharCount: wordCharCount ?? this.wordCharCount,
      changeAvatar: changeAvatar ?? this.changeAvatar,
      qrCode: qrCode ?? this.qrCode,
      myQrCode: myQrCode ?? this.myQrCode,
      play: play ?? this.play,
      pause: pause ?? this.pause,
      download: download ?? this.download,
      voicePlaybackFailed: voicePlaybackFailed ?? this.voicePlaybackFailed,
      videoLoadFailed: videoLoadFailed ?? this.videoLoadFailed,
      permissionNotifications:
          permissionNotifications ?? this.permissionNotifications,
      permissionStorage: permissionStorage ?? this.permissionStorage,
      permissionPhotos: permissionPhotos ?? this.permissionPhotos,
      permissionContacts: permissionContacts ?? this.permissionContacts,
      permissionLocation: permissionLocation ?? this.permissionLocation,
      permissionScreen: permissionScreen ?? this.permissionScreen,
      permissionVerbMicrophone:
          permissionVerbMicrophone ?? this.permissionVerbMicrophone,
      permissionVerbCamera: permissionVerbCamera ?? this.permissionVerbCamera,
      permissionVerbNotifications:
          permissionVerbNotifications ?? this.permissionVerbNotifications,
      permissionVerbStorage:
          permissionVerbStorage ?? this.permissionVerbStorage,
      permissionVerbPhotos: permissionVerbPhotos ?? this.permissionVerbPhotos,
      permissionVerbContacts:
          permissionVerbContacts ?? this.permissionVerbContacts,
      permissionVerbLocation:
          permissionVerbLocation ?? this.permissionVerbLocation,
      permissionVerbScreen: permissionVerbScreen ?? this.permissionVerbScreen,
      permissionThisFeature:
          permissionThisFeature ?? this.permissionThisFeature,
      permissionTitle: permissionTitle ?? this.permissionTitle,
      permissionUndeterminedDescription:
          permissionUndeterminedDescription ??
          this.permissionUndeterminedDescription,
      permissionDeniedDescription:
          permissionDeniedDescription ?? this.permissionDeniedDescription,
      permissionRestrictedDescription:
          permissionRestrictedDescription ??
          this.permissionRestrictedDescription,
      permissionUnavailableDescription:
          permissionUnavailableDescription ??
          this.permissionUnavailableDescription,
      permissionAllow: permissionAllow ?? this.permissionAllow,
      permissionOpenSettings:
          permissionOpenSettings ?? this.permissionOpenSettings,
      permissionStateUndetermined:
          permissionStateUndetermined ?? this.permissionStateUndetermined,
      permissionStateDenied:
          permissionStateDenied ?? this.permissionStateDenied,
      permissionStateRestricted:
          permissionStateRestricted ?? this.permissionStateRestricted,
      permissionStateUnavailable:
          permissionStateUnavailable ?? this.permissionStateUnavailable,
      search: search ?? this.search,
      noGroups: noGroups ?? this.noGroups,
      noConversations: noConversations ?? this.noConversations,
      groupMembers: groupMembers ?? this.groupMembers,
      groupOwner: groupOwner ?? this.groupOwner,
      groupAdmin: groupAdmin ?? this.groupAdmin,
      addMember: addMember ?? this.addMember,
      loginDevices: loginDevices ?? this.loginDevices,
      currentDevice: currentDevice ?? this.currentDevice,
      filesAndMedia: filesAndMedia ?? this.filesAndMedia,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      confirmAction: confirmAction ?? this.confirmAction,
      transferQueue: transferQueue ?? this.transferQueue,
      noTransfers: noTransfers ?? this.noTransfers,
      retryFailedTransfers: retryFailedTransfers ?? this.retryFailedTransfers,
      reload: reload ?? this.reload,
      today: today ?? this.today,
      yesterday: yesterday ?? this.yesterday,
      timeRange: timeRange ?? this.timeRange,
      searchIdleHint: searchIdleHint ?? this.searchIdleHint,
      permissionDismiss: permissionDismiss ?? this.permissionDismiss,
      composerPlaceholder: composerPlaceholder ?? this.composerPlaceholder,
      composerReply: composerReply ?? this.composerReply,
      composerVoice: composerVoice ?? this.composerVoice,
      composerVoiceRecording:
          composerVoiceRecording ?? this.composerVoiceRecording,
      composerVoiceCancel: composerVoiceCancel ?? this.composerVoiceCancel,
      composerBold: composerBold ?? this.composerBold,
      composerItalic: composerItalic ?? this.composerItalic,
      composerStrike: composerStrike ?? this.composerStrike,
      composerUnderline: composerUnderline ?? this.composerUnderline,
      composerCode: composerCode ?? this.composerCode,
      composerCodeBlock: composerCodeBlock ?? this.composerCodeBlock,
      composerLink: composerLink ?? this.composerLink,
      composerParagraph: composerParagraph ?? this.composerParagraph,
      composerDivider: composerDivider ?? this.composerDivider,
      composerHeading: composerHeading ?? this.composerHeading,
      composerQuote: composerQuote ?? this.composerQuote,
      composerList: composerList ?? this.composerList,
      composerOrderedList: composerOrderedList ?? this.composerOrderedList,
      composerEmoji: composerEmoji ?? this.composerEmoji,
      composerMention: composerMention ?? this.composerMention,
      composerVoiceInput: composerVoiceInput ?? this.composerVoiceInput,
      composerRichText: composerRichText ?? this.composerRichText,
      composerExpandInput: composerExpandInput ?? this.composerExpandInput,
      inlineVoiceMicrophoneUnavailable:
          inlineVoiceMicrophoneUnavailable ??
          this.inlineVoiceMicrophoneUnavailable,
      inlineVoiceSendFailed:
          inlineVoiceSendFailed ?? this.inlineVoiceSendFailed,
      inlineVoiceKeyboard: inlineVoiceKeyboard ?? this.inlineVoiceKeyboard,
      inlineVoicePause: inlineVoicePause ?? this.inlineVoicePause,
      inlineVoiceStart: inlineVoiceStart ?? this.inlineVoiceStart,
      inlineVoicePreview: inlineVoicePreview ?? this.inlineVoicePreview,
      inlineVoiceResume: inlineVoiceResume ?? this.inlineVoiceResume,
      inlineVoiceDiscard: inlineVoiceDiscard ?? this.inlineVoiceDiscard,
      messageListLoadOlder: messageListLoadOlder ?? this.messageListLoadOlder,
      messageRecalledSelf: messageRecalledSelf ?? this.messageRecalledSelf,
      messageRecalledPeer: messageRecalledPeer ?? this.messageRecalledPeer,
      messageRecalledGroupOther:
          messageRecalledGroupOther ?? this.messageRecalledGroupOther,
      quotedMessage: quotedMessage ?? this.quotedMessage,
      jumpedToMessage: jumpedToMessage ?? this.jumpedToMessage,
      previewMessage: previewMessage ?? this.previewMessage,
      previewRichText: previewRichText ?? this.previewRichText,
      previewGif: previewGif ?? this.previewGif,
      previewImage: previewImage ?? this.previewImage,
      previewImageNamed: previewImageNamed ?? this.previewImageNamed,
      previewVideo: previewVideo ?? this.previewVideo,
      previewAudio: previewAudio ?? this.previewAudio,
      previewFile: previewFile ?? this.previewFile,
      previewFileNamed: previewFileNamed ?? this.previewFileNamed,
      previewLocation: previewLocation ?? this.previewLocation,
      previewLocationNamed: previewLocationNamed ?? this.previewLocationNamed,
      previewCard: previewCard ?? this.previewCard,
      previewCardNamed: previewCardNamed ?? this.previewCardNamed,
      previewSticker: previewSticker ?? this.previewSticker,
      previewEmoji: previewEmoji ?? this.previewEmoji,
      previewQuote: previewQuote ?? this.previewQuote,
      previewLink: previewLink ?? this.previewLink,
      previewForward: previewForward ?? this.previewForward,
      previewForwardCount: previewForwardCount ?? this.previewForwardCount,
      previewMiniProgram: previewMiniProgram ?? this.previewMiniProgram,
      previewImageGroup: previewImageGroup ?? this.previewImageGroup,
      previewImageGroupCount:
          previewImageGroupCount ?? this.previewImageGroupCount,
      previewSystem: previewSystem ?? this.previewSystem,
      previewNotification: previewNotification ?? this.previewNotification,
      previewVote: previewVote ?? this.previewVote,
      previewTask: previewTask ?? this.previewTask,
      previewSchedule: previewSchedule ?? this.previewSchedule,
      previewAnnouncement: previewAnnouncement ?? this.previewAnnouncement,
      previewCustom: previewCustom ?? this.previewCustom,
      previewPlaceholder: previewPlaceholder ?? this.previewPlaceholder,
      previewUnknown: previewUnknown ?? this.previewUnknown,
      unknownMessageHint: unknownMessageHint ?? this.unknownMessageHint,
      unknownMessageUnsupported:
          unknownMessageUnsupported ?? this.unknownMessageUnsupported,
      unknownMessageDiagnostic:
          unknownMessageDiagnostic ?? this.unknownMessageDiagnostic,
      emojiPickerEmpty: emojiPickerEmpty ?? this.emojiPickerEmpty,
      stickerPanelEmpty: stickerPanelEmpty ?? this.stickerPanelEmpty,
      quickPhrasesTitle: quickPhrasesTitle ?? this.quickPhrasesTitle,
      qrCardHint: qrCardHint ?? this.qrCardHint,
      qrCardUnavailable: qrCardUnavailable ?? this.qrCardUnavailable,
      readReceiptSheetReadEmpty:
          readReceiptSheetReadEmpty ?? this.readReceiptSheetReadEmpty,
      readReceiptSheetUnreadEmpty:
          readReceiptSheetUnreadEmpty ?? this.readReceiptSheetUnreadEmpty,
      announcementReadBarConfirmRead:
          announcementReadBarConfirmRead ?? this.announcementReadBarConfirmRead,
      announcementReadBarViewUnread:
          announcementReadBarViewUnread ?? this.announcementReadBarViewUnread,
      announcementReadBarReadCount:
          announcementReadBarReadCount ?? this.announcementReadBarReadCount,
      newFriendRequestsEmpty:
          newFriendRequestsEmpty ?? this.newFriendRequestsEmpty,
      newFriendRequestsAccept:
          newFriendRequestsAccept ?? this.newFriendRequestsAccept,
      newFriendRequestsReject:
          newFriendRequestsReject ?? this.newFriendRequestsReject,
      newFriendRequestsPending:
          newFriendRequestsPending ?? this.newFriendRequestsPending,
      newFriendRequestsWithdraw:
          newFriendRequestsWithdraw ?? this.newFriendRequestsWithdraw,
      contactMatchListAdd: contactMatchListAdd ?? this.contactMatchListAdd,
      contactMatchListEmpty:
          contactMatchListEmpty ?? this.contactMatchListEmpty,
      startConversationSheetSearchPlaceholder:
          startConversationSheetSearchPlaceholder ??
          this.startConversationSheetSearchPlaceholder,
      startConversationSheetEmpty:
          startConversationSheetEmpty ?? this.startConversationSheetEmpty,
      unknownUserPlaceholderUnknown:
          unknownUserPlaceholderUnknown ?? this.unknownUserPlaceholderUnknown,
      unknownUserPlaceholderDeactivated:
          unknownUserPlaceholderDeactivated ??
          this.unknownUserPlaceholderDeactivated,
      unknownUserPlaceholderBlocked:
          unknownUserPlaceholderBlocked ?? this.unknownUserPlaceholderBlocked,
      unknownUserPlaceholderUnreachable:
          unknownUserPlaceholderUnreachable ??
          this.unknownUserPlaceholderUnreachable,
      contactDetailInfo: contactDetailInfo ?? this.contactDetailInfo,
      contactDetailRemark: contactDetailRemark ?? this.contactDetailRemark,
      contactDetailDescription:
          contactDetailDescription ?? this.contactDetailDescription,
      contactDetailStar: contactDetailStar ?? this.contactDetailStar,
      contactDetailNotSet: contactDetailNotSet ?? this.contactDetailNotSet,
      contactDetailVoice: contactDetailVoice ?? this.contactDetailVoice,
      contactDetailVideo: contactDetailVideo ?? this.contactDetailVideo,
      contactDetailBlock: contactDetailBlock ?? this.contactDetailBlock,
      contactDetailRemove: contactDetailRemove ?? this.contactDetailRemove,
      relationActionBarAdd: relationActionBarAdd ?? this.relationActionBarAdd,
      relationActionBarAccept:
          relationActionBarAccept ?? this.relationActionBarAccept,
      relationActionBarRemove:
          relationActionBarRemove ?? this.relationActionBarRemove,
      relationActionBarBlock:
          relationActionBarBlock ?? this.relationActionBarBlock,
      relationActionBarUnblock:
          relationActionBarUnblock ?? this.relationActionBarUnblock,
      relationActionBarPending:
          relationActionBarPending ?? this.relationActionBarPending,
      relationActionBarBusy:
          relationActionBarBusy ?? this.relationActionBarBusy,
      relationActionBarDismissError:
          relationActionBarDismissError ?? this.relationActionBarDismissError,
      relationActionBarEmpty:
          relationActionBarEmpty ?? this.relationActionBarEmpty,
      memberRoleSheetMemberRole:
          memberRoleSheetMemberRole ?? this.memberRoleSheetMemberRole,
      memberRoleSheetMuted: memberRoleSheetMuted ?? this.memberRoleSheetMuted,
      memberRoleSheetPromote:
          memberRoleSheetPromote ?? this.memberRoleSheetPromote,
      memberRoleSheetDemote:
          memberRoleSheetDemote ?? this.memberRoleSheetDemote,
      memberRoleSheetMute: memberRoleSheetMute ?? this.memberRoleSheetMute,
      memberRoleSheetUnmute:
          memberRoleSheetUnmute ?? this.memberRoleSheetUnmute,
      memberRoleSheetRemove:
          memberRoleSheetRemove ?? this.memberRoleSheetRemove,
      memberRoleSheetTransferOwner:
          memberRoleSheetTransferOwner ?? this.memberRoleSheetTransferOwner,
      memberRoleSheetDangerGroup:
          memberRoleSheetDangerGroup ?? this.memberRoleSheetDangerGroup,
      memberRoleSheetEmpty: memberRoleSheetEmpty ?? this.memberRoleSheetEmpty,
      memberRoleSheetOwnerProtected:
          memberRoleSheetOwnerProtected ?? this.memberRoleSheetOwnerProtected,
      groupPermissionMatrixTitle:
          groupPermissionMatrixTitle ?? this.groupPermissionMatrixTitle,
      groupPermissionMatrixReadOnlyHint:
          groupPermissionMatrixReadOnlyHint ??
          this.groupPermissionMatrixReadOnlyHint,
      groupPermissionMatrixJoinPolicy:
          groupPermissionMatrixJoinPolicy ??
          this.groupPermissionMatrixJoinPolicy,
      groupPermissionMatrixJoinPolicyDescription:
          groupPermissionMatrixJoinPolicyDescription ??
          this.groupPermissionMatrixJoinPolicyDescription,
      groupPermissionMatrixJoinInvite:
          groupPermissionMatrixJoinInvite ??
          this.groupPermissionMatrixJoinInvite,
      groupPermissionMatrixJoinApproval:
          groupPermissionMatrixJoinApproval ??
          this.groupPermissionMatrixJoinApproval,
      groupPermissionMatrixJoinOpen:
          groupPermissionMatrixJoinOpen ?? this.groupPermissionMatrixJoinOpen,
      groupPermissionMatrixUnknownJoinPolicy:
          groupPermissionMatrixUnknownJoinPolicy ??
          this.groupPermissionMatrixUnknownJoinPolicy,
      groupPermissionMatrixMuteAll:
          groupPermissionMatrixMuteAll ?? this.groupPermissionMatrixMuteAll,
      groupPermissionMatrixMuteAllDescription:
          groupPermissionMatrixMuteAllDescription ??
          this.groupPermissionMatrixMuteAllDescription,
      groupPermissionMatrixOnlyAdminCanAtAll:
          groupPermissionMatrixOnlyAdminCanAtAll ??
          this.groupPermissionMatrixOnlyAdminCanAtAll,
      groupPermissionMatrixOnlyAdminCanAtAllDescription:
          groupPermissionMatrixOnlyAdminCanAtAllDescription ??
          this.groupPermissionMatrixOnlyAdminCanAtAllDescription,
      groupPermissionMatrixOnlyAdminCanPin:
          groupPermissionMatrixOnlyAdminCanPin ??
          this.groupPermissionMatrixOnlyAdminCanPin,
      groupPermissionMatrixOnlyAdminCanPinDescription:
          groupPermissionMatrixOnlyAdminCanPinDescription ??
          this.groupPermissionMatrixOnlyAdminCanPinDescription,
      groupPermissionMatrixShareCardPermission:
          groupPermissionMatrixShareCardPermission ??
          this.groupPermissionMatrixShareCardPermission,
      groupPermissionMatrixShareCardPermissionDescription:
          groupPermissionMatrixShareCardPermissionDescription ??
          this.groupPermissionMatrixShareCardPermissionDescription,
      groupPermissionMatrixOn:
          groupPermissionMatrixOn ?? this.groupPermissionMatrixOn,
      groupPermissionMatrixOff:
          groupPermissionMatrixOff ?? this.groupPermissionMatrixOff,
      groupPermissionMatrixBusy:
          groupPermissionMatrixBusy ?? this.groupPermissionMatrixBusy,
      groupPermissionMatrixDismissError:
          groupPermissionMatrixDismissError ??
          this.groupPermissionMatrixDismissError,
      groupDetailGroupFallback:
          groupDetailGroupFallback ?? this.groupDetailGroupFallback,
      groupDetailInfo: groupDetailInfo ?? this.groupDetailInfo,
      groupDetailName: groupDetailName ?? this.groupDetailName,
      groupDetailNotSet: groupDetailNotSet ?? this.groupDetailNotSet,
      groupDetailSettingUnavailable:
          groupDetailSettingUnavailable ?? this.groupDetailSettingUnavailable,
      groupDetailMyInGroup: groupDetailMyInGroup ?? this.groupDetailMyInGroup,
      groupDetailMyNickname:
          groupDetailMyNickname ?? this.groupDetailMyNickname,
      groupDetailNicknamePlaceholder:
          groupDetailNicknamePlaceholder ?? this.groupDetailNicknamePlaceholder,
      groupDetailMuteNotif: groupDetailMuteNotif ?? this.groupDetailMuteNotif,
      groupDetailPinGroup: groupDetailPinGroup ?? this.groupDetailPinGroup,
      groupDetailManage: groupDetailManage ?? this.groupDetailManage,
      groupDetailDiscoverable:
          groupDetailDiscoverable ?? this.groupDetailDiscoverable,
      groupDetailJoinMode: groupDetailJoinMode ?? this.groupDetailJoinMode,
      groupDetailJoinOpen: groupDetailJoinOpen ?? this.groupDetailJoinOpen,
      groupDetailJoinApproval:
          groupDetailJoinApproval ?? this.groupDetailJoinApproval,
      groupDetailJoinInvite:
          groupDetailJoinInvite ?? this.groupDetailJoinInvite,
      groupDetailJoinRequests:
          groupDetailJoinRequests ?? this.groupDetailJoinRequests,
      groupDetailMuteAll: groupDetailMuteAll ?? this.groupDetailMuteAll,
      groupDetailInviteLink:
          groupDetailInviteLink ?? this.groupDetailInviteLink,
      groupDetailInviteLinkHint:
          groupDetailInviteLinkHint ?? this.groupDetailInviteLinkHint,
      groupDetailCopyCode: groupDetailCopyCode ?? this.groupDetailCopyCode,
      groupDetailCannotGenerate:
          groupDetailCannotGenerate ?? this.groupDetailCannotGenerate,
      groupDetailPerms: groupDetailPerms ?? this.groupDetailPerms,
      groupDetailOnlyAdminAtAll:
          groupDetailOnlyAdminAtAll ?? this.groupDetailOnlyAdminAtAll,
      groupDetailOnlyAdminPin:
          groupDetailOnlyAdminPin ?? this.groupDetailOnlyAdminPin,
      groupDetailShareCard: groupDetailShareCard ?? this.groupDetailShareCard,
      groupDetailLeave: groupDetailLeave ?? this.groupDetailLeave,
      groupDetailDissolve: groupDetailDissolve ?? this.groupDetailDissolve,
      groupDetailLeaveConfirm:
          groupDetailLeaveConfirm ?? this.groupDetailLeaveConfirm,
      groupDetailDissolveConfirm:
          groupDetailDissolveConfirm ?? this.groupDetailDissolveConfirm,
      groupDetailSave: groupDetailSave ?? this.groupDetailSave,
      groupDetailEditName: groupDetailEditName ?? this.groupDetailEditName,
      groupDetailEditAnnouncement:
          groupDetailEditAnnouncement ?? this.groupDetailEditAnnouncement,
      groupDetailMemberManage:
          groupDetailMemberManage ?? this.groupDetailMemberManage,
      groupDetailSetAdmin: groupDetailSetAdmin ?? this.groupDetailSetAdmin,
      groupDetailUnsetAdmin:
          groupDetailUnsetAdmin ?? this.groupDetailUnsetAdmin,
      groupDetailMute: groupDetailMute ?? this.groupDetailMute,
      groupDetailUnmute: groupDetailUnmute ?? this.groupDetailUnmute,
      groupDetailTransferOwner:
          groupDetailTransferOwner ?? this.groupDetailTransferOwner,
      groupDetailConfirmTransfer:
          groupDetailConfirmTransfer ?? this.groupDetailConfirmTransfer,
      groupDetailRemoveMember:
          groupDetailRemoveMember ?? this.groupDetailRemoveMember,
      groupDetailInvite: groupDetailInvite ?? this.groupDetailInvite,
      groupDetailInviteEmpty:
          groupDetailInviteEmpty ?? this.groupDetailInviteEmpty,
      groupDetailApprove: groupDetailApprove ?? this.groupDetailApprove,
      groupDetailLoading: groupDetailLoading ?? this.groupDetailLoading,
      groupDetailNoRequests:
          groupDetailNoRequests ?? this.groupDetailNoRequests,
      groupDetailUnavailable:
          groupDetailUnavailable ?? this.groupDetailUnavailable,
      groupDetailUnavailableHint:
          groupDetailUnavailableHint ?? this.groupDetailUnavailableHint,
      groupDetailMemberCount:
          groupDetailMemberCount ?? this.groupDetailMemberCount,
      groupDetailInviteConfirm:
          groupDetailInviteConfirm ?? this.groupDetailInviteConfirm,
      groupDetailTransferConfirm:
          groupDetailTransferConfirm ?? this.groupDetailTransferConfirm,
      conversationActionSheetPin:
          conversationActionSheetPin ?? this.conversationActionSheetPin,
      conversationActionSheetUnpin:
          conversationActionSheetUnpin ?? this.conversationActionSheetUnpin,
      conversationActionSheetMute:
          conversationActionSheetMute ?? this.conversationActionSheetMute,
      conversationActionSheetUnmute:
          conversationActionSheetUnmute ?? this.conversationActionSheetUnmute,
      conversationActionSheetMarkRead:
          conversationActionSheetMarkRead ??
          this.conversationActionSheetMarkRead,
      conversationActionSheetMarkUnread:
          conversationActionSheetMarkUnread ??
          this.conversationActionSheetMarkUnread,
      conversationActionSheetArchive:
          conversationActionSheetArchive ?? this.conversationActionSheetArchive,
      conversationActionSheetUnarchive:
          conversationActionSheetUnarchive ??
          this.conversationActionSheetUnarchive,
      conversationActionSheetHide:
          conversationActionSheetHide ?? this.conversationActionSheetHide,
      conversationActionSheetClearHistory:
          conversationActionSheetClearHistory ??
          this.conversationActionSheetClearHistory,
      conversationActionSheetEmpty:
          conversationActionSheetEmpty ?? this.conversationActionSheetEmpty,
      conversationHeaderAddActions:
          conversationHeaderAddActions ?? this.conversationHeaderAddActions,
      conversationHeaderMoreActions:
          conversationHeaderMoreActions ?? this.conversationHeaderMoreActions,
      messageActionSheetLabel:
          messageActionSheetLabel ?? this.messageActionSheetLabel,
      messageActionSheetEmpty:
          messageActionSheetEmpty ?? this.messageActionSheetEmpty,
      messageSpoilerReveal: messageSpoilerReveal ?? this.messageSpoilerReveal,
      messageImageGroupLabel:
          messageImageGroupLabel ?? this.messageImageGroupLabel,
      messageImageGroupItem:
          messageImageGroupItem ?? this.messageImageGroupItem,
      messageImageGroupItemMore:
          messageImageGroupItemMore ?? this.messageImageGroupItemMore,
      messageActionReply: messageActionReply ?? this.messageActionReply,
      messageActionForward: messageActionForward ?? this.messageActionForward,
      messageActionRecall: messageActionRecall ?? this.messageActionRecall,
      messageActionResend: messageActionResend ?? this.messageActionResend,
      messageActionMultiSelect:
          messageActionMultiSelect ?? this.messageActionMultiSelect,
      messageActionMark: messageActionMark ?? this.messageActionMark,
      messageActionPin: messageActionPin ?? this.messageActionPin,
      messageActionPinSelf: messageActionPinSelf ?? this.messageActionPinSelf,
      messageActionUnpin: messageActionUnpin ?? this.messageActionUnpin,
      messageActionCopy: messageActionCopy ?? this.messageActionCopy,
      messageActionPreview: messageActionPreview ?? this.messageActionPreview,
      messageActionSave: messageActionSave ?? this.messageActionSave,
      messageActionEdit: messageActionEdit ?? this.messageActionEdit,
      messageActionDelete: messageActionDelete ?? this.messageActionDelete,
      conversationDetailsMessages:
          conversationDetailsMessages ?? this.conversationDetailsMessages,
      conversationDetailsMute:
          conversationDetailsMute ?? this.conversationDetailsMute,
      conversationDetailsPin:
          conversationDetailsPin ?? this.conversationDetailsPin,
      conversationDetailsMarkRead:
          conversationDetailsMarkRead ?? this.conversationDetailsMarkRead,
      conversationDetailsMarkUnread:
          conversationDetailsMarkUnread ?? this.conversationDetailsMarkUnread,
      conversationDetailsSync:
          conversationDetailsSync ?? this.conversationDetailsSync,
      conversationDetailsArchive:
          conversationDetailsArchive ?? this.conversationDetailsArchive,
      conversationDetailsUnarchive:
          conversationDetailsUnarchive ?? this.conversationDetailsUnarchive,
      conversationDetailsClearHistory:
          conversationDetailsClearHistory ??
          this.conversationDetailsClearHistory,
      conversationDetailsDelete:
          conversationDetailsDelete ?? this.conversationDetailsDelete,
      conversationBatchToolbarSelected:
          conversationBatchToolbarSelected ??
          this.conversationBatchToolbarSelected,
      conversationBatchToolbarEmpty:
          conversationBatchToolbarEmpty ?? this.conversationBatchToolbarEmpty,
      conversationBatchToolbarMarkRead:
          conversationBatchToolbarMarkRead ??
          this.conversationBatchToolbarMarkRead,
      conversationBatchToolbarMute:
          conversationBatchToolbarMute ?? this.conversationBatchToolbarMute,
      conversationBatchToolbarArchive:
          conversationBatchToolbarArchive ??
          this.conversationBatchToolbarArchive,
      conversationBatchToolbarCancel:
          conversationBatchToolbarCancel ?? this.conversationBatchToolbarCancel,
      conversationBatchToolbarBusy:
          conversationBatchToolbarBusy ?? this.conversationBatchToolbarBusy,
      conversationBatchToolbarSucceededSummary:
          conversationBatchToolbarSucceededSummary ??
          this.conversationBatchToolbarSucceededSummary,
      conversationBatchToolbarFailedSummary:
          conversationBatchToolbarFailedSummary ??
          this.conversationBatchToolbarFailedSummary,
      conversationBatchToolbarRetryFailed:
          conversationBatchToolbarRetryFailed ??
          this.conversationBatchToolbarRetryFailed,
      conversationBatchToolbarDismiss:
          conversationBatchToolbarDismiss ??
          this.conversationBatchToolbarDismiss,
      conversationBatchToolbarExpand:
          conversationBatchToolbarExpand ?? this.conversationBatchToolbarExpand,
      conversationBatchToolbarMaxSelection:
          conversationBatchToolbarMaxSelection ??
          this.conversationBatchToolbarMaxSelection,
      workspaceFrameLoading:
          workspaceFrameLoading ?? this.workspaceFrameLoading,
      workspaceFrameEmpty: workspaceFrameEmpty ?? this.workspaceFrameEmpty,
      workspaceFrameFailure:
          workspaceFrameFailure ?? this.workspaceFrameFailure,
      workspaceFrameRetry: workspaceFrameRetry ?? this.workspaceFrameRetry,
      conversationWorkspaceChatEmpty:
          conversationWorkspaceChatEmpty ?? this.conversationWorkspaceChatEmpty,
      conversationWorkspaceDetailEmpty:
          conversationWorkspaceDetailEmpty ??
          this.conversationWorkspaceDetailEmpty,
      conversationWorkspaceListFailure:
          conversationWorkspaceListFailure ??
          this.conversationWorkspaceListFailure,
      conversationWorkspaceChatFailure:
          conversationWorkspaceChatFailure ??
          this.conversationWorkspaceChatFailure,
      conversationWorkspaceDetailFailure:
          conversationWorkspaceDetailFailure ??
          this.conversationWorkspaceDetailFailure,
      conversationWorkspaceListLoading:
          conversationWorkspaceListLoading ??
          this.conversationWorkspaceListLoading,
      conversationWorkspaceChatLoading:
          conversationWorkspaceChatLoading ??
          this.conversationWorkspaceChatLoading,
      conversationWorkspaceDetailLoading:
          conversationWorkspaceDetailLoading ??
          this.conversationWorkspaceDetailLoading,
      searchDateRangeFilterCustom:
          searchDateRangeFilterCustom ?? this.searchDateRangeFilterCustom,
      searchDateRangeFilterFrom:
          searchDateRangeFilterFrom ?? this.searchDateRangeFilterFrom,
      searchDateRangeFilterTo:
          searchDateRangeFilterTo ?? this.searchDateRangeFilterTo,
      searchDateRangeFilterUnlimited:
          searchDateRangeFilterUnlimited ?? this.searchDateRangeFilterUnlimited,
      searchDateRangeFilterInvalid:
          searchDateRangeFilterInvalid ?? this.searchDateRangeFilterInvalid,
      inviteCodeLabel: inviteCodeLabel ?? this.inviteCodeLabel,
      inviteCodePlaceholder:
          inviteCodePlaceholder ?? this.inviteCodePlaceholder,
      inviteCodeOptional: inviteCodeOptional ?? this.inviteCodeOptional,
      inviteCodeChecking: inviteCodeChecking ?? this.inviteCodeChecking,
      inviteCodeValid: inviteCodeValid ?? this.inviteCodeValid,
      inviteCodeInviter: inviteCodeInviter ?? this.inviteCodeInviter,
      inviteCodeInvalid: inviteCodeInvalid ?? this.inviteCodeInvalid,
      myInviteTitle: myInviteTitle ?? this.myInviteTitle,
      myInviteCodeLabel: myInviteCodeLabel ?? this.myInviteCodeLabel,
      myInviteCodeUnavailable:
          myInviteCodeUnavailable ?? this.myInviteCodeUnavailable,
      myInviteCopy: myInviteCopy ?? this.myInviteCopy,
      myInviteShare: myInviteShare ?? this.myInviteShare,
      myInviteRegenerate: myInviteRegenerate ?? this.myInviteRegenerate,
      myInviteRegenerating: myInviteRegenerating ?? this.myInviteRegenerating,
      myInviteCooldown: myInviteCooldown ?? this.myInviteCooldown,
      myInviteUnitMinutes: myInviteUnitMinutes ?? this.myInviteUnitMinutes,
      myInviteUnitHours: myInviteUnitHours ?? this.myInviteUnitHours,
      myInviteUnitDays: myInviteUnitDays ?? this.myInviteUnitDays,
      myInviteStatsTitle: myInviteStatsTitle ?? this.myInviteStatsTitle,
      myInviteDirect: myInviteDirect ?? this.myInviteDirect,
      myInviteLevel2: myInviteLevel2 ?? this.myInviteLevel2,
      myInviteLevel3: myInviteLevel3 ?? this.myInviteLevel3,
      myInviteTotal: myInviteTotal ?? this.myInviteTotal,
      myInviteInviteesTitle:
          myInviteInviteesTitle ?? this.myInviteInviteesTitle,
      myInviteEmpty: myInviteEmpty ?? this.myInviteEmpty,
      myInviteLoadMore: myInviteLoadMore ?? this.myInviteLoadMore,
      myInviteLoading: myInviteLoading ?? this.myInviteLoading,
      myInviteJoined: myInviteJoined ?? this.myInviteJoined,
      myInviteCountOnly: myInviteCountOnly ?? this.myInviteCountOnly,
      storageUsageTitle: storageUsageTitle ?? this.storageUsageTitle,
      storageUsageUnknownSize:
          storageUsageUnknownSize ?? this.storageUsageUnknownSize,
      storageUsageAtLeast: storageUsageAtLeast ?? this.storageUsageAtLeast,
      storageUsageClear: storageUsageClear ?? this.storageUsageClear,
      storageUsageClearing: storageUsageClearing ?? this.storageUsageClearing,
      storageUsageTotal: storageUsageTotal ?? this.storageUsageTotal,
      storageUsageDeviceFree:
          storageUsageDeviceFree ?? this.storageUsageDeviceFree,
      storageUsageReload: storageUsageReload ?? this.storageUsageReload,
      storageUsageRetry: storageUsageRetry ?? this.storageUsageRetry,
      storageUsageDismissError:
          storageUsageDismissError ?? this.storageUsageDismissError,
      storageUsageLoading: storageUsageLoading ?? this.storageUsageLoading,
      storageUsageEmpty: storageUsageEmpty ?? this.storageUsageEmpty,
      storageUsageFileCount:
          storageUsageFileCount ?? this.storageUsageFileCount,
      screenShareTitle: screenShareTitle ?? this.screenShareTitle,
      screenShareIdle: screenShareIdle ?? this.screenShareIdle,
      screenShareRequesting:
          screenShareRequesting ?? this.screenShareRequesting,
      screenShareSharing: screenShareSharing ?? this.screenShareSharing,
      screenShareViewing: screenShareViewing ?? this.screenShareViewing,
      screenShareUnavailable:
          screenShareUnavailable ?? this.screenShareUnavailable,
      screenShareSourceRow: screenShareSourceRow ?? this.screenShareSourceRow,
      screenSharePresenterRow:
          screenSharePresenterRow ?? this.screenSharePresenterRow,
      screenShareStart: screenShareStart ?? this.screenShareStart,
      screenShareStop: screenShareStop ?? this.screenShareStop,
      screenShareCancel: screenShareCancel ?? this.screenShareCancel,
      momentAudienceSheetPublic:
          momentAudienceSheetPublic ?? this.momentAudienceSheetPublic,
      momentAudienceSheetPublicHint:
          momentAudienceSheetPublicHint ?? this.momentAudienceSheetPublicHint,
      momentAudienceSheetFriends:
          momentAudienceSheetFriends ?? this.momentAudienceSheetFriends,
      momentAudienceSheetFriendsHint:
          momentAudienceSheetFriendsHint ?? this.momentAudienceSheetFriendsHint,
      momentAudienceSheetPrivate:
          momentAudienceSheetPrivate ?? this.momentAudienceSheetPrivate,
      momentAudienceSheetPrivateHint:
          momentAudienceSheetPrivateHint ?? this.momentAudienceSheetPrivateHint,
      momentAudienceSheetInclude:
          momentAudienceSheetInclude ?? this.momentAudienceSheetInclude,
      momentAudienceSheetIncludeHint:
          momentAudienceSheetIncludeHint ?? this.momentAudienceSheetIncludeHint,
      momentAudienceSheetExclude:
          momentAudienceSheetExclude ?? this.momentAudienceSheetExclude,
      momentAudienceSheetExcludeHint:
          momentAudienceSheetExcludeHint ?? this.momentAudienceSheetExcludeHint,
      momentAudienceSheetPick:
          momentAudienceSheetPick ?? this.momentAudienceSheetPick,
      momentAudienceSheetDone:
          momentAudienceSheetDone ?? this.momentAudienceSheetDone,
      momentAudienceSheetSelected:
          momentAudienceSheetSelected ?? this.momentAudienceSheetSelected,
      momentsVisibilityHideFromTitle:
          momentsVisibilityHideFromTitle ?? this.momentsVisibilityHideFromTitle,
      momentsVisibilityHideFromHint:
          momentsVisibilityHideFromHint ?? this.momentsVisibilityHideFromHint,
      momentsVisibilityMuteTitle:
          momentsVisibilityMuteTitle ?? this.momentsVisibilityMuteTitle,
      momentsVisibilityMuteHint:
          momentsVisibilityMuteHint ?? this.momentsVisibilityMuteHint,
      momentsVisibilityEmpty:
          momentsVisibilityEmpty ?? this.momentsVisibilityEmpty,
      momentsVisibilityRemove:
          momentsVisibilityRemove ?? this.momentsVisibilityRemove,
      momentsVisibilityAdd: momentsVisibilityAdd ?? this.momentsVisibilityAdd,
      conversationHeaderSearch:
          conversationHeaderSearch ?? this.conversationHeaderSearch,
      conversationHeaderAudioCall:
          conversationHeaderAudioCall ?? this.conversationHeaderAudioCall,
      conversationHeaderVideoCall:
          conversationHeaderVideoCall ?? this.conversationHeaderVideoCall,
      conversationHeaderAddMember:
          conversationHeaderAddMember ?? this.conversationHeaderAddMember,
      conversationHeaderShare:
          conversationHeaderShare ?? this.conversationHeaderShare,
      conversationHeaderDetails:
          conversationHeaderDetails ?? this.conversationHeaderDetails,
      conversationHeaderMemberCount:
          conversationHeaderMemberCount ?? this.conversationHeaderMemberCount,
      presenceOnline: presenceOnline ?? this.presenceOnline,
      presenceOffline: presenceOffline ?? this.presenceOffline,
      presenceBusy: presenceBusy ?? this.presenceBusy,
      presenceAway: presenceAway ?? this.presenceAway,
      imageLoadFailed: imageLoadFailed ?? this.imageLoadFailed,
      connectionConnecting: connectionConnecting ?? this.connectionConnecting,
      connectionReconnecting:
          connectionReconnecting ?? this.connectionReconnecting,
      connectionOffline: connectionOffline ?? this.connectionOffline,
      connectionDisconnected:
          connectionDisconnected ?? this.connectionDisconnected,
      connectionDisconnectedReason:
          connectionDisconnectedReason ?? this.connectionDisconnectedReason,
      connectionKicked: connectionKicked ?? this.connectionKicked,
      connectionExpired: connectionExpired ?? this.connectionExpired,
      connectionReconnect: connectionReconnect ?? this.connectionReconnect,
      connectionSignIn: connectionSignIn ?? this.connectionSignIn,
      groupDetailMembersTitle:
          groupDetailMembersTitle ?? this.groupDetailMembersTitle,
      groupDetailSearchMembers:
          groupDetailSearchMembers ?? this.groupDetailSearchMembers,
      groupDetailNoMatchingMembers:
          groupDetailNoMatchingMembers ?? this.groupDetailNoMatchingMembers,
      profilePanelEditProfile:
          profilePanelEditProfile ?? this.profilePanelEditProfile,
      momentReplyTo: momentReplyTo ?? this.momentReplyTo,
      momentReplyToComment: momentReplyToComment ?? this.momentReplyToComment,
      favorites: favorites ?? this.favorites,
      moments: moments ?? this.moments,
      settings: settings ?? this.settings,
      themeSystem: themeSystem ?? this.themeSystem,
      themeLight: themeLight ?? this.themeLight,
      themeDark: themeDark ?? this.themeDark,
      inputReveal: inputReveal ?? this.inputReveal,
      inputHide: inputHide ?? this.inputHide,
      navigationChats: navigationChats ?? this.navigationChats,
      navigationContacts: navigationContacts ?? this.navigationContacts,
      navigationProfile: navigationProfile ?? this.navigationProfile,
      navigationFriends: navigationFriends ?? this.navigationFriends,
      navigationGroups: navigationGroups ?? this.navigationGroups,
      navigationNewFriends: navigationNewFriends ?? this.navigationNewFriends,
      callDevicePickerPlaceholder:
          callDevicePickerPlaceholder ?? this.callDevicePickerPlaceholder,
      profileEditorNickname:
          profileEditorNickname ?? this.profileEditorNickname,
      profileEditorBio: profileEditorBio ?? this.profileEditorBio,
      profileEditorBioPlaceholder:
          profileEditorBioPlaceholder ?? this.profileEditorBioPlaceholder,
      profileEditorCancel: profileEditorCancel ?? this.profileEditorCancel,
      profileEditorSave: profileEditorSave ?? this.profileEditorSave,
      emojiPickerEmoji: emojiPickerEmoji ?? this.emojiPickerEmoji,
    );
  }

  /// 当前生效的组件文案。无 [FlareStringsScope] 祖先时返回默认值，不抛异常。
  static FlareStrings of(BuildContext context) => FlareStringsScope.of(context);

  static String _readTab(int count) => '已读 ($count)';
  static String _unreadTab(int count) => '未读 ($count)';
  static String _viewAll(int total) => '查看全部 $total';
  static String _typingOne(String name) => '$name 正在输入…';
  static String _typingMany(int count) => '$count 人正在输入…';
  static String _newMessages(int count) => count > 0 ? '$count 条新消息' : '新消息';
  static String _joinedCount(int count, String status) =>
      '$count 人已加入 · $status';
  static String _selfSuffix(String name) => '$name（我）';
  static String _selectedCount(int count) => '已选 $count';
  static String _packetClaimed(String amount) => '已领取 · $amount';
  static String _translatedBy(String provider) => '由 $provider 翻译';
  static String _pollOptionHint(int index) => '选项 $index';
  static String _yearMonth(int year, int month) => '${year}年${month}月';
  static String _ratingStars(int count) => '$count 星';
  static String _confirmCount(int count) => '确定 ($count)';
  static String _memberCount(int count) => '$count 名成员';
  static String _wordCharCount(int words, int chars) => '$words 个词 · $chars 字符';
  static String _permissionTitle(String noun) => '需要$noun权限';
  static String _permissionUndeterminedDescription(
    String feature,
    String verb,
  ) => '$feature需要$verb，请允许后继续。';
  static String _permissionDeniedDescription(String feature, String verb) =>
      '$verb的权限已被拒绝，$feature无法使用。请前往系统设置开启。';
  static String _permissionRestrictedDescription(String feature, String verb) =>
      '$verb的权限受设备或组织策略限制，$feature暂不可用。';
  static String _permissionUnavailableDescription(
    String feature,
    String verb,
  ) => '当前设备或运行环境不支持$verb，$feature暂不可用。';
  static String _messageRecalledGroupOther(String name) => '$name 撤回了一条消息';
  static String _quotedMessage(String name, String summary) =>
      name.isEmpty ? '引用：$summary' : '引用 $name：$summary';
  static String _jumpedToMessage(String name, String summary) =>
      '已跳转到 $name 的消息：$summary';
  static String _previewImageNamed(String label) => '[图片] $label';
  static String _previewFileNamed(String name) => '[文件] $name';
  static String _previewLocationNamed(String label) => '[位置] $label';
  static String _previewCardNamed(String label) => '[名片] $label';
  static String _previewForwardCount(int count) => '[转发] $count 条消息';
  static String _previewImageGroupCount(int count) => '[多图] $count 张';
  static String _messageImageGroupLabel(int count) => '$count 张图片';
  static String _imagePreviewPosition(int index, int count) =>
      '第 $index 张，共 $count 张';
  static String _messageImageGroupItem(int index, int count) =>
      '第 $index 张图片，共 $count 张';
  static String _messageImageGroupItemMore(int index, int count, int more) =>
      '第 $index 张图片，共 $count 张，另有 $more 张未显示';
  static String _announcementReadBarReadCount(int read, int total) =>
      '$read/$total 人已读';
  static String _groupDetailMemberCount(int count) => '$count 位成员';
  static String _groupDetailInviteConfirm(int count) => '邀请 ($count)';
  static String _groupDetailTransferConfirm(String name) =>
      '确定把群主转让给「$name」？转让后你将成为普通成员，此操作不可撤销。';
  static String _conversationBatchToolbarSucceededSummary(int count) =>
      '成功 $count 项';
  static String _conversationBatchToolbarFailedSummary(int count) =>
      '$count 项失败';
  static String _conversationBatchToolbarMaxSelection(int max) => '最多可选 $max 项';
  static String _storageUsageFileCount(int count) => '$count 个文件';
  static String _momentAudienceSheetSelected(int count) => '已选 $count 人';
  static String _conversationHeaderMemberCount(int count) => '$count 位成员';
  static String _connectionDisconnectedReason(String reason) => '连接已断开：$reason';
  static String _groupDetailMembersTitle(int count) => '群成员（$count）';
  static String _profilePanelEditProfile(String name) => '$name，编辑资料';
  static String _momentReplyToComment(String name, String text) =>
      '回复 $name：$text';
}

/// 在组件树根部提供一套 [FlareStrings]。
///
/// 不提供时组件取 `const FlareStrings()` 的中文默认值，因此这是可选的——宿主只有
/// 需要换语言或改措辞时才需要包一层。
class FlareStringsScope extends InheritedWidget {
  const FlareStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final FlareStrings strings;

  /// 取最近祖先提供的文案；没有祖先时返回默认值（不抛异常）。
  static FlareStrings of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<FlareStringsScope>()
          ?.strings ??
      const FlareStrings();

  @override
  bool updateShouldNotify(FlareStringsScope oldWidget) =>
      !identical(strings, oldWidget.strings);
}
