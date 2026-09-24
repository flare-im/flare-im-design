package com.flare.im.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf

/**
 * 组件内联文案（无障碍标签、状态提示、空态等）。
 *
 * 这些串原先直接写死在组件调用里，宿主无法覆盖——对一个跨端组件库而言等于把界面语言
 * 焊死。改为环境值后默认仍是中文，需要其他语言的宿主在根部覆盖即可：
 *
 * ```kotlin
 * CompositionLocalProvider(LocalFlareStrings provides FlareStrings { send = "Send" }) {
 *     App()
 * }
 * ```
 *
 * 取值方式与 [flareColors] 一致（composable 访问器），故组件里无需逐层传参。
 * 已有 `FlareXxxLabels` 参数的组件不受影响，两者可共存。
 */
@Suppress("UNCHECKED_CAST")
class FlareStrings private constructor(private val overrides: Map<String, Any>) {
    constructor() : this(emptyMap())

    constructor(configure: FlareStringsBuilder.() -> Unit) : this(
        FlareStringsBuilder().apply(configure).values.toMap(),
    )

    // 通话
    val microphone: String
        get() = (overrides["microphone"] as? (String)) ?: "麦克风"
    val camera: String
        get() = (overrides["camera"] as? (String)) ?: "摄像头"
    val flipCamera: String
        get() = (overrides["flipCamera"] as? (String)) ?: "翻转"
    val speaker: String
        get() = (overrides["speaker"] as? (String)) ?: "扬声器"
    val hangUp: String
        get() = (overrides["hangUp"] as? (String)) ?: "挂断"
    // 通话窗口的图标按钮；en: "Minimize call" / "Return to call"
    val callMinimize: String
        get() = (overrides["callMinimize"] as? (String)) ?: "最小化通话"
    val callReturn: String
        get() = (overrides["callReturn"] as? (String)) ?: "返回通话"
    val callWaitingAnswer: String
        get() = (overrides["callWaitingAnswer"] as? (String)) ?: "等待对方接听…"
    val callCalling: String
        get() = (overrides["callCalling"] as? (String)) ?: "正在呼叫…"
    val callRinging: String
        get() = (overrides["callRinging"] as? (String)) ?: "正在响铃…"
    val callConnected: String
        get() = (overrides["callConnected"] as? (String)) ?: "已接通"
    val callReconnecting: String
        get() = (overrides["callReconnecting"] as? (String)) ?: "正在恢复通话…"
    val callFailed: String
        get() = (overrides["callFailed"] as? (String)) ?: "通话连接失败"

    // 输入区
    val send: String
        get() = (overrides["send"] as? (String)) ?: "发送"
    val cancelReply: String
        get() = (overrides["cancelReply"] as? (String)) ?: "取消回复"

    // 空态
    val noContacts: String
        get() = (overrides["noContacts"] as? (String)) ?: "暂无联系人"
    val noResults: String
        get() = (overrides["noResults"] as? (String)) ?: "未找到结果"

    // 通用动作
    val close: String
        get() = (overrides["close"] as? (String)) ?: "关闭"
    val delete: String
        get() = (overrides["delete"] as? (String)) ?: "删除"
    val manage: String
        get() = (overrides["manage"] as? (String)) ?: "管理"
    val selectAll: String
        get() = (overrides["selectAll"] as? (String)) ?: "全选"

    // 底部面板（BottomSheet 无标题时的面板名；en: "Bottom sheet"）
    val bottomSheetLabel: String
        get() = (overrides["bottomSheetLabel"] as? (String)) ?: "底部面板"

    // 消息操作
    val addReaction: String
        get() = (overrides["addReaction"] as? (String)) ?: "添加表情回复"
    val readReceipt: String
        get() = (overrides["readReceipt"] as? (String)) ?: "已读回执"
    val readTab: (Int) -> String
        get() = (overrides["readTab"] as? ((Int) -> String)) ?: { "已读 ($it)" }
    val unreadTab: (Int) -> String
        get() = (overrides["unreadTab"] as? ((Int) -> String)) ?: { "未读 ($it)" }
    val noReadersYet: String
        get() = (overrides["noReadersYet"] as? (String)) ?: "还没有人读过"
    val everyoneHasRead: String
        get() = (overrides["everyoneHasRead"] as? (String)) ?: "所有人都已读"
    val selectedSuffix: String
        get() = (overrides["selectedSuffix"] as? (String)) ?: "已选"
    val forwardEach: String
        get() = (overrides["forwardEach"] as? (String)) ?: "逐条转发"
    val forwardMerged: String
        get() = (overrides["forwardMerged"] as? (String)) ?: "合并转发"
    val messageBatchPin: String
        get() = (overrides["messageBatchPin"] as? (String)) ?: "置顶"
    val messageBatchPinSelf: String
        get() = (overrides["messageBatchPinSelf"] as? (String)) ?: "仅自己置顶"
    val messageBatchClear: String
        get() = (overrides["messageBatchClear"] as? (String)) ?: "清除选择"
    // 多选工具条的退出按钮；en: "Exit multi-select"
    val exitMultiSelect: String
        get() = (overrides["exitMultiSelect"] as? (String)) ?: "退出多选"

    // 提及
    val searchMembers: String
        get() = (overrides["searchMembers"] as? (String)) ?: "搜索成员"
    // 提及全体：选中后写进正文的就是这个词，核心只把 all / everyone / 全员 / 所有人 解析为 @全体；en: "everyone"
    val everyone: String
        get() = (overrides["everyone"] as? (String)) ?: "所有人"
    val notifyEveryone: String
        get() = (overrides["notifyEveryone"] as? (String)) ?: "通知所有成员"
    val noMatchingMembers: String
        get() = (overrides["noMatchingMembers"] as? (String)) ?: "没有匹配的成员"

    // 快捷短语
    val quickPhrases: String
        get() = (overrides["quickPhrases"] as? (String)) ?: "快捷短语"
    val viewAll: (Int) -> String
        get() = (overrides["viewAll"] as? ((Int) -> String)) ?: { "查看全部 $it" }

    // 正在输入 / 新消息
    val typing: String
        get() = (overrides["typing"] as? (String)) ?: "正在输入…"
    val typingOne: (String) -> String
        get() = (overrides["typingOne"] as? ((String) -> String)) ?: { "$it 正在输入…" }
    val typingMany: (Int) -> String
        get() = (overrides["typingMany"] as? ((Int) -> String)) ?: { "$it 人正在输入…" }
    val newMessages: (Int) -> String
        get() = (overrides["newMessages"] as? ((Int) -> String)) ?: { if (it > 0) "$it 条新消息" else "新消息" }

    // 名片 / 群通话
    val sendMessage: String
        get() = (overrides["sendMessage"] as? (String)) ?: "发消息"
    val groupCall: String
        get() = (overrides["groupCall"] as? (String)) ?: "群通话"
    val joinedCount: (Int, String) -> String
        get() = (overrides["joinedCount"] as? ((Int, String) -> String)) ?: { n, status -> "$n 人已加入 · $status" }
    val selfSuffix: (String) -> String
        get() = (overrides["selfSuffix"] as? ((String) -> String)) ?: { "$it（我）" }

    // 转发选择
    val forwardTo: String
        get() = (overrides["forwardTo"] as? (String)) ?: "转发给"
    val searchConversations: String
        get() = (overrides["searchConversations"] as? (String)) ?: "搜索会话"
    val noMatchingConversations: String
        get() = (overrides["noMatchingConversations"] as? (String)) ?: "没有匹配的会话"
    val selectedCount: (Int) -> String
        get() = (overrides["selectedCount"] as? ((Int) -> String)) ?: { "已选 $it" }

    // 群公告
    val groupAnnouncement: String
        get() = (overrides["groupAnnouncement"] as? (String)) ?: "群公告"
    val collapse: String
        get() = (overrides["collapse"] as? (String)) ?: "收起"
    val expand: String
        get() = (overrides["expand"] as? (String)) ?: "展开"

    // 红包
    val packetClaimed: (String) -> String
        get() = (overrides["packetClaimed"] as? ((String) -> String)) ?: { "已领取 · $it" }
    val packetFinished: String
        get() = (overrides["packetFinished"] as? (String)) ?: "已被领完"
    val packetTapToClaim: String
        get() = (overrides["packetTapToClaim"] as? (String)) ?: "点击领取"
    val packetBrand: String
        get() = (overrides["packetBrand"] as? (String)) ?: "闪包"

    // 命令 / 翻译 / 名片码
    val commands: String
        get() = (overrides["commands"] as? (String)) ?: "命令"
    val noMatchingCommands: String
        get() = (overrides["noMatchingCommands"] as? (String)) ?: "没有匹配的命令"
    val translating: String
        get() = (overrides["translating"] as? (String)) ?: "翻译中…"
    val translatedBy: (String) -> String
        get() = (overrides["translatedBy"] as? ((String) -> String)) ?: { "由 $it 翻译" }
    val translated: String
        get() = (overrides["translated"] as? (String)) ?: "已翻译"
    val hideOriginal: String
        get() = (overrides["hideOriginal"] as? (String)) ?: "隐藏原文"
    val showOriginal: String
        get() = (overrides["showOriginal"] as? (String)) ?: "显示原文"
    val scanToAddMe: String
        get() = (overrides["scanToAddMe"] as? (String)) ?: "扫一扫加我"
    /** [QRCard] frame without a code (en: "QR code unavailable"). */
    val qrCardUnavailable: String
        get() = (overrides["qrCardUnavailable"] as? (String)) ?: "二维码暂不可用"

    // 录音 / 投票
    val cancel: String
        get() = (overrides["cancel"] as? (String)) ?: "取消"
    val releaseToCancel: String
        get() = (overrides["releaseToCancel"] as? (String)) ?: "松开取消"
    // 录音条的两个图标按钮；en: "Cancel recording" / "Send voice message"
    val voiceRecordingCancel: String
        get() = (overrides["voiceRecordingCancel"] as? (String)) ?: "取消录音"
    val voiceRecordingSend: String
        get() = (overrides["voiceRecordingSend"] as? (String)) ?: "发送语音"
    /** 会话行的草稿 / 被提及前缀（与 iOS conversationRowDraft / conversationRowMention 同名）。 */
    val conversationRowDraft: String
        get() = (overrides["conversationRowDraft"] as? (String)) ?: "[草稿] "
    val conversationRowMention: String
        get() = (overrides["conversationRowMention"] as? (String)) ?: "[@我] "
    val createPoll: String
        get() = (overrides["createPoll"] as? (String)) ?: "发起投票"
    val pollQuestionHint: String
        get() = (overrides["pollQuestionHint"] as? (String)) ?: "请输入问题"
    val pollOptionHint: (Int) -> String
        get() = (overrides["pollOptionHint"] as? ((Int) -> String)) ?: { "选项 $it" }
    val removeOption: String
        get() = (overrides["removeOption"] as? (String)) ?: "删除选项"
    val addOption: String
        get() = (overrides["addOption"] as? (String)) ?: "添加选项"
    val allowMultiple: String
        get() = (overrides["allowMultiple"] as? (String)) ?: "允许多选"
    val submitPoll: String
        get() = (overrides["submitPoll"] as? (String)) ?: "创建投票"
    val chatBackground: String
        get() = (overrides["chatBackground"] as? (String)) ?: "聊天背景"

    // 步进 / 日历
    val decrease: String
        get() = (overrides["decrease"] as? (String)) ?: "减少"
    val increase: String
        get() = (overrides["increase"] as? (String)) ?: "增加"
    val previousMonth: String
        get() = (overrides["previousMonth"] as? (String)) ?: "上个月"
    val nextMonth: String
        get() = (overrides["nextMonth"] as? (String)) ?: "下个月"
    val yearMonth: (Int, Int) -> String
        get() = (overrides["yearMonth"] as? ((Int, Int) -> String)) ?: { y, m -> "${y}年${m}月" }

    // 朋友圈
    val unlike: String
        get() = (overrides["unlike"] as? (String)) ?: "取消赞"
    val like: String
        get() = (overrides["like"] as? (String)) ?: "赞"
    val comment: String
        get() = (overrides["comment"] as? (String)) ?: "评论"
    val changeCover: String
        get() = (overrides["changeCover"] as? (String)) ?: "换封面"
    val post: String
        get() = (overrides["post"] as? (String)) ?: "发表"
    val momentTextHint: String
        get() = (overrides["momentTextHint"] as? (String)) ?: "这一刻的想法…"
    val addImage: String
        get() = (overrides["addImage"] as? (String)) ?: "添加图片"
    // 动态编辑器缩略图上的移除按钮；en: "Remove image"
    val removeImage: String
        get() = (overrides["removeImage"] as? (String)) ?: "移除图片"
    val pickLocation: String
        get() = (overrides["pickLocation"] as? (String)) ?: "所在位置"
    val pickVisibility: String
        get() = (overrides["pickVisibility"] as? (String)) ?: "谁可以看"
    val more: String
        get() = (overrides["more"] as? (String)) ?: "更多"

    // 操作菜单（ActionMenu 未传 label 时的无障碍名称；en: "Actions"）
    val actionMenuLabel: String
        get() = (overrides["actionMenuLabel"] as? (String)) ?: "操作菜单"

    // 语音转文字 / 表情贴纸
    val hideTranscript: String
        get() = (overrides["hideTranscript"] as? (String)) ?: "隐藏文字"
    val showTranscript: String
        get() = (overrides["showTranscript"] as? (String)) ?: "转文字"
    val recent: String
        get() = (overrides["recent"] as? (String)) ?: "最近"
    val searchEmoji: String
        get() = (overrides["searchEmoji"] as? (String)) ?: "搜索表情"
    val noMatchingEmoji: String
        get() = (overrides["noMatchingEmoji"] as? (String)) ?: "没有匹配的表情"
    val emptyStickerPack: String
        get() = (overrides["emptyStickerPack"] as? (String)) ?: "该表情包暂无贴纸"
    val sticker: String
        get() = (overrides["sticker"] as? (String)) ?: "贴纸"

    // 加号面板
    val actionImage: String
        get() = (overrides["actionImage"] as? (String)) ?: "图片"
    val actionCamera: String
        get() = (overrides["actionCamera"] as? (String)) ?: "拍摄"
    val actionFile: String
        get() = (overrides["actionFile"] as? (String)) ?: "文件"
    val actionLocation: String
        get() = (overrides["actionLocation"] as? (String)) ?: "位置"
    val actionCard: String
        get() = (overrides["actionCard"] as? (String)) ?: "名片"
    val actionVote: String
        get() = (overrides["actionVote"] as? (String)) ?: "投票"
    val actionTask: String
        get() = (overrides["actionTask"] as? (String)) ?: "任务"
    val actionSchedule: String
        get() = (overrides["actionSchedule"] as? (String)) ?: "日程"

    // 来电
    val incomingVideoCall: String
        get() = (overrides["incomingVideoCall"] as? (String)) ?: "邀请你进行视频通话"
    val incomingVoiceCall: String
        get() = (overrides["incomingVoiceCall"] as? (String)) ?: "邀请你进行语音通话"
    val reject: String
        get() = (overrides["reject"] as? (String)) ?: "拒绝"
    val accept: String
        get() = (overrides["accept"] as? (String)) ?: "接听"

    // 通用
    val back: String
        get() = (overrides["back"] as? (String)) ?: "返回"
    val confirm: String
        get() = (overrides["confirm"] as? (String)) ?: "确定"
    val confirmCount: (Int) -> String
        get() = (overrides["confirmCount"] as? ((Int) -> String)) ?: { "确定 ($it)" }
    val memberCount: (Int) -> String
        get() = (overrides["memberCount"] as? ((Int) -> String)) ?: { "$it 名成员" }
    val clear: String
        get() = (overrides["clear"] as? (String)) ?: "清除"
    val retry: String
        get() = (overrides["retry"] as? (String)) ?: "重试"
    val messagePending: String
        get() = (overrides["messagePending"] as? String) ?: "等待发送"
    val messageSending: String
        get() = (overrides["messageSending"] as? String) ?: "发送中"
    val messageSent: String
        get() = (overrides["messageSent"] as? String) ?: "已发送"
    val messageDelivered: String
        get() = (overrides["messageDelivered"] as? String) ?: "已送达"
    val messageRead: String
        get() = (overrides["messageRead"] as? String) ?: "已读"
    val messageFailed: String
        get() = (overrides["messageFailed"] as? String) ?: "发送失败"
    val messageRetrying: String
        get() = (overrides["messageRetrying"] as? String) ?: "正在重试"
    val messageEdited: String
        get() = (overrides["messageEdited"] as? String) ?: "已编辑"
    val messageReadOnce: String
        get() = (overrides["messageReadOnce"] as? String) ?: "仅可查看一次"
    val messageBurnAfterRead: String
        get() = (overrides["messageBurnAfterRead"] as? String) ?: "阅后即焚"
    val messageExpired: String
        get() = (overrides["messageExpired"] as? String) ?: "已过期"
    val select: String
        get() = (overrides["select"] as? (String)) ?: "选择"
    val wordCharCount: (Int, Int) -> String
        get() = (overrides["wordCharCount"] as? ((Int, Int) -> String)) ?: { w, c -> "$w 个词 · $c 字符" }
    val changeAvatar: String
        get() = (overrides["changeAvatar"] as? (String)) ?: "更换头像"
    val qrCode: String
        get() = (overrides["qrCode"] as? (String)) ?: "二维码"
    val play: String
        get() = (overrides["play"] as? (String)) ?: "播放"
    // 媒体控件；en: "Pause" / "Download" / "Close preview"
    val pause: String
        get() = (overrides["pause"] as? (String)) ?: "暂停"
    val download: String
        get() = (overrides["download"] as? (String)) ?: "下载"
    val imagePreviewClose: String
        get() = (overrides["imagePreviewClose"] as? (String)) ?: "关闭预览"
    /** A gallery preview's paging keys and where it is (en: "Previous image", "Next image", "{index} of {count}"). */
    val imagePreviewPrevious: String
        get() = (overrides["imagePreviewPrevious"] as? (String)) ?: "上一张"
    val imagePreviewNext: String
        get() = (overrides["imagePreviewNext"] as? (String)) ?: "下一张"
    val imagePreviewPosition: (Int, Int) -> String
        get() = (overrides["imagePreviewPosition"] as? ((Int, Int) -> String)) ?: { index, count -> "第 $index 张，共 $count 张" }
    // 媒体默认呈现（预览、播放器、气泡内语音）；en: "View image" / "Voice message" / "{n} seconds" /
    // "Playback failed" / "This video can't be played" / "Image failed to load"
    val imagePreviewOpen: String
        get() = (overrides["imagePreviewOpen"] as? (String)) ?: "查看图片"
    val voiceMessage: String
        get() = (overrides["voiceMessage"] as? (String)) ?: "语音"
    val voiceDuration: (Int) -> String
        get() = (overrides["voiceDuration"] as? ((Int) -> String)) ?: { "$it 秒" }
    val voicePlaybackFailed: String
        get() = (overrides["voicePlaybackFailed"] as? (String)) ?: "播放失败"
    val videoLoadFailed: String
        get() = (overrides["videoLoadFailed"] as? (String)) ?: "视频无法播放"
    val imageLoadFailed: String
        get() = (overrides["imageLoadFailed"] as? (String)) ?: "图片加载失败"

    // 通用（与 iOS FlareStrings 同名）
    val search: String
        get() = (overrides["search"] as? (String)) ?: "搜索"
    val reload: String
        get() = (overrides["reload"] as? (String)) ?: "重新加载"
    val today: String
        get() = (overrides["today"] as? (String)) ?: "今天"
    // FlareTimeFormat.conversationTime 的前一天；en: "Yesterday"
    val yesterday: String
        get() = (overrides["yesterday"] as? (String)) ?: "昨天"
    val timeRange: String
        get() = (overrides["timeRange"] as? (String)) ?: "时间范围"
    val searchIdleHint: String
        get() = (overrides["searchIdleHint"] as? (String)) ?: "输入关键词或选择类型"
    val selectDevice: String
        get() = (overrides["selectDevice"] as? (String)) ?: "选择设备"
    val confirmAction: String
        get() = (overrides["confirmAction"] as? (String)) ?: "确认"
    val noContent: String
        get() = (overrides["noContent"] as? (String)) ?: "暂无内容"
    val noConversations: String
        get() = (overrides["noConversations"] as? (String)) ?: "暂无会话"
    val noGroups: String
        get() = (overrides["noGroups"] as? (String)) ?: "暂无群组"
    val groupMembers: String
        get() = (overrides["groupMembers"] as? (String)) ?: "群成员"
    val groupOwner: String
        get() = (overrides["groupOwner"] as? (String)) ?: "群主"
    val groupAdmin: String
        get() = (overrides["groupAdmin"] as? (String)) ?: "管理员"
    val addMember: String
        get() = (overrides["addMember"] as? (String)) ?: "加成员"
    val loginDevices: String
        get() = (overrides["loginDevices"] as? (String)) ?: "登录设备"
    val currentDevice: String
        get() = (overrides["currentDevice"] as? (String)) ?: "当前设备"
    val filesAndMedia: String
        get() = (overrides["filesAndMedia"] as? (String)) ?: "文件与媒体"
    val notificationSettings: String
        get() = (overrides["notificationSettings"] as? (String)) ?: "通知设置"
    val transferQueue: String
        get() = (overrides["transferQueue"] as? (String)) ?: "传输队列"
    val noTransfers: String
        get() = (overrides["noTransfers"] as? (String)) ?: "暂无传输任务"
    val retryFailedTransfers: String
        get() = (overrides["retryFailedTransfers"] as? (String)) ?: "重试失败任务"

