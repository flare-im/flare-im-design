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
 * CompositionLocalProvider(LocalFlareStrings provides FlareStrings(send = "Send")) {
 *     App()
 * }
 * ```
 *
 * 取值方式与 [flareColors] 一致（composable 访问器），故组件里无需逐层传参。
 * 已有 `FlareXxxLabels` 参数的组件不受影响，两者可共存。
 */
data class FlareStrings(
    // 通话
    val microphone: String = "麦克风",
    val camera: String = "摄像头",
    val flipCamera: String = "翻转",
    val speaker: String = "扬声器",
    val hangUp: String = "挂断",
    val callWaitingAnswer: String = "等待对方接听…",
    val callCalling: String = "正在呼叫…",
    val callRinging: String = "正在响铃…",
    val callConnected: String = "已接通",
    // 输入区
    val send: String = "发送",
    val cancelReply: String = "取消回复",
    // 空态
    val noContacts: String = "暂无联系人",
    val noResults: String = "未找到结果",
    // 通用动作
    val close: String = "关闭",
    val delete: String = "删除",
    val manage: String = "管理",
    val selectAll: String = "全选",
    // 消息操作
    val addReaction: String = "添加表情回复",
    val readReceipt: String = "已读回执",
    val readTab: (Int) -> String = { "已读 ($it)" },
    val unreadTab: (Int) -> String = { "未读 ($it)" },
    val noReadersYet: String = "还没有人读过",
    val everyoneHasRead: String = "所有人都已读",
    val selectedSuffix: String = "已选",
    val forwardEach: String = "逐条转发",
    val forwardMerged: String = "合并转发",
    // 提及
    val searchMembers: String = "搜索成员",
    val everyone: String = "全体成员",
    val notifyEveryone: String = "通知所有成员",
    val noMatchingMembers: String = "没有匹配的成员",
    // 快捷短语
    val quickPhrases: String = "快捷短语",
    val viewAll: (Int) -> String = { "查看全部 $it" },
    // 正在输入 / 新消息
    val typing: String = "正在输入…",
    val typingOne: (String) -> String = { "$it 正在输入…" },
    val typingMany: (Int) -> String = { "$it 人正在输入…" },
    val newMessages: (Int) -> String = { if (it > 0) "$it 条新消息" else "新消息" },
    // 名片 / 群通话
    val sendMessage: String = "发消息",
    val groupCall: String = "群通话",
    val joinedCount: (Int, String) -> String = { n, status -> "$n 人已加入 · $status" },
    val selfSuffix: (String) -> String = { "$it（我）" },
    // 转发选择
    val forwardTo: String = "转发给",
    val searchConversations: String = "搜索会话",
    val noMatchingConversations: String = "没有匹配的会话",
    val selectedCount: (Int) -> String = { "已选 $it" },
    // 群公告
    val groupAnnouncement: String = "群公告",
    val collapse: String = "收起",
    val expand: String = "展开",
    // 红包
    val packetClaimed: (String) -> String = { "已领取 · $it" },
    val packetFinished: String = "已被领完",
    val packetTapToClaim: String = "点击领取",
    val packetBrand: String = "闪包",
    // 命令 / 翻译 / 名片码
    val commands: String = "命令",
    val noMatchingCommands: String = "没有匹配的命令",
    val translating: String = "翻译中…",
    val translatedBy: (String) -> String = { "由 $it 翻译" },
    val translated: String = "已翻译",
    val hideOriginal: String = "隐藏原文",
    val showOriginal: String = "显示原文",
    val scanToAddMe: String = "扫一扫加我",
    // 录音 / 投票
    val cancel: String = "取消",
    val releaseToCancel: String = "松开取消",
    val createPoll: String = "发起投票",
    val pollQuestionHint: String = "请输入问题",
    val pollOptionHint: (Int) -> String = { "选项 $it" },
    val removeOption: String = "删除选项",
    val addOption: String = "添加选项",
    val allowMultiple: String = "允许多选",
    val submitPoll: String = "创建投票",
    val chatBackground: String = "聊天背景",
    // 步进 / 日历
    val decrease: String = "减少",
    val increase: String = "增加",
    val previousMonth: String = "上个月",
    val nextMonth: String = "下个月",
    val yearMonth: (Int, Int) -> String = { y, m -> "${y}年${m}月" },
    // 朋友圈
    val unlike: String = "取消赞",
    val like: String = "赞",
    val comment: String = "评论",
    val changeCover: String = "换封面",
    val post: String = "发表",
    val momentTextHint: String = "这一刻的想法…",
    val addImage: String = "添加图片",
    val pickLocation: String = "所在位置",
    val pickVisibility: String = "谁可以看",
    val more: String = "更多",
    // 语音转文字 / 表情贴纸
    val hideTranscript: String = "隐藏文字",
    val showTranscript: String = "转文字",
    val recent: String = "最近",
    val searchEmoji: String = "搜索表情",
    val noMatchingEmoji: String = "没有匹配的表情",
    val emptyStickerPack: String = "该表情包暂无贴纸",
    val sticker: String = "贴纸",
    // 加号面板
    val actionImage: String = "图片",
    val actionCamera: String = "拍摄",
    val actionFile: String = "文件",
    val actionLocation: String = "位置",
    val actionCard: String = "名片",
    val actionVote: String = "投票",
    val actionTask: String = "任务",
    val actionSchedule: String = "日程",
    // 来电
    val incomingVideoCall: String = "邀请你进行视频通话",
    val incomingVoiceCall: String = "邀请你进行语音通话",
    val reject: String = "拒绝",
    val accept: String = "接听",
    // 通用
    val back: String = "返回",
    val confirm: String = "确定",
    val confirmCount: (Int) -> String = { "确定 ($it)" },
    val memberCount: (Int) -> String = { "$it 名成员" },
    val clear: String = "清除",
    val wordCharCount: (Int, Int) -> String = { w, c -> "$w 个词 · $c 字符" },
    val changeAvatar: String = "更换头像",
    val qrCode: String = "二维码",
    val play: String = "播放",
)

val LocalFlareStrings = staticCompositionLocalOf { FlareStrings() }

/** 当前生效的组件文案。宿主可用 [LocalFlareStrings] 覆盖。 */
@Composable
@ReadOnlyComposable
fun flareStrings(): FlareStrings = LocalFlareStrings.current
