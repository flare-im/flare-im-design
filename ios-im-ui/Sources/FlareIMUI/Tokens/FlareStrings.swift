import SwiftUI

/// Inline component copy (accessibility labels, status hints, empty states…).
///
/// These strings used to be hard-coded inside view bodies, which left hosts with no way to
/// change the interface language of a cross-platform component kit. They now live in an
/// environment value whose defaults are still Chinese; a host that needs another language
/// overrides once at the root:
///
/// ```swift
/// ContentView().flareStrings(FlareStrings(send: "Send"))
/// ```
///
/// Mirrors `FlareStrings` on Android (`LocalFlareStrings`) and the Flutter/Vue equivalents:
/// same field names, same defaults. Components that already take explicit `FlareXxxLabels`
/// parameters are unaffected — the two coexist, explicit parameters win.
public struct FlareStrings: Sendable {
    // Call
    public var microphone: String
    public var camera: String
    public var flipCamera: String
    public var speaker: String
    public var hangUp: String
    public var muted: String
    public var unmuted: String
    public var on: String
    public var off: String
    public var callWaitingAnswer: String
    public var callCalling: String
    public var callRinging: String
    public var callConnected: String
    public var callReconnecting: String
    public var callFailed: String
    public var callInProgress: String
    // Composer
    public var send: String
    public var cancelReply: String
    // Empty states
    public var noContacts: String
    public var noGroups: String
    public var noResults: String
    public var noContent: String
    public var noConversations: String
    // Generic actions
    public var close: String
    public var delete: String
    public var manage: String
    public var selectAll: String
    public var retry: String
    public var search: String
    public var clearSearch: String
    // Message actions
    public var addReaction: String
    public var readReceipt: String
    public var readTab: @Sendable (Int) -> String
    public var unreadTab: @Sendable (Int) -> String
    public var noReadersYet: String
    public var everyoneHasRead: String
    public var selectedSuffix: String
    public var forwardEach: String
    public var forwardMerged: String
    // Mentions
    public var searchMembers: String
    public var everyone: String
    public var notifyEveryone: String
    public var noMatchingMembers: String
    // Quick phrases
    public var quickPhrases: String
    public var viewAll: @Sendable (Int) -> String
    // Typing / new messages
    public var typing: String
    public var typingOne: @Sendable (String) -> String
    public var typingMany: @Sendable (Int) -> String
    public var newMessages: @Sendable (Int) -> String
    // Profile card / group call
    public var sendMessage: String
    public var voiceCall: String
    public var videoCall: String
    public var groupCall: String
    public var joinedCount: @Sendable (Int, String) -> String
    public var selfSuffix: @Sendable (String) -> String
    // Forward picker
    public var forwardTo: String
    public var searchConversations: String
    public var noMatchingConversations: String
    public var selectedCount: @Sendable (Int) -> String
    // Group announcement
    public var groupAnnouncement: String
    public var collapse: String
    public var expand: String
    // Red packet
    public var packetClaimed: String
    public var packetFinished: String
    public var packetTapToClaim: String
    public var packetBrand: String
    // Commands / translation / QR
    public var commands: String
    public var noMatchingCommands: String
    public var translating: String
    public var translatedBy: @Sendable (String) -> String
    public var translated: String
    public var hideOriginal: String
    public var showOriginal: String
    public var scanToAddMe: String
    // Recording / poll
    public var cancel: String
    public var releaseToCancel: String
    public var createPoll: String
    public var pollQuestionHint: String
    public var pollOptionHint: @Sendable (Int) -> String
    public var removeOption: String
    public var addOption: String
    public var allowMultiple: String
    public var submitPoll: String
    public var chatBackground: String
    // Stepper / calendar
    public var decrease: String
    public var increase: String
    public var previousMonth: String
    public var nextMonth: String
    public var yearMonth: @Sendable (Int, Int) -> String
    // Moments
    public var unlike: String
    public var like: String
    public var comment: String
    public var replyInfix: String
    public var changeCover: String
    public var post: String
    public var momentTextHint: String
    public var addImage: String
    public var pickLocation: String
    public var pickVisibility: String
    public var more: String
    // Voice transcript / emoji & stickers
    public var hideTranscript: String
    public var showTranscript: String
    public var recent: String
    public var searchEmoji: String
    public var noMatchingEmoji: String
    public var emptyStickerPack: String
    public var sticker: String
    // Plus panel
    public var actionImage: String
    public var actionCamera: String
    public var actionFile: String
    public var actionLocation: String
    public var actionCard: String
    public var actionVote: String
    public var actionTask: String
    public var actionSchedule: String
    // Incoming call
    public var incomingVideoCall: String
    public var incomingVoiceCall: String
    public var reject: String
    public var accept: String
    // Generic
    public var back: String
    public var confirm: String
    public var confirmCount: @Sendable (Int) -> String
    public var memberCount: @Sendable (Int) -> String
    public var clear: String
    public var wordCharCount: @Sendable (Int, Int) -> String
    public var changeAvatar: String
    public var qrCode: String
    public var play: String
    // Profile entries
    public var favorites: String
    public var moments: String
    public var settings: String
    // Permission prompt (see `defaultPermissionCopy`)
    public var permissionNoun: @Sendable (FlarePermissionKind) -> String
    public var permissionVerb: @Sendable (FlarePermissionKind) -> String
    public var permissionTitle: @Sendable (String) -> String
    public var permissionFeatureFallback: String
    public var permissionUndeterminedBody: @Sendable (String, String) -> String
    public var permissionDeniedBody: @Sendable (String, String) -> String
    public var permissionRestrictedBody: @Sendable (String, String) -> String
    public var permissionUnavailableBody: @Sendable (String, String) -> String
    public var permissionAllow: String
    public var permissionOpenSettings: String
    public var permissionStateLabel: @Sendable (FlarePermissionState) -> String
    public var permissionDismiss: String
    // Scene panels / pickers
    public var groupMembers: String
    public var groupOwner: String
    public var groupAdmin: String
    public var addMember: String
    public var loginDevices: String
    public var currentDevice: String
    public var filesAndMedia: String
    public var notificationSettings: String
    public var confirmAction: String
    public var selectDevice: String
    public var transferQueue: String
    public var noTransfers: String
    public var retryFailedTransfers: String
    public var reload: String
    // Form controls
    public var select: String
    public var selectTime: String
    public var selectDate: String
    public var today: String
    public var timeRange: String
    public var searchIdleHint: String