    // 权限提示（PermissionPrompt；与 iOS 同名，按 kind/state 取词）
    val permissionNoun: (FlarePermissionKind) -> String
        get() = (overrides["permissionNoun"] as? ((FlarePermissionKind) -> String)) ?: {
            when (it) {
            FlarePermissionKind.Microphone -> "麦克风"
            FlarePermissionKind.Camera -> "摄像头"
            FlarePermissionKind.Notifications -> "通知"
            FlarePermissionKind.Storage -> "存储空间"
            FlarePermissionKind.Photos -> "相册"
            FlarePermissionKind.Contacts -> "通讯录"
            FlarePermissionKind.Location -> "位置信息"
            FlarePermissionKind.Screen -> "屏幕录制"
            }
            }
    val permissionVerb: (FlarePermissionKind) -> String
        get() = (overrides["permissionVerb"] as? ((FlarePermissionKind) -> String)) ?: {
            when (it) {
            FlarePermissionKind.Microphone -> "使用麦克风"
            FlarePermissionKind.Camera -> "使用摄像头"
            FlarePermissionKind.Notifications -> "发送通知"
            FlarePermissionKind.Storage -> "访问存储空间"
            FlarePermissionKind.Photos -> "访问相册"
            FlarePermissionKind.Contacts -> "访问通讯录"
            FlarePermissionKind.Location -> "获取位置信息"
            FlarePermissionKind.Screen -> "录制屏幕内容"
            }
            }
    val permissionTitle: (String) -> String
        get() = (overrides["permissionTitle"] as? ((String) -> String)) ?: { "需要${it}权限" }
    val permissionFeatureFallback: String
        get() = (overrides["permissionFeatureFallback"] as? (String)) ?: "此功能"
    val permissionUndeterminedBody: (String, String) -> String
        get() = (overrides["permissionUndeterminedBody"] as? ((String, String) -> String)) ?: { feature, verb -> "${feature}需要${verb}，请允许后继续。" }
    val permissionDeniedBody: (String, String) -> String
        get() = (overrides["permissionDeniedBody"] as? ((String, String) -> String)) ?: { feature, verb -> "${verb}的权限已被拒绝，${feature}无法使用。请前往系统设置开启。" }
    val permissionRestrictedBody: (String, String) -> String
        get() = (overrides["permissionRestrictedBody"] as? ((String, String) -> String)) ?: { feature, verb -> "${verb}的权限受设备或组织策略限制，${feature}暂不可用。" }
    val permissionUnavailableBody: (String, String) -> String
        get() = (overrides["permissionUnavailableBody"] as? ((String, String) -> String)) ?: { feature, verb -> "当前设备或运行环境不支持${verb}，${feature}暂不可用。" }
    val permissionAllow: String
        get() = (overrides["permissionAllow"] as? (String)) ?: "允许"
    val permissionOpenSettings: String
        get() = (overrides["permissionOpenSettings"] as? (String)) ?: "前往设置"
    val permissionStateLabel: (FlarePermissionState) -> String
        get() = (overrides["permissionStateLabel"] as? ((FlarePermissionState) -> String)) ?: {
            when (it) {
            FlarePermissionState.Undetermined -> "未授权"
            FlarePermissionState.Denied -> "已拒绝"
            FlarePermissionState.Restricted -> "受限制"
            FlarePermissionState.Unavailable -> "不可用"
            }
            }
    val permissionDismiss: String
        get() = (overrides["permissionDismiss"] as? (String)) ?: "知道了"

    // 输入区（Composer / VoiceHoldButton / ComposerReplyStrip / InlineVoiceComposer）
    val composerPlaceholder: String
        get() = (overrides["composerPlaceholder"] as? (String)) ?: "消息"
    val composerReply: String
        get() = (overrides["composerReply"] as? (String)) ?: "回复"
    val composerEmoji: String
        get() = (overrides["composerEmoji"] as? (String)) ?: "表情"
    val composerMention: String
        get() = (overrides["composerMention"] as? (String)) ?: "提及"
    val composerVoice: String
        get() = (overrides["composerVoice"] as? (String)) ?: "语音"
    val composerImage: String
        get() = (overrides["composerImage"] as? (String)) ?: "图片"
    val composerRichText: String
        get() = (overrides["composerRichText"] as? (String)) ?: "富文本"
    val composerMore: String
        get() = (overrides["composerMore"] as? (String)) ?: "更多"
    val composerExpandInput: String
        get() = (overrides["composerExpandInput"] as? (String)) ?: "展开输入框"
    val composerCollapseInput: String
        get() = (overrides["composerCollapseInput"] as? (String)) ?: "收起输入框"
    val composerFormatBold: String
        get() = (overrides["composerFormatBold"] as? (String)) ?: "加粗"
    val composerFormatItalic: String
        get() = (overrides["composerFormatItalic"] as? (String)) ?: "斜体"
    val composerFormatStrike: String
        get() = (overrides["composerFormatStrike"] as? (String)) ?: "删除线"
    val composerFormatCode: String
        get() = (overrides["composerFormatCode"] as? (String)) ?: "代码"
    val composerFormatLink: String
        get() = (overrides["composerFormatLink"] as? (String)) ?: "链接"
    val composerFormatHeading: String
        get() = (overrides["composerFormatHeading"] as? (String)) ?: "标题"
    val composerFormatQuote: String
        get() = (overrides["composerFormatQuote"] as? (String)) ?: "引用"
    val composerFormatBullet: String
        get() = (overrides["composerFormatBullet"] as? (String)) ?: "无序列表"
    val composerFormatOrdered: String
        get() = (overrides["composerFormatOrdered"] as? (String)) ?: "有序列表"
    val voiceHoldButtonLabel: String
        get() = (overrides["voiceHoldButtonLabel"] as? (String)) ?: "按住 说话"
    val voiceHoldButtonRecording: String
        get() = (overrides["voiceHoldButtonRecording"] as? (String)) ?: "松开发送 · 上滑取消"
    val voiceHoldButtonCancel: String
        get() = (overrides["voiceHoldButtonCancel"] as? (String)) ?: "松开取消"
    val composerReplyStripLabel: String
        get() = (overrides["composerReplyStripLabel"] as? (String)) ?: "回复"
    val inlineVoiceComposerAllowMicrophone: String
        get() = (overrides["inlineVoiceComposerAllowMicrophone"] as? (String)) ?: "请允许麦克风权限"
    val inlineVoiceComposerKeyboard: String
        get() = (overrides["inlineVoiceComposerKeyboard"] as? (String)) ?: "返回键盘并删除录音"
    val inlineVoiceComposerPause: String
        get() = (overrides["inlineVoiceComposerPause"] as? (String)) ?: "暂停录音"
    val inlineVoiceComposerStart: String
        get() = (overrides["inlineVoiceComposerStart"] as? (String)) ?: "开始录音"
    val inlineVoiceComposerPreview: String
        get() = (overrides["inlineVoiceComposerPreview"] as? (String)) ?: "试听 / 暂停"
    val inlineVoiceComposerResume: String
        get() = (overrides["inlineVoiceComposerResume"] as? (String)) ?: "继续录音"
    val inlineVoiceComposerDiscard: String
        get() = (overrides["inlineVoiceComposerDiscard"] as? (String)) ?: "删除录音"
    val inlineVoiceComposerSendFailed: String
        get() = (overrides["inlineVoiceComposerSendFailed"] as? (String)) ?: "发送失败，可重试"
    val emojiStickerPickerEmoji: String
        get() = (overrides["emojiStickerPickerEmoji"] as? (String)) ?: "表情"
    // 表情目录尚未载入时的进度名；en: "Loading emoji"
    val emojiStickerPickerLoading: String
        get() = (overrides["emojiStickerPickerLoading"] as? (String)) ?: "正在加载表情"

    // 群设置矩阵（GroupPermissionMatrix）
    val groupPermissionMatrixTitle: String
        get() = (overrides["groupPermissionMatrixTitle"] as? (String)) ?: "群设置"
    val groupPermissionMatrixReadOnlyHint: String
        get() = (overrides["groupPermissionMatrixReadOnlyHint"] as? (String)) ?: "仅群主和管理员可修改"
    val groupPermissionMatrixJoinPolicy: String
        get() = (overrides["groupPermissionMatrixJoinPolicy"] as? (String)) ?: "加群方式"
    val groupPermissionMatrixJoinPolicyDescription: String
        get() = (overrides["groupPermissionMatrixJoinPolicyDescription"] as? (String)) ?: "决定他人如何加入本群"
    val groupPermissionMatrixJoinInvite: String
        get() = (overrides["groupPermissionMatrixJoinInvite"] as? (String)) ?: "仅邀请"
    val groupPermissionMatrixJoinApproval: String
        get() = (overrides["groupPermissionMatrixJoinApproval"] as? (String)) ?: "需管理员审批"
    val groupPermissionMatrixJoinOpen: String
        get() = (overrides["groupPermissionMatrixJoinOpen"] as? (String)) ?: "允许直接加入"
    val groupPermissionMatrixUnknownJoinPolicy: String
        get() = (overrides["groupPermissionMatrixUnknownJoinPolicy"] as? (String)) ?: "当前加群方式未知，请重新选择"
    val groupPermissionMatrixMuteAll: String
        get() = (overrides["groupPermissionMatrixMuteAll"] as? (String)) ?: "全员禁言"
    val groupPermissionMatrixMuteAllDescription: String
        get() = (overrides["groupPermissionMatrixMuteAllDescription"] as? (String)) ?: "开启后仅群主和管理员可发言"
    val groupPermissionMatrixOnlyAdminCanAtAll: String
        get() = (overrides["groupPermissionMatrixOnlyAdminCanAtAll"] as? (String)) ?: "仅管理员可 @所有人"
    val groupPermissionMatrixOnlyAdminCanAtAllDescription: String
        get() = (overrides["groupPermissionMatrixOnlyAdminCanAtAllDescription"] as? (String)) ?: "限制 @所有人 的使用范围"
    val groupPermissionMatrixOnlyAdminCanPin: String
        get() = (overrides["groupPermissionMatrixOnlyAdminCanPin"] as? (String)) ?: "仅管理员可置顶消息"
    val groupPermissionMatrixOnlyAdminCanPinDescription: String
        get() = (overrides["groupPermissionMatrixOnlyAdminCanPinDescription"] as? (String)) ?: "限制群内置顶消息的权限"
    val groupPermissionMatrixShareCardPermission: String
        get() = (overrides["groupPermissionMatrixShareCardPermission"] as? (String)) ?: "允许分享群名片"
    val groupPermissionMatrixShareCardPermissionDescription: String
        get() = (overrides["groupPermissionMatrixShareCardPermissionDescription"] as? (String)) ?: "关闭后成员不能把本群分享给他人"
    val groupPermissionMatrixOn: String
        get() = (overrides["groupPermissionMatrixOn"] as? (String)) ?: "已开启"
    val groupPermissionMatrixOff: String
        get() = (overrides["groupPermissionMatrixOff"] as? (String)) ?: "已关闭"
    val groupPermissionMatrixBusy: String
        get() = (overrides["groupPermissionMatrixBusy"] as? (String)) ?: "提交中"
    val groupPermissionMatrixDismissError: String
        get() = (overrides["groupPermissionMatrixDismissError"] as? (String)) ?: "忽略此错误"

    // 会话批量工具栏（ConversationBatchToolbar；{n} 由组件替换）
    val conversationBatchToolbarEmpty: String
        get() = (overrides["conversationBatchToolbarEmpty"] as? (String)) ?: "请选择会话"
    val conversationBatchToolbarMarkRead: String
        get() = (overrides["conversationBatchToolbarMarkRead"] as? (String)) ?: "标为已读"
    val conversationBatchToolbarMute: String
        get() = (overrides["conversationBatchToolbarMute"] as? (String)) ?: "免打扰"
    val conversationBatchToolbarArchive: String
        get() = (overrides["conversationBatchToolbarArchive"] as? (String)) ?: "归档"
    val conversationBatchToolbarCancel: String
        get() = (overrides["conversationBatchToolbarCancel"] as? (String)) ?: "取消选择"
    val conversationBatchToolbarBusy: String
        get() = (overrides["conversationBatchToolbarBusy"] as? (String)) ?: "处理中"
    val conversationBatchToolbarSucceededSummary: String
        get() = (overrides["conversationBatchToolbarSucceededSummary"] as? (String)) ?: "成功 {n} 项"
    val conversationBatchToolbarFailedSummary: String
        get() = (overrides["conversationBatchToolbarFailedSummary"] as? (String)) ?: "{n} 项失败"
    val conversationBatchToolbarRetryFailed: String
        get() = (overrides["conversationBatchToolbarRetryFailed"] as? (String)) ?: "重试失败项"
    val conversationBatchToolbarDismiss: String
        get() = (overrides["conversationBatchToolbarDismiss"] as? (String)) ?: "关闭结果"
    val conversationBatchToolbarExpand: String
        get() = (overrides["conversationBatchToolbarExpand"] as? (String)) ?: "查看详情"
    val conversationBatchToolbarMaxSelection: String
        get() = (overrides["conversationBatchToolbarMaxSelection"] as? (String)) ?: "最多可选 {n} 项"

    // 成员角色面板（MemberRoleSheet）
    val memberRoleSheetMemberRole: String
        get() = (overrides["memberRoleSheetMemberRole"] as? (String)) ?: "成员"
    val memberRoleSheetMuted: String
        get() = (overrides["memberRoleSheetMuted"] as? (String)) ?: "已禁言"
    val memberRoleSheetPromote: String
        get() = (overrides["memberRoleSheetPromote"] as? (String)) ?: "设为管理员"
    val memberRoleSheetDemote: String
        get() = (overrides["memberRoleSheetDemote"] as? (String)) ?: "取消管理员"
    val memberRoleSheetMute: String
        get() = (overrides["memberRoleSheetMute"] as? (String)) ?: "禁言"
    val memberRoleSheetUnmute: String
        get() = (overrides["memberRoleSheetUnmute"] as? (String)) ?: "解除禁言"
    val memberRoleSheetRemove: String
        get() = (overrides["memberRoleSheetRemove"] as? (String)) ?: "移出群聊"
    val memberRoleSheetTransferOwner: String
        get() = (overrides["memberRoleSheetTransferOwner"] as? (String)) ?: "转让群主"
    val memberRoleSheetDangerGroup: String
        get() = (overrides["memberRoleSheetDangerGroup"] as? (String)) ?: "危险操作"
    val memberRoleSheetEmpty: String
        get() = (overrides["memberRoleSheetEmpty"] as? (String)) ?: "你没有管理权限"
    val memberRoleSheetOwnerProtected: String
        get() = (overrides["memberRoleSheetOwnerProtected"] as? (String)) ?: "群主不可被管理"

    // 存储空间（StorageUsage；{count} 由组件替换）
    // 邀请（InviteCodeField / MyInvitePanel）
    val inviteCodeLabel: String
        get() = (overrides["inviteCodeLabel"] as? (String)) ?: "邀请码"
    val inviteCodePlaceholder: String
        get() = (overrides["inviteCodePlaceholder"] as? (String)) ?: "请输入邀请码"
    val inviteCodeOptional: String
        get() = (overrides["inviteCodeOptional"] as? (String)) ?: "选填"
    val inviteCodeChecking: String
        get() = (overrides["inviteCodeChecking"] as? (String)) ?: "正在校验邀请码…"
    val inviteCodeValid: String
        get() = (overrides["inviteCodeValid"] as? (String)) ?: "邀请码可用"
    val inviteCodeInviter: String
        get() = (overrides["inviteCodeInviter"] as? (String)) ?: "邀请人：{name}"
    val inviteCodeInvalid: String
        get() = (overrides["inviteCodeInvalid"] as? (String)) ?: "邀请码无效"
    val myInviteTitle: String
        get() = (overrides["myInviteTitle"] as? (String)) ?: "我的邀请"
    val myInviteCodeLabel: String
        get() = (overrides["myInviteCodeLabel"] as? (String)) ?: "我的邀请码"
    val myInviteCodeUnavailable: String
        get() = (overrides["myInviteCodeUnavailable"] as? (String)) ?: "邀请码暂不可用"
    val myInviteCopy: String
        get() = (overrides["myInviteCopy"] as? (String)) ?: "复制"
    val myInviteShare: String
        get() = (overrides["myInviteShare"] as? (String)) ?: "分享"
    val myInviteRegenerate: String
        get() = (overrides["myInviteRegenerate"] as? (String)) ?: "重新生成"
    val myInviteRegenerating: String
        get() = (overrides["myInviteRegenerating"] as? (String)) ?: "生成中…"
    val myInviteCooldown: String
        get() = (overrides["myInviteCooldown"] as? (String)) ?: "{time} 后可重新生成"
    val myInviteUnitMinutes: String
        get() = (overrides["myInviteUnitMinutes"] as? (String)) ?: "{n} 分钟"
    val myInviteUnitHours: String
        get() = (overrides["myInviteUnitHours"] as? (String)) ?: "{n} 小时"
    val myInviteUnitDays: String
        get() = (overrides["myInviteUnitDays"] as? (String)) ?: "{n} 天"
    val myInviteStatsTitle: String
        get() = (overrides["myInviteStatsTitle"] as? (String)) ?: "我的团队"
    val myInviteDirect: String
        get() = (overrides["myInviteDirect"] as? (String)) ?: "直接邀请"
    val myInviteLevel2: String
        get() = (overrides["myInviteLevel2"] as? (String)) ?: "二级"
    val myInviteLevel3: String
        get() = (overrides["myInviteLevel3"] as? (String)) ?: "三级"
    val myInviteTotal: String
        get() = (overrides["myInviteTotal"] as? (String)) ?: "团队总数"
    val myInviteInviteesTitle: String
        get() = (overrides["myInviteInviteesTitle"] as? (String)) ?: "直接邀请的人"
    val myInviteEmpty: String
        get() = (overrides["myInviteEmpty"] as? (String)) ?: "还没有人通过你的邀请码加入"
    val myInviteLoadMore: String
        get() = (overrides["myInviteLoadMore"] as? (String)) ?: "加载更多"
    val myInviteLoading: String
        get() = (overrides["myInviteLoading"] as? (String)) ?: "正在加载邀请信息"
    val myInviteJoined: String
        get() = (overrides["myInviteJoined"] as? (String)) ?: "{date} 加入"
    val myInviteCountOnly: String
        get() = (overrides["myInviteCountOnly"] as? (String)) ?: "{count} 人"
    val storageUsageTitle: String
        get() = (overrides["storageUsageTitle"] as? (String)) ?: "存储空间"
    val storageUsageUnknown: String
        get() = (overrides["storageUsageUnknown"] as? (String)) ?: "未知"
    val storageUsageAtLeast: String
        get() = (overrides["storageUsageAtLeast"] as? (String)) ?: "至少"
    val storageUsageClear: String
        get() = (overrides["storageUsageClear"] as? (String)) ?: "清理"
    val storageUsageClearing: String
        get() = (overrides["storageUsageClearing"] as? (String)) ?: "清理中"
    val storageUsageTotal: String
        get() = (overrides["storageUsageTotal"] as? (String)) ?: "总计"
    val storageUsageDeviceFree: String
        get() = (overrides["storageUsageDeviceFree"] as? (String)) ?: "可用空间"
    val storageUsageReload: String
        get() = (overrides["storageUsageReload"] as? (String)) ?: "重新统计"
    val storageUsageRetry: String
        get() = (overrides["storageUsageRetry"] as? (String)) ?: "失败重试"
    val storageUsageDismissError: String
        get() = (overrides["storageUsageDismissError"] as? (String)) ?: "忽略此错误"
    val storageUsageLoading: String
        get() = (overrides["storageUsageLoading"] as? (String)) ?: "正在统计存储占用"
    val storageUsageEmpty: String
        get() = (overrides["storageUsageEmpty"] as? (String)) ?: "没有可统计的存储分类"
    val storageUsageFileCount: String
        get() = (overrides["storageUsageFileCount"] as? (String)) ?: "{count} 个文件"

    // 好友关系操作栏（RelationActionBar）
    val relationActionBarAdd: String
        get() = (overrides["relationActionBarAdd"] as? (String)) ?: "添加好友"
    val relationActionBarAccept: String
        get() = (overrides["relationActionBarAccept"] as? (String)) ?: "接受"
    val relationActionBarRemove: String
        get() = (overrides["relationActionBarRemove"] as? (String)) ?: "删除好友"
    val relationActionBarBlock: String
        get() = (overrides["relationActionBarBlock"] as? (String)) ?: "加入黑名单"
    val relationActionBarUnblock: String
        get() = (overrides["relationActionBarUnblock"] as? (String)) ?: "移出黑名单"
    val relationActionBarPending: String
        get() = (overrides["relationActionBarPending"] as? (String)) ?: "等待对方验证"
    val relationActionBarBusy: String
        get() = (overrides["relationActionBarBusy"] as? (String)) ?: "处理中"
    val relationActionBarDismissError: String
        get() = (overrides["relationActionBarDismissError"] as? (String)) ?: "关闭错误提示"
    val relationActionBarEmpty: String
        get() = (overrides["relationActionBarEmpty"] as? (String)) ?: "暂无可用操作"

    // 屏幕共享（ScreenShare）
    val screenShareTitle: String
        get() = (overrides["screenShareTitle"] as? (String)) ?: "屏幕共享"
    val screenShareIdle: String
        get() = (overrides["screenShareIdle"] as? (String)) ?: "未在共享"
    val screenShareRequesting: String
        get() = (overrides["screenShareRequesting"] as? (String)) ?: "正在请求共享"
    val screenShareSharing: String
        get() = (overrides["screenShareSharing"] as? (String)) ?: "正在共享屏幕"
    val screenShareViewing: String
        get() = (overrides["screenShareViewing"] as? (String)) ?: "正在观看共享"
    val screenShareUnavailable: String
        get() = (overrides["screenShareUnavailable"] as? (String)) ?: "当前环境不支持屏幕共享"
    val screenShareSourceRow: String
        get() = (overrides["screenShareSourceRow"] as? (String)) ?: "共享内容"
    val screenSharePresenterRow: String
        get() = (overrides["screenSharePresenterRow"] as? (String)) ?: "共享者"
    val screenShareStart: String
        get() = (overrides["screenShareStart"] as? (String)) ?: "共享屏幕"
    val screenShareStop: String
        get() = (overrides["screenShareStop"] as? (String)) ?: "停止共享"
    val screenShareCancel: String
        get() = (overrides["screenShareCancel"] as? (String)) ?: "取消请求"

