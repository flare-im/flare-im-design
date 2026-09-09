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
    // 输入区
    this.send = '发送',
    this.cancelReply = '取消回复',
    // 空态
    this.noContacts = '暂无联系人',
    this.noResults = '未找到结果',
    this.noMessages = '暂无消息',
    this.noContent = '暂无内容',
    // 通用动作
    this.close = '关闭',
    this.delete = '删除',
    this.manage = '管理',
    this.selectAll = '全选',
    this.retry = '重试',
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
    // 提及
    this.searchMembers = '搜索成员',
    this.everyone = '全体成员',
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
    this.packetBrand = '闪包',
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
    this.play = '播放',
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
  final String delete;
  final String manage;
  final String selectAll;
  final String retry;
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
  final String play;
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
  final String Function(String feature, String verb) permissionUndeterminedDescription;
  final String Function(String feature, String verb) permissionDeniedDescription;
  final String Function(String feature, String verb) permissionRestrictedDescription;
  final String Function(String feature, String verb) permissionUnavailableDescription;
  final String permissionAllow;
  final String permissionOpenSettings;
  final String permissionStateUndetermined;
  final String permissionStateDenied;
  final String permissionStateRestricted;
  final String permissionStateUnavailable;

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
    String? send,
    String? cancelReply,
    String? noContacts,
    String? noResults,
    String? noMessages,
    String? noContent,
    String? close,
    String? delete,
    String? manage,
    String? selectAll,
    String? retry,
    String? addReaction,
    String? readReceipt,
    String Function(int count)? readTab,
    String Function(int count)? unreadTab,
    String? noReadersYet,
    String? everyoneHasRead,
    String? selectedSuffix,
    String? forwardEach,
    String? forwardMerged,
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
    String? play,
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
    String Function(String feature, String verb)? permissionUndeterminedDescription,
    String Function(String feature, String verb)? permissionDeniedDescription,
    String Function(String feature, String verb)? permissionRestrictedDescription,
    String Function(String feature, String verb)? permissionUnavailableDescription,
    String? permissionAllow,
    String? permissionOpenSettings,
    String? permissionStateUndetermined,
    String? permissionStateDenied,
    String? permissionStateRestricted,
    String? permissionStateUnavailable,
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
      send: send ?? this.send,
      cancelReply: cancelReply ?? this.cancelReply,
      noContacts: noContacts ?? this.noContacts,
      noResults: noResults ?? this.noResults,
      noMessages: noMessages ?? this.noMessages,
      noContent: noContent ?? this.noContent,
      close: close ?? this.close,
      delete: delete ?? this.delete,
      manage: manage ?? this.manage,
      selectAll: selectAll ?? this.selectAll,
      retry: retry ?? this.retry,
      addReaction: addReaction ?? this.addReaction,
      readReceipt: readReceipt ?? this.readReceipt,
      readTab: readTab ?? this.readTab,
      unreadTab: unreadTab ?? this.unreadTab,
      noReadersYet: noReadersYet ?? this.noReadersYet,
      everyoneHasRead: everyoneHasRead ?? this.everyoneHasRead,
      selectedSuffix: selectedSuffix ?? this.selectedSuffix,
      forwardEach: forwardEach ?? this.forwardEach,
      forwardMerged: forwardMerged ?? this.forwardMerged,
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
      sendMessage: sendMessage ?? this.sendMessage,
      groupCall: groupCall ?? this.groupCall,
      joinedCount: joinedCount ?? this.joinedCount,
      selfSuffix: selfSuffix ?? this.selfSuffix,
      forwardTo: forwardTo ?? this.forwardTo,
      searchConversations: searchConversations ?? this.searchConversations,
      noMatchingConversations: noMatchingConversations ?? this.noMatchingConversations,
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
      play: play ?? this.play,
      permissionNotifications: permissionNotifications ?? this.permissionNotifications,
      permissionStorage: permissionStorage ?? this.permissionStorage,
      permissionPhotos: permissionPhotos ?? this.permissionPhotos,
      permissionContacts: permissionContacts ?? this.permissionContacts,
      permissionLocation: permissionLocation ?? this.permissionLocation,
      permissionScreen: permissionScreen ?? this.permissionScreen,
      permissionVerbMicrophone: permissionVerbMicrophone ?? this.permissionVerbMicrophone,
      permissionVerbCamera: permissionVerbCamera ?? this.permissionVerbCamera,
      permissionVerbNotifications: permissionVerbNotifications ?? this.permissionVerbNotifications,
      permissionVerbStorage: permissionVerbStorage ?? this.permissionVerbStorage,
      permissionVerbPhotos: permissionVerbPhotos ?? this.permissionVerbPhotos,
      permissionVerbContacts: permissionVerbContacts ?? this.permissionVerbContacts,
      permissionVerbLocation: permissionVerbLocation ?? this.permissionVerbLocation,
      permissionVerbScreen: permissionVerbScreen ?? this.permissionVerbScreen,
      permissionThisFeature: permissionThisFeature ?? this.permissionThisFeature,
      permissionTitle: permissionTitle ?? this.permissionTitle,
      permissionUndeterminedDescription: permissionUndeterminedDescription ?? this.permissionUndeterminedDescription,
      permissionDeniedDescription: permissionDeniedDescription ?? this.permissionDeniedDescription,
      permissionRestrictedDescription: permissionRestrictedDescription ?? this.permissionRestrictedDescription,
      permissionUnavailableDescription: permissionUnavailableDescription ?? this.permissionUnavailableDescription,
      permissionAllow: permissionAllow ?? this.permissionAllow,
      permissionOpenSettings: permissionOpenSettings ?? this.permissionOpenSettings,
      permissionStateUndetermined: permissionStateUndetermined ?? this.permissionStateUndetermined,
      permissionStateDenied: permissionStateDenied ?? this.permissionStateDenied,
      permissionStateRestricted: permissionStateRestricted ?? this.permissionStateRestricted,
      permissionStateUnavailable: permissionStateUnavailable ?? this.permissionStateUnavailable,
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
  static String _joinedCount(int count, String status) => '$count 人已加入 · $status';
  static String _selfSuffix(String name) => '$name（我）';
  static String _selectedCount(int count) => '已选 $count';
  static String _packetClaimed(String amount) => '已领取 · $amount';
  static String _translatedBy(String provider) => '由 $provider 翻译';
  static String _pollOptionHint(int index) => '选项 $index';
  static String _yearMonth(int year, int month) => '${year}年${month}月';
  static String _confirmCount(int count) => '确定 ($count)';
  static String _memberCount(int count) => '$count 名成员';
  static String _wordCharCount(int words, int chars) => '$words 个词 · $chars 字符';
  static String _permissionTitle(String noun) => '需要$noun权限';
  static String _permissionUndeterminedDescription(String feature, String verb) => '$feature需要$verb，请允许后继续。';
  static String _permissionDeniedDescription(String feature, String verb) => '$verb的权限已被拒绝，$feature无法使用。请前往系统设置开启。';
  static String _permissionRestrictedDescription(String feature, String verb) => '$verb的权限受设备或组织策略限制，$feature暂不可用。';
  static String _permissionUnavailableDescription(String feature, String verb) => '当前设备或运行环境不支持$verb，$feature暂不可用。';
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