    public init(
        microphone: String = "麦克风",
        camera: String = "摄像头",
        flipCamera: String = "翻转",
        speaker: String = "扬声器",
        hangUp: String = "挂断",
        muted: String = "已静音",
        unmuted: String = "未静音",
        on: String = "开启",
        off: String = "关闭",
        callWaitingAnswer: String = "等待接听…",
        callCalling: String = "呼叫中…",
        callRinging: String = "响铃中…",
        callConnected: String = "已接通",
        callReconnecting: String = "正在恢复通话…",
        callFailed: String = "通话连接失败",
        callInProgress: String = "通话中",
        send: String = "发送",
        cancelReply: String = "取消回复",
        noContacts: String = "还没有联系人",
        noGroups: String = "还没有群组",
        noResults: String = "没有找到结果",
        noContent: String = "暂无内容",
        noConversations: String = "暂无会话",
        close: String = "关闭",
        delete: String = "删除",
        manage: String = "管理",
        selectAll: String = "全选",
        retry: String = "重试",
        search: String = "搜索",
        clearSearch: String = "清除搜索",
        addReaction: String = "添加表情回复",
        readReceipt: String = "已读回执",
        readTab: @escaping @Sendable (Int) -> String = { "已读 (\($0))" },
        unreadTab: @escaping @Sendable (Int) -> String = { "未读 (\($0))" },
        noReadersYet: String = "还没有人已读",
        everyoneHasRead: String = "所有人都已读",
        selectedSuffix: String = "已选",
        forwardEach: String = "逐条转发",
        forwardMerged: String = "合并转发",
        searchMembers: String = "搜索成员",
        everyone: String = "所有人",
        notifyEveryone: String = "通知全体成员",
        noMatchingMembers: String = "没有匹配的成员",
        quickPhrases: String = "快捷短语",
        viewAll: @escaping @Sendable (Int) -> String = { "查看全部 \($0)" },
        typing: String = "正在输入…",
        typingOne: @escaping @Sendable (String) -> String = { "\($0) 正在输入…" },
        typingMany: @escaping @Sendable (Int) -> String = { "\($0) 人正在输入…" },
        newMessages: @escaping @Sendable (Int) -> String = { $0 > 0 ? "\($0) 条新消息" : "新消息" },
        sendMessage: String = "发消息",
        voiceCall: String = "语音",
        videoCall: String = "视频",
        groupCall: String = "群通话",
        joinedCount: @escaping @Sendable (Int, String) -> String = { "\($0) 人已加入 · \($1)" },
        selfSuffix: @escaping @Sendable (String) -> String = { "\($0)（我）" },
        forwardTo: String = "转发给",
        searchConversations: String = "搜索会话",
        noMatchingConversations: String = "没有匹配的会话",
        selectedCount: @escaping @Sendable (Int) -> String = { "已选 \($0)" },
        groupAnnouncement: String = "群公告",
        collapse: String = "收起",
        expand: String = "展开",
        packetClaimed: String = "已领取 · ",
        packetFinished: String = "已被抢光",
        packetTapToClaim: String = "点击拆开",
        packetBrand: String = "Flare 红包",
        commands: String = "命令",
        noMatchingCommands: String = "没有匹配的命令",
        translating: String = "翻译中…",
        translatedBy: @escaping @Sendable (String) -> String = { "由 \($0) 翻译" },
        translated: String = "已翻译",
        hideOriginal: String = "隐藏原文",
        showOriginal: String = "显示原文",
        scanToAddMe: String = "扫一扫加我",
        cancel: String = "取消",
        releaseToCancel: String = "松开取消",
        createPoll: String = "发起投票",
        pollQuestionHint: String = "输入问题",
        pollOptionHint: @escaping @Sendable (Int) -> String = { "选项 \($0)" },
        removeOption: String = "删除选项",
        addOption: String = "添加选项",
        allowMultiple: String = "允许多选",
        submitPoll: String = "创建投票",
        chatBackground: String = "聊天背景",
        decrease: String = "减少",
        increase: String = "增加",
        previousMonth: String = "上个月",
        nextMonth: String = "下个月",
        yearMonth: @escaping @Sendable (Int, Int) -> String = { "\($0)年\($1)月" },
        unlike: String = "取消赞",
        like: String = "赞",
        comment: String = "评论",
        replyInfix: String = " 回复 ",
        changeCover: String = "更换封面",
        post: String = "发表",
        momentTextHint: String = "这一刻的想法…",
        addImage: String = "添加图片",
        pickLocation: String = "所在位置",
        pickVisibility: String = "谁可以看",
        more: String = "更多",
        hideTranscript: String = "收起文字",
        showTranscript: String = "转文字",
        recent: String = "最近",
        searchEmoji: String = "搜索表情",
        noMatchingEmoji: String = "没有匹配的表情",
        emptyStickerPack: String = "该表情包暂无贴纸",
        sticker: String = "贴纸",
        actionImage: String = "图片",
        actionCamera: String = "拍摄",
        actionFile: String = "文件",
        actionLocation: String = "位置",
        actionCard: String = "名片",
        actionVote: String = "投票",
        actionTask: String = "任务",
        actionSchedule: String = "日程",
        incomingVideoCall: String = "邀请你进行视频通话",
        incomingVoiceCall: String = "邀请你进行语音通话",
        reject: String = "拒绝",
        accept: String = "接听",
        back: String = "返回",
        confirm: String = "确定",
        confirmCount: @escaping @Sendable (Int) -> String = { "确定 (\($0))" },
        memberCount: @escaping @Sendable (Int) -> String = { "\($0) 名成员" },
        clear: String = "清除",
        wordCharCount: @escaping @Sendable (Int, Int) -> String = { "\($0) 个词 · \($1) 字符" },
        changeAvatar: String = "更换头像",
        qrCode: String = "二维码",
        play: String = "播放",
        favorites: String = "收藏",
        moments: String = "朋友圈",
        settings: String = "设置",
        permissionNoun: @escaping @Sendable (FlarePermissionKind) -> String = { kind in
            switch kind {
            case .microphone: return "麦克风"
            case .camera: return "摄像头"
            case .notifications: return "通知"
            case .storage: return "存储空间"
            case .photos: return "相册"
            case .contacts: return "通讯录"
            case .location: return "位置信息"
            case .screen: return "屏幕录制"
            }
        },
        permissionVerb: @escaping @Sendable (FlarePermissionKind) -> String = { kind in
            switch kind {
            case .microphone: return "使用麦克风"
            case .camera: return "使用摄像头"
            case .notifications: return "发送通知"
            case .storage: return "访问存储空间"
            case .photos: return "访问相册"
            case .contacts: return "访问通讯录"
            case .location: return "获取位置信息"
            case .screen: return "录制屏幕内容"
            }
        },
        permissionTitle: @escaping @Sendable (String) -> String = { "需要\($0)权限" },
        permissionFeatureFallback: String = "此功能",
        permissionUndeterminedBody: @escaping @Sendable (String, String) -> String = { "\($0)需要\($1)，请允许后继续。" },
        permissionDeniedBody: @escaping @Sendable (String, String) -> String = { "\($1)的权限已被拒绝，\($0)无法使用。请前往系统设置开启。" },
        permissionRestrictedBody: @escaping @Sendable (String, String) -> String = { "\($1)的权限受设备或组织策略限制，\($0)暂不可用。" },
        permissionUnavailableBody: @escaping @Sendable (String, String) -> String = { "当前设备或运行环境不支持\($1)，\($0)暂不可用。" },
        permissionAllow: String = "允许",
        permissionOpenSettings: String = "前往设置",
        permissionStateLabel: @escaping @Sendable (FlarePermissionState) -> String = { state in
            switch state {
            case .undetermined: return "未授权"
            case .denied: return "已拒绝"
            case .restricted: return "受限制"
            case .unavailable: return "不可用"
            }
        },
        permissionDismiss: String = "知道了",
        groupMembers: String = "群成员",
        groupOwner: String = "群主",
        groupAdmin: String = "管理员",
        addMember: String = "加成员",
        loginDevices: String = "登录设备",
        currentDevice: String = "当前设备",
        filesAndMedia: String = "文件与媒体",
        notificationSettings: String = "通知设置",
        confirmAction: String = "确认",
        selectDevice: String = "选择设备",
        transferQueue: String = "传输队列",
        noTransfers: String = "暂无传输任务",
        retryFailedTransfers: String = "重试失败任务",
        reload: String = "重新加载",
        select: String = "选择",
        selectTime: String = "选择时间",
        selectDate: String = "选择日期",
        today: String = "今天",
        timeRange: String = "时间范围",
        searchIdleHint: String = "输入关键词或选择类型"
    ) {
        self.microphone = microphone
        self.camera = camera
        self.flipCamera = flipCamera
        self.speaker = speaker
        self.hangUp = hangUp
        self.muted = muted
        self.unmuted = unmuted
        self.on = on
        self.off = off
        self.callWaitingAnswer = callWaitingAnswer
        self.callCalling = callCalling
        self.callRinging = callRinging
        self.callConnected = callConnected
        self.callReconnecting = callReconnecting
        self.callFailed = callFailed
        self.callInProgress = callInProgress
        self.send = send
        self.cancelReply = cancelReply
        self.noContacts = noContacts
        self.noGroups = noGroups
        self.noResults = noResults
        self.noContent = noContent
        self.noConversations = noConversations
        self.close = close
        self.delete = delete
        self.manage = manage
        self.selectAll = selectAll
        self.retry = retry
        self.search = search
        self.clearSearch = clearSearch
        self.addReaction = addReaction
        self.readReceipt = readReceipt
        self.readTab = readTab
        self.unreadTab = unreadTab
        self.noReadersYet = noReadersYet
        self.everyoneHasRead = everyoneHasRead
        self.selectedSuffix = selectedSuffix
        self.forwardEach = forwardEach
        self.forwardMerged = forwardMerged
        self.searchMembers = searchMembers
        self.everyone = everyone
        self.notifyEveryone = notifyEveryone
        self.noMatchingMembers = noMatchingMembers
        self.quickPhrases = quickPhrases
        self.viewAll = viewAll
        self.typing = typing
        self.typingOne = typingOne
        self.typingMany = typingMany
        self.newMessages = newMessages
        self.sendMessage = sendMessage
        self.voiceCall = voiceCall
        self.videoCall = videoCall
        self.groupCall = groupCall
        self.joinedCount = joinedCount
        self.selfSuffix = selfSuffix
        self.forwardTo = forwardTo
        self.searchConversations = searchConversations
        self.noMatchingConversations = noMatchingConversations
        self.selectedCount = selectedCount
        self.groupAnnouncement = groupAnnouncement
        self.collapse = collapse
        self.expand = expand
        self.packetClaimed = packetClaimed
        self.packetFinished = packetFinished
        self.packetTapToClaim = packetTapToClaim
        self.packetBrand = packetBrand
        self.commands = commands
        self.noMatchingCommands = noMatchingCommands
        self.translating = translating
        self.translatedBy = translatedBy
        self.translated = translated
        self.hideOriginal = hideOriginal
        self.showOriginal = showOriginal
        self.scanToAddMe = scanToAddMe
        self.cancel = cancel
        self.releaseToCancel = releaseToCancel
        self.createPoll = createPoll
        self.pollQuestionHint = pollQuestionHint
        self.pollOptionHint = pollOptionHint
        self.removeOption = removeOption
        self.addOption = addOption
        self.allowMultiple = allowMultiple
        self.submitPoll = submitPoll
        self.chatBackground = chatBackground
        self.decrease = decrease
        self.increase = increase
        self.previousMonth = previousMonth
        self.nextMonth = nextMonth
        self.yearMonth = yearMonth
        self.unlike = unlike
        self.like = like
        self.comment = comment
        self.replyInfix = replyInfix
        self.changeCover = changeCover
        self.post = post
        self.momentTextHint = momentTextHint
        self.addImage = addImage
        self.pickLocation = pickLocation
        self.pickVisibility = pickVisibility
        self.more = more
        self.hideTranscript = hideTranscript
        self.showTranscript = showTranscript
        self.recent = recent
        self.searchEmoji = searchEmoji
        self.noMatchingEmoji = noMatchingEmoji
        self.emptyStickerPack = emptyStickerPack
        self.sticker = sticker
        self.actionImage = actionImage
        self.actionCamera = actionCamera
        self.actionFile = actionFile
        self.actionLocation = actionLocation
        self.actionCard = actionCard
        self.actionVote = actionVote
        self.actionTask = actionTask
        self.actionSchedule = actionSchedule
        self.incomingVideoCall = incomingVideoCall
        self.incomingVoiceCall = incomingVoiceCall
        self.reject = reject
        self.accept = accept
        self.back = back
        self.confirm = confirm
        self.confirmCount = confirmCount
        self.memberCount = memberCount
        self.clear = clear
        self.wordCharCount = wordCharCount
        self.changeAvatar = changeAvatar
        self.qrCode = qrCode
        self.play = play
        self.favorites = favorites
        self.moments = moments
        self.settings = settings
        self.permissionNoun = permissionNoun
        self.permissionVerb = permissionVerb
        self.permissionTitle = permissionTitle
        self.permissionFeatureFallback = permissionFeatureFallback
        self.permissionUndeterminedBody = permissionUndeterminedBody
        self.permissionDeniedBody = permissionDeniedBody
        self.permissionRestrictedBody = permissionRestrictedBody
        self.permissionUnavailableBody = permissionUnavailableBody
        self.permissionAllow = permissionAllow
        self.permissionOpenSettings = permissionOpenSettings
        self.permissionStateLabel = permissionStateLabel
        self.permissionDismiss = permissionDismiss
        self.groupMembers = groupMembers
        self.groupOwner = groupOwner
        self.groupAdmin = groupAdmin
        self.addMember = addMember
        self.loginDevices = loginDevices
        self.currentDevice = currentDevice
        self.filesAndMedia = filesAndMedia
        self.notificationSettings = notificationSettings
        self.confirmAction = confirmAction
        self.selectDevice = selectDevice
        self.transferQueue = transferQueue
        self.noTransfers = noTransfers
        self.retryFailedTransfers = retryFailedTransfers
        self.reload = reload
        self.select = select
        self.selectTime = selectTime
        self.selectDate = selectDate
        self.today = today
        self.timeRange = timeRange
        self.searchIdleHint = searchIdleHint
    }
}

private struct FlareStringsKey: EnvironmentKey {
    static let defaultValue = FlareStrings()
}

public extension EnvironmentValues {
    /// Component copy in effect. Override at the root with `View.flareStrings(_:)`.
    var flareStrings: FlareStrings {
        get { self[FlareStringsKey.self] }
        set { self[FlareStringsKey.self] = newValue }
    }
}

public extension View {
    /// Installs component copy for this subtree. Call once near the app root.
    func flareStrings(_ strings: FlareStrings) -> some View {
        environment(\.flareStrings, strings)
    }
}