    // 会话操作面板（ConversationActionSheet）
    val conversationActionSheetPin: String
        get() = (overrides["conversationActionSheetPin"] as? (String)) ?: "置顶"
    val conversationActionSheetUnpin: String
        get() = (overrides["conversationActionSheetUnpin"] as? (String)) ?: "取消置顶"
    val conversationActionSheetMute: String
        get() = (overrides["conversationActionSheetMute"] as? (String)) ?: "免打扰"
    val conversationActionSheetUnmute: String
        get() = (overrides["conversationActionSheetUnmute"] as? (String)) ?: "取消免打扰"
    val conversationActionSheetMarkRead: String
        get() = (overrides["conversationActionSheetMarkRead"] as? (String)) ?: "标为已读"
    // 没有未读时才提供；en: "Mark as unread"
    val conversationActionSheetMarkUnread: String
        get() = (overrides["conversationActionSheetMarkUnread"] as? (String)) ?: "标为未读"
    val conversationActionSheetArchive: String
        get() = (overrides["conversationActionSheetArchive"] as? (String)) ?: "归档"
    val conversationActionSheetUnarchive: String
        get() = (overrides["conversationActionSheetUnarchive"] as? (String)) ?: "取消归档"
    val conversationActionSheetHide: String
        get() = (overrides["conversationActionSheetHide"] as? (String)) ?: "隐藏"
    // 危险分组，排在删除之前；en: "Clear local history"
    val conversationActionSheetClearHistory: String
        get() = (overrides["conversationActionSheetClearHistory"] as? (String)) ?: "清空本地记录"
    val conversationActionSheetEmpty: String
        get() = (overrides["conversationActionSheetEmpty"] as? (String)) ?: "暂无可用操作"
    val messageActionSheetLabel: String
        get() = (overrides["messageActionSheetLabel"] as? (String)) ?: "消息操作"
    val messageActionSheetEmpty: String
        get() = (overrides["messageActionSheetEmpty"] as? (String)) ?: "暂无可用操作"
    /** A covered spoiler in a rich-text body, as TalkBack names it (en: "Spoiler, select to reveal"). */
    val messageSpoilerReveal: String
        get() = (overrides["messageSpoilerReveal"] as? (String)) ?: "剧透内容，点按显示"
    /** An album body and its tiles, as TalkBack names them (en: "{count} images", "Image {index} of {count}", "…, {more} more not shown"). */
    val messageImageGroupLabel: (Int) -> String
        get() = (overrides["messageImageGroupLabel"] as? ((Int) -> String)) ?: { "$it 张图片" }
    val messageImageGroupItem: (Int, Int) -> String
        get() = (overrides["messageImageGroupItem"] as? ((Int, Int) -> String)) ?: { index, count -> "第 $index 张图片，共 $count 张" }
    val messageImageGroupItemMore: (Int, Int, Int) -> String
        get() = (overrides["messageImageGroupItemMore"] as? ((Int, Int, Int) -> String))
            ?: { index, count, more -> "第 $index 张图片，共 $count 张，另有 $more 张未显示" }
    val messageActionReply: String
        get() = (overrides["messageActionReply"] as? (String)) ?: "回复"
    val messageActionForward: String
        get() = (overrides["messageActionForward"] as? (String)) ?: "转发"
    val messageActionRecall: String
        get() = (overrides["messageActionRecall"] as? (String)) ?: "撤回"
    val messageActionResend: String
        get() = (overrides["messageActionResend"] as? (String)) ?: "重新发送"
    val messageActionMultiSelect: String
        get() = (overrides["messageActionMultiSelect"] as? (String)) ?: "多选"
    val messageActionMark: String
        get() = (overrides["messageActionMark"] as? (String)) ?: "标记"
    val messageActionPin: String
        get() = (overrides["messageActionPin"] as? (String)) ?: "置顶消息"
    val messageActionPinSelf: String
        get() = (overrides["messageActionPinSelf"] as? (String)) ?: "仅自己置顶"
    val messageActionUnpin: String
        get() = (overrides["messageActionUnpin"] as? (String)) ?: "取消置顶"
    val messageActionCopy: String
        get() = (overrides["messageActionCopy"] as? (String)) ?: "复制"
    val messageActionPreview: String
        get() = (overrides["messageActionPreview"] as? (String)) ?: "预览"
    val messageActionSave: String
        get() = (overrides["messageActionSave"] as? (String)) ?: "保存"
    val messageActionEdit: String
        get() = (overrides["messageActionEdit"] as? (String)) ?: "编辑"
    val messageActionDelete: String
        get() = (overrides["messageActionDelete"] as? (String)) ?: "删除"

    // 工作区外壳（WorkspaceFrame）——通用兜底，不能提"会话"
    val workspaceFrameLoading: String
        get() = (overrides["workspaceFrameLoading"] as? (String)) ?: "正在加载"
    val workspaceFrameEmpty: String
        get() = (overrides["workspaceFrameEmpty"] as? (String)) ?: "暂无内容"
    val workspaceFrameFailure: String
        get() = (overrides["workspaceFrameFailure"] as? (String)) ?: "加载失败"
    val workspaceFrameRetry: String
        get() = (overrides["workspaceFrameRetry"] as? (String)) ?: "重试"

    // 会话工作区（ConversationWorkspace）
    val conversationWorkspaceListEmpty: String
        get() = (overrides["conversationWorkspaceListEmpty"] as? (String)) ?: "暂无会话"
    val conversationWorkspaceChatEmpty: String
        get() = (overrides["conversationWorkspaceChatEmpty"] as? (String)) ?: "选择一个会话开始聊天"
    val conversationWorkspaceDetailEmpty: String
        get() = (overrides["conversationWorkspaceDetailEmpty"] as? (String)) ?: "暂无详情"
    val conversationWorkspaceListFailure: String
        get() = (overrides["conversationWorkspaceListFailure"] as? (String)) ?: "会话列表加载失败"
    val conversationWorkspaceChatFailure: String
        get() = (overrides["conversationWorkspaceChatFailure"] as? (String)) ?: "消息加载失败"
    val conversationWorkspaceDetailFailure: String
        get() = (overrides["conversationWorkspaceDetailFailure"] as? (String)) ?: "详情加载失败"
    val conversationWorkspaceListLoading: String
        get() = (overrides["conversationWorkspaceListLoading"] as? (String)) ?: "正在加载会话列表"
    val conversationWorkspaceChatLoading: String
        get() = (overrides["conversationWorkspaceChatLoading"] as? (String)) ?: "正在加载消息"
    val conversationWorkspaceDetailLoading: String
        get() = (overrides["conversationWorkspaceDetailLoading"] as? (String)) ?: "正在加载详情"

    // 搜索时间范围（SearchDateRangeFilter）
    val searchDateRangeFilterCustom: String
        get() = (overrides["searchDateRangeFilterCustom"] as? (String)) ?: "自定义"
    val searchDateRangeFilterFrom: String
        get() = (overrides["searchDateRangeFilterFrom"] as? (String)) ?: "起始日期"
    val searchDateRangeFilterTo: String
        get() = (overrides["searchDateRangeFilterTo"] as? (String)) ?: "结束日期"
    val searchDateRangeFilterUnlimited: String
        get() = (overrides["searchDateRangeFilterUnlimited"] as? (String)) ?: "不限时间"
    val searchDateRangeFilterInvalid: String
        get() = (overrides["searchDateRangeFilterInvalid"] as? (String)) ?: "起始日期不能晚于结束日期"

    // 未知用户 / 未知消息 / 好友申请 / 列表空态
    val unknownUserPlaceholderUnknown: String
        get() = (overrides["unknownUserPlaceholderUnknown"] as? (String)) ?: "未知用户"
    val unknownUserPlaceholderDeactivated: String
        get() = (overrides["unknownUserPlaceholderDeactivated"] as? (String)) ?: "该账号已注销"
    val unknownUserPlaceholderBlocked: String
        get() = (overrides["unknownUserPlaceholderBlocked"] as? (String)) ?: "该账号已被屏蔽"
    val unknownUserPlaceholderUnreachable: String
        get() = (overrides["unknownUserPlaceholderUnreachable"] as? (String)) ?: "暂时无法联系该账号"
    val unknownUserPlaceholderId: String
        get() = (overrides["unknownUserPlaceholderId"] as? (String)) ?: "ID"
    val unknownMessageHint: String
        get() = (overrides["unknownMessageHint"] as? (String)) ?: "当前版本无法显示这条消息"
    val unknownMessageUnsupported: String
        get() = (overrides["unknownMessageUnsupported"] as? (String)) ?: "不支持的消息类型"
    val unknownMessageDiagnostic: String
        get() = (overrides["unknownMessageDiagnostic"] as? (String)) ?: "消息类型"
    val newFriendRequestsEmpty: String
        get() = (overrides["newFriendRequestsEmpty"] as? (String)) ?: "暂无新的好友申请"
    val newFriendRequestsAccept: String
        get() = (overrides["newFriendRequestsAccept"] as? (String)) ?: "接受"
    val newFriendRequestsDecline: String
        get() = (overrides["newFriendRequestsDecline"] as? (String)) ?: "拒绝"
    // 我发出的申请（FriendRequestDirection.Outgoing）；en: "Pending" / "Withdraw"
    val newFriendRequestsPending: String
        get() = (overrides["newFriendRequestsPending"] as? (String)) ?: "等待验证"
    val newFriendRequestsWithdraw: String
        get() = (overrides["newFriendRequestsWithdraw"] as? (String)) ?: "撤回"
    val messageListEmpty: String
        get() = (overrides["messageListEmpty"] as? (String)) ?: "暂无消息"
    val messageListLoadOlder: String
        get() = (overrides["messageListLoadOlder"] as? (String)) ?: "加载更早消息"
    val messageRecalledSelf: String
        get() = (overrides["messageRecalledSelf"] as? (String)) ?: "你撤回了一条消息"
    val messageRecalledPeer: String
        get() = (overrides["messageRecalledPeer"] as? (String)) ?: "对方撤回了一条消息"
    val messageRecalledGroupOther: (String) -> String
        get() = (overrides["messageRecalledGroupOther"] as? ((String) -> String)) ?: { "$it 撤回了一条消息" }
    // 气泡引用条作为按钮时的名字（名字为空时省略）；en: "Quoted {name}: {summary}" / "Quoted: {summary}"
    val messageQuoteLabel: (String, String) -> String
        get() = (overrides["messageQuoteLabel"] as? ((String, String) -> String))
            ?: { name, summary -> if (name.isEmpty()) "引用：$summary" else "引用 $name：$summary" }
    // 跳转落地后读屏听到的那句话：看得见的人由高亮得知落在哪一行，看不见的人由这句话得知。
    // en: "Jumped to {name}'s message: {summary}"
    val jumpedToMessage: (String, String) -> String
        get() = (overrides["jumpedToMessage"] as? ((String, String) -> String))
            ?: { name, summary -> "已跳转到 $name 的消息：$summary" }
    // 一条消息的一句话摘要（会话行、回复条、气泡引用块）。同一套词汇四端共用，
    // 规则表在 spec/message-preview-vectors.json，摘要函数是 [flareMessagePreviewText]。
    // 没有可读内容时用 previewMessage，回复条与引用块因此永远不是空行。
    val previewMessage: String
        get() = (overrides["previewMessage"] as? (String)) ?: "[消息]"
    val previewRichText: String
        get() = (overrides["previewRichText"] as? (String)) ?: "[富文本]"
    val previewGif: String
        get() = (overrides["previewGif"] as? (String)) ?: "[动图]"
    val previewImage: String
        get() = (overrides["previewImage"] as? (String)) ?: "[图片]"
    // markdown 行里带 alt 的图片（[flareMarkdownToPlainText]）；en: "[Image] {label}"
    val previewImageNamed: (String) -> String
        get() = (overrides["previewImageNamed"] as? ((String) -> String)) ?: { "[图片] $it" }
    val previewVideo: String
        get() = (overrides["previewVideo"] as? (String)) ?: "[视频]"
    val previewAudio: String
        get() = (overrides["previewAudio"] as? (String)) ?: "[语音]"
    val previewFile: String
        get() = (overrides["previewFile"] as? (String)) ?: "[文件]"
    // en: "[File] {name}"
    val previewFileNamed: (String) -> String
        get() = (overrides["previewFileNamed"] as? ((String) -> String)) ?: { "[文件] $it" }
    val previewLocation: String
        get() = (overrides["previewLocation"] as? (String)) ?: "[位置]"
    // en: "[Location] {label}"
    val previewLocationNamed: (String) -> String
        get() = (overrides["previewLocationNamed"] as? ((String) -> String)) ?: { "[位置] $it" }
    val previewCard: String
        get() = (overrides["previewCard"] as? (String)) ?: "[名片]"
    // en: "[Contact] {label}"
    val previewCardNamed: (String) -> String
        get() = (overrides["previewCardNamed"] as? ((String) -> String)) ?: { "[名片] $it" }
    val previewSticker: String
        get() = (overrides["previewSticker"] as? (String)) ?: "[贴纸]"
    val previewEmoji: String
        get() = (overrides["previewEmoji"] as? (String)) ?: "[表情]"
    val previewQuote: String
        get() = (overrides["previewQuote"] as? (String)) ?: "[引用]"
    val previewLink: String
        get() = (overrides["previewLink"] as? (String)) ?: "[链接]"
    val previewForward: String
        get() = (overrides["previewForward"] as? (String)) ?: "[转发]"
    // en: "[Forward] {count} messages"
    val previewForwardCount: (Int) -> String
        get() = (overrides["previewForwardCount"] as? ((Int) -> String)) ?: { "[转发] $it 条消息" }
    val previewThread: String
        get() = (overrides["previewThread"] as? (String)) ?: "[话题]"
    val previewMiniProgram: String
        get() = (overrides["previewMiniProgram"] as? (String)) ?: "[小程序]"
    val previewImageGroup: String
        get() = (overrides["previewImageGroup"] as? (String)) ?: "[多图]"
    // en: "[Album] {count}"
    val previewImageGroupCount: (Int) -> String
        get() = (overrides["previewImageGroupCount"] as? ((Int) -> String)) ?: { "[多图] $it 张" }
    val previewSystem: String
        get() = (overrides["previewSystem"] as? (String)) ?: "[系统消息]"
    val previewNotification: String
        get() = (overrides["previewNotification"] as? (String)) ?: "[通知]"
    val previewVote: String
        get() = (overrides["previewVote"] as? (String)) ?: "[投票]"
    val previewTask: String
        get() = (overrides["previewTask"] as? (String)) ?: "[任务]"
    val previewSchedule: String
        get() = (overrides["previewSchedule"] as? (String)) ?: "[日程]"
    val previewAnnouncement: String
        get() = (overrides["previewAnnouncement"] as? (String)) ?: "[公告]"
    val previewCustom: String
        get() = (overrides["previewCustom"] as? (String)) ?: "[自定义]"
    val previewPlaceholder: String
        get() = (overrides["previewPlaceholder"] as? (String)) ?: "[占位]"
    val previewUnknown: String
        get() = (overrides["previewUnknown"] as? (String)) ?: "[未知]"

    // 会话头身份区作为按钮时的名字（标题 + 动作）；en: "{title}, {action}"
    val conversationHeaderIdentityLabel: (String, String) -> String
        get() = (overrides["conversationHeaderIdentityLabel"] as? ((String, String) -> String)) ?: { title, action -> "$title，$action" }
    val startConversationDialogSearchPlaceholder: String
        get() = (overrides["startConversationDialogSearchPlaceholder"] as? (String)) ?: "搜索联系人"

    // 群详情（GroupDetail Labels）
    val groupDetailFallbackTitle: String
        get() = (overrides["groupDetailFallbackTitle"] as? (String)) ?: "群聊"
    val groupDetailUnavailable: String
        get() = (overrides["groupDetailUnavailable"] as? (String)) ?: "群信息不可用"
    val groupDetailUnavailableHint: String
        get() = (overrides["groupDetailUnavailableHint"] as? (String)) ?: "未连接服务时无法加载群详情。"
    val groupDetailNotSet: String
        get() = (overrides["groupDetailNotSet"] as? (String)) ?: "未设置"
    // 读不到的「我在本群」设置（免打扰 / 置顶）：不谎称关着，行改为只读说明; en: "Unavailable right now"
    val groupDetailSettingUnavailable: String
        get() = (overrides["groupDetailSettingUnavailable"] as? (String)) ?: "暂时无法读取"
    val groupDetailAnnouncement: String
        get() = (overrides["groupDetailAnnouncement"] as? (String)) ?: "群公告"
    val groupDetailMembers: String
        get() = (overrides["groupDetailMembers"] as? (String)) ?: "群成员"
    val groupDetailInfoSection: String
        get() = (overrides["groupDetailInfoSection"] as? (String)) ?: "群信息"
    val groupDetailMyInGroupSection: String
        get() = (overrides["groupDetailMyInGroupSection"] as? (String)) ?: "我在本群"
    val groupDetailManageSection: String
        get() = (overrides["groupDetailManageSection"] as? (String)) ?: "群管理"
    val groupDetailPermsSection: String
        get() = (overrides["groupDetailPermsSection"] as? (String)) ?: "群权限"
    val groupDetailName: String
        get() = (overrides["groupDetailName"] as? (String)) ?: "群聊名称"
    val groupDetailMyNickname: String
        get() = (overrides["groupDetailMyNickname"] as? (String)) ?: "我的群昵称"
    val groupDetailMuteNotif: String
        get() = (overrides["groupDetailMuteNotif"] as? (String)) ?: "消息免打扰"
    val groupDetailPinGroup: String
        get() = (overrides["groupDetailPinGroup"] as? (String)) ?: "置顶该群"
    val groupDetailJoinMode: String
        get() = (overrides["groupDetailJoinMode"] as? (String)) ?: "进群方式"
    val groupDetailJoinRequests: String
        get() = (overrides["groupDetailJoinRequests"] as? (String)) ?: "入群申请"
    val groupDetailMuteAll: String
        get() = (overrides["groupDetailMuteAll"] as? (String)) ?: "全员禁言"
    val groupDetailInviteLink: String
        get() = (overrides["groupDetailInviteLink"] as? (String)) ?: "群邀请链接"
    val groupDetailOnlyAdminAtAll: String
        get() = (overrides["groupDetailOnlyAdminAtAll"] as? (String)) ?: "仅管理员可@全体成员"
    val groupDetailOnlyAdminPin: String
        get() = (overrides["groupDetailOnlyAdminPin"] as? (String)) ?: "仅管理员可置顶消息"
    val groupDetailShareCard: String
        get() = (overrides["groupDetailShareCard"] as? (String)) ?: "允许分享群名片"
    val groupDetailJoinOpen: String
        get() = (overrides["groupDetailJoinOpen"] as? (String)) ?: "允许任何人加入"
    val groupDetailJoinApproval: String
        get() = (overrides["groupDetailJoinApproval"] as? (String)) ?: "需管理员审批"
    val groupDetailJoinInvite: String
        get() = (overrides["groupDetailJoinInvite"] as? (String)) ?: "仅邀请加入"
    val groupDetailLeave: String
        get() = (overrides["groupDetailLeave"] as? (String)) ?: "退出群聊"
    val groupDetailDissolve: String
        get() = (overrides["groupDetailDissolve"] as? (String)) ?: "解散群聊"
    val groupDetailEditName: String
        get() = (overrides["groupDetailEditName"] as? (String)) ?: "群聊名称"
    val groupDetailEditAnnouncement: String
        get() = (overrides["groupDetailEditAnnouncement"] as? (String)) ?: "群公告"
    val groupDetailNicknamePlaceholder: String
        get() = (overrides["groupDetailNicknamePlaceholder"] as? (String)) ?: "输入群昵称"
    val groupDetailSave: String
        get() = (overrides["groupDetailSave"] as? (String)) ?: "保存"
    val groupDetailMemberManage: String
        get() = (overrides["groupDetailMemberManage"] as? (String)) ?: "成员管理"
    val groupDetailSetAdmin: String
        get() = (overrides["groupDetailSetAdmin"] as? (String)) ?: "设为管理员"
    val groupDetailUnsetAdmin: String
        get() = (overrides["groupDetailUnsetAdmin"] as? (String)) ?: "取消管理员"
    val groupDetailMute: String
        get() = (overrides["groupDetailMute"] as? (String)) ?: "禁言 1 天"
    val groupDetailUnmute: String
        get() = (overrides["groupDetailUnmute"] as? (String)) ?: "取消禁言"
    val groupDetailTransferOwner: String
        get() = (overrides["groupDetailTransferOwner"] as? (String)) ?: "转让群主"
    val groupDetailRemoveMember: String
        get() = (overrides["groupDetailRemoveMember"] as? (String)) ?: "移出群聊"
    val groupDetailTransferConfirmPrefix: String
        get() = (overrides["groupDetailTransferConfirmPrefix"] as? (String)) ?: "确定把群主转让给「"
    val groupDetailTransferConfirmSuffix: String
        get() = (overrides["groupDetailTransferConfirmSuffix"] as? (String)) ?: "」吗？转让后你将变为普通成员，此操作不可撤销。"
    val groupDetailConfirmTransfer: String
        get() = (overrides["groupDetailConfirmTransfer"] as? (String)) ?: "确认转让"
    val groupDetailInvite: String
        get() = (overrides["groupDetailInvite"] as? (String)) ?: "邀请"
    val groupDetailInviteSearchPlaceholder: String
        get() = (overrides["groupDetailInviteSearchPlaceholder"] as? (String)) ?: "选择要邀请的联系人"
    val groupDetailLoading: String
        get() = (overrides["groupDetailLoading"] as? (String)) ?: "加载中…"
    val groupDetailNoRequests: String
        get() = (overrides["groupDetailNoRequests"] as? (String)) ?: "暂无待处理的入群申请"
    val groupDetailApprove: String
        get() = (overrides["groupDetailApprove"] as? (String)) ?: "通过"
    val groupDetailInviteLinkHint: String
        get() = (overrides["groupDetailInviteLinkHint"] as? (String)) ?: "分享邀请码，好友可凭码加入本群。"
    val groupDetailGenerating: String
        get() = (overrides["groupDetailGenerating"] as? (String)) ?: "生成中…"
    val groupDetailInviteCodeLabel: String
        get() = (overrides["groupDetailInviteCodeLabel"] as? (String)) ?: "邀请码"
    val groupDetailCopyCode: String
        get() = (overrides["groupDetailCopyCode"] as? (String)) ?: "复制"
    val groupDetailCannotGenerate: String
        get() = (overrides["groupDetailCannotGenerate"] as? (String)) ?: "暂时无法获取邀请链接。"
    val groupDetailLeaveConfirmText: String
        get() = (overrides["groupDetailLeaveConfirmText"] as? (String)) ?: "退出后将不再接收该群消息。"
    val groupDetailDissolveConfirmText: String
        get() = (overrides["groupDetailDissolveConfirmText"] as? (String)) ?: "解散后所有成员将被移出，且不可恢复。"

    // 动态可见范围（MomentAudienceSheet Labels）
    val momentAudienceSheetPublic: String
        get() = (overrides["momentAudienceSheetPublic"] as? (String)) ?: "公开"
    val momentAudienceSheetPublicHint: String
        get() = (overrides["momentAudienceSheetPublicHint"] as? (String)) ?: "所有人可见"
    val momentAudienceSheetFriends: String
        get() = (overrides["momentAudienceSheetFriends"] as? (String)) ?: "朋友可见"
    val momentAudienceSheetFriendsHint: String
        get() = (overrides["momentAudienceSheetFriendsHint"] as? (String)) ?: "你的好友可见"
    val momentAudienceSheetPrivate: String
        get() = (overrides["momentAudienceSheetPrivate"] as? (String)) ?: "私密"
    val momentAudienceSheetPrivateHint: String
        get() = (overrides["momentAudienceSheetPrivateHint"] as? (String)) ?: "仅自己可见"
    val momentAudienceSheetInclude: String
        get() = (overrides["momentAudienceSheetInclude"] as? (String)) ?: "部分可见"
    val momentAudienceSheetIncludeHint: String
        get() = (overrides["momentAudienceSheetIncludeHint"] as? (String)) ?: "仅选中的朋友可见"
    val momentAudienceSheetExclude: String
        get() = (overrides["momentAudienceSheetExclude"] as? (String)) ?: "不给谁看"
    val momentAudienceSheetExcludeHint: String
        get() = (overrides["momentAudienceSheetExcludeHint"] as? (String)) ?: "选中的朋友看不到"
    val momentAudienceSheetPick: String
        get() = (overrides["momentAudienceSheetPick"] as? (String)) ?: "选择朋友"
    val momentAudienceSheetDone: String
        get() = (overrides["momentAudienceSheetDone"] as? (String)) ?: "完成"
    val momentAudienceSheetSelected: (Int) -> String
        get() = (overrides["momentAudienceSheetSelected"] as? ((Int) -> String)) ?: { "已选 $it 人" }

    // 朋友圈可见规则 / 通讯录匹配 / 公告已读（Labels）
    val momentsVisibilityRuleListHideFromTitle: String
        get() = (overrides["momentsVisibilityRuleListHideFromTitle"] as? (String)) ?: "不让他看我的朋友圈"
    val momentsVisibilityRuleListHideFromHint: String
        get() = (overrides["momentsVisibilityRuleListHideFromHint"] as? (String)) ?: "名单中的人看不到你发的内容"
    val momentsVisibilityRuleListMuteTitle: String
        get() = (overrides["momentsVisibilityRuleListMuteTitle"] as? (String)) ?: "不看他的朋友圈"
    val momentsVisibilityRuleListMuteHint: String
        get() = (overrides["momentsVisibilityRuleListMuteHint"] as? (String)) ?: "你不会看到名单中的人发的内容"
    val momentsVisibilityRuleListEmpty: String
        get() = (overrides["momentsVisibilityRuleListEmpty"] as? (String)) ?: "名单为空"
    val momentsVisibilityRuleListRemove: String
        get() = (overrides["momentsVisibilityRuleListRemove"] as? (String)) ?: "移出"
    // 名单标题行的添加按钮；en: "Add people"
    val momentsVisibilityRuleListAdd: String
        get() = (overrides["momentsVisibilityRuleListAdd"] as? (String)) ?: "添加成员"
    val contactMatchListAdd: String
        get() = (overrides["contactMatchListAdd"] as? (String)) ?: "添加"
    val contactMatchListEmpty: String
        get() = (overrides["contactMatchListEmpty"] as? (String)) ?: "通讯录里还没有已注册的联系人"
    val announcementReadBarConfirmRead: String
        get() = (overrides["announcementReadBarConfirmRead"] as? (String)) ?: "已读"
    val announcementReadBarViewUnread: String
        get() = (overrides["announcementReadBarViewUnread"] as? (String)) ?: "查看未读"
    val announcementReadBarReadCount: (Int, Int) -> String
        get() = (overrides["announcementReadBarReadCount"] as? ((Int, Int) -> String)) ?: { read, total -> "$read/$total 人已读" }

    // 联系人详情 / 会话详情 / 资料编辑（Labels）
    val contactDetailVoice: String
        get() = (overrides["contactDetailVoice"] as? (String)) ?: "语音通话"
    val contactDetailVideo: String
        get() = (overrides["contactDetailVideo"] as? (String)) ?: "视频通话"
    val contactDetailInfoSection: String
        get() = (overrides["contactDetailInfoSection"] as? (String)) ?: "资料"
    val contactDetailFlareId: String
        get() = (overrides["contactDetailFlareId"] as? (String)) ?: "Flare ID"
    val contactDetailRemark: String
        get() = (overrides["contactDetailRemark"] as? (String)) ?: "备注"
    val contactDetailDescription: String
        get() = (overrides["contactDetailDescription"] as? (String)) ?: "描述"
    val contactDetailStar: String
        get() = (overrides["contactDetailStar"] as? (String)) ?: "星标好友"
    val contactDetailNotSet: String
        get() = (overrides["contactDetailNotSet"] as? (String)) ?: "未设置"
    val contactDetailBlock: String
        get() = (overrides["contactDetailBlock"] as? (String)) ?: "加入黑名单"
    val contactDetailRemove: String
        get() = (overrides["contactDetailRemove"] as? (String)) ?: "删除好友"
    val conversationDetailsMessages: String
        get() = (overrides["conversationDetailsMessages"] as? (String)) ?: "消息"
    val conversationDetailsMute: String
        get() = (overrides["conversationDetailsMute"] as? (String)) ?: "免打扰"
    val conversationDetailsPin: String
        get() = (overrides["conversationDetailsPin"] as? (String)) ?: "置顶会话"
    val conversationDetailsMarkRead: String
        get() = (overrides["conversationDetailsMarkRead"] as? (String)) ?: "标为已读"
    val conversationDetailsMarkUnread: String
        get() = (overrides["conversationDetailsMarkUnread"] as? (String)) ?: "标为未读"
    val conversationDetailsSync: String
        get() = (overrides["conversationDetailsSync"] as? (String)) ?: "同步会话"
    val conversationDetailsArchive: String
        get() = (overrides["conversationDetailsArchive"] as? (String)) ?: "归档会话"
    val conversationDetailsUnarchive: String
        get() = (overrides["conversationDetailsUnarchive"] as? (String)) ?: "取消归档"
    val conversationDetailsClearHistory: String
        get() = (overrides["conversationDetailsClearHistory"] as? (String)) ?: "清空聊天记录"
    val conversationDetailsDelete: String
        get() = (overrides["conversationDetailsDelete"] as? (String)) ?: "删除会话"
    val profileEditorNickname: String
        get() = (overrides["profileEditorNickname"] as? (String)) ?: "昵称"
    val profileEditorNicknamePlaceholder: String
        get() = (overrides["profileEditorNicknamePlaceholder"] as? (String)) ?: "昵称"
    val profileEditorBio: String
        get() = (overrides["profileEditorBio"] as? (String)) ?: "个性签名"
    val profileEditorBioPlaceholder: String
        get() = (overrides["profileEditorBioPlaceholder"] as? (String)) ?: "介绍一下自己吧"
    val profileEditorSave: String
        get() = (overrides["profileEditorSave"] as? (String)) ?: "保存"

    // 连接提示（flareConnectionNotice）; en: "Connecting…" / "Connection lost. Reconnecting…" / "No network. Messages will sync when it is back." / "Disconnected" / "Disconnected: {reason}" / "Your account signed in on another device" / "Your sign-in has expired" / "Reconnect" / "Sign in again"
    val connectionConnecting: String
        get() = (overrides["connectionConnecting"] as? (String)) ?: "正在连接…"
    val connectionReconnecting: String
        get() = (overrides["connectionReconnecting"] as? (String)) ?: "连接已断开，正在重连…"
    val connectionOffline: String
        get() = (overrides["connectionOffline"] as? (String)) ?: "网络不可用，恢复后会自动重连"
    val connectionDisconnected: String
        get() = (overrides["connectionDisconnected"] as? (String)) ?: "连接已断开"
    val connectionDisconnectedReason: (String) -> String
        get() = (overrides["connectionDisconnectedReason"] as? ((String) -> String)) ?: { "连接已断开：$it" }
    val connectionKicked: String
        get() = (overrides["connectionKicked"] as? (String)) ?: "账号已在其他设备登录"
    val connectionExpired: String
        get() = (overrides["connectionExpired"] as? (String)) ?: "登录已过期"
    val connectionReconnect: String
        get() = (overrides["connectionReconnect"] as? (String)) ?: "重新连接"
    val connectionSignIn: String
        get() = (overrides["connectionSignIn"] as? (String)) ?: "重新登录"

    // 会话头栏的添加 / 更多菜单按钮; en: "Add conversation actions" / "More conversation actions"
    val conversationHeaderAddActions: String
        get() = (overrides["conversationHeaderAddActions"] as? (String)) ?: "添加会话操作"
    val conversationHeaderMoreActions: String
        get() = (overrides["conversationHeaderMoreActions"] as? (String)) ?: "更多会话操作"

    // 群详情的全部成员面板; en: "Members ({count})" / "Search members" / "No matching members"
    val groupDetailMembersTitle: (Int) -> String
        get() = (overrides["groupDetailMembersTitle"] as? ((Int) -> String)) ?: { "群成员（$it）" }
    val groupDetailSearchMembers: String
        get() = (overrides["groupDetailSearchMembers"] as? (String)) ?: "搜索群成员"
    val groupDetailNoMatchingMembers: String
        get() = (overrides["groupDetailNoMatchingMembers"] as? (String)) ?: "没有匹配的群成员"

    // 会话头栏默认操作、成员数与在线状态（仍是该会话类型的英文默认标签时才替换）; en: "Search messages" / "Start audio call" / "Start video call" / "Add member" / "Share conversation" / "Conversation details" / "{count} members" / "Online" / "Offline" / "Busy" / "Away"
    val conversationHeaderSearch: String
        get() = (overrides["conversationHeaderSearch"] as? (String)) ?: "搜索消息"
    val conversationHeaderAudioCall: String
        get() = (overrides["conversationHeaderAudioCall"] as? (String)) ?: "发起语音通话"
    val conversationHeaderVideoCall: String
        get() = (overrides["conversationHeaderVideoCall"] as? (String)) ?: "发起视频通话"
    val conversationHeaderAddMember: String
        get() = (overrides["conversationHeaderAddMember"] as? (String)) ?: "添加成员"
    val conversationHeaderShare: String
        get() = (overrides["conversationHeaderShare"] as? (String)) ?: "分享会话"
    val conversationHeaderDetails: String
        get() = (overrides["conversationHeaderDetails"] as? (String)) ?: "会话详情"
    val conversationHeaderMemberCount: (Int) -> String
        get() = (overrides["conversationHeaderMemberCount"] as? ((Int) -> String)) ?: { "$it 位成员" }
    val presenceOnline: String
        get() = (overrides["presenceOnline"] as? (String)) ?: "在线"
    val presenceOffline: String
        get() = (overrides["presenceOffline"] as? (String)) ?: "离线"
    val presenceBusy: String
        get() = (overrides["presenceBusy"] as? (String)) ?: "忙碌"
    val presenceAway: String
        get() = (overrides["presenceAway"] as? (String)) ?: "离开"

    // 个人资料卡与圈子（资料卡的编辑入口、我的二维码、评论回复）; en: "{name}, edit profile" / "My QR code" / "replying to" / "Reply to {name}: {text}"
    val profilePanelEditProfile: (String) -> String
        get() = (overrides["profilePanelEditProfile"] as? ((String) -> String)) ?: { "$it，编辑资料" }
    val myQrCode: String
        get() = (overrides["myQrCode"] as? (String)) ?: "我的二维码"
    val momentReplyTo: String
        get() = (overrides["momentReplyTo"] as? (String)) ?: "回复"
    val momentReplyToComment: (String, String) -> String
        get() = (overrides["momentReplyToComment"] as? ((String, String) -> String)) ?: { name, text -> "回复 $name：$text" }

    // 个人中心默认入口（收藏、圈子、设置）; en: "Favorites" / "Moments" / "Settings"
    val favorites: String
        get() = (overrides["favorites"] as? (String)) ?: "收藏"
    val moments: String
        get() = (overrides["moments"] as? (String)) ?: "圈子"
    val settings: String
        get() = (overrides["settings"] as? (String)) ?: "设置"

    // 主题模式的三个选项，宿主的设置页画（`spec/theme-mode-vectors.json`）; en: "System" / "Light" / "Dark"
    val themeSystem: String
        get() = (overrides["themeSystem"] as? (String)) ?: "跟随系统"
    val themeLight: String
        get() = (overrides["themeLight"] as? (String)) ?: "浅色"
    val themeDark: String
        get() = (overrides["themeDark"] as? (String)) ?: "深色"

    // 密码框的显隐键（`Input(revealable = true)`）; en: "Show password" / "Hide password"
    val inputReveal: String
        get() = (overrides["inputReveal"] as? (String)) ?: "显示密码"
    val inputHide: String
        get() = (overrides["inputHide"] as? (String)) ?: "隐藏密码"

    // 回到最新消息的按钮（下方没有新消息时的读屏名；有新消息时读 newMessages）; en: "Back to latest"
    val scrollToLatest: String
        get() = (overrides["scrollToLatest"] as? (String)) ?: "回到最新"

    // 应用壳默认导航（flareDefaultIMNavigation / flareDefaultContactNavigation）；
    // en: "Chats" / "Contacts" / "Profile" / "Friends" / "Groups" / "New Friends"（收藏用 favorites）
    val navigationChats: String
        get() = (overrides["navigationChats"] as? (String)) ?: "消息"
    val navigationContacts: String
        get() = (overrides["navigationContacts"] as? (String)) ?: "通讯录"
    val navigationProfile: String
        get() = (overrides["navigationProfile"] as? (String)) ?: "我"
    val navigationFriends: String
        get() = (overrides["navigationFriends"] as? (String)) ?: "好友"
    val navigationGroups: String
        get() = (overrides["navigationGroups"] as? (String)) ?: "群聊"
    val navigationNewFriends: String
        get() = (overrides["navigationNewFriends"] as? (String)) ?: "新的朋友"
}

@Suppress("UNCHECKED_CAST")
class FlareStringsBuilder internal constructor() {
    internal val values = mutableMapOf<String, Any>()

    var microphone: String
        get() = (values["microphone"] as? (String)) ?: "麦克风"
        set(value) { values["microphone"] = value }

    var camera: String
        get() = (values["camera"] as? (String)) ?: "摄像头"
        set(value) { values["camera"] = value }

    var flipCamera: String
        get() = (values["flipCamera"] as? (String)) ?: "翻转"
        set(value) { values["flipCamera"] = value }

    var speaker: String
        get() = (values["speaker"] as? (String)) ?: "扬声器"
        set(value) { values["speaker"] = value }

    var hangUp: String
        get() = (values["hangUp"] as? (String)) ?: "挂断"
        set(value) { values["hangUp"] = value }

    var callMinimize: String
        get() = (values["callMinimize"] as? (String)) ?: "最小化通话"
        set(value) { values["callMinimize"] = value }

    var callReturn: String
        get() = (values["callReturn"] as? (String)) ?: "返回通话"
        set(value) { values["callReturn"] = value }

    var callWaitingAnswer: String
        get() = (values["callWaitingAnswer"] as? (String)) ?: "等待对方接听…"
        set(value) { values["callWaitingAnswer"] = value }

    var callCalling: String
        get() = (values["callCalling"] as? (String)) ?: "正在呼叫…"
        set(value) { values["callCalling"] = value }

    var callRinging: String
        get() = (values["callRinging"] as? (String)) ?: "正在响铃…"
        set(value) { values["callRinging"] = value }

    var callConnected: String
        get() = (values["callConnected"] as? (String)) ?: "已接通"
        set(value) { values["callConnected"] = value }

    var callReconnecting: String
        get() = (values["callReconnecting"] as? (String)) ?: "正在恢复通话…"
        set(value) { values["callReconnecting"] = value }

    var callFailed: String
        get() = (values["callFailed"] as? (String)) ?: "通话连接失败"
        set(value) { values["callFailed"] = value }

    var send: String
        get() = (values["send"] as? (String)) ?: "发送"
        set(value) { values["send"] = value }

    var cancelReply: String
        get() = (values["cancelReply"] as? (String)) ?: "取消回复"
        set(value) { values["cancelReply"] = value }

    var noContacts: String
        get() = (values["noContacts"] as? (String)) ?: "暂无联系人"
        set(value) { values["noContacts"] = value }

    var noResults: String
        get() = (values["noResults"] as? (String)) ?: "未找到结果"
        set(value) { values["noResults"] = value }

    var close: String
        get() = (values["close"] as? (String)) ?: "关闭"
        set(value) { values["close"] = value }

    var delete: String
        get() = (values["delete"] as? (String)) ?: "删除"
        set(value) { values["delete"] = value }

    var manage: String
        get() = (values["manage"] as? (String)) ?: "管理"
        set(value) { values["manage"] = value }

    var selectAll: String
        get() = (values["selectAll"] as? (String)) ?: "全选"
        set(value) { values["selectAll"] = value }

    var bottomSheetLabel: String
        get() = (values["bottomSheetLabel"] as? (String)) ?: "底部面板"
        set(value) { values["bottomSheetLabel"] = value }

    var addReaction: String
        get() = (values["addReaction"] as? (String)) ?: "添加表情回复"
        set(value) { values["addReaction"] = value }

    var readReceipt: String
        get() = (values["readReceipt"] as? (String)) ?: "已读回执"
        set(value) { values["readReceipt"] = value }

    var readTab: (Int) -> String
        get() = (values["readTab"] as? ((Int) -> String)) ?: { "已读 ($it)" }
        set(value) { values["readTab"] = value }

    var unreadTab: (Int) -> String
        get() = (values["unreadTab"] as? ((Int) -> String)) ?: { "未读 ($it)" }
        set(value) { values["unreadTab"] = value }

    var noReadersYet: String
        get() = (values["noReadersYet"] as? (String)) ?: "还没有人读过"
        set(value) { values["noReadersYet"] = value }

    var everyoneHasRead: String
        get() = (values["everyoneHasRead"] as? (String)) ?: "所有人都已读"
        set(value) { values["everyoneHasRead"] = value }

    var selectedSuffix: String
        get() = (values["selectedSuffix"] as? (String)) ?: "已选"
        set(value) { values["selectedSuffix"] = value }

    var forwardEach: String
        get() = (values["forwardEach"] as? (String)) ?: "逐条转发"
        set(value) { values["forwardEach"] = value }

    var forwardMerged: String
        get() = (values["forwardMerged"] as? (String)) ?: "合并转发"
        set(value) { values["forwardMerged"] = value }

    var messageBatchPin: String
        get() = (values["messageBatchPin"] as? (String)) ?: "置顶"
        set(value) { values["messageBatchPin"] = value }

    var messageBatchPinSelf: String
        get() = (values["messageBatchPinSelf"] as? (String)) ?: "仅自己置顶"
        set(value) { values["messageBatchPinSelf"] = value }

    var messageBatchClear: String
        get() = (values["messageBatchClear"] as? (String)) ?: "清除选择"
        set(value) { values["messageBatchClear"] = value }

    var exitMultiSelect: String
        get() = (values["exitMultiSelect"] as? (String)) ?: "退出多选"
        set(value) { values["exitMultiSelect"] = value }

    var searchMembers: String
        get() = (values["searchMembers"] as? (String)) ?: "搜索成员"
        set(value) { values["searchMembers"] = value }

    var everyone: String
        get() = (values["everyone"] as? (String)) ?: "所有人"
        set(value) { values["everyone"] = value }

    var notifyEveryone: String
        get() = (values["notifyEveryone"] as? (String)) ?: "通知所有成员"
        set(value) { values["notifyEveryone"] = value }

    var noMatchingMembers: String
        get() = (values["noMatchingMembers"] as? (String)) ?: "没有匹配的成员"
        set(value) { values["noMatchingMembers"] = value }

    var quickPhrases: String
        get() = (values["quickPhrases"] as? (String)) ?: "快捷短语"
        set(value) { values["quickPhrases"] = value }

    var viewAll: (Int) -> String
        get() = (values["viewAll"] as? ((Int) -> String)) ?: { "查看全部 $it" }
        set(value) { values["viewAll"] = value }

    var typing: String
        get() = (values["typing"] as? (String)) ?: "正在输入…"
        set(value) { values["typing"] = value }

    var typingOne: (String) -> String
        get() = (values["typingOne"] as? ((String) -> String)) ?: { "$it 正在输入…" }
        set(value) { values["typingOne"] = value }

    var typingMany: (Int) -> String
        get() = (values["typingMany"] as? ((Int) -> String)) ?: { "$it 人正在输入…" }
        set(value) { values["typingMany"] = value }

    var newMessages: (Int) -> String
        get() = (values["newMessages"] as? ((Int) -> String)) ?: { if (it > 0) "$it 条新消息" else "新消息" }
        set(value) { values["newMessages"] = value }

    var sendMessage: String
        get() = (values["sendMessage"] as? (String)) ?: "发消息"
        set(value) { values["sendMessage"] = value }

    var groupCall: String
        get() = (values["groupCall"] as? (String)) ?: "群通话"
        set(value) { values["groupCall"] = value }

    var joinedCount: (Int, String) -> String
        get() = (values["joinedCount"] as? ((Int, String) -> String)) ?: { n, status -> "$n 人已加入 · $status" }
        set(value) { values["joinedCount"] = value }

    var selfSuffix: (String) -> String
        get() = (values["selfSuffix"] as? ((String) -> String)) ?: { "$it（我）" }
        set(value) { values["selfSuffix"] = value }

    var forwardTo: String
        get() = (values["forwardTo"] as? (String)) ?: "转发给"
        set(value) { values["forwardTo"] = value }

    var searchConversations: String
        get() = (values["searchConversations"] as? (String)) ?: "搜索会话"
        set(value) { values["searchConversations"] = value }

    var noMatchingConversations: String
        get() = (values["noMatchingConversations"] as? (String)) ?: "没有匹配的会话"
        set(value) { values["noMatchingConversations"] = value }

    var selectedCount: (Int) -> String
        get() = (values["selectedCount"] as? ((Int) -> String)) ?: { "已选 $it" }
        set(value) { values["selectedCount"] = value }

    var groupAnnouncement: String
        get() = (values["groupAnnouncement"] as? (String)) ?: "群公告"
        set(value) { values["groupAnnouncement"] = value }

    var collapse: String
        get() = (values["collapse"] as? (String)) ?: "收起"
        set(value) { values["collapse"] = value }

    var expand: String
        get() = (values["expand"] as? (String)) ?: "展开"
        set(value) { values["expand"] = value }

    var packetClaimed: (String) -> String
        get() = (values["packetClaimed"] as? ((String) -> String)) ?: { "已领取 · $it" }
        set(value) { values["packetClaimed"] = value }

    var packetFinished: String
        get() = (values["packetFinished"] as? (String)) ?: "已被领完"
        set(value) { values["packetFinished"] = value }

    var packetTapToClaim: String
        get() = (values["packetTapToClaim"] as? (String)) ?: "点击领取"
        set(value) { values["packetTapToClaim"] = value }

    var packetBrand: String
        get() = (values["packetBrand"] as? (String)) ?: "闪包"
        set(value) { values["packetBrand"] = value }

    var commands: String
        get() = (values["commands"] as? (String)) ?: "命令"
        set(value) { values["commands"] = value }

    var noMatchingCommands: String
        get() = (values["noMatchingCommands"] as? (String)) ?: "没有匹配的命令"
        set(value) { values["noMatchingCommands"] = value }

    var translating: String
        get() = (values["translating"] as? (String)) ?: "翻译中…"
        set(value) { values["translating"] = value }

    var translatedBy: (String) -> String
        get() = (values["translatedBy"] as? ((String) -> String)) ?: { "由 $it 翻译" }
        set(value) { values["translatedBy"] = value }

    var translated: String
        get() = (values["translated"] as? (String)) ?: "已翻译"
        set(value) { values["translated"] = value }

    var hideOriginal: String
        get() = (values["hideOriginal"] as? (String)) ?: "隐藏原文"
        set(value) { values["hideOriginal"] = value }

    var showOriginal: String
        get() = (values["showOriginal"] as? (String)) ?: "显示原文"
        set(value) { values["showOriginal"] = value }

    var scanToAddMe: String
        get() = (values["scanToAddMe"] as? (String)) ?: "扫一扫加我"
        set(value) { values["scanToAddMe"] = value }

    var qrCardUnavailable: String
        get() = (values["qrCardUnavailable"] as? (String)) ?: "二维码暂不可用"
        set(value) { values["qrCardUnavailable"] = value }

    var cancel: String
        get() = (values["cancel"] as? (String)) ?: "取消"
        set(value) { values["cancel"] = value }

    var releaseToCancel: String
        get() = (values["releaseToCancel"] as? (String)) ?: "松开取消"
        set(value) { values["releaseToCancel"] = value }

    var voiceRecordingCancel: String
        get() = (values["voiceRecordingCancel"] as? (String)) ?: "取消录音"
        set(value) { values["voiceRecordingCancel"] = value }

    var voiceRecordingSend: String
        get() = (values["voiceRecordingSend"] as? (String)) ?: "发送语音"
        set(value) { values["voiceRecordingSend"] = value }
    var conversationRowDraft: String
        get() = (values["conversationRowDraft"] as? (String)) ?: "[草稿] "
        set(value) { values["conversationRowDraft"] = value }
    var conversationRowMention: String
        get() = (values["conversationRowMention"] as? (String)) ?: "[@我] "
        set(value) { values["conversationRowMention"] = value }

    var createPoll: String
        get() = (values["createPoll"] as? (String)) ?: "发起投票"
        set(value) { values["createPoll"] = value }

    var pollQuestionHint: String
        get() = (values["pollQuestionHint"] as? (String)) ?: "请输入问题"
        set(value) { values["pollQuestionHint"] = value }

    var pollOptionHint: (Int) -> String
        get() = (values["pollOptionHint"] as? ((Int) -> String)) ?: { "选项 $it" }
        set(value) { values["pollOptionHint"] = value }

    var removeOption: String
        get() = (values["removeOption"] as? (String)) ?: "删除选项"
        set(value) { values["removeOption"] = value }

    var addOption: String
        get() = (values["addOption"] as? (String)) ?: "添加选项"
        set(value) { values["addOption"] = value }

    var allowMultiple: String
        get() = (values["allowMultiple"] as? (String)) ?: "允许多选"
        set(value) { values["allowMultiple"] = value }

    var submitPoll: String
        get() = (values["submitPoll"] as? (String)) ?: "创建投票"
        set(value) { values["submitPoll"] = value }

    var chatBackground: String
        get() = (values["chatBackground"] as? (String)) ?: "聊天背景"
        set(value) { values["chatBackground"] = value }

    var decrease: String
        get() = (values["decrease"] as? (String)) ?: "减少"
        set(value) { values["decrease"] = value }

    var increase: String
        get() = (values["increase"] as? (String)) ?: "增加"
        set(value) { values["increase"] = value }

    var previousMonth: String
        get() = (values["previousMonth"] as? (String)) ?: "上个月"
        set(value) { values["previousMonth"] = value }

    var nextMonth: String
        get() = (values["nextMonth"] as? (String)) ?: "下个月"
        set(value) { values["nextMonth"] = value }

    var yearMonth: (Int, Int) -> String
        get() = (values["yearMonth"] as? ((Int, Int) -> String)) ?: { y, m -> "${y}年${m}月" }
        set(value) { values["yearMonth"] = value }

    var unlike: String
        get() = (values["unlike"] as? (String)) ?: "取消赞"
        set(value) { values["unlike"] = value }

    var like: String
        get() = (values["like"] as? (String)) ?: "赞"
        set(value) { values["like"] = value }

    var comment: String
        get() = (values["comment"] as? (String)) ?: "评论"
        set(value) { values["comment"] = value }

    var changeCover: String
        get() = (values["changeCover"] as? (String)) ?: "换封面"
        set(value) { values["changeCover"] = value }

    var post: String
        get() = (values["post"] as? (String)) ?: "发表"
        set(value) { values["post"] = value }

    var momentTextHint: String
        get() = (values["momentTextHint"] as? (String)) ?: "这一刻的想法…"
        set(value) { values["momentTextHint"] = value }

    var addImage: String
        get() = (values["addImage"] as? (String)) ?: "添加图片"
        set(value) { values["addImage"] = value }

    var removeImage: String
        get() = (values["removeImage"] as? (String)) ?: "移除图片"
        set(value) { values["removeImage"] = value }

    var pickLocation: String
        get() = (values["pickLocation"] as? (String)) ?: "所在位置"
        set(value) { values["pickLocation"] = value }

    var pickVisibility: String
        get() = (values["pickVisibility"] as? (String)) ?: "谁可以看"
        set(value) { values["pickVisibility"] = value }

    var more: String
        get() = (values["more"] as? (String)) ?: "更多"
        set(value) { values["more"] = value }

    var actionMenuLabel: String
        get() = (values["actionMenuLabel"] as? (String)) ?: "操作菜单"
        set(value) { values["actionMenuLabel"] = value }

    var hideTranscript: String
        get() = (values["hideTranscript"] as? (String)) ?: "隐藏文字"
        set(value) { values["hideTranscript"] = value }

    var showTranscript: String
        get() = (values["showTranscript"] as? (String)) ?: "转文字"
        set(value) { values["showTranscript"] = value }

    var recent: String
        get() = (values["recent"] as? (String)) ?: "最近"
        set(value) { values["recent"] = value }

    var searchEmoji: String
        get() = (values["searchEmoji"] as? (String)) ?: "搜索表情"
        set(value) { values["searchEmoji"] = value }

    var noMatchingEmoji: String
        get() = (values["noMatchingEmoji"] as? (String)) ?: "没有匹配的表情"
        set(value) { values["noMatchingEmoji"] = value }

    var emptyStickerPack: String
        get() = (values["emptyStickerPack"] as? (String)) ?: "该表情包暂无贴纸"
        set(value) { values["emptyStickerPack"] = value }

    var sticker: String
        get() = (values["sticker"] as? (String)) ?: "贴纸"
        set(value) { values["sticker"] = value }

    var actionImage: String
        get() = (values["actionImage"] as? (String)) ?: "图片"
        set(value) { values["actionImage"] = value }

    var actionCamera: String
        get() = (values["actionCamera"] as? (String)) ?: "拍摄"
        set(value) { values["actionCamera"] = value }

    var actionFile: String
        get() = (values["actionFile"] as? (String)) ?: "文件"
        set(value) { values["actionFile"] = value }

    var actionLocation: String
        get() = (values["actionLocation"] as? (String)) ?: "位置"
        set(value) { values["actionLocation"] = value }

    var actionCard: String
        get() = (values["actionCard"] as? (String)) ?: "名片"
        set(value) { values["actionCard"] = value }

    var actionVote: String
        get() = (values["actionVote"] as? (String)) ?: "投票"
        set(value) { values["actionVote"] = value }

    var actionTask: String
        get() = (values["actionTask"] as? (String)) ?: "任务"
        set(value) { values["actionTask"] = value }

    var actionSchedule: String
        get() = (values["actionSchedule"] as? (String)) ?: "日程"
        set(value) { values["actionSchedule"] = value }

    var incomingVideoCall: String
        get() = (values["incomingVideoCall"] as? (String)) ?: "邀请你进行视频通话"
        set(value) { values["incomingVideoCall"] = value }

    var incomingVoiceCall: String
        get() = (values["incomingVoiceCall"] as? (String)) ?: "邀请你进行语音通话"
        set(value) { values["incomingVoiceCall"] = value }

    var reject: String
        get() = (values["reject"] as? (String)) ?: "拒绝"
        set(value) { values["reject"] = value }

    var accept: String
        get() = (values["accept"] as? (String)) ?: "接听"
        set(value) { values["accept"] = value }

    var back: String
        get() = (values["back"] as? (String)) ?: "返回"
        set(value) { values["back"] = value }

    var confirm: String
        get() = (values["confirm"] as? (String)) ?: "确定"
        set(value) { values["confirm"] = value }

    var confirmCount: (Int) -> String
        get() = (values["confirmCount"] as? ((Int) -> String)) ?: { "确定 ($it)" }
        set(value) { values["confirmCount"] = value }

    var memberCount: (Int) -> String
        get() = (values["memberCount"] as? ((Int) -> String)) ?: { "$it 名成员" }
        set(value) { values["memberCount"] = value }

    var clear: String
        get() = (values["clear"] as? (String)) ?: "清除"
        set(value) { values["clear"] = value }

    var retry: String
        get() = (values["retry"] as? (String)) ?: "重试"
        set(value) { values["retry"] = value }

    var messagePending: String
        get() = (values["messagePending"] as? String) ?: "等待发送"
        set(value) { values["messagePending"] = value }
    var messageSending: String
        get() = (values["messageSending"] as? String) ?: "发送中"
        set(value) { values["messageSending"] = value }
    var messageSent: String
        get() = (values["messageSent"] as? String) ?: "已发送"
        set(value) { values["messageSent"] = value }
    var messageDelivered: String
        get() = (values["messageDelivered"] as? String) ?: "已送达"
        set(value) { values["messageDelivered"] = value }
    var messageRead: String
        get() = (values["messageRead"] as? String) ?: "已读"
        set(value) { values["messageRead"] = value }
    var messageFailed: String
        get() = (values["messageFailed"] as? String) ?: "发送失败"
        set(value) { values["messageFailed"] = value }
    var messageRetrying: String
        get() = (values["messageRetrying"] as? String) ?: "正在重试"
        set(value) { values["messageRetrying"] = value }
    var messageEdited: String
        get() = (values["messageEdited"] as? String) ?: "已编辑"
        set(value) { values["messageEdited"] = value }
    var messageReadOnce: String
        get() = (values["messageReadOnce"] as? String) ?: "仅可查看一次"
        set(value) { values["messageReadOnce"] = value }
    var messageBurnAfterRead: String
        get() = (values["messageBurnAfterRead"] as? String) ?: "阅后即焚"
        set(value) { values["messageBurnAfterRead"] = value }
    var messageExpired: String
        get() = (values["messageExpired"] as? String) ?: "已过期"
        set(value) { values["messageExpired"] = value }

    var select: String
        get() = (values["select"] as? (String)) ?: "选择"
        set(value) { values["select"] = value }

    var wordCharCount: (Int, Int) -> String
        get() = (values["wordCharCount"] as? ((Int, Int) -> String)) ?: { w, c -> "$w 个词 · $c 字符" }
        set(value) { values["wordCharCount"] = value }

    var changeAvatar: String
        get() = (values["changeAvatar"] as? (String)) ?: "更换头像"
        set(value) { values["changeAvatar"] = value }

    var qrCode: String
        get() = (values["qrCode"] as? (String)) ?: "二维码"
        set(value) { values["qrCode"] = value }

    var play: String
        get() = (values["play"] as? (String)) ?: "播放"
        set(value) { values["play"] = value }

    var pause: String
        get() = (values["pause"] as? (String)) ?: "暂停"
        set(value) { values["pause"] = value }

    var download: String
        get() = (values["download"] as? (String)) ?: "下载"
        set(value) { values["download"] = value }

    var imagePreviewClose: String
        get() = (values["imagePreviewClose"] as? (String)) ?: "关闭预览"
        set(value) { values["imagePreviewClose"] = value }
    var imagePreviewPrevious: String
        get() = (values["imagePreviewPrevious"] as? (String)) ?: "上一张"
        set(value) { values["imagePreviewPrevious"] = value }
    var imagePreviewNext: String
        get() = (values["imagePreviewNext"] as? (String)) ?: "下一张"
        set(value) { values["imagePreviewNext"] = value }
    var imagePreviewPosition: (Int, Int) -> String
        get() = (values["imagePreviewPosition"] as? ((Int, Int) -> String)) ?: { index, count -> "第 $index 张，共 $count 张" }
        set(value) { values["imagePreviewPosition"] = value }

    var imagePreviewOpen: String
        get() = (values["imagePreviewOpen"] as? (String)) ?: "查看图片"
        set(value) { values["imagePreviewOpen"] = value }

    var voiceMessage: String
        get() = (values["voiceMessage"] as? (String)) ?: "语音"
        set(value) { values["voiceMessage"] = value }

    var voiceDuration: (Int) -> String
        get() = (values["voiceDuration"] as? ((Int) -> String)) ?: { "$it 秒" }
        set(value) { values["voiceDuration"] = value }

    var voicePlaybackFailed: String
        get() = (values["voicePlaybackFailed"] as? (String)) ?: "播放失败"
        set(value) { values["voicePlaybackFailed"] = value }

    var videoLoadFailed: String
        get() = (values["videoLoadFailed"] as? (String)) ?: "视频无法播放"
        set(value) { values["videoLoadFailed"] = value }

    var imageLoadFailed: String
        get() = (values["imageLoadFailed"] as? (String)) ?: "图片加载失败"
        set(value) { values["imageLoadFailed"] = value }

    var search: String
        get() = (values["search"] as? (String)) ?: "搜索"
        set(value) { values["search"] = value }

    var reload: String
        get() = (values["reload"] as? (String)) ?: "重新加载"
        set(value) { values["reload"] = value }

    var today: String
        get() = (values["today"] as? (String)) ?: "今天"
        set(value) { values["today"] = value }

    var yesterday: String
        get() = (values["yesterday"] as? (String)) ?: "昨天"
        set(value) { values["yesterday"] = value }

    var timeRange: String
        get() = (values["timeRange"] as? (String)) ?: "时间范围"
        set(value) { values["timeRange"] = value }

    var searchIdleHint: String
        get() = (values["searchIdleHint"] as? (String)) ?: "输入关键词或选择类型"
        set(value) { values["searchIdleHint"] = value }

    var selectDevice: String
        get() = (values["selectDevice"] as? (String)) ?: "选择设备"
        set(value) { values["selectDevice"] = value }

    var confirmAction: String
        get() = (values["confirmAction"] as? (String)) ?: "确认"
        set(value) { values["confirmAction"] = value }

    var noContent: String
        get() = (values["noContent"] as? (String)) ?: "暂无内容"
        set(value) { values["noContent"] = value }

    var noConversations: String
        get() = (values["noConversations"] as? (String)) ?: "暂无会话"
        set(value) { values["noConversations"] = value }

    var noGroups: String
        get() = (values["noGroups"] as? (String)) ?: "暂无群组"
        set(value) { values["noGroups"] = value }

    var groupMembers: String
        get() = (values["groupMembers"] as? (String)) ?: "群成员"
        set(value) { values["groupMembers"] = value }

    var groupOwner: String
        get() = (values["groupOwner"] as? (String)) ?: "群主"
        set(value) { values["groupOwner"] = value }

    var groupAdmin: String
        get() = (values["groupAdmin"] as? (String)) ?: "管理员"
        set(value) { values["groupAdmin"] = value }

    var addMember: String
        get() = (values["addMember"] as? (String)) ?: "加成员"
        set(value) { values["addMember"] = value }

    var loginDevices: String
        get() = (values["loginDevices"] as? (String)) ?: "登录设备"
        set(value) { values["loginDevices"] = value }

    var currentDevice: String
        get() = (values["currentDevice"] as? (String)) ?: "当前设备"
        set(value) { values["currentDevice"] = value }

    var filesAndMedia: String
        get() = (values["filesAndMedia"] as? (String)) ?: "文件与媒体"
        set(value) { values["filesAndMedia"] = value }

    var notificationSettings: String
        get() = (values["notificationSettings"] as? (String)) ?: "通知设置"
        set(value) { values["notificationSettings"] = value }

    var transferQueue: String
        get() = (values["transferQueue"] as? (String)) ?: "传输队列"
        set(value) { values["transferQueue"] = value }

    var noTransfers: String
        get() = (values["noTransfers"] as? (String)) ?: "暂无传输任务"
        set(value) { values["noTransfers"] = value }

    var retryFailedTransfers: String
        get() = (values["retryFailedTransfers"] as? (String)) ?: "重试失败任务"
        set(value) { values["retryFailedTransfers"] = value }

    var permissionNoun: (FlarePermissionKind) -> String
        get() = (values["permissionNoun"] as? ((FlarePermissionKind) -> String)) ?: {
            when (it) {
            FlarePermissionKind.Microphone -> "麦克风"
            FlarePermissionKind.Camera -> "摄像头"
            FlarePermissionKind.Notifications -> "通知"
            FlarePermissionKind.Storage -> "存储空间"
            FlarePermissionKind.Photos -> "相册"
            FlarePermissionKind.Contacts -> "通讯录"
            FlarePermissionKind.Location -> "位置信息"
            FlarePermissionKind.Screen -> "屏幕录制"
            }
            }
        set(value) { values["permissionNoun"] = value }

    var permissionVerb: (FlarePermissionKind) -> String
        get() = (values["permissionVerb"] as? ((FlarePermissionKind) -> String)) ?: {
            when (it) {
            FlarePermissionKind.Microphone -> "使用麦克风"
            FlarePermissionKind.Camera -> "使用摄像头"
            FlarePermissionKind.Notifications -> "发送通知"
            FlarePermissionKind.Storage -> "访问存储空间"
            FlarePermissionKind.Photos -> "访问相册"
            FlarePermissionKind.Contacts -> "访问通讯录"
            FlarePermissionKind.Location -> "获取位置信息"
            FlarePermissionKind.Screen -> "录制屏幕内容"
            }
            }
        set(value) { values["permissionVerb"] = value }

    var permissionTitle: (String) -> String
        get() = (values["permissionTitle"] as? ((String) -> String)) ?: { "需要${it}权限" }
        set(value) { values["permissionTitle"] = value }

    var permissionFeatureFallback: String
        get() = (values["permissionFeatureFallback"] as? (String)) ?: "此功能"
        set(value) { values["permissionFeatureFallback"] = value }

    var permissionUndeterminedBody: (String, String) -> String
        get() = (values["permissionUndeterminedBody"] as? ((String, String) -> String)) ?: { feature, verb -> "${feature}需要${verb}，请允许后继续。" }
        set(value) { values["permissionUndeterminedBody"] = value }

    var permissionDeniedBody: (String, String) -> String
        get() = (values["permissionDeniedBody"] as? ((String, String) -> String)) ?: { feature, verb -> "${verb}的权限已被拒绝，${feature}无法使用。请前往系统设置开启。" }
        set(value) { values["permissionDeniedBody"] = value }

    var permissionRestrictedBody: (String, String) -> String
        get() = (values["permissionRestrictedBody"] as? ((String, String) -> String)) ?: { feature, verb -> "${verb}的权限受设备或组织策略限制，${feature}暂不可用。" }
        set(value) { values["permissionRestrictedBody"] = value }

    var permissionUnavailableBody: (String, String) -> String
        get() = (values["permissionUnavailableBody"] as? ((String, String) -> String)) ?: { feature, verb -> "当前设备或运行环境不支持${verb}，${feature}暂不可用。" }
        set(value) { values["permissionUnavailableBody"] = value }

    var permissionAllow: String
        get() = (values["permissionAllow"] as? (String)) ?: "允许"
        set(value) { values["permissionAllow"] = value }

    var permissionOpenSettings: String
        get() = (values["permissionOpenSettings"] as? (String)) ?: "前往设置"
        set(value) { values["permissionOpenSettings"] = value }

    var permissionStateLabel: (FlarePermissionState) -> String
        get() = (values["permissionStateLabel"] as? ((FlarePermissionState) -> String)) ?: {
            when (it) {
            FlarePermissionState.Undetermined -> "未授权"
            FlarePermissionState.Denied -> "已拒绝"
            FlarePermissionState.Restricted -> "受限制"
            FlarePermissionState.Unavailable -> "不可用"
            }
            }
        set(value) { values["permissionStateLabel"] = value }

    var permissionDismiss: String
        get() = (values["permissionDismiss"] as? (String)) ?: "知道了"
        set(value) { values["permissionDismiss"] = value }

    var composerPlaceholder: String
        get() = (values["composerPlaceholder"] as? (String)) ?: "消息"
        set(value) { values["composerPlaceholder"] = value }

    var composerReply: String
        get() = (values["composerReply"] as? (String)) ?: "回复"
        set(value) { values["composerReply"] = value }

    var composerEmoji: String
        get() = (values["composerEmoji"] as? (String)) ?: "表情"
        set(value) { values["composerEmoji"] = value }

    var composerMention: String
        get() = (values["composerMention"] as? (String)) ?: "提及"
        set(value) { values["composerMention"] = value }

    var composerVoice: String
        get() = (values["composerVoice"] as? (String)) ?: "语音"
        set(value) { values["composerVoice"] = value }

    var composerImage: String
        get() = (values["composerImage"] as? (String)) ?: "图片"
        set(value) { values["composerImage"] = value }

    var composerRichText: String
        get() = (values["composerRichText"] as? (String)) ?: "富文本"
        set(value) { values["composerRichText"] = value }

    var composerMore: String
        get() = (values["composerMore"] as? (String)) ?: "更多"
        set(value) { values["composerMore"] = value }

    var composerExpandInput: String
        get() = (values["composerExpandInput"] as? (String)) ?: "展开输入框"
        set(value) { values["composerExpandInput"] = value }

    var composerCollapseInput: String
        get() = (values["composerCollapseInput"] as? (String)) ?: "收起输入框"
        set(value) { values["composerCollapseInput"] = value }

    var composerFormatBold: String
        get() = (values["composerFormatBold"] as? (String)) ?: "加粗"
        set(value) { values["composerFormatBold"] = value }

    var composerFormatItalic: String
        get() = (values["composerFormatItalic"] as? (String)) ?: "斜体"
        set(value) { values["composerFormatItalic"] = value }

    var composerFormatStrike: String
        get() = (values["composerFormatStrike"] as? (String)) ?: "删除线"
        set(value) { values["composerFormatStrike"] = value }

    var composerFormatCode: String
        get() = (values["composerFormatCode"] as? (String)) ?: "代码"
        set(value) { values["composerFormatCode"] = value }

    var composerFormatLink: String
        get() = (values["composerFormatLink"] as? (String)) ?: "链接"
        set(value) { values["composerFormatLink"] = value }

    var composerFormatHeading: String
        get() = (values["composerFormatHeading"] as? (String)) ?: "标题"
        set(value) { values["composerFormatHeading"] = value }

    var composerFormatQuote: String
        get() = (values["composerFormatQuote"] as? (String)) ?: "引用"
        set(value) { values["composerFormatQuote"] = value }

    var composerFormatBullet: String
        get() = (values["composerFormatBullet"] as? (String)) ?: "无序列表"
        set(value) { values["composerFormatBullet"] = value }

    var composerFormatOrdered: String
        get() = (values["composerFormatOrdered"] as? (String)) ?: "有序列表"
        set(value) { values["composerFormatOrdered"] = value }

    var voiceHoldButtonLabel: String
        get() = (values["voiceHoldButtonLabel"] as? (String)) ?: "按住 说话"
        set(value) { values["voiceHoldButtonLabel"] = value }

    var voiceHoldButtonRecording: String
        get() = (values["voiceHoldButtonRecording"] as? (String)) ?: "松开发送 · 上滑取消"
        set(value) { values["voiceHoldButtonRecording"] = value }

    var voiceHoldButtonCancel: String
        get() = (values["voiceHoldButtonCancel"] as? (String)) ?: "松开取消"
        set(value) { values["voiceHoldButtonCancel"] = value }

    var composerReplyStripLabel: String
        get() = (values["composerReplyStripLabel"] as? (String)) ?: "回复"
        set(value) { values["composerReplyStripLabel"] = value }

    var inlineVoiceComposerAllowMicrophone: String
        get() = (values["inlineVoiceComposerAllowMicrophone"] as? (String)) ?: "请允许麦克风权限"
        set(value) { values["inlineVoiceComposerAllowMicrophone"] = value }

    var inlineVoiceComposerKeyboard: String
        get() = (values["inlineVoiceComposerKeyboard"] as? (String)) ?: "返回键盘并删除录音"
        set(value) { values["inlineVoiceComposerKeyboard"] = value }

    var inlineVoiceComposerPause: String
        get() = (values["inlineVoiceComposerPause"] as? (String)) ?: "暂停录音"
        set(value) { values["inlineVoiceComposerPause"] = value }

    var inlineVoiceComposerStart: String
        get() = (values["inlineVoiceComposerStart"] as? (String)) ?: "开始录音"
        set(value) { values["inlineVoiceComposerStart"] = value }

    var inlineVoiceComposerPreview: String
        get() = (values["inlineVoiceComposerPreview"] as? (String)) ?: "试听 / 暂停"
        set(value) { values["inlineVoiceComposerPreview"] = value }

    var inlineVoiceComposerResume: String
        get() = (values["inlineVoiceComposerResume"] as? (String)) ?: "继续录音"
        set(value) { values["inlineVoiceComposerResume"] = value }

    var inlineVoiceComposerDiscard: String
        get() = (values["inlineVoiceComposerDiscard"] as? (String)) ?: "删除录音"
        set(value) { values["inlineVoiceComposerDiscard"] = value }

    var inlineVoiceComposerSendFailed: String
        get() = (values["inlineVoiceComposerSendFailed"] as? (String)) ?: "发送失败，可重试"
        set(value) { values["inlineVoiceComposerSendFailed"] = value }

    var emojiStickerPickerEmoji: String
        get() = (values["emojiStickerPickerEmoji"] as? (String)) ?: "表情"
        set(value) { values["emojiStickerPickerEmoji"] = value }

    var emojiStickerPickerLoading: String
        get() = (values["emojiStickerPickerLoading"] as? (String)) ?: "正在加载表情"
        set(value) { values["emojiStickerPickerLoading"] = value }

    var groupPermissionMatrixTitle: String
        get() = (values["groupPermissionMatrixTitle"] as? (String)) ?: "群设置"
        set(value) { values["groupPermissionMatrixTitle"] = value }

    var groupPermissionMatrixReadOnlyHint: String
        get() = (values["groupPermissionMatrixReadOnlyHint"] as? (String)) ?: "仅群主和管理员可修改"
        set(value) { values["groupPermissionMatrixReadOnlyHint"] = value }

    var groupPermissionMatrixJoinPolicy: String
        get() = (values["groupPermissionMatrixJoinPolicy"] as? (String)) ?: "加群方式"
        set(value) { values["groupPermissionMatrixJoinPolicy"] = value }

    var groupPermissionMatrixJoinPolicyDescription: String
        get() = (values["groupPermissionMatrixJoinPolicyDescription"] as? (String)) ?: "决定他人如何加入本群"
        set(value) { values["groupPermissionMatrixJoinPolicyDescription"] = value }

    var groupPermissionMatrixJoinInvite: String
        get() = (values["groupPermissionMatrixJoinInvite"] as? (String)) ?: "仅邀请"
        set(value) { values["groupPermissionMatrixJoinInvite"] = value }

    var groupPermissionMatrixJoinApproval: String
        get() = (values["groupPermissionMatrixJoinApproval"] as? (String)) ?: "需管理员审批"
        set(value) { values["groupPermissionMatrixJoinApproval"] = value }

    var groupPermissionMatrixJoinOpen: String
        get() = (values["groupPermissionMatrixJoinOpen"] as? (String)) ?: "允许直接加入"
        set(value) { values["groupPermissionMatrixJoinOpen"] = value }

    var groupPermissionMatrixUnknownJoinPolicy: String
        get() = (values["groupPermissionMatrixUnknownJoinPolicy"] as? (String)) ?: "当前加群方式未知，请重新选择"
        set(value) { values["groupPermissionMatrixUnknownJoinPolicy"] = value }

    var groupPermissionMatrixMuteAll: String
        get() = (values["groupPermissionMatrixMuteAll"] as? (String)) ?: "全员禁言"
        set(value) { values["groupPermissionMatrixMuteAll"] = value }

    var groupPermissionMatrixMuteAllDescription: String
        get() = (values["groupPermissionMatrixMuteAllDescription"] as? (String)) ?: "开启后仅群主和管理员可发言"
        set(value) { values["groupPermissionMatrixMuteAllDescription"] = value }

    var groupPermissionMatrixOnlyAdminCanAtAll: String
        get() = (values["groupPermissionMatrixOnlyAdminCanAtAll"] as? (String)) ?: "仅管理员可 @所有人"
        set(value) { values["groupPermissionMatrixOnlyAdminCanAtAll"] = value }

    var groupPermissionMatrixOnlyAdminCanAtAllDescription: String
        get() = (values["groupPermissionMatrixOnlyAdminCanAtAllDescription"] as? (String)) ?: "限制 @所有人 的使用范围"
        set(value) { values["groupPermissionMatrixOnlyAdminCanAtAllDescription"] = value }

    var groupPermissionMatrixOnlyAdminCanPin: String
        get() = (values["groupPermissionMatrixOnlyAdminCanPin"] as? (String)) ?: "仅管理员可置顶消息"
        set(value) { values["groupPermissionMatrixOnlyAdminCanPin"] = value }

    var groupPermissionMatrixOnlyAdminCanPinDescription: String
        get() = (values["groupPermissionMatrixOnlyAdminCanPinDescription"] as? (String)) ?: "限制群内置顶消息的权限"
        set(value) { values["groupPermissionMatrixOnlyAdminCanPinDescription"] = value }

    var groupPermissionMatrixShareCardPermission: String
        get() = (values["groupPermissionMatrixShareCardPermission"] as? (String)) ?: "允许分享群名片"
        set(value) { values["groupPermissionMatrixShareCardPermission"] = value }

    var groupPermissionMatrixShareCardPermissionDescription: String
        get() = (values["groupPermissionMatrixShareCardPermissionDescription"] as? (String)) ?: "关闭后成员不能把本群分享给他人"
        set(value) { values["groupPermissionMatrixShareCardPermissionDescription"] = value }

    var groupPermissionMatrixOn: String
        get() = (values["groupPermissionMatrixOn"] as? (String)) ?: "已开启"
        set(value) { values["groupPermissionMatrixOn"] = value }

    var groupPermissionMatrixOff: String
        get() = (values["groupPermissionMatrixOff"] as? (String)) ?: "已关闭"
        set(value) { values["groupPermissionMatrixOff"] = value }

    var groupPermissionMatrixBusy: String
        get() = (values["groupPermissionMatrixBusy"] as? (String)) ?: "提交中"
        set(value) { values["groupPermissionMatrixBusy"] = value }

    var groupPermissionMatrixDismissError: String
        get() = (values["groupPermissionMatrixDismissError"] as? (String)) ?: "忽略此错误"
        set(value) { values["groupPermissionMatrixDismissError"] = value }

    var conversationBatchToolbarEmpty: String
        get() = (values["conversationBatchToolbarEmpty"] as? (String)) ?: "请选择会话"
        set(value) { values["conversationBatchToolbarEmpty"] = value }

    var conversationBatchToolbarMarkRead: String
        get() = (values["conversationBatchToolbarMarkRead"] as? (String)) ?: "标为已读"
        set(value) { values["conversationBatchToolbarMarkRead"] = value }

    var conversationBatchToolbarMute: String
        get() = (values["conversationBatchToolbarMute"] as? (String)) ?: "免打扰"
        set(value) { values["conversationBatchToolbarMute"] = value }

    var conversationBatchToolbarArchive: String
        get() = (values["conversationBatchToolbarArchive"] as? (String)) ?: "归档"
        set(value) { values["conversationBatchToolbarArchive"] = value }

    var conversationBatchToolbarCancel: String
        get() = (values["conversationBatchToolbarCancel"] as? (String)) ?: "取消选择"
        set(value) { values["conversationBatchToolbarCancel"] = value }

    var conversationBatchToolbarBusy: String
        get() = (values["conversationBatchToolbarBusy"] as? (String)) ?: "处理中"
        set(value) { values["conversationBatchToolbarBusy"] = value }

    var conversationBatchToolbarSucceededSummary: String
        get() = (values["conversationBatchToolbarSucceededSummary"] as? (String)) ?: "成功 {n} 项"
        set(value) { values["conversationBatchToolbarSucceededSummary"] = value }

    var conversationBatchToolbarFailedSummary: String
        get() = (values["conversationBatchToolbarFailedSummary"] as? (String)) ?: "{n} 项失败"
        set(value) { values["conversationBatchToolbarFailedSummary"] = value }

    var conversationBatchToolbarRetryFailed: String
        get() = (values["conversationBatchToolbarRetryFailed"] as? (String)) ?: "重试失败项"
        set(value) { values["conversationBatchToolbarRetryFailed"] = value }

    var conversationBatchToolbarDismiss: String
        get() = (values["conversationBatchToolbarDismiss"] as? (String)) ?: "关闭结果"
        set(value) { values["conversationBatchToolbarDismiss"] = value }

    var conversationBatchToolbarExpand: String
        get() = (values["conversationBatchToolbarExpand"] as? (String)) ?: "查看详情"
        set(value) { values["conversationBatchToolbarExpand"] = value }

    var conversationBatchToolbarMaxSelection: String
        get() = (values["conversationBatchToolbarMaxSelection"] as? (String)) ?: "最多可选 {n} 项"
        set(value) { values["conversationBatchToolbarMaxSelection"] = value }

    var memberRoleSheetMemberRole: String
        get() = (values["memberRoleSheetMemberRole"] as? (String)) ?: "成员"
        set(value) { values["memberRoleSheetMemberRole"] = value }

    var memberRoleSheetMuted: String
        get() = (values["memberRoleSheetMuted"] as? (String)) ?: "已禁言"
        set(value) { values["memberRoleSheetMuted"] = value }

    var memberRoleSheetPromote: String
        get() = (values["memberRoleSheetPromote"] as? (String)) ?: "设为管理员"
        set(value) { values["memberRoleSheetPromote"] = value }

    var memberRoleSheetDemote: String
        get() = (values["memberRoleSheetDemote"] as? (String)) ?: "取消管理员"
        set(value) { values["memberRoleSheetDemote"] = value }

    var memberRoleSheetMute: String
        get() = (values["memberRoleSheetMute"] as? (String)) ?: "禁言"
        set(value) { values["memberRoleSheetMute"] = value }

    var memberRoleSheetUnmute: String
        get() = (values["memberRoleSheetUnmute"] as? (String)) ?: "解除禁言"
        set(value) { values["memberRoleSheetUnmute"] = value }

    var memberRoleSheetRemove: String
        get() = (values["memberRoleSheetRemove"] as? (String)) ?: "移出群聊"
        set(value) { values["memberRoleSheetRemove"] = value }

    var memberRoleSheetTransferOwner: String
        get() = (values["memberRoleSheetTransferOwner"] as? (String)) ?: "转让群主"
        set(value) { values["memberRoleSheetTransferOwner"] = value }

    var memberRoleSheetDangerGroup: String
        get() = (values["memberRoleSheetDangerGroup"] as? (String)) ?: "危险操作"
        set(value) { values["memberRoleSheetDangerGroup"] = value }

    var memberRoleSheetEmpty: String
        get() = (values["memberRoleSheetEmpty"] as? (String)) ?: "你没有管理权限"
        set(value) { values["memberRoleSheetEmpty"] = value }

    var memberRoleSheetOwnerProtected: String
        get() = (values["memberRoleSheetOwnerProtected"] as? (String)) ?: "群主不可被管理"
        set(value) { values["memberRoleSheetOwnerProtected"] = value }

    var inviteCodeLabel: String
        get() = (values["inviteCodeLabel"] as? (String)) ?: "邀请码"
        set(value) { values["inviteCodeLabel"] = value }

    var inviteCodePlaceholder: String
        get() = (values["inviteCodePlaceholder"] as? (String)) ?: "请输入邀请码"
        set(value) { values["inviteCodePlaceholder"] = value }

    var inviteCodeOptional: String
        get() = (values["inviteCodeOptional"] as? (String)) ?: "选填"
        set(value) { values["inviteCodeOptional"] = value }

    var inviteCodeChecking: String
        get() = (values["inviteCodeChecking"] as? (String)) ?: "正在校验邀请码…"
        set(value) { values["inviteCodeChecking"] = value }

    var inviteCodeValid: String
        get() = (values["inviteCodeValid"] as? (String)) ?: "邀请码可用"
        set(value) { values["inviteCodeValid"] = value }

    var inviteCodeInviter: String
        get() = (values["inviteCodeInviter"] as? (String)) ?: "邀请人：{name}"
        set(value) { values["inviteCodeInviter"] = value }

    var inviteCodeInvalid: String
        get() = (values["inviteCodeInvalid"] as? (String)) ?: "邀请码无效"
        set(value) { values["inviteCodeInvalid"] = value }

    var myInviteTitle: String
        get() = (values["myInviteTitle"] as? (String)) ?: "我的邀请"
        set(value) { values["myInviteTitle"] = value }

    var myInviteCodeLabel: String
        get() = (values["myInviteCodeLabel"] as? (String)) ?: "我的邀请码"
        set(value) { values["myInviteCodeLabel"] = value }

    var myInviteCodeUnavailable: String
        get() = (values["myInviteCodeUnavailable"] as? (String)) ?: "邀请码暂不可用"
        set(value) { values["myInviteCodeUnavailable"] = value }

    var myInviteCopy: String
        get() = (values["myInviteCopy"] as? (String)) ?: "复制"
        set(value) { values["myInviteCopy"] = value }

    var myInviteShare: String
        get() = (values["myInviteShare"] as? (String)) ?: "分享"
        set(value) { values["myInviteShare"] = value }

    var myInviteRegenerate: String
        get() = (values["myInviteRegenerate"] as? (String)) ?: "重新生成"
        set(value) { values["myInviteRegenerate"] = value }

    var myInviteRegenerating: String
        get() = (values["myInviteRegenerating"] as? (String)) ?: "生成中…"
        set(value) { values["myInviteRegenerating"] = value }

    var myInviteCooldown: String
        get() = (values["myInviteCooldown"] as? (String)) ?: "{time} 后可重新生成"
        set(value) { values["myInviteCooldown"] = value }

    var myInviteUnitMinutes: String
        get() = (values["myInviteUnitMinutes"] as? (String)) ?: "{n} 分钟"
        set(value) { values["myInviteUnitMinutes"] = value }

    var myInviteUnitHours: String
        get() = (values["myInviteUnitHours"] as? (String)) ?: "{n} 小时"
        set(value) { values["myInviteUnitHours"] = value }

    var myInviteUnitDays: String
        get() = (values["myInviteUnitDays"] as? (String)) ?: "{n} 天"
        set(value) { values["myInviteUnitDays"] = value }

    var myInviteStatsTitle: String
        get() = (values["myInviteStatsTitle"] as? (String)) ?: "我的团队"
        set(value) { values["myInviteStatsTitle"] = value }

    var myInviteDirect: String
        get() = (values["myInviteDirect"] as? (String)) ?: "直接邀请"
        set(value) { values["myInviteDirect"] = value }

    var myInviteLevel2: String
        get() = (values["myInviteLevel2"] as? (String)) ?: "二级"
        set(value) { values["myInviteLevel2"] = value }

    var myInviteLevel3: String
        get() = (values["myInviteLevel3"] as? (String)) ?: "三级"
        set(value) { values["myInviteLevel3"] = value }

    var myInviteTotal: String
        get() = (values["myInviteTotal"] as? (String)) ?: "团队总数"
        set(value) { values["myInviteTotal"] = value }

    var myInviteInviteesTitle: String
        get() = (values["myInviteInviteesTitle"] as? (String)) ?: "直接邀请的人"
        set(value) { values["myInviteInviteesTitle"] = value }

    var myInviteEmpty: String
        get() = (values["myInviteEmpty"] as? (String)) ?: "还没有人通过你的邀请码加入"
        set(value) { values["myInviteEmpty"] = value }

    var myInviteLoadMore: String
        get() = (values["myInviteLoadMore"] as? (String)) ?: "加载更多"
        set(value) { values["myInviteLoadMore"] = value }

    var myInviteLoading: String
        get() = (values["myInviteLoading"] as? (String)) ?: "正在加载邀请信息"
        set(value) { values["myInviteLoading"] = value }

    var myInviteJoined: String
        get() = (values["myInviteJoined"] as? (String)) ?: "{date} 加入"
        set(value) { values["myInviteJoined"] = value }

    var myInviteCountOnly: String
        get() = (values["myInviteCountOnly"] as? (String)) ?: "{count} 人"
        set(value) { values["myInviteCountOnly"] = value }

    var storageUsageTitle: String
        get() = (values["storageUsageTitle"] as? (String)) ?: "存储空间"
        set(value) { values["storageUsageTitle"] = value }

    var storageUsageUnknown: String
        get() = (values["storageUsageUnknown"] as? (String)) ?: "未知"
        set(value) { values["storageUsageUnknown"] = value }

    var storageUsageAtLeast: String
        get() = (values["storageUsageAtLeast"] as? (String)) ?: "至少"
        set(value) { values["storageUsageAtLeast"] = value }

    var storageUsageClear: String
        get() = (values["storageUsageClear"] as? (String)) ?: "清理"
        set(value) { values["storageUsageClear"] = value }

    var storageUsageClearing: String
        get() = (values["storageUsageClearing"] as? (String)) ?: "清理中"
        set(value) { values["storageUsageClearing"] = value }

    var storageUsageTotal: String
        get() = (values["storageUsageTotal"] as? (String)) ?: "总计"
        set(value) { values["storageUsageTotal"] = value }

    var storageUsageDeviceFree: String
        get() = (values["storageUsageDeviceFree"] as? (String)) ?: "可用空间"
        set(value) { values["storageUsageDeviceFree"] = value }

    var storageUsageReload: String
        get() = (values["storageUsageReload"] as? (String)) ?: "重新统计"
        set(value) { values["storageUsageReload"] = value }

    var storageUsageRetry: String
        get() = (values["storageUsageRetry"] as? (String)) ?: "失败重试"
        set(value) { values["storageUsageRetry"] = value }

    var storageUsageDismissError: String
        get() = (values["storageUsageDismissError"] as? (String)) ?: "忽略此错误"
        set(value) { values["storageUsageDismissError"] = value }

    var storageUsageLoading: String
        get() = (values["storageUsageLoading"] as? (String)) ?: "正在统计存储占用"
        set(value) { values["storageUsageLoading"] = value }

    var storageUsageEmpty: String
        get() = (values["storageUsageEmpty"] as? (String)) ?: "没有可统计的存储分类"
        set(value) { values["storageUsageEmpty"] = value }

    var storageUsageFileCount: String
        get() = (values["storageUsageFileCount"] as? (String)) ?: "{count} 个文件"
        set(value) { values["storageUsageFileCount"] = value }

    var relationActionBarAdd: String
        get() = (values["relationActionBarAdd"] as? (String)) ?: "添加好友"
        set(value) { values["relationActionBarAdd"] = value }

    var relationActionBarAccept: String
        get() = (values["relationActionBarAccept"] as? (String)) ?: "接受"
        set(value) { values["relationActionBarAccept"] = value }

    var relationActionBarRemove: String
        get() = (values["relationActionBarRemove"] as? (String)) ?: "删除好友"
        set(value) { values["relationActionBarRemove"] = value }

    var relationActionBarBlock: String
        get() = (values["relationActionBarBlock"] as? (String)) ?: "加入黑名单"
        set(value) { values["relationActionBarBlock"] = value }

    var relationActionBarUnblock: String
        get() = (values["relationActionBarUnblock"] as? (String)) ?: "移出黑名单"
        set(value) { values["relationActionBarUnblock"] = value }

    var relationActionBarPending: String
        get() = (values["relationActionBarPending"] as? (String)) ?: "等待对方验证"
        set(value) { values["relationActionBarPending"] = value }

    var relationActionBarBusy: String
        get() = (values["relationActionBarBusy"] as? (String)) ?: "处理中"
        set(value) { values["relationActionBarBusy"] = value }

    var relationActionBarDismissError: String
        get() = (values["relationActionBarDismissError"] as? (String)) ?: "关闭错误提示"
        set(value) { values["relationActionBarDismissError"] = value }

    var relationActionBarEmpty: String
        get() = (values["relationActionBarEmpty"] as? (String)) ?: "暂无可用操作"
        set(value) { values["relationActionBarEmpty"] = value }

    var screenShareTitle: String
        get() = (values["screenShareTitle"] as? (String)) ?: "屏幕共享"
        set(value) { values["screenShareTitle"] = value }

    var screenShareIdle: String
        get() = (values["screenShareIdle"] as? (String)) ?: "未在共享"
        set(value) { values["screenShareIdle"] = value }

    var screenShareRequesting: String
        get() = (values["screenShareRequesting"] as? (String)) ?: "正在请求共享"
        set(value) { values["screenShareRequesting"] = value }

    var screenShareSharing: String
        get() = (values["screenShareSharing"] as? (String)) ?: "正在共享屏幕"
        set(value) { values["screenShareSharing"] = value }

    var screenShareViewing: String
        get() = (values["screenShareViewing"] as? (String)) ?: "正在观看共享"
        set(value) { values["screenShareViewing"] = value }

    var screenShareUnavailable: String
        get() = (values["screenShareUnavailable"] as? (String)) ?: "当前环境不支持屏幕共享"
        set(value) { values["screenShareUnavailable"] = value }

    var screenShareSourceRow: String
        get() = (values["screenShareSourceRow"] as? (String)) ?: "共享内容"
        set(value) { values["screenShareSourceRow"] = value }

    var screenSharePresenterRow: String
        get() = (values["screenSharePresenterRow"] as? (String)) ?: "共享者"
        set(value) { values["screenSharePresenterRow"] = value }

    var screenShareStart: String
        get() = (values["screenShareStart"] as? (String)) ?: "共享屏幕"
        set(value) { values["screenShareStart"] = value }

    var screenShareStop: String
        get() = (values["screenShareStop"] as? (String)) ?: "停止共享"
        set(value) { values["screenShareStop"] = value }

    var screenShareCancel: String
        get() = (values["screenShareCancel"] as? (String)) ?: "取消请求"
        set(value) { values["screenShareCancel"] = value }

    var conversationActionSheetPin: String
        get() = (values["conversationActionSheetPin"] as? (String)) ?: "置顶"
        set(value) { values["conversationActionSheetPin"] = value }

    var conversationActionSheetUnpin: String
        get() = (values["conversationActionSheetUnpin"] as? (String)) ?: "取消置顶"
        set(value) { values["conversationActionSheetUnpin"] = value }

    var conversationActionSheetMute: String
        get() = (values["conversationActionSheetMute"] as? (String)) ?: "免打扰"
        set(value) { values["conversationActionSheetMute"] = value }

    var conversationActionSheetUnmute: String
        get() = (values["conversationActionSheetUnmute"] as? (String)) ?: "取消免打扰"
        set(value) { values["conversationActionSheetUnmute"] = value }

    var conversationActionSheetMarkRead: String
        get() = (values["conversationActionSheetMarkRead"] as? (String)) ?: "标为已读"
        set(value) { values["conversationActionSheetMarkRead"] = value }

    var conversationActionSheetMarkUnread: String
        get() = (values["conversationActionSheetMarkUnread"] as? (String)) ?: "标为未读"
        set(value) { values["conversationActionSheetMarkUnread"] = value }

    var conversationActionSheetArchive: String
        get() = (values["conversationActionSheetArchive"] as? (String)) ?: "归档"
        set(value) { values["conversationActionSheetArchive"] = value }

    var conversationActionSheetUnarchive: String
        get() = (values["conversationActionSheetUnarchive"] as? (String)) ?: "取消归档"
        set(value) { values["conversationActionSheetUnarchive"] = value }

    var conversationActionSheetHide: String
        get() = (values["conversationActionSheetHide"] as? (String)) ?: "隐藏"
        set(value) { values["conversationActionSheetHide"] = value }

    var conversationActionSheetClearHistory: String
        get() = (values["conversationActionSheetClearHistory"] as? (String)) ?: "清空本地记录"
        set(value) { values["conversationActionSheetClearHistory"] = value }

    var conversationActionSheetEmpty: String
        get() = (values["conversationActionSheetEmpty"] as? (String)) ?: "暂无可用操作"
        set(value) { values["conversationActionSheetEmpty"] = value }
    var messageActionSheetLabel: String
        get() = (values["messageActionSheetLabel"] as? (String)) ?: "消息操作"
        set(value) { values["messageActionSheetLabel"] = value }
    var messageActionSheetEmpty: String
        get() = (values["messageActionSheetEmpty"] as? (String)) ?: "暂无可用操作"
        set(value) { values["messageActionSheetEmpty"] = value }
    var messageSpoilerReveal: String
        get() = (values["messageSpoilerReveal"] as? (String)) ?: "剧透内容，点按显示"
        set(value) { values["messageSpoilerReveal"] = value }
    var messageImageGroupLabel: (Int) -> String
        get() = (values["messageImageGroupLabel"] as? ((Int) -> String)) ?: { "$it 张图片" }
        set(value) { values["messageImageGroupLabel"] = value }
    var messageImageGroupItem: (Int, Int) -> String
        get() = (values["messageImageGroupItem"] as? ((Int, Int) -> String)) ?: { index, count -> "第 $index 张图片，共 $count 张" }
        set(value) { values["messageImageGroupItem"] = value }
    var messageImageGroupItemMore: (Int, Int, Int) -> String
        get() = (values["messageImageGroupItemMore"] as? ((Int, Int, Int) -> String))
            ?: { index, count, more -> "第 $index 张图片，共 $count 张，另有 $more 张未显示" }
        set(value) { values["messageImageGroupItemMore"] = value }
    var messageActionReply: String
        get() = (values["messageActionReply"] as? (String)) ?: "回复"
        set(value) { values["messageActionReply"] = value }
    var messageActionForward: String
        get() = (values["messageActionForward"] as? (String)) ?: "转发"
        set(value) { values["messageActionForward"] = value }
    var messageActionRecall: String
        get() = (values["messageActionRecall"] as? (String)) ?: "撤回"
        set(value) { values["messageActionRecall"] = value }
    var messageActionResend: String
        get() = (values["messageActionResend"] as? (String)) ?: "重新发送"
        set(value) { values["messageActionResend"] = value }
    var messageActionMultiSelect: String
        get() = (values["messageActionMultiSelect"] as? (String)) ?: "多选"
        set(value) { values["messageActionMultiSelect"] = value }
    var messageActionMark: String
        get() = (values["messageActionMark"] as? (String)) ?: "标记"
        set(value) { values["messageActionMark"] = value }
    var messageActionPin: String
        get() = (values["messageActionPin"] as? (String)) ?: "置顶消息"
        set(value) { values["messageActionPin"] = value }
    var messageActionPinSelf: String
        get() = (values["messageActionPinSelf"] as? (String)) ?: "仅自己置顶"
        set(value) { values["messageActionPinSelf"] = value }
    var messageActionUnpin: String
        get() = (values["messageActionUnpin"] as? (String)) ?: "取消置顶"
        set(value) { values["messageActionUnpin"] = value }
    var messageActionCopy: String
        get() = (values["messageActionCopy"] as? (String)) ?: "复制"
        set(value) { values["messageActionCopy"] = value }
    var messageActionPreview: String
        get() = (values["messageActionPreview"] as? (String)) ?: "预览"
        set(value) { values["messageActionPreview"] = value }
    var messageActionSave: String
        get() = (values["messageActionSave"] as? (String)) ?: "保存"
        set(value) { values["messageActionSave"] = value }
    var messageActionEdit: String
        get() = (values["messageActionEdit"] as? (String)) ?: "编辑"
        set(value) { values["messageActionEdit"] = value }
    var messageActionDelete: String
        get() = (values["messageActionDelete"] as? (String)) ?: "删除"
        set(value) { values["messageActionDelete"] = value }

    var workspaceFrameLoading: String
        get() = (values["workspaceFrameLoading"] as? (String)) ?: "正在加载"
        set(value) { values["workspaceFrameLoading"] = value }

    var workspaceFrameEmpty: String
        get() = (values["workspaceFrameEmpty"] as? (String)) ?: "暂无内容"
        set(value) { values["workspaceFrameEmpty"] = value }

    var workspaceFrameFailure: String
        get() = (values["workspaceFrameFailure"] as? (String)) ?: "加载失败"
        set(value) { values["workspaceFrameFailure"] = value }

    var workspaceFrameRetry: String
        get() = (values["workspaceFrameRetry"] as? (String)) ?: "重试"
        set(value) { values["workspaceFrameRetry"] = value }

    var conversationWorkspaceListEmpty: String
        get() = (values["conversationWorkspaceListEmpty"] as? (String)) ?: "暂无会话"
        set(value) { values["conversationWorkspaceListEmpty"] = value }

    var conversationWorkspaceChatEmpty: String
        get() = (values["conversationWorkspaceChatEmpty"] as? (String)) ?: "选择一个会话开始聊天"
        set(value) { values["conversationWorkspaceChatEmpty"] = value }

    var conversationWorkspaceDetailEmpty: String
        get() = (values["conversationWorkspaceDetailEmpty"] as? (String)) ?: "暂无详情"
        set(value) { values["conversationWorkspaceDetailEmpty"] = value }

    var conversationWorkspaceListFailure: String
        get() = (values["conversationWorkspaceListFailure"] as? (String)) ?: "会话列表加载失败"
        set(value) { values["conversationWorkspaceListFailure"] = value }

    var conversationWorkspaceChatFailure: String
        get() = (values["conversationWorkspaceChatFailure"] as? (String)) ?: "消息加载失败"
        set(value) { values["conversationWorkspaceChatFailure"] = value }

    var conversationWorkspaceDetailFailure: String
        get() = (values["conversationWorkspaceDetailFailure"] as? (String)) ?: "详情加载失败"
        set(value) { values["conversationWorkspaceDetailFailure"] = value }

    var conversationWorkspaceListLoading: String
        get() = (values["conversationWorkspaceListLoading"] as? (String)) ?: "正在加载会话列表"
        set(value) { values["conversationWorkspaceListLoading"] = value }

    var conversationWorkspaceChatLoading: String
        get() = (values["conversationWorkspaceChatLoading"] as? (String)) ?: "正在加载消息"
        set(value) { values["conversationWorkspaceChatLoading"] = value }

    var conversationWorkspaceDetailLoading: String
        get() = (values["conversationWorkspaceDetailLoading"] as? (String)) ?: "正在加载详情"
        set(value) { values["conversationWorkspaceDetailLoading"] = value }

    var searchDateRangeFilterCustom: String
        get() = (values["searchDateRangeFilterCustom"] as? (String)) ?: "自定义"
        set(value) { values["searchDateRangeFilterCustom"] = value }

    var searchDateRangeFilterFrom: String
        get() = (values["searchDateRangeFilterFrom"] as? (String)) ?: "起始日期"
        set(value) { values["searchDateRangeFilterFrom"] = value }

    var searchDateRangeFilterTo: String
        get() = (values["searchDateRangeFilterTo"] as? (String)) ?: "结束日期"
        set(value) { values["searchDateRangeFilterTo"] = value }

    var searchDateRangeFilterUnlimited: String
        get() = (values["searchDateRangeFilterUnlimited"] as? (String)) ?: "不限时间"
        set(value) { values["searchDateRangeFilterUnlimited"] = value }

    var searchDateRangeFilterInvalid: String
        get() = (values["searchDateRangeFilterInvalid"] as? (String)) ?: "起始日期不能晚于结束日期"
        set(value) { values["searchDateRangeFilterInvalid"] = value }

    var unknownUserPlaceholderUnknown: String
        get() = (values["unknownUserPlaceholderUnknown"] as? (String)) ?: "未知用户"
        set(value) { values["unknownUserPlaceholderUnknown"] = value }

    var unknownUserPlaceholderDeactivated: String
        get() = (values["unknownUserPlaceholderDeactivated"] as? (String)) ?: "该账号已注销"
        set(value) { values["unknownUserPlaceholderDeactivated"] = value }

    var unknownUserPlaceholderBlocked: String
        get() = (values["unknownUserPlaceholderBlocked"] as? (String)) ?: "该账号已被屏蔽"
        set(value) { values["unknownUserPlaceholderBlocked"] = value }

    var unknownUserPlaceholderUnreachable: String
        get() = (values["unknownUserPlaceholderUnreachable"] as? (String)) ?: "暂时无法联系该账号"
        set(value) { values["unknownUserPlaceholderUnreachable"] = value }

    var unknownUserPlaceholderId: String
        get() = (values["unknownUserPlaceholderId"] as? (String)) ?: "ID"
        set(value) { values["unknownUserPlaceholderId"] = value }

    var unknownMessageHint: String
        get() = (values["unknownMessageHint"] as? (String)) ?: "当前版本无法显示这条消息"
        set(value) { values["unknownMessageHint"] = value }

    var unknownMessageUnsupported: String
        get() = (values["unknownMessageUnsupported"] as? (String)) ?: "不支持的消息类型"
        set(value) { values["unknownMessageUnsupported"] = value }

    var unknownMessageDiagnostic: String
        get() = (values["unknownMessageDiagnostic"] as? (String)) ?: "消息类型"
        set(value) { values["unknownMessageDiagnostic"] = value }

    var newFriendRequestsEmpty: String
        get() = (values["newFriendRequestsEmpty"] as? (String)) ?: "暂无新的好友申请"
        set(value) { values["newFriendRequestsEmpty"] = value }

    var newFriendRequestsAccept: String
        get() = (values["newFriendRequestsAccept"] as? (String)) ?: "接受"
        set(value) { values["newFriendRequestsAccept"] = value }

    var newFriendRequestsDecline: String
        get() = (values["newFriendRequestsDecline"] as? (String)) ?: "拒绝"
        set(value) { values["newFriendRequestsDecline"] = value }

    var newFriendRequestsPending: String
        get() = (values["newFriendRequestsPending"] as? (String)) ?: "等待验证"
        set(value) { values["newFriendRequestsPending"] = value }

    var newFriendRequestsWithdraw: String
        get() = (values["newFriendRequestsWithdraw"] as? (String)) ?: "撤回"
        set(value) { values["newFriendRequestsWithdraw"] = value }

    var messageListEmpty: String
        get() = (values["messageListEmpty"] as? (String)) ?: "暂无消息"
        set(value) { values["messageListEmpty"] = value }

    var messageListLoadOlder: String
        get() = (values["messageListLoadOlder"] as? (String)) ?: "加载更早消息"
        set(value) { values["messageListLoadOlder"] = value }

    var messageRecalledSelf: String
        get() = (values["messageRecalledSelf"] as? (String)) ?: "你撤回了一条消息"
        set(value) { values["messageRecalledSelf"] = value }

    var messageRecalledPeer: String
        get() = (values["messageRecalledPeer"] as? (String)) ?: "对方撤回了一条消息"
        set(value) { values["messageRecalledPeer"] = value }

    var messageRecalledGroupOther: (String) -> String
        get() = (values["messageRecalledGroupOther"] as? ((String) -> String)) ?: { "$it 撤回了一条消息" }
        set(value) { values["messageRecalledGroupOther"] = value }

    var messageQuoteLabel: (String, String) -> String
        get() = (values["messageQuoteLabel"] as? ((String, String) -> String))
            ?: { name, summary -> if (name.isEmpty()) "引用：$summary" else "引用 $name：$summary" }
        set(value) { values["messageQuoteLabel"] = value }

    var jumpedToMessage: (String, String) -> String
        get() = (values["jumpedToMessage"] as? ((String, String) -> String))
            ?: { name, summary -> "已跳转到 $name 的消息：$summary" }
        set(value) { values["jumpedToMessage"] = value }

    var previewMessage: String
        get() = (values["previewMessage"] as? (String)) ?: "[消息]"
        set(value) { values["previewMessage"] = value }

    var previewRichText: String
        get() = (values["previewRichText"] as? (String)) ?: "[富文本]"
        set(value) { values["previewRichText"] = value }

    var previewGif: String
        get() = (values["previewGif"] as? (String)) ?: "[动图]"
        set(value) { values["previewGif"] = value }

    var previewImage: String
        get() = (values["previewImage"] as? (String)) ?: "[图片]"
        set(value) { values["previewImage"] = value }

    var previewImageNamed: (String) -> String
        get() = (values["previewImageNamed"] as? ((String) -> String)) ?: { "[图片] $it" }
        set(value) { values["previewImageNamed"] = value }

    var previewVideo: String
        get() = (values["previewVideo"] as? (String)) ?: "[视频]"
        set(value) { values["previewVideo"] = value }

    var previewAudio: String
        get() = (values["previewAudio"] as? (String)) ?: "[语音]"
        set(value) { values["previewAudio"] = value }

    var previewFile: String
        get() = (values["previewFile"] as? (String)) ?: "[文件]"
        set(value) { values["previewFile"] = value }

    var previewFileNamed: (String) -> String
        get() = (values["previewFileNamed"] as? ((String) -> String)) ?: { "[文件] $it" }
        set(value) { values["previewFileNamed"] = value }

    var previewLocation: String
        get() = (values["previewLocation"] as? (String)) ?: "[位置]"
        set(value) { values["previewLocation"] = value }

    var previewLocationNamed: (String) -> String
        get() = (values["previewLocationNamed"] as? ((String) -> String)) ?: { "[位置] $it" }
        set(value) { values["previewLocationNamed"] = value }

    var previewCard: String
        get() = (values["previewCard"] as? (String)) ?: "[名片]"
        set(value) { values["previewCard"] = value }

    var previewCardNamed: (String) -> String
        get() = (values["previewCardNamed"] as? ((String) -> String)) ?: { "[名片] $it" }
        set(value) { values["previewCardNamed"] = value }

    var previewSticker: String
        get() = (values["previewSticker"] as? (String)) ?: "[贴纸]"
        set(value) { values["previewSticker"] = value }

    var previewEmoji: String
        get() = (values["previewEmoji"] as? (String)) ?: "[表情]"
        set(value) { values["previewEmoji"] = value }

    var previewQuote: String
        get() = (values["previewQuote"] as? (String)) ?: "[引用]"
        set(value) { values["previewQuote"] = value }

    var previewLink: String
        get() = (values["previewLink"] as? (String)) ?: "[链接]"
        set(value) { values["previewLink"] = value }

    var previewForward: String
        get() = (values["previewForward"] as? (String)) ?: "[转发]"
        set(value) { values["previewForward"] = value }

    var previewForwardCount: (Int) -> String
        get() = (values["previewForwardCount"] as? ((Int) -> String)) ?: { "[转发] $it 条消息" }
        set(value) { values["previewForwardCount"] = value }

    var previewThread: String
        get() = (values["previewThread"] as? (String)) ?: "[话题]"
        set(value) { values["previewThread"] = value }

    var previewMiniProgram: String
        get() = (values["previewMiniProgram"] as? (String)) ?: "[小程序]"
        set(value) { values["previewMiniProgram"] = value }

    var previewImageGroup: String
        get() = (values["previewImageGroup"] as? (String)) ?: "[多图]"
        set(value) { values["previewImageGroup"] = value }

    var previewImageGroupCount: (Int) -> String
        get() = (values["previewImageGroupCount"] as? ((Int) -> String)) ?: { "[多图] $it 张" }
        set(value) { values["previewImageGroupCount"] = value }

    var previewSystem: String
        get() = (values["previewSystem"] as? (String)) ?: "[系统消息]"
        set(value) { values["previewSystem"] = value }

    var previewNotification: String
        get() = (values["previewNotification"] as? (String)) ?: "[通知]"
        set(value) { values["previewNotification"] = value }

    var previewVote: String
        get() = (values["previewVote"] as? (String)) ?: "[投票]"
        set(value) { values["previewVote"] = value }

    var previewTask: String
        get() = (values["previewTask"] as? (String)) ?: "[任务]"
        set(value) { values["previewTask"] = value }

    var previewSchedule: String
        get() = (values["previewSchedule"] as? (String)) ?: "[日程]"
        set(value) { values["previewSchedule"] = value }

    var previewAnnouncement: String
        get() = (values["previewAnnouncement"] as? (String)) ?: "[公告]"
        set(value) { values["previewAnnouncement"] = value }

    var previewCustom: String
        get() = (values["previewCustom"] as? (String)) ?: "[自定义]"
        set(value) { values["previewCustom"] = value }

    var previewPlaceholder: String
        get() = (values["previewPlaceholder"] as? (String)) ?: "[占位]"
        set(value) { values["previewPlaceholder"] = value }

    var previewUnknown: String
        get() = (values["previewUnknown"] as? (String)) ?: "[未知]"
        set(value) { values["previewUnknown"] = value }

    var conversationHeaderIdentityLabel: (String, String) -> String
        get() = (values["conversationHeaderIdentityLabel"] as? ((String, String) -> String)) ?: { title, action -> "$title，$action" }
        set(value) { values["conversationHeaderIdentityLabel"] = value }

    var startConversationDialogSearchPlaceholder: String
        get() = (values["startConversationDialogSearchPlaceholder"] as? (String)) ?: "搜索联系人"
        set(value) { values["startConversationDialogSearchPlaceholder"] = value }

    var groupDetailFallbackTitle: String
        get() = (values["groupDetailFallbackTitle"] as? (String)) ?: "群聊"
        set(value) { values["groupDetailFallbackTitle"] = value }

    var groupDetailUnavailable: String
        get() = (values["groupDetailUnavailable"] as? (String)) ?: "群信息不可用"
        set(value) { values["groupDetailUnavailable"] = value }

    var groupDetailUnavailableHint: String
        get() = (values["groupDetailUnavailableHint"] as? (String)) ?: "未连接服务时无法加载群详情。"
        set(value) { values["groupDetailUnavailableHint"] = value }

    var groupDetailNotSet: String
        get() = (values["groupDetailNotSet"] as? (String)) ?: "未设置"
        set(value) { values["groupDetailNotSet"] = value }

    var groupDetailSettingUnavailable: String
        get() = (values["groupDetailSettingUnavailable"] as? (String)) ?: "暂时无法读取"
        set(value) { values["groupDetailSettingUnavailable"] = value }

    var groupDetailAnnouncement: String
        get() = (values["groupDetailAnnouncement"] as? (String)) ?: "群公告"
        set(value) { values["groupDetailAnnouncement"] = value }

    var groupDetailMembers: String
        get() = (values["groupDetailMembers"] as? (String)) ?: "群成员"
        set(value) { values["groupDetailMembers"] = value }

    var groupDetailInfoSection: String
        get() = (values["groupDetailInfoSection"] as? (String)) ?: "群信息"
        set(value) { values["groupDetailInfoSection"] = value }

    var groupDetailMyInGroupSection: String
        get() = (values["groupDetailMyInGroupSection"] as? (String)) ?: "我在本群"
        set(value) { values["groupDetailMyInGroupSection"] = value }

    var groupDetailManageSection: String
        get() = (values["groupDetailManageSection"] as? (String)) ?: "群管理"
        set(value) { values["groupDetailManageSection"] = value }

    var groupDetailPermsSection: String
        get() = (values["groupDetailPermsSection"] as? (String)) ?: "群权限"
        set(value) { values["groupDetailPermsSection"] = value }

    var groupDetailName: String
        get() = (values["groupDetailName"] as? (String)) ?: "群聊名称"
        set(value) { values["groupDetailName"] = value }

    var groupDetailMyNickname: String
        get() = (values["groupDetailMyNickname"] as? (String)) ?: "我的群昵称"
        set(value) { values["groupDetailMyNickname"] = value }

    var groupDetailMuteNotif: String
        get() = (values["groupDetailMuteNotif"] as? (String)) ?: "消息免打扰"
        set(value) { values["groupDetailMuteNotif"] = value }

    var groupDetailPinGroup: String
        get() = (values["groupDetailPinGroup"] as? (String)) ?: "置顶该群"
        set(value) { values["groupDetailPinGroup"] = value }

    var groupDetailJoinMode: String
        get() = (values["groupDetailJoinMode"] as? (String)) ?: "进群方式"
        set(value) { values["groupDetailJoinMode"] = value }

    var groupDetailJoinRequests: String
        get() = (values["groupDetailJoinRequests"] as? (String)) ?: "入群申请"
        set(value) { values["groupDetailJoinRequests"] = value }

    var groupDetailMuteAll: String
        get() = (values["groupDetailMuteAll"] as? (String)) ?: "全员禁言"
        set(value) { values["groupDetailMuteAll"] = value }

    var groupDetailInviteLink: String
        get() = (values["groupDetailInviteLink"] as? (String)) ?: "群邀请链接"
        set(value) { values["groupDetailInviteLink"] = value }

    var groupDetailOnlyAdminAtAll: String
        get() = (values["groupDetailOnlyAdminAtAll"] as? (String)) ?: "仅管理员可@全体成员"
        set(value) { values["groupDetailOnlyAdminAtAll"] = value }

    var groupDetailOnlyAdminPin: String
        get() = (values["groupDetailOnlyAdminPin"] as? (String)) ?: "仅管理员可置顶消息"
        set(value) { values["groupDetailOnlyAdminPin"] = value }

    var groupDetailShareCard: String
        get() = (values["groupDetailShareCard"] as? (String)) ?: "允许分享群名片"
        set(value) { values["groupDetailShareCard"] = value }

    var groupDetailJoinOpen: String
        get() = (values["groupDetailJoinOpen"] as? (String)) ?: "允许任何人加入"
        set(value) { values["groupDetailJoinOpen"] = value }

    var groupDetailJoinApproval: String
        get() = (values["groupDetailJoinApproval"] as? (String)) ?: "需管理员审批"
        set(value) { values["groupDetailJoinApproval"] = value }

    var groupDetailJoinInvite: String
        get() = (values["groupDetailJoinInvite"] as? (String)) ?: "仅邀请加入"
        set(value) { values["groupDetailJoinInvite"] = value }

    var groupDetailLeave: String
        get() = (values["groupDetailLeave"] as? (String)) ?: "退出群聊"
        set(value) { values["groupDetailLeave"] = value }

    var groupDetailDissolve: String
        get() = (values["groupDetailDissolve"] as? (String)) ?: "解散群聊"
        set(value) { values["groupDetailDissolve"] = value }

    var groupDetailEditName: String
        get() = (values["groupDetailEditName"] as? (String)) ?: "群聊名称"
        set(value) { values["groupDetailEditName"] = value }

    var groupDetailEditAnnouncement: String
        get() = (values["groupDetailEditAnnouncement"] as? (String)) ?: "群公告"
        set(value) { values["groupDetailEditAnnouncement"] = value }

    var groupDetailNicknamePlaceholder: String
        get() = (values["groupDetailNicknamePlaceholder"] as? (String)) ?: "输入群昵称"
        set(value) { values["groupDetailNicknamePlaceholder"] = value }

    var groupDetailSave: String
        get() = (values["groupDetailSave"] as? (String)) ?: "保存"
        set(value) { values["groupDetailSave"] = value }

    var groupDetailMemberManage: String
        get() = (values["groupDetailMemberManage"] as? (String)) ?: "成员管理"
        set(value) { values["groupDetailMemberManage"] = value }

    var groupDetailSetAdmin: String
        get() = (values["groupDetailSetAdmin"] as? (String)) ?: "设为管理员"
        set(value) { values["groupDetailSetAdmin"] = value }

    var groupDetailUnsetAdmin: String
        get() = (values["groupDetailUnsetAdmin"] as? (String)) ?: "取消管理员"
        set(value) { values["groupDetailUnsetAdmin"] = value }

    var groupDetailMute: String
        get() = (values["groupDetailMute"] as? (String)) ?: "禁言 1 天"
        set(value) { values["groupDetailMute"] = value }

    var groupDetailUnmute: String
        get() = (values["groupDetailUnmute"] as? (String)) ?: "取消禁言"
        set(value) { values["groupDetailUnmute"] = value }

    var groupDetailTransferOwner: String
        get() = (values["groupDetailTransferOwner"] as? (String)) ?: "转让群主"
        set(value) { values["groupDetailTransferOwner"] = value }

    var groupDetailRemoveMember: String
        get() = (values["groupDetailRemoveMember"] as? (String)) ?: "移出群聊"
        set(value) { values["groupDetailRemoveMember"] = value }

    var groupDetailTransferConfirmPrefix: String
        get() = (values["groupDetailTransferConfirmPrefix"] as? (String)) ?: "确定把群主转让给「"
        set(value) { values["groupDetailTransferConfirmPrefix"] = value }

    var groupDetailTransferConfirmSuffix: String
        get() = (values["groupDetailTransferConfirmSuffix"] as? (String)) ?: "」吗？转让后你将变为普通成员，此操作不可撤销。"
        set(value) { values["groupDetailTransferConfirmSuffix"] = value }

    var groupDetailConfirmTransfer: String
        get() = (values["groupDetailConfirmTransfer"] as? (String)) ?: "确认转让"
        set(value) { values["groupDetailConfirmTransfer"] = value }

    var groupDetailInvite: String
        get() = (values["groupDetailInvite"] as? (String)) ?: "邀请"
        set(value) { values["groupDetailInvite"] = value }

    var groupDetailInviteSearchPlaceholder: String
        get() = (values["groupDetailInviteSearchPlaceholder"] as? (String)) ?: "选择要邀请的联系人"
        set(value) { values["groupDetailInviteSearchPlaceholder"] = value }

    var groupDetailLoading: String
        get() = (values["groupDetailLoading"] as? (String)) ?: "加载中…"
        set(value) { values["groupDetailLoading"] = value }

    var groupDetailNoRequests: String
        get() = (values["groupDetailNoRequests"] as? (String)) ?: "暂无待处理的入群申请"
        set(value) { values["groupDetailNoRequests"] = value }

    var groupDetailApprove: String
        get() = (values["groupDetailApprove"] as? (String)) ?: "通过"
        set(value) { values["groupDetailApprove"] = value }

    var groupDetailInviteLinkHint: String
        get() = (values["groupDetailInviteLinkHint"] as? (String)) ?: "分享邀请码，好友可凭码加入本群。"
        set(value) { values["groupDetailInviteLinkHint"] = value }

    var groupDetailGenerating: String
        get() = (values["groupDetailGenerating"] as? (String)) ?: "生成中…"
        set(value) { values["groupDetailGenerating"] = value }

    var groupDetailInviteCodeLabel: String
        get() = (values["groupDetailInviteCodeLabel"] as? (String)) ?: "邀请码"
        set(value) { values["groupDetailInviteCodeLabel"] = value }

    var groupDetailCopyCode: String
        get() = (values["groupDetailCopyCode"] as? (String)) ?: "复制"
        set(value) { values["groupDetailCopyCode"] = value }

    var groupDetailCannotGenerate: String
        get() = (values["groupDetailCannotGenerate"] as? (String)) ?: "暂时无法获取邀请链接。"
        set(value) { values["groupDetailCannotGenerate"] = value }

    var groupDetailLeaveConfirmText: String
        get() = (values["groupDetailLeaveConfirmText"] as? (String)) ?: "退出后将不再接收该群消息。"
        set(value) { values["groupDetailLeaveConfirmText"] = value }

    var groupDetailDissolveConfirmText: String
        get() = (values["groupDetailDissolveConfirmText"] as? (String)) ?: "解散后所有成员将被移出，且不可恢复。"
        set(value) { values["groupDetailDissolveConfirmText"] = value }

    var momentAudienceSheetPublic: String
        get() = (values["momentAudienceSheetPublic"] as? (String)) ?: "公开"
        set(value) { values["momentAudienceSheetPublic"] = value }

    var momentAudienceSheetPublicHint: String
        get() = (values["momentAudienceSheetPublicHint"] as? (String)) ?: "所有人可见"
        set(value) { values["momentAudienceSheetPublicHint"] = value }

    var momentAudienceSheetFriends: String
        get() = (values["momentAudienceSheetFriends"] as? (String)) ?: "朋友可见"
        set(value) { values["momentAudienceSheetFriends"] = value }

    var momentAudienceSheetFriendsHint: String
        get() = (values["momentAudienceSheetFriendsHint"] as? (String)) ?: "你的好友可见"
        set(value) { values["momentAudienceSheetFriendsHint"] = value }

    var momentAudienceSheetPrivate: String
        get() = (values["momentAudienceSheetPrivate"] as? (String)) ?: "私密"
        set(value) { values["momentAudienceSheetPrivate"] = value }

    var momentAudienceSheetPrivateHint: String
        get() = (values["momentAudienceSheetPrivateHint"] as? (String)) ?: "仅自己可见"
        set(value) { values["momentAudienceSheetPrivateHint"] = value }

    var momentAudienceSheetInclude: String
        get() = (values["momentAudienceSheetInclude"] as? (String)) ?: "部分可见"
        set(value) { values["momentAudienceSheetInclude"] = value }

    var momentAudienceSheetIncludeHint: String
        get() = (values["momentAudienceSheetIncludeHint"] as? (String)) ?: "仅选中的朋友可见"
        set(value) { values["momentAudienceSheetIncludeHint"] = value }

    var momentAudienceSheetExclude: String
        get() = (values["momentAudienceSheetExclude"] as? (String)) ?: "不给谁看"
        set(value) { values["momentAudienceSheetExclude"] = value }

    var momentAudienceSheetExcludeHint: String
        get() = (values["momentAudienceSheetExcludeHint"] as? (String)) ?: "选中的朋友看不到"
        set(value) { values["momentAudienceSheetExcludeHint"] = value }

    var momentAudienceSheetPick: String
        get() = (values["momentAudienceSheetPick"] as? (String)) ?: "选择朋友"
        set(value) { values["momentAudienceSheetPick"] = value }

    var momentAudienceSheetDone: String
        get() = (values["momentAudienceSheetDone"] as? (String)) ?: "完成"
        set(value) { values["momentAudienceSheetDone"] = value }

    var momentAudienceSheetSelected: (Int) -> String
        get() = (values["momentAudienceSheetSelected"] as? ((Int) -> String)) ?: { "已选 $it 人" }
        set(value) { values["momentAudienceSheetSelected"] = value }

    var momentsVisibilityRuleListHideFromTitle: String
        get() = (values["momentsVisibilityRuleListHideFromTitle"] as? (String)) ?: "不让他看我的朋友圈"
        set(value) { values["momentsVisibilityRuleListHideFromTitle"] = value }

    var momentsVisibilityRuleListHideFromHint: String
        get() = (values["momentsVisibilityRuleListHideFromHint"] as? (String)) ?: "名单中的人看不到你发的内容"
        set(value) { values["momentsVisibilityRuleListHideFromHint"] = value }

    var momentsVisibilityRuleListMuteTitle: String
        get() = (values["momentsVisibilityRuleListMuteTitle"] as? (String)) ?: "不看他的朋友圈"
        set(value) { values["momentsVisibilityRuleListMuteTitle"] = value }

    var momentsVisibilityRuleListMuteHint: String
        get() = (values["momentsVisibilityRuleListMuteHint"] as? (String)) ?: "你不会看到名单中的人发的内容"
        set(value) { values["momentsVisibilityRuleListMuteHint"] = value }

    var momentsVisibilityRuleListEmpty: String
        get() = (values["momentsVisibilityRuleListEmpty"] as? (String)) ?: "名单为空"
        set(value) { values["momentsVisibilityRuleListEmpty"] = value }

    var momentsVisibilityRuleListRemove: String
        get() = (values["momentsVisibilityRuleListRemove"] as? (String)) ?: "移出"
        set(value) { values["momentsVisibilityRuleListRemove"] = value }

    var momentsVisibilityRuleListAdd: String
        get() = (values["momentsVisibilityRuleListAdd"] as? (String)) ?: "添加成员"
        set(value) { values["momentsVisibilityRuleListAdd"] = value }

    var contactMatchListAdd: String
        get() = (values["contactMatchListAdd"] as? (String)) ?: "添加"
        set(value) { values["contactMatchListAdd"] = value }

    var contactMatchListEmpty: String
        get() = (values["contactMatchListEmpty"] as? (String)) ?: "通讯录里还没有已注册的联系人"
        set(value) { values["contactMatchListEmpty"] = value }

    var announcementReadBarConfirmRead: String
        get() = (values["announcementReadBarConfirmRead"] as? (String)) ?: "已读"
        set(value) { values["announcementReadBarConfirmRead"] = value }

    var announcementReadBarViewUnread: String
        get() = (values["announcementReadBarViewUnread"] as? (String)) ?: "查看未读"
        set(value) { values["announcementReadBarViewUnread"] = value }

    var announcementReadBarReadCount: (Int, Int) -> String
        get() = (values["announcementReadBarReadCount"] as? ((Int, Int) -> String)) ?: { read, total -> "$read/$total 人已读" }
        set(value) { values["announcementReadBarReadCount"] = value }

    var contactDetailVoice: String
        get() = (values["contactDetailVoice"] as? (String)) ?: "语音通话"
        set(value) { values["contactDetailVoice"] = value }

    var contactDetailVideo: String
        get() = (values["contactDetailVideo"] as? (String)) ?: "视频通话"
        set(value) { values["contactDetailVideo"] = value }

    var contactDetailInfoSection: String
        get() = (values["contactDetailInfoSection"] as? (String)) ?: "资料"
        set(value) { values["contactDetailInfoSection"] = value }

    var contactDetailFlareId: String
        get() = (values["contactDetailFlareId"] as? (String)) ?: "Flare ID"
        set(value) { values["contactDetailFlareId"] = value }

    var contactDetailRemark: String
        get() = (values["contactDetailRemark"] as? (String)) ?: "备注"
        set(value) { values["contactDetailRemark"] = value }

    var contactDetailDescription: String
        get() = (values["contactDetailDescription"] as? (String)) ?: "描述"
        set(value) { values["contactDetailDescription"] = value }

    var contactDetailStar: String
        get() = (values["contactDetailStar"] as? (String)) ?: "星标好友"
        set(value) { values["contactDetailStar"] = value }

    var contactDetailNotSet: String
        get() = (values["contactDetailNotSet"] as? (String)) ?: "未设置"
        set(value) { values["contactDetailNotSet"] = value }

    var contactDetailBlock: String
        get() = (values["contactDetailBlock"] as? (String)) ?: "加入黑名单"
        set(value) { values["contactDetailBlock"] = value }

    var contactDetailRemove: String
        get() = (values["contactDetailRemove"] as? (String)) ?: "删除好友"
        set(value) { values["contactDetailRemove"] = value }

    var conversationDetailsMessages: String
        get() = (values["conversationDetailsMessages"] as? (String)) ?: "消息"
        set(value) { values["conversationDetailsMessages"] = value }

    var conversationDetailsMute: String
        get() = (values["conversationDetailsMute"] as? (String)) ?: "免打扰"
        set(value) { values["conversationDetailsMute"] = value }

    var conversationDetailsPin: String
        get() = (values["conversationDetailsPin"] as? (String)) ?: "置顶会话"
        set(value) { values["conversationDetailsPin"] = value }

    var conversationDetailsMarkRead: String
        get() = (values["conversationDetailsMarkRead"] as? (String)) ?: "标为已读"
        set(value) { values["conversationDetailsMarkRead"] = value }

    var conversationDetailsMarkUnread: String
        get() = (values["conversationDetailsMarkUnread"] as? (String)) ?: "标为未读"
        set(value) { values["conversationDetailsMarkUnread"] = value }

    var conversationDetailsSync: String
        get() = (values["conversationDetailsSync"] as? (String)) ?: "同步会话"
        set(value) { values["conversationDetailsSync"] = value }

    var conversationDetailsArchive: String
        get() = (values["conversationDetailsArchive"] as? (String)) ?: "归档会话"
        set(value) { values["conversationDetailsArchive"] = value }

    var conversationDetailsUnarchive: String
        get() = (values["conversationDetailsUnarchive"] as? (String)) ?: "取消归档"
        set(value) { values["conversationDetailsUnarchive"] = value }

    var conversationDetailsClearHistory: String
        get() = (values["conversationDetailsClearHistory"] as? (String)) ?: "清空聊天记录"
        set(value) { values["conversationDetailsClearHistory"] = value }

    var conversationDetailsDelete: String
        get() = (values["conversationDetailsDelete"] as? (String)) ?: "删除会话"
        set(value) { values["conversationDetailsDelete"] = value }

    var profileEditorNickname: String
        get() = (values["profileEditorNickname"] as? (String)) ?: "昵称"
        set(value) { values["profileEditorNickname"] = value }

    var profileEditorNicknamePlaceholder: String
        get() = (values["profileEditorNicknamePlaceholder"] as? (String)) ?: "昵称"
        set(value) { values["profileEditorNicknamePlaceholder"] = value }

    var profileEditorBio: String
        get() = (values["profileEditorBio"] as? (String)) ?: "个性签名"
        set(value) { values["profileEditorBio"] = value }

    var profileEditorBioPlaceholder: String
        get() = (values["profileEditorBioPlaceholder"] as? (String)) ?: "介绍一下自己吧"
        set(value) { values["profileEditorBioPlaceholder"] = value }

    var profileEditorSave: String
        get() = (values["profileEditorSave"] as? (String)) ?: "保存"
        set(value) { values["profileEditorSave"] = value }

    var connectionConnecting: String
        get() = (values["connectionConnecting"] as? (String)) ?: "正在连接…"
        set(value) { values["connectionConnecting"] = value }

    var connectionReconnecting: String
        get() = (values["connectionReconnecting"] as? (String)) ?: "连接已断开，正在重连…"
        set(value) { values["connectionReconnecting"] = value }

    var connectionOffline: String
        get() = (values["connectionOffline"] as? (String)) ?: "网络不可用，恢复后会自动重连"
        set(value) { values["connectionOffline"] = value }

    var connectionDisconnected: String
        get() = (values["connectionDisconnected"] as? (String)) ?: "连接已断开"
        set(value) { values["connectionDisconnected"] = value }

    var connectionDisconnectedReason: (String) -> String
        get() = (values["connectionDisconnectedReason"] as? ((String) -> String)) ?: { "连接已断开：$it" }
        set(value) { values["connectionDisconnectedReason"] = value }

    var connectionKicked: String
        get() = (values["connectionKicked"] as? (String)) ?: "账号已在其他设备登录"
        set(value) { values["connectionKicked"] = value }

    var connectionExpired: String
        get() = (values["connectionExpired"] as? (String)) ?: "登录已过期"
        set(value) { values["connectionExpired"] = value }

    var connectionReconnect: String
        get() = (values["connectionReconnect"] as? (String)) ?: "重新连接"
        set(value) { values["connectionReconnect"] = value }

    var connectionSignIn: String
        get() = (values["connectionSignIn"] as? (String)) ?: "重新登录"
        set(value) { values["connectionSignIn"] = value }

    var conversationHeaderAddActions: String
        get() = (values["conversationHeaderAddActions"] as? (String)) ?: "添加会话操作"
        set(value) { values["conversationHeaderAddActions"] = value }

    var conversationHeaderMoreActions: String
        get() = (values["conversationHeaderMoreActions"] as? (String)) ?: "更多会话操作"
        set(value) { values["conversationHeaderMoreActions"] = value }

    var groupDetailMembersTitle: (Int) -> String
        get() = (values["groupDetailMembersTitle"] as? ((Int) -> String)) ?: { "群成员（$it）" }
        set(value) { values["groupDetailMembersTitle"] = value }

    var groupDetailSearchMembers: String
        get() = (values["groupDetailSearchMembers"] as? (String)) ?: "搜索群成员"
        set(value) { values["groupDetailSearchMembers"] = value }

    var groupDetailNoMatchingMembers: String
        get() = (values["groupDetailNoMatchingMembers"] as? (String)) ?: "没有匹配的群成员"
        set(value) { values["groupDetailNoMatchingMembers"] = value }

    var conversationHeaderSearch: String
        get() = (values["conversationHeaderSearch"] as? (String)) ?: "搜索消息"
        set(value) { values["conversationHeaderSearch"] = value }

    var conversationHeaderAudioCall: String
        get() = (values["conversationHeaderAudioCall"] as? (String)) ?: "发起语音通话"
        set(value) { values["conversationHeaderAudioCall"] = value }

    var conversationHeaderVideoCall: String
        get() = (values["conversationHeaderVideoCall"] as? (String)) ?: "发起视频通话"
        set(value) { values["conversationHeaderVideoCall"] = value }

    var conversationHeaderAddMember: String
        get() = (values["conversationHeaderAddMember"] as? (String)) ?: "添加成员"
        set(value) { values["conversationHeaderAddMember"] = value }

    var conversationHeaderShare: String
        get() = (values["conversationHeaderShare"] as? (String)) ?: "分享会话"
        set(value) { values["conversationHeaderShare"] = value }

    var conversationHeaderDetails: String
        get() = (values["conversationHeaderDetails"] as? (String)) ?: "会话详情"
        set(value) { values["conversationHeaderDetails"] = value }

    var conversationHeaderMemberCount: (Int) -> String
        get() = (values["conversationHeaderMemberCount"] as? ((Int) -> String)) ?: { "$it 位成员" }
        set(value) { values["conversationHeaderMemberCount"] = value }

    var presenceOnline: String
        get() = (values["presenceOnline"] as? (String)) ?: "在线"
        set(value) { values["presenceOnline"] = value }

    var presenceOffline: String
        get() = (values["presenceOffline"] as? (String)) ?: "离线"
        set(value) { values["presenceOffline"] = value }

    var presenceBusy: String
        get() = (values["presenceBusy"] as? (String)) ?: "忙碌"
        set(value) { values["presenceBusy"] = value }

    var presenceAway: String
        get() = (values["presenceAway"] as? (String)) ?: "离开"
        set(value) { values["presenceAway"] = value }

    var profilePanelEditProfile: (String) -> String
        get() = (values["profilePanelEditProfile"] as? ((String) -> String)) ?: { "$it，编辑资料" }
        set(value) { values["profilePanelEditProfile"] = value }

    var myQrCode: String
        get() = (values["myQrCode"] as? (String)) ?: "我的二维码"
        set(value) { values["myQrCode"] = value }

    var momentReplyTo: String
        get() = (values["momentReplyTo"] as? (String)) ?: "回复"
        set(value) { values["momentReplyTo"] = value }

    var momentReplyToComment: (String, String) -> String
        get() = (values["momentReplyToComment"] as? ((String, String) -> String)) ?: { name, text -> "回复 $name：$text" }
        set(value) { values["momentReplyToComment"] = value }

    var favorites: String
        get() = (values["favorites"] as? (String)) ?: "收藏"
        set(value) { values["favorites"] = value }

    var moments: String
        get() = (values["moments"] as? (String)) ?: "圈子"
        set(value) { values["moments"] = value }

    var settings: String
        get() = (values["settings"] as? (String)) ?: "设置"
        set(value) { values["settings"] = value }

    var themeSystem: String
        get() = (values["themeSystem"] as? (String)) ?: "跟随系统"
        set(value) { values["themeSystem"] = value }

    var themeLight: String
        get() = (values["themeLight"] as? (String)) ?: "浅色"
        set(value) { values["themeLight"] = value }

    var themeDark: String
        get() = (values["themeDark"] as? (String)) ?: "深色"
        set(value) { values["themeDark"] = value }

    var inputReveal: String
        get() = (values["inputReveal"] as? (String)) ?: "显示密码"
        set(value) { values["inputReveal"] = value }

    var inputHide: String
        get() = (values["inputHide"] as? (String)) ?: "隐藏密码"
        set(value) { values["inputHide"] = value }

    var scrollToLatest: String
        get() = (values["scrollToLatest"] as? (String)) ?: "回到最新"
        set(value) { values["scrollToLatest"] = value }

    var navigationChats: String
        get() = (values["navigationChats"] as? (String)) ?: "消息"
        set(value) { values["navigationChats"] = value }

    var navigationContacts: String
        get() = (values["navigationContacts"] as? (String)) ?: "通讯录"
        set(value) { values["navigationContacts"] = value }

    var navigationProfile: String
        get() = (values["navigationProfile"] as? (String)) ?: "我"
        set(value) { values["navigationProfile"] = value }

    var navigationFriends: String
        get() = (values["navigationFriends"] as? (String)) ?: "好友"
        set(value) { values["navigationFriends"] = value }

    var navigationGroups: String
        get() = (values["navigationGroups"] as? (String)) ?: "群聊"
        set(value) { values["navigationGroups"] = value }

    var navigationNewFriends: String
        get() = (values["navigationNewFriends"] as? (String)) ?: "新的朋友"
        set(value) { values["navigationNewFriends"] = value }
}


val LocalFlareStrings = staticCompositionLocalOf { FlareStrings() }

/** 当前生效的组件文案。宿主可用 [LocalFlareStrings] 覆盖。 */
@Composable
@ReadOnlyComposable
fun flareStrings(): FlareStrings = LocalFlareStrings.current
