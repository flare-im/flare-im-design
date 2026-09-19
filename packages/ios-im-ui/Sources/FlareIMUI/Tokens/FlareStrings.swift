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
    public var messagePending: String
    public var messageSending: String
    public var messageSent: String
    public var messageDelivered: String
    public var messageRead: String
    public var messageFailed: String
    public var messageRetrying: String
    public var messageEdited: String
    public var messageReadOnce: String
    public var messageBurnAfterRead: String
    public var messageExpired: String
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
    public var messageBatchPin: String
    public var messageBatchPinSelf: String
    public var messageBatchClear: String
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
    /// `QRCardView` frame without a code (en: "QR code unavailable").
    public var qrCardUnavailable: String
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
    /// en: "replying to" — between a moment comment's author and the person it replies to.
    public var momentReplyTo: String
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
    // Default navigation (``flareDefaultIMNavigation``, ``flareDefaultContactNavigation``)
    public var navChats: String
    public var navContacts: String
    public var navProfile: String
    public var navFriends: String
    public var navGroups: String
    public var navNewFriends: String
    // Profile entries
    public var favorites: String
    public var moments: String
    public var settings: String
    // Theme mode options a host draws in its settings (`spec/theme-mode-vectors.json`)
    public var themeSystem: String
    public var themeLight: String
    public var themeDark: String
    // The reveal key of a secure input (`InputView(revealable:)`)
    public var inputReveal: String
    public var inputHide: String
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
    // Message status
    public var resend: String
    // GroupPermissionMatrixView
    public var groupPermissionMatrixTitle: String
    public var groupPermissionMatrixReadOnlyHint: String
    public var groupPermissionMatrixJoinPolicy: String
    public var groupPermissionMatrixJoinPolicyDescription: String
    public var groupPermissionMatrixJoinInvite: String
    public var groupPermissionMatrixJoinApproval: String
    public var groupPermissionMatrixJoinOpen: String
    public var groupPermissionMatrixUnknownJoinPolicy: String
    public var groupPermissionMatrixMuteAll: String
    public var groupPermissionMatrixMuteAllDescription: String
    public var groupPermissionMatrixOnlyAdminCanAtAll: String
    public var groupPermissionMatrixOnlyAdminCanAtAllDescription: String
    public var groupPermissionMatrixOnlyAdminCanPin: String
    public var groupPermissionMatrixOnlyAdminCanPinDescription: String
    public var groupPermissionMatrixShareCardPermission: String
    public var groupPermissionMatrixShareCardPermissionDescription: String
    public var groupPermissionMatrixOn: String
    public var groupPermissionMatrixOff: String
    public var groupPermissionMatrixBusy: String
    public var groupPermissionMatrixDismissError: String
    // ConversationBatchToolbarView
    public var conversationBatchToolbarSelected: String
    public var conversationBatchToolbarEmpty: String
    public var conversationBatchToolbarMarkRead: String
    public var conversationBatchToolbarMute: String
    public var conversationBatchToolbarArchive: String
    public var conversationBatchToolbarCancel: String
    public var conversationBatchToolbarBusy: String
    public var conversationBatchToolbarSucceededSummary: String
    public var conversationBatchToolbarFailedSummary: String
    public var conversationBatchToolbarRetryFailed: String
    public var conversationBatchToolbarDismiss: String
    public var conversationBatchToolbarExpand: String
    public var conversationBatchToolbarMaxSelection: String
    // StorageUsageView
    public var storageUsageTitle: String
    public var storageUsageUnknownSize: String
    public var storageUsageAtLeast: String
    public var storageUsageClear: String
    public var storageUsageClearing: String
    public var storageUsageTotal: String
    public var storageUsageDeviceFree: String
    public var storageUsageReload: String
    public var storageUsageRetry: String
    public var storageUsageDismissError: String
    public var storageUsageLoading: String
    public var storageUsageEmpty: String
    public var storageUsageFileCount: String
    // MemberRoleSheetView
    public var memberRoleSheetMemberRole: String
    public var memberRoleSheetMuted: String
    public var memberRoleSheetPromote: String
    public var memberRoleSheetDemote: String
    public var memberRoleSheetMute: String
    public var memberRoleSheetUnmute: String
    public var memberRoleSheetRemove: String
    public var memberRoleSheetTransferOwner: String
    public var memberRoleSheetDangerGroup: String
    public var memberRoleSheetEmpty: String
    public var memberRoleSheetOwnerProtected: String
    // RelationActionBarView
    public var relationActionBarAdd: String
    public var relationActionBarAccept: String
    public var relationActionBarRemove: String
    public var relationActionBarBlock: String
    public var relationActionBarUnblock: String
    public var relationActionBarPending: String
    public var relationActionBarBusy: String
    public var relationActionBarDismissError: String
    public var relationActionBarEmpty: String
    // ScreenShareView
    public var screenShareTitle: String
    public var screenShareIdle: String
    public var screenShareRequesting: String
    public var screenShareSharing: String
    public var screenShareViewing: String
    public var screenShareUnavailable: String
    public var screenShareSourceRow: String
    public var screenSharePresenterRow: String
    public var screenShareStart: String
    public var screenShareStop: String
    public var screenShareCancel: String
    // ConversationActionSheetView
    public var conversationActionSheetPin: String
    public var conversationActionSheetUnpin: String
    public var conversationActionSheetMute: String
    public var conversationActionSheetUnmute: String
    public var conversationActionSheetMarkRead: String
    /// Offered when nothing is unread (en: "Mark as unread").
    public var conversationActionSheetMarkUnread: String
    public var conversationActionSheetArchive: String
    public var conversationActionSheetUnarchive: String
    public var conversationActionSheetHide: String
    /// Danger group, before delete (en: "Clear local history").
    public var conversationActionSheetClearHistory: String
    public var conversationActionSheetEmpty: String
    public var messageActionSheetLabel: String
    public var messageActionSheetEmpty: String
    /// A covered spoiler in a rich-text body, as assistive technology names it (en: "Spoiler, select to reveal").
    public var messageSpoilerReveal: String
    /// An album body and its tiles, as VoiceOver names them (en: "{count} images", "Image {index} of {count}",
    /// "Image {index} of {count}, {more} more not shown").
    public var messageImageGroupLabel: @Sendable (Int) -> String
    public var messageImageGroupItem: @Sendable (_ index: Int, _ count: Int) -> String
    public var messageImageGroupItemMore: @Sendable (_ index: Int, _ count: Int, _ more: Int) -> String
    public var messageActionReply: String
    public var messageActionForward: String
    public var messageActionRecall: String
    public var messageActionResend: String
    public var messageActionMultiSelect: String
    public var messageActionMark: String
    public var messageActionPin: String
    public var messageActionPinSelf: String
    public var messageActionUnpin: String
    public var messageActionCopy: String
    public var messageActionPreview: String
    public var messageActionSave: String
    public var messageActionEdit: String
    public var messageActionDelete: String
    // WorkspaceFrameView —— 通用兜底，不能提"会话"
    public var workspaceFrameLoading: String
    public var workspaceFrameEmpty: String
    public var workspaceFrameFailure: String
    public var workspaceFrameRetry: String
    // ConversationWorkspaceView
    public var conversationWorkspaceChatEmpty: String
    public var conversationWorkspaceDetailEmpty: String
    public var conversationWorkspaceListFailure: String
    public var conversationWorkspaceChatFailure: String
    public var conversationWorkspaceDetailFailure: String
    public var conversationWorkspaceListLoading: String
    public var conversationWorkspaceChatLoading: String
    public var conversationWorkspaceDetailLoading: String
    // SearchDateRangeFilterView
    public var searchDateRangeFilterCustom: String
    public var searchDateRangeFilterFrom: String
    public var searchDateRangeFilterTo: String
    public var searchDateRangeFilterUnlimited: String
    public var searchDateRangeFilterInvalid: String
    // ComposerView
    public var composerPlaceholder: String
    public var composerReply: String
    public var voiceHoldButtonLabel: String
    public var voiceHoldButtonRecording: String
    // UnknownUserPlaceholderView
    public var unknownUserPlaceholderUnknown: String
    public var unknownUserPlaceholderDeactivated: String
    public var unknownUserPlaceholderBlocked: String
    public var unknownUserPlaceholderUnreachable: String
    public var unknownUserPlaceholderId: String
    // NewFriendRequestsView
    public var newFriendRequestsEmpty: String
    public var newFriendRequestsAccept: String
    /// Status of a request the user sent (en "Pending").
    public var newFriendRequestsPending: String
    /// Withdraw a request the user sent (en "Withdraw").
    public var newFriendRequestsWithdraw: String
    // UnknownMessageView
    public var unknownMessageHint: String
    public var unknownMessageUnsupported: String
    public var unknownMessageDiagnostic: String
    // ConversationRowView
    public var conversationRowDraft: String
    public var conversationRowMention: String
    // MessageListView
    public var messageListEmpty: String
    public var messageListLoadOlder: String
    // MessageBubbleView (recalled notice)
    public var messageRecalledSelf: String
    public var messageRecalledPeer: String
    public var messageRecalledGroupOther: @Sendable (String) -> String
    /// Label of a tappable reply quote from the quoted sender (may be empty) and the summary
    /// (en "Quoted \(name): \(summary)", or "Quoted: \(summary)" without a name).
    public var messageQuoteLabel: @Sendable (String, String) -> String
    /// What a screen reader is told once a jump lands: the ring says which row it is to everyone who
    /// can see it, and this says the same thing to a reader who cannot
    /// (en "Jumped to \(name)'s message: \(summary)").
    public var jumpedToMessage: @Sendable (String, String) -> String
    // ConversationHeaderView
    /// Label of the identity button from the title and the identity action's label (en "\(title), \(label)").
    public var conversationHeaderIdentityLabel: @Sendable (String, String) -> String
    // FlareTimeFormat
    /// The previous calendar day in conversation times (en "Yesterday").
    public var yesterday: String
    // StartConversationView
    public var startConversationSearchPlaceholder: String
    // FlareGroupDetail
    public var groupDetailTitle: String
    public var groupDetailUnavailable: String
    public var groupDetailUnavailableHint: String
    public var groupDetailMemberCountSuffix: String
    public var groupDetailNotSet: String
    /// A per-group setting the host could not read: the row shows this instead of claiming a state.
    public var groupDetailSettingUnavailable: String
    public var groupDetailSectionInfo: String
    public var groupDetailSectionMyInGroup: String
    public var groupDetailSectionManage: String
    public var groupDetailSectionPerms: String
    public var groupDetailGroupName: String
    public var groupDetailAnnouncementEmpty: String
    public var groupDetailMyNickname: String
    public var groupDetailMuteNotif: String
    public var groupDetailPinGroup: String
    public var groupDetailJoinMode: String
    public var groupDetailJoinRequests: String
    public var groupDetailMuteAll: String
    public var groupDetailInviteLink: String
    public var groupDetailOnlyAdminAtAll: String
    public var groupDetailOnlyAdminPin: String
    public var groupDetailShareCard: String
    public var groupDetailJoinOpen: String
    public var groupDetailJoinApproval: String
    public var groupDetailJoinInvite: String
    public var groupDetailEditName: String
    public var groupDetailEditAnnouncement: String
    public var groupDetailNicknamePlaceholder: String
    public var groupDetailMemberManage: String
    public var groupDetailSetAdmin: String
    public var groupDetailUnsetAdmin: String
    public var groupDetailMute: String
    public var groupDetailUnmute: String
    public var groupDetailTransferOwner: String
    public var groupDetailTransferConfirm: String
    public var groupDetailRemoveMember: String
    public var groupDetailNoRequests: String
    public var groupDetailRequestDefaultMessage: String
    public var groupDetailApprove: String
    public var groupDetailInvite: String
    public var groupDetailInviteEmpty: String
    public var groupDetailInviteLinkHint: String
    public var groupDetailInviteCodeTitle: String
    public var groupDetailCopyCode: String
    public var groupDetailCopied: String
    public var groupDetailCannotGenerate: String
    public var groupDetailLeave: String
    public var groupDetailDissolve: String
    public var groupDetailSave: String
    public var groupDetailDone: String
    // MomentAudienceSheetView
    public var momentAudienceSheetPublic: String
    public var momentAudienceSheetPublicHint: String
    public var momentAudienceSheetFriends: String
    public var momentAudienceSheetFriendsHint: String
    public var momentAudienceSheetPrivate: String
    public var momentAudienceSheetPrivateHint: String
    public var momentAudienceSheetInclude: String
    public var momentAudienceSheetIncludeHint: String
    public var momentAudienceSheetExclude: String
    public var momentAudienceSheetExcludeHint: String
    public var momentAudienceSheetPick: String
    public var momentAudienceSheetDone: String
    public var momentAudienceSheetSelected: @Sendable (Int) -> String
    // MomentsVisibilityRuleListView
    public var momentsVisibilityRuleListHideFromTitle: String
    public var momentsVisibilityRuleListHideFromHint: String
    public var momentsVisibilityRuleListMuteTitle: String
    public var momentsVisibilityRuleListMuteHint: String
    public var momentsVisibilityRuleListEmpty: String
    public var momentsVisibilityRuleListRemove: String
    // ContactMatchListView
    public var contactMatchListAdd: String
    public var contactMatchListEmpty: String
    // AnnouncementReadBarView
    public var announcementReadBarConfirmRead: String
    public var announcementReadBarViewUnread: String
    public var announcementReadBarReadCount: @Sendable (Int, Int) -> String
    // FlareContactDetail
    public var contactDetailInfo: String
    public var contactDetailFlareId: String
    public var contactDetailRemark: String
    public var contactDetailDescription: String
    public var contactDetailStar: String
    public var contactDetailNotSet: String
    public var contactDetailVoice: String
    public var contactDetailVideo: String
    public var contactDetailBlock: String
    public var contactDetailRemove: String
    // ConversationDetailsView
    public var conversationDetailsMessages: String
    public var conversationDetailsMute: String
    public var conversationDetailsPin: String
    public var conversationDetailsMarkRead: String
    public var conversationDetailsMarkUnread: String
    public var conversationDetailsSync: String
    public var conversationDetailsArchive: String
    public var conversationDetailsUnarchive: String
    public var conversationDetailsClearHistory: String
    public var conversationDetailsDelete: String
    // ProfileEditorView
    public var profileEditorNickname: String
    public var profileEditorNicknamePlaceholder: String
    public var profileEditorBio: String
    public var profileEditorBioPlaceholder: String
    public var profileEditorSave: String

    // Icon-only controls: each one is named by what it does.
    /// en: "Emoji"
    public var composerEmoji: String
    /// en: "Mention"
    public var composerMention: String
    /// en: "Voice"
    public var composerVoice: String
    /// en: "Image"
    public var composerImage: String
    /// en: "Rich text"
    public var composerRichText: String
    /// en: "More actions"
    public var composerMore: String
    /// en: "Expand input"
    public var composerExpandInput: String
    /// en: "Collapse input"
    public var composerCollapseInput: String
    /// en: "Bold"
    public var composerFormatBold: String
    /// en: "Italic"
    public var composerFormatItalic: String
    /// en: "Strikethrough"
    public var composerFormatStrike: String
    /// en: "Code"
    public var composerFormatCode: String
    /// en: "Link"
    public var composerFormatLink: String
    /// en: "Heading"
    public var composerFormatHeading: String
    /// en: "Quote"
    public var composerFormatQuote: String
    /// en: "Bulleted list"
    public var composerFormatBullet: String
    /// en: "Numbered list"
    public var composerFormatOrdered: String
    /// en: "Keyboard: discard recording"
    public var inlineVoiceComposerKeyboard: String
    /// en: "Pause recording"
    public var inlineVoiceComposerPause: String
    /// en: "Start recording"
    public var inlineVoiceComposerStart: String
    /// en: "Play / pause preview"
    public var inlineVoiceComposerPreview: String
    /// en: "Resume recording"
    public var inlineVoiceComposerResume: String
    /// en: "Discard recording"
    public var inlineVoiceComposerDiscard: String
    /// en: "Allow microphone access to record" — the recorder without permission.
    public var inlineVoiceComposerMicDenied: String
    /// en: "Sending failed. Try again." — the recorder when the host refused the clip.
    public var inlineVoiceComposerSendFailed: String
    /// en: "Cancel recording"
    public var cancelRecording: String
    /// en: "Send voice message"
    public var sendVoice: String
    /// en: "Pause"
    public var pause: String
    /// en: "Download"
    public var download: String
    /// en: "Close preview"
    public var imagePreviewClose: String
    /// A gallery preview's paging keys and where it is (en: "Previous image", "Next image", "{index} of {count}").
    public var imagePreviewPrevious: String
    public var imagePreviewNext: String
    public var imagePreviewPosition: @Sendable (_ index: Int, _ count: Int) -> String
    /// en: "Exit multi-select"
    public var exitMultiSelect: String
    /// en: "Jump to latest messages"
    public var scrollToLatest: String
    /// en: "Minimize call"
    public var callMinimize: String
    /// en: "On" — the value of a call device toggle (microphone, camera, speaker) whose device is on.
    public var callDeviceOn: String
    /// en: "Off" — the value of a call device toggle whose device is off (a muted microphone is off).
    public var callDeviceOff: String
    /// en: "Return to call" — the call dock's main button.
    public var callReturn: String
    /// en: "Add conversation actions" — the conversation header's add menu.
    public var conversationHeaderAddActions: String
    /// en: "More conversation actions" — the conversation header's overflow menu.
    public var conversationHeaderMoreActions: String
    /// en: "Image" — the name of an image message without a description.
    public var messageImage: String
    /// en: "Video" — the name of a video message.
    public var messageVideo: String
    /// en: "Voice message" — the name of a voice message that has no play action.
    public var messageVoice: String
    /// en: "\(n) seconds" — a voice message's length, or what is left of it while it plays.
    public var voiceSeconds: @Sendable (Int) -> String
    /// en: "Playback failed" — a voice message that could not play; a tap tries again.
    public var voicePlaybackFailed: String
    /// en: "Image failed to load" — the image preview when the image cannot load.
    public var imageLoadFailed: String
    /// en: "Video failed to load" — the video player when the video cannot load.
    public var videoLoadFailed: String
    /// en: "Dismiss announcement"
    public var announcementBannerDismiss: String
    /// en: "Remove image"
    public var removeImage: String
    /// en: "Moment actions"
    public var momentActions: String
    /// en: "Add to list"
    public var momentsVisibilityRuleListAdd: String
    /// en: "My QR code"
    public var myQrCode: String
    /// en: "Rating"
    public var rating: String
    /// en: "\(n) stars"
    public var ratingStar: @Sendable (Int) -> String
    /// en: "Search messages" — the conversation header's default search action.
    public var conversationHeaderSearch: String
    /// en: "Start audio call" — the conversation header's default audio call action.
    public var conversationHeaderAudioCall: String
    /// en: "Start video call" — the conversation header's default video call action.
    public var conversationHeaderVideoCall: String
    /// en: "Add member" — the conversation header's default add-member action.
    public var conversationHeaderAddMember: String
    /// en: "Share conversation" — the conversation header's default share action.
    public var conversationHeaderShare: String
    /// en: "Details" — the conversation header's default details action.
    public var conversationHeaderDetails: String
    /// en: "Online" — a presence shown as text (the conversation header subtitle).
    public var presenceOnline: String
    /// en: "Offline"
    public var presenceOffline: String
    /// en: "Busy"
    public var presenceBusy: String
    /// en: "Away"
    public var presenceAway: String
    /// en: "Connecting…" — the connection notice while the first connection is made.
    public var connectionConnecting: String
    /// en: "Connection lost. Reconnecting…"
    public var connectionReconnecting: String
    /// en: "No network. Messages will sync when it is back."
    public var connectionOffline: String
    /// en: "Disconnected"
    public var connectionDisconnected: String
    /// en: "Disconnected: \(reason)"
    public var connectionDisconnectedReason: @Sendable (String) -> String
    /// en: "Your account signed in on another device"
    public var connectionKicked: String
    /// en: "Your sign-in has expired"
    public var connectionExpired: String
    /// en: "Reconnect" — the connection notice's recovery action.
    public var connectionReconnect: String
    /// en: "Sign in again" — the recovery action after being signed out by the server.
    public var connectionSignIn: String
    /// en: "Members (\(n))" — the group detail's all-members sheet.
    public var groupDetailMembersTitle: @Sendable (Int) -> String
    /// en: "Search members"
    public var groupDetailSearchMembers: String
    /// en: "No matching members"
    public var groupDetailNoMatchingMembers: String
    /// en: "\(name), edit profile" — the profile panel's identity row, which opens the profile editor.
    public var profilePanelEditProfile: @Sendable (String) -> String
    /// en: "Reply to \(name): \(text)" — a moment comment row that replies to its comment.
    public var momentReplyToComment: @Sendable (String, String) -> String
    // Message preview — the one-line summary of a message whose body is not plain text
    // (``flareMessagePreviewText(_:strings:)``). Same vocabulary and keys as the other three
    // kits' `preview.*` entries; the shared rule table is `spec/message-preview-vectors.json`.
    /// en: "[Message]" — a message with nothing readable to summarize; a reply strip or a quote
    /// never shows a blank line, while a conversation row may show nothing.
    public var previewMessage: String
    /// en: "[Rich text]"
    public var previewRichText: String
    /// en: "[GIF]" — a moving image; a still one is ``previewImage``.
    public var previewGif: String
    /// en: "[Image]"
    public var previewImage: String
    /// An image named by its alt text inside a markdown line (``flareMarkdownToPlainText(_:strings:)``)
    /// (en "[Image] {label}").
    public var previewImageNamed: @Sendable (String) -> String
    /// en: "[Video]"
    public var previewVideo: String
    /// en: "[Voice]"
    public var previewAudio: String
    /// en: "[File]"
    public var previewFile: String
    /// en: "[File] \(name)"
    public var previewFileNamed: @Sendable (String) -> String
    /// en: "[Location]"
    public var previewLocation: String
    /// en: "[Location] \(label)"
    public var previewLocationNamed: @Sendable (String) -> String
    /// en: "[Contact]"
    public var previewCard: String
    /// en: "[Contact] \(label)"
    public var previewCardNamed: @Sendable (String) -> String
    /// en: "[Sticker]"
    public var previewSticker: String
    /// en: "[Emoji]"
    public var previewEmoji: String
    /// en: "[Quote]"
    public var previewQuote: String
    /// en: "[Link]"
    public var previewLink: String
    /// en: "[Forward]"
    public var previewForward: String
    /// en: "[Forward] \(count) messages"
    public var previewForwardCount: @Sendable (Int) -> String
    /// en: "[Thread]"
    public var previewThread: String
    /// en: "[Mini Program]"
    public var previewMiniProgram: String
    /// en: "[Album]"
    public var previewImageGroup: String
    /// en: "[Album] \(count)"
    public var previewImageGroupCount: @Sendable (Int) -> String
    /// en: "[System]"
    public var previewSystem: String
    /// en: "[Notification]"
    public var previewNotification: String
    /// en: "[Poll]"
    public var previewVote: String
    /// en: "[Task]"
    public var previewTask: String
    /// en: "[Schedule]"
    public var previewSchedule: String
    /// en: "[Announcement]"
    public var previewAnnouncement: String
    /// en: "[Custom]"
    public var previewCustom: String
    /// en: "[Placeholder]"
    public var previewPlaceholder: String
    /// en: "[Unknown]"
    public var previewUnknown: String

    public init(
        microphone: String = "麦克风",
        camera: String = "摄像头",
        flipCamera: String = "翻转",
        speaker: String = "扬声器",
        hangUp: String = "挂断",
        muted: String = "已静音",
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
        messagePending: String = "等待发送",
        messageSending: String = "发送中",
        messageSent: String = "已发送",
        messageDelivered: String = "已送达",
        messageRead: String = "已读",
        messageFailed: String = "发送失败",
        messageRetrying: String = "正在重试",
        messageEdited: String = "已编辑",
        messageReadOnce: String = "仅可查看一次",
        messageBurnAfterRead: String = "阅后即焚",
        messageExpired: String = "已过期",
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
        messageBatchPin: String = "置顶",
        messageBatchPinSelf: String = "仅自己置顶",
        messageBatchClear: String = "清除选择",
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
        qrCardUnavailable: String = "二维码暂不可用",
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
        momentReplyTo: String = "回复",
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
        navChats: String = "消息",            // Chats
        navContacts: String = "通讯录",        // Contacts
        navProfile: String = "我",             // Me
        navFriends: String = "好友",           // Friends
        navGroups: String = "群聊",            // Groups
        navNewFriends: String = "新的朋友",     // New friends
        favorites: String = "收藏",
        moments: String = "圈子",
        settings: String = "设置",
        themeSystem: String = "跟随系统",     // System
        themeLight: String = "浅色",          // Light
        themeDark: String = "深色",           // Dark
        inputReveal: String = "显示密码",      // Show password
        inputHide: String = "隐藏密码",        // Hide password
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
        searchIdleHint: String = "输入关键词或选择类型",
        resend: String = "重新发送",
        groupPermissionMatrixTitle: String = "群设置",
        groupPermissionMatrixReadOnlyHint: String = "仅群主和管理员可修改",
        groupPermissionMatrixJoinPolicy: String = "加群方式",
        groupPermissionMatrixJoinPolicyDescription: String = "决定他人如何加入本群",
        groupPermissionMatrixJoinInvite: String = "仅邀请",
        groupPermissionMatrixJoinApproval: String = "需管理员审批",
        groupPermissionMatrixJoinOpen: String = "允许直接加入",
        groupPermissionMatrixUnknownJoinPolicy: String = "当前加群方式未知，请重新选择",
        groupPermissionMatrixMuteAll: String = "全员禁言",
        groupPermissionMatrixMuteAllDescription: String = "开启后仅群主和管理员可发言",
        groupPermissionMatrixOnlyAdminCanAtAll: String = "仅管理员可 @所有人",
        groupPermissionMatrixOnlyAdminCanAtAllDescription: String = "限制 @所有人 的使用范围",
        groupPermissionMatrixOnlyAdminCanPin: String = "仅管理员可置顶消息",
        groupPermissionMatrixOnlyAdminCanPinDescription: String = "限制群内置顶消息的权限",
        groupPermissionMatrixShareCardPermission: String = "允许分享群名片",
        groupPermissionMatrixShareCardPermissionDescription: String = "关闭后成员不能把本群分享给他人",
        groupPermissionMatrixOn: String = "已开启",
        groupPermissionMatrixOff: String = "已关闭",
        groupPermissionMatrixBusy: String = "提交中",
        groupPermissionMatrixDismissError: String = "忽略此错误",
        conversationBatchToolbarSelected: String = "已选",
        conversationBatchToolbarEmpty: String = "请选择会话",
        conversationBatchToolbarMarkRead: String = "标为已读",
        conversationBatchToolbarMute: String = "免打扰",
        conversationBatchToolbarArchive: String = "归档",
        conversationBatchToolbarCancel: String = "取消选择",
        conversationBatchToolbarBusy: String = "处理中",
        conversationBatchToolbarSucceededSummary: String = "成功 {n} 项",
        conversationBatchToolbarFailedSummary: String = "{n} 项失败",
        conversationBatchToolbarRetryFailed: String = "重试失败项",
        conversationBatchToolbarDismiss: String = "关闭结果",
        conversationBatchToolbarExpand: String = "查看详情",
        conversationBatchToolbarMaxSelection: String = "最多可选 {n} 项",
        storageUsageTitle: String = "存储空间",
        storageUsageUnknownSize: String = "未知",
        storageUsageAtLeast: String = "至少",
        storageUsageClear: String = "清理",
        storageUsageClearing: String = "清理中",
        storageUsageTotal: String = "总计",
        storageUsageDeviceFree: String = "可用空间",
        storageUsageReload: String = "重新统计",
        storageUsageRetry: String = "失败重试",
        storageUsageDismissError: String = "忽略此错误",
        storageUsageLoading: String = "正在统计存储占用",
        storageUsageEmpty: String = "没有可统计的存储分类",
        storageUsageFileCount: String = "{count} 个文件",
        memberRoleSheetMemberRole: String = "成员",
        memberRoleSheetMuted: String = "已禁言",
        memberRoleSheetPromote: String = "设为管理员",
        memberRoleSheetDemote: String = "取消管理员",
        memberRoleSheetMute: String = "禁言",
        memberRoleSheetUnmute: String = "解除禁言",
        memberRoleSheetRemove: String = "移出群聊",
        memberRoleSheetTransferOwner: String = "转让群主",
        memberRoleSheetDangerGroup: String = "危险操作",
        memberRoleSheetEmpty: String = "你没有管理权限",
        memberRoleSheetOwnerProtected: String = "群主不可被管理",
        relationActionBarAdd: String = "添加好友",
        relationActionBarAccept: String = "接受",
        relationActionBarRemove: String = "删除好友",
        relationActionBarBlock: String = "加入黑名单",
        relationActionBarUnblock: String = "移出黑名单",
        relationActionBarPending: String = "等待对方验证",
        relationActionBarBusy: String = "处理中",
        relationActionBarDismissError: String = "关闭错误提示",
        relationActionBarEmpty: String = "暂无可用操作",
        screenShareTitle: String = "屏幕共享",
        screenShareIdle: String = "未在共享",
        screenShareRequesting: String = "正在请求共享",
        screenShareSharing: String = "正在共享屏幕",
        screenShareViewing: String = "正在观看共享",
        screenShareUnavailable: String = "当前环境不支持屏幕共享",
        screenShareSourceRow: String = "共享内容",
        screenSharePresenterRow: String = "共享者",
        screenShareStart: String = "共享屏幕",
        screenShareStop: String = "停止共享",
        screenShareCancel: String = "取消请求",
        conversationActionSheetPin: String = "置顶",
        conversationActionSheetUnpin: String = "取消置顶",
        conversationActionSheetMute: String = "免打扰",
        conversationActionSheetUnmute: String = "取消免打扰",
        conversationActionSheetMarkRead: String = "标为已读",
        conversationActionSheetMarkUnread: String = "标为未读",
        conversationActionSheetArchive: String = "归档",
        conversationActionSheetUnarchive: String = "取消归档",
        conversationActionSheetHide: String = "隐藏",
        conversationActionSheetClearHistory: String = "清空本地记录",
        conversationActionSheetEmpty: String = "暂无可用操作",
        messageActionSheetLabel: String = "消息操作",
        messageActionSheetEmpty: String = "暂无可用操作",
        messageSpoilerReveal: String = "剧透内容，点按显示",
        messageImageGroupLabel: @escaping @Sendable (Int) -> String = { "\($0) 张图片" },
        messageImageGroupItem: @escaping @Sendable (Int, Int) -> String = { "第 \($0) 张图片，共 \($1) 张" },
        messageImageGroupItemMore: @escaping @Sendable (Int, Int, Int) -> String = {
            "第 \($0) 张图片，共 \($1) 张，另有 \($2) 张未显示"
        },
        messageActionReply: String = "回复",
        messageActionForward: String = "转发",
        messageActionRecall: String = "撤回",
        messageActionResend: String = "重新发送",
        messageActionMultiSelect: String = "多选",
        messageActionMark: String = "标记",
        messageActionPin: String = "置顶消息",
        messageActionPinSelf: String = "仅自己置顶",
        messageActionUnpin: String = "取消置顶",
        messageActionCopy: String = "复制",
        messageActionPreview: String = "预览",
        messageActionSave: String = "保存",
        messageActionEdit: String = "编辑",
        messageActionDelete: String = "删除",
        workspaceFrameLoading: String = "正在加载",
        workspaceFrameEmpty: String = "暂无内容",
        workspaceFrameFailure: String = "加载失败",
        workspaceFrameRetry: String = "重试",
        conversationWorkspaceChatEmpty: String = "选择一个会话开始聊天",
        conversationWorkspaceDetailEmpty: String = "暂无详情",
        conversationWorkspaceListFailure: String = "会话列表加载失败",
        conversationWorkspaceChatFailure: String = "消息加载失败",
        conversationWorkspaceDetailFailure: String = "详情加载失败",
        conversationWorkspaceListLoading: String = "正在加载会话列表",
        conversationWorkspaceChatLoading: String = "正在加载消息",
        conversationWorkspaceDetailLoading: String = "正在加载详情",
        searchDateRangeFilterCustom: String = "自定义",
        searchDateRangeFilterFrom: String = "起始日期",
        searchDateRangeFilterTo: String = "结束日期",
        searchDateRangeFilterUnlimited: String = "不限时间",
        searchDateRangeFilterInvalid: String = "起始日期不能晚于结束日期",
        composerPlaceholder: String = "输入消息",
        composerReply: String = "回复",
        voiceHoldButtonLabel: String = "按住 说话",
        voiceHoldButtonRecording: String = "松开发送 · 上滑取消",
        unknownUserPlaceholderUnknown: String = "未知用户",
        unknownUserPlaceholderDeactivated: String = "该账号已注销",
        unknownUserPlaceholderBlocked: String = "该账号已被屏蔽",
        unknownUserPlaceholderUnreachable: String = "暂时无法联系该账号",
        unknownUserPlaceholderId: String = "ID",
        newFriendRequestsEmpty: String = "没有新的好友请求",
        newFriendRequestsAccept: String = "接受",
        newFriendRequestsPending: String = "等待验证",
        newFriendRequestsWithdraw: String = "撤回",
        unknownMessageHint: String = "当前版本无法显示这条消息",
        unknownMessageUnsupported: String = "不支持的消息类型",
        unknownMessageDiagnostic: String = "消息类型",
        conversationRowDraft: String = "[草稿] ",
        conversationRowMention: String = "[@我] ",
        messageListEmpty: String = "还没有消息",
        messageListLoadOlder: String = "加载更早消息",
        messageRecalledSelf: String = "你撤回了一条消息",
        messageRecalledPeer: String = "对方撤回了一条消息",
        messageRecalledGroupOther: @escaping @Sendable (String) -> String = { "\($0) 撤回了一条消息" },
        messageQuoteLabel: @escaping @Sendable (String, String) -> String = { $0.isEmpty ? "引用：\($1)" : "引用 \($0)：\($1)" },
        jumpedToMessage: @escaping @Sendable (String, String) -> String = { "已跳转到 \($0) 的消息：\($1)" },
        conversationHeaderIdentityLabel: @escaping @Sendable (String, String) -> String = { "\($0)，\($1)" },
        yesterday: String = "昨天",
        startConversationSearchPlaceholder: String = "搜索联系人",
        groupDetailTitle: String = "群资料",
        groupDetailUnavailable: String = "无法加载群资料",
        groupDetailUnavailableHint: String = "请检查网络连接后重试。",
        groupDetailMemberCountSuffix: String = "位成员",
        groupDetailNotSet: String = "未设置",
        groupDetailSettingUnavailable: String = "暂时无法读取",   // Unavailable right now
        groupDetailSectionInfo: String = "群信息",
        groupDetailSectionMyInGroup: String = "我在本群",
        groupDetailSectionManage: String = "群管理",
        groupDetailSectionPerms: String = "群权限",
        groupDetailGroupName: String = "群名称",
        groupDetailAnnouncementEmpty: String = "暂无群公告",
        groupDetailMyNickname: String = "我的群昵称",
        groupDetailMuteNotif: String = "消息免打扰",
        groupDetailPinGroup: String = "置顶该群",
        groupDetailJoinMode: String = "进群方式",
        groupDetailJoinRequests: String = "入群申请",
        groupDetailMuteAll: String = "全员禁言",
        groupDetailInviteLink: String = "群邀请链接",
        groupDetailOnlyAdminAtAll: String = "仅管理员可@全体成员",
        groupDetailOnlyAdminPin: String = "仅管理员可置顶消息",
        groupDetailShareCard: String = "允许分享群名片",
        groupDetailJoinOpen: String = "允许任何人加入",
        groupDetailJoinApproval: String = "需管理员审批",
        groupDetailJoinInvite: String = "仅邀请加入",
        groupDetailEditName: String = "修改群名称",
        groupDetailEditAnnouncement: String = "编辑群公告",
        groupDetailNicknamePlaceholder: String = "群内显示名",
        groupDetailMemberManage: String = "成员管理",
        groupDetailSetAdmin: String = "设为管理员",
        groupDetailUnsetAdmin: String = "取消管理员",
        groupDetailMute: String = "禁言",
        groupDetailUnmute: String = "取消禁言",
        groupDetailTransferOwner: String = "转让群主",
        groupDetailTransferConfirm: String = "确定把群主转让给「%@」吗？转让后你将变为普通成员，此操作不可撤销。",
        groupDetailRemoveMember: String = "移出群聊",
        groupDetailNoRequests: String = "暂无入群申请",
        groupDetailRequestDefaultMessage: String = "申请加入群聊",
        groupDetailApprove: String = "通过",
        groupDetailInvite: String = "邀请成员",
        groupDetailInviteEmpty: String = "暂无可邀请的联系人",
        groupDetailInviteLinkHint: String = "将邀请码分享给好友，即可加入本群。",
        groupDetailInviteCodeTitle: String = "邀请码",
        groupDetailCopyCode: String = "复制邀请码",
        groupDetailCopied: String = "已复制",
        groupDetailCannotGenerate: String = "无法生成邀请链接",
        groupDetailLeave: String = "退出群聊",
        groupDetailDissolve: String = "解散群聊",
        groupDetailSave: String = "保存",
        groupDetailDone: String = "完成",
        momentAudienceSheetPublic: String = "公开",
        momentAudienceSheetPublicHint: String = "所有人可见",
        momentAudienceSheetFriends: String = "朋友可见",
        momentAudienceSheetFriendsHint: String = "你的好友可见",
        momentAudienceSheetPrivate: String = "私密",
        momentAudienceSheetPrivateHint: String = "仅自己可见",
        momentAudienceSheetInclude: String = "部分可见",
        momentAudienceSheetIncludeHint: String = "仅选中的朋友可见",
        momentAudienceSheetExclude: String = "不给谁看",
        momentAudienceSheetExcludeHint: String = "选中的朋友看不到",
        momentAudienceSheetPick: String = "选择朋友",
        momentAudienceSheetDone: String = "完成",
        momentAudienceSheetSelected: @escaping @Sendable (Int) -> String = { "已选 \($0) 人" },
        momentsVisibilityRuleListHideFromTitle: String = "不让他看我的朋友圈",
        momentsVisibilityRuleListHideFromHint: String = "名单中的人看不到你发的内容",
        momentsVisibilityRuleListMuteTitle: String = "不看他的朋友圈",
        momentsVisibilityRuleListMuteHint: String = "你不会看到名单中的人发的内容",
        momentsVisibilityRuleListEmpty: String = "名单为空",
        momentsVisibilityRuleListRemove: String = "移出",
        contactMatchListAdd: String = "添加",
        contactMatchListEmpty: String = "通讯录里还没有已注册的联系人",
        announcementReadBarConfirmRead: String = "已读",
        announcementReadBarViewUnread: String = "查看未读",
        announcementReadBarReadCount: @escaping @Sendable (Int, Int) -> String = { "\($0)/\($1) 人已读" },
        contactDetailInfo: String = "资料",
        contactDetailFlareId: String = "Flare ID",
        contactDetailRemark: String = "备注",
        contactDetailDescription: String = "描述",
        contactDetailStar: String = "星标好友",
        contactDetailNotSet: String = "未设置",
        contactDetailVoice: String = "语音通话",
        contactDetailVideo: String = "视频通话",
        contactDetailBlock: String = "加入黑名单",
        contactDetailRemove: String = "删除好友",
        conversationDetailsMessages: String = "消息",
        conversationDetailsMute: String = "免打扰",
        conversationDetailsPin: String = "置顶会话",
        conversationDetailsMarkRead: String = "标为已读",
        conversationDetailsMarkUnread: String = "标为未读",
        conversationDetailsSync: String = "同步会话",
        conversationDetailsArchive: String = "归档会话",
        conversationDetailsUnarchive: String = "取消归档",
        conversationDetailsClearHistory: String = "清空聊天记录",
        conversationDetailsDelete: String = "删除会话",
        profileEditorNickname: String = "昵称",
        profileEditorNicknamePlaceholder: String = "昵称",
        profileEditorBio: String = "个性签名",
        profileEditorBioPlaceholder: String = "介绍一下自己吧",
        profileEditorSave: String = "保存",
        composerEmoji: String = "表情",
        composerMention: String = "提及",
        composerVoice: String = "语音",
        composerImage: String = "图片",
        composerRichText: String = "富文本",
        composerMore: String = "更多功能",
        composerExpandInput: String = "放大输入框",
        composerCollapseInput: String = "缩小输入框",
        composerFormatBold: String = "加粗",
        composerFormatItalic: String = "斜体",
        composerFormatStrike: String = "删除线",
        composerFormatCode: String = "代码",
        composerFormatLink: String = "链接",
        composerFormatHeading: String = "标题",
        composerFormatQuote: String = "引用",
        composerFormatBullet: String = "无序列表",
        composerFormatOrdered: String = "有序列表",
        inlineVoiceComposerKeyboard: String = "返回键盘并删除录音",
        inlineVoiceComposerPause: String = "暂停录音",
        inlineVoiceComposerStart: String = "开始录音",
        inlineVoiceComposerPreview: String = "试听 / 暂停",
        inlineVoiceComposerResume: String = "继续录音",
        inlineVoiceComposerDiscard: String = "删除录音",
        inlineVoiceComposerMicDenied: String = "请允许使用麦克风后再录音",
        inlineVoiceComposerSendFailed: String = "发送失败，请重试",
        cancelRecording: String = "取消录音",
        sendVoice: String = "发送语音",
        pause: String = "暂停",
        download: String = "下载",
        imagePreviewClose: String = "关闭预览",
        imagePreviewPrevious: String = "上一张",
        imagePreviewNext: String = "下一张",
        imagePreviewPosition: @escaping @Sendable (Int, Int) -> String = { "第 \($0) 张，共 \($1) 张" },
        exitMultiSelect: String = "退出多选",
        scrollToLatest: String = "回到最新消息",
        callMinimize: String = "收起通话",
        callDeviceOn: String = "已开启",
        callDeviceOff: String = "已关闭",
        callReturn: String = "返回通话",
        conversationHeaderAddActions: String = "添加会话操作",
        conversationHeaderMoreActions: String = "更多会话操作",
        messageImage: String = "图片",
        messageVideo: String = "视频",
        messageVoice: String = "语音消息",
        voiceSeconds: @escaping @Sendable (Int) -> String = { "\($0) 秒" },
        voicePlaybackFailed: String = "播放失败",
        imageLoadFailed: String = "图片加载失败",
        videoLoadFailed: String = "视频加载失败",
        announcementBannerDismiss: String = "关闭公告",
        removeImage: String = "移除图片",
        momentActions: String = "动态操作",
        momentsVisibilityRuleListAdd: String = "添加到名单",
        myQrCode: String = "我的二维码",
        rating: String = "评分",
        ratingStar: @escaping @Sendable (Int) -> String = { "\($0) 星" },
        conversationHeaderSearch: String = "搜索消息",
        conversationHeaderAudioCall: String = "发起语音通话",
        conversationHeaderVideoCall: String = "发起视频通话",
        conversationHeaderAddMember: String = "添加成员",
        conversationHeaderShare: String = "分享会话",
        conversationHeaderDetails: String = "会话详情",
        presenceOnline: String = "在线",
        presenceOffline: String = "离线",
        presenceBusy: String = "忙碌",
        presenceAway: String = "离开",
        connectionConnecting: String = "正在连接…",
        connectionReconnecting: String = "连接已断开，正在重连…",
        connectionOffline: String = "网络不可用，恢复后会自动重连",
        connectionDisconnected: String = "连接已断开",
        connectionDisconnectedReason: @escaping @Sendable (String) -> String = { "连接已断开：\($0)" },
        connectionKicked: String = "账号已在其他设备登录",
        connectionExpired: String = "登录已过期",
        connectionReconnect: String = "重新连接",
        connectionSignIn: String = "重新登录",
        groupDetailMembersTitle: @escaping @Sendable (Int) -> String = { "群成员（\($0)）" },
        groupDetailSearchMembers: String = "搜索群成员",
        groupDetailNoMatchingMembers: String = "没有匹配的群成员",
        profilePanelEditProfile: @escaping @Sendable (String) -> String = { "\($0)，编辑资料" },
        momentReplyToComment: @escaping @Sendable (String, String) -> String = { "回复 \($0)：\($1)" },
        previewMessage: String = "[消息]",
        previewRichText: String = "[富文本]",
        previewGif: String = "[动图]",
        previewImage: String = "[图片]",
        previewImageNamed: @escaping @Sendable (String) -> String = { "[图片] \($0)" },
        previewVideo: String = "[视频]",
        previewAudio: String = "[语音]",
        previewFile: String = "[文件]",
        previewFileNamed: @escaping @Sendable (String) -> String = { "[文件] \($0)" },
        previewLocation: String = "[位置]",
        previewLocationNamed: @escaping @Sendable (String) -> String = { "[位置] \($0)" },
        previewCard: String = "[名片]",
        previewCardNamed: @escaping @Sendable (String) -> String = { "[名片] \($0)" },
        previewSticker: String = "[贴纸]",
        previewEmoji: String = "[表情]",
        previewQuote: String = "[引用]",
        previewLink: String = "[链接]",
        previewForward: String = "[转发]",
        previewForwardCount: @escaping @Sendable (Int) -> String = { "[转发] \($0) 条消息" },
        previewThread: String = "[话题]",
        previewMiniProgram: String = "[小程序]",
        previewImageGroup: String = "[多图]",
        previewImageGroupCount: @escaping @Sendable (Int) -> String = { "[多图] \($0) 张" },
        previewSystem: String = "[系统消息]",
        previewNotification: String = "[通知]",
        previewVote: String = "[投票]",
        previewTask: String = "[任务]",
        previewSchedule: String = "[日程]",
        previewAnnouncement: String = "[公告]",
        previewCustom: String = "[自定义]",
        previewPlaceholder: String = "[占位]",
        previewUnknown: String = "[未知]"
    ) {
        self.microphone = microphone
        self.camera = camera
        self.flipCamera = flipCamera
        self.speaker = speaker
        self.hangUp = hangUp
        self.muted = muted
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
        self.messagePending = messagePending
        self.messageSending = messageSending
        self.messageSent = messageSent
        self.messageDelivered = messageDelivered
        self.messageRead = messageRead
        self.messageFailed = messageFailed
        self.messageRetrying = messageRetrying
        self.messageEdited = messageEdited
        self.messageReadOnce = messageReadOnce
        self.messageBurnAfterRead = messageBurnAfterRead
        self.messageExpired = messageExpired
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
        self.messageBatchPin = messageBatchPin
        self.messageBatchPinSelf = messageBatchPinSelf
        self.messageBatchClear = messageBatchClear
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
        self.qrCardUnavailable = qrCardUnavailable
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
        self.momentReplyTo = momentReplyTo
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
        self.navChats = navChats; self.navContacts = navContacts; self.navProfile = navProfile
        self.navFriends = navFriends; self.navGroups = navGroups; self.navNewFriends = navNewFriends
        self.favorites = favorites
        self.moments = moments
        self.settings = settings
        self.themeSystem = themeSystem; self.themeLight = themeLight; self.themeDark = themeDark
        self.inputReveal = inputReveal; self.inputHide = inputHide
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
        self.resend = resend
        self.groupPermissionMatrixTitle = groupPermissionMatrixTitle
        self.groupPermissionMatrixReadOnlyHint = groupPermissionMatrixReadOnlyHint
        self.groupPermissionMatrixJoinPolicy = groupPermissionMatrixJoinPolicy
        self.groupPermissionMatrixJoinPolicyDescription = groupPermissionMatrixJoinPolicyDescription
        self.groupPermissionMatrixJoinInvite = groupPermissionMatrixJoinInvite
        self.groupPermissionMatrixJoinApproval = groupPermissionMatrixJoinApproval
        self.groupPermissionMatrixJoinOpen = groupPermissionMatrixJoinOpen
        self.groupPermissionMatrixUnknownJoinPolicy = groupPermissionMatrixUnknownJoinPolicy
        self.groupPermissionMatrixMuteAll = groupPermissionMatrixMuteAll
        self.groupPermissionMatrixMuteAllDescription = groupPermissionMatrixMuteAllDescription
        self.groupPermissionMatrixOnlyAdminCanAtAll = groupPermissionMatrixOnlyAdminCanAtAll
        self.groupPermissionMatrixOnlyAdminCanAtAllDescription = groupPermissionMatrixOnlyAdminCanAtAllDescription
        self.groupPermissionMatrixOnlyAdminCanPin = groupPermissionMatrixOnlyAdminCanPin
        self.groupPermissionMatrixOnlyAdminCanPinDescription = groupPermissionMatrixOnlyAdminCanPinDescription
        self.groupPermissionMatrixShareCardPermission = groupPermissionMatrixShareCardPermission
        self.groupPermissionMatrixShareCardPermissionDescription = groupPermissionMatrixShareCardPermissionDescription
        self.groupPermissionMatrixOn = groupPermissionMatrixOn
        self.groupPermissionMatrixOff = groupPermissionMatrixOff
        self.groupPermissionMatrixBusy = groupPermissionMatrixBusy
        self.groupPermissionMatrixDismissError = groupPermissionMatrixDismissError
        self.conversationBatchToolbarSelected = conversationBatchToolbarSelected
        self.conversationBatchToolbarEmpty = conversationBatchToolbarEmpty
        self.conversationBatchToolbarMarkRead = conversationBatchToolbarMarkRead
        self.conversationBatchToolbarMute = conversationBatchToolbarMute
        self.conversationBatchToolbarArchive = conversationBatchToolbarArchive
        self.conversationBatchToolbarCancel = conversationBatchToolbarCancel
        self.conversationBatchToolbarBusy = conversationBatchToolbarBusy
        self.conversationBatchToolbarSucceededSummary = conversationBatchToolbarSucceededSummary
        self.conversationBatchToolbarFailedSummary = conversationBatchToolbarFailedSummary
        self.conversationBatchToolbarRetryFailed = conversationBatchToolbarRetryFailed
        self.conversationBatchToolbarDismiss = conversationBatchToolbarDismiss
        self.conversationBatchToolbarExpand = conversationBatchToolbarExpand
        self.conversationBatchToolbarMaxSelection = conversationBatchToolbarMaxSelection
        self.storageUsageTitle = storageUsageTitle
        self.storageUsageUnknownSize = storageUsageUnknownSize
        self.storageUsageAtLeast = storageUsageAtLeast
        self.storageUsageClear = storageUsageClear
        self.storageUsageClearing = storageUsageClearing
        self.storageUsageTotal = storageUsageTotal
        self.storageUsageDeviceFree = storageUsageDeviceFree
        self.storageUsageReload = storageUsageReload
        self.storageUsageRetry = storageUsageRetry
        self.storageUsageDismissError = storageUsageDismissError
        self.storageUsageLoading = storageUsageLoading
        self.storageUsageEmpty = storageUsageEmpty
        self.storageUsageFileCount = storageUsageFileCount
        self.memberRoleSheetMemberRole = memberRoleSheetMemberRole
        self.memberRoleSheetMuted = memberRoleSheetMuted
        self.memberRoleSheetPromote = memberRoleSheetPromote
        self.memberRoleSheetDemote = memberRoleSheetDemote
        self.memberRoleSheetMute = memberRoleSheetMute
        self.memberRoleSheetUnmute = memberRoleSheetUnmute
        self.memberRoleSheetRemove = memberRoleSheetRemove
        self.memberRoleSheetTransferOwner = memberRoleSheetTransferOwner
        self.memberRoleSheetDangerGroup = memberRoleSheetDangerGroup
        self.memberRoleSheetEmpty = memberRoleSheetEmpty
        self.memberRoleSheetOwnerProtected = memberRoleSheetOwnerProtected
        self.relationActionBarAdd = relationActionBarAdd
        self.relationActionBarAccept = relationActionBarAccept
        self.relationActionBarRemove = relationActionBarRemove
        self.relationActionBarBlock = relationActionBarBlock
        self.relationActionBarUnblock = relationActionBarUnblock
        self.relationActionBarPending = relationActionBarPending
        self.relationActionBarBusy = relationActionBarBusy
        self.relationActionBarDismissError = relationActionBarDismissError
        self.relationActionBarEmpty = relationActionBarEmpty
        self.screenShareTitle = screenShareTitle
        self.screenShareIdle = screenShareIdle
        self.screenShareRequesting = screenShareRequesting
        self.screenShareSharing = screenShareSharing
        self.screenShareViewing = screenShareViewing
        self.screenShareUnavailable = screenShareUnavailable
        self.screenShareSourceRow = screenShareSourceRow
        self.screenSharePresenterRow = screenSharePresenterRow
        self.screenShareStart = screenShareStart
        self.screenShareStop = screenShareStop
        self.screenShareCancel = screenShareCancel
        self.conversationActionSheetPin = conversationActionSheetPin
        self.conversationActionSheetUnpin = conversationActionSheetUnpin
        self.conversationActionSheetMute = conversationActionSheetMute
        self.conversationActionSheetUnmute = conversationActionSheetUnmute
        self.conversationActionSheetMarkRead = conversationActionSheetMarkRead
        self.conversationActionSheetMarkUnread = conversationActionSheetMarkUnread
        self.conversationActionSheetArchive = conversationActionSheetArchive
        self.conversationActionSheetUnarchive = conversationActionSheetUnarchive
        self.conversationActionSheetHide = conversationActionSheetHide
        self.conversationActionSheetClearHistory = conversationActionSheetClearHistory
        self.conversationActionSheetEmpty = conversationActionSheetEmpty
        self.messageActionSheetLabel = messageActionSheetLabel
        self.messageActionSheetEmpty = messageActionSheetEmpty
        self.messageSpoilerReveal = messageSpoilerReveal
        self.messageImageGroupLabel = messageImageGroupLabel
        self.messageImageGroupItem = messageImageGroupItem
        self.messageImageGroupItemMore = messageImageGroupItemMore
        self.messageActionReply = messageActionReply
        self.messageActionForward = messageActionForward
        self.messageActionRecall = messageActionRecall
        self.messageActionResend = messageActionResend
        self.messageActionMultiSelect = messageActionMultiSelect
        self.messageActionMark = messageActionMark
        self.messageActionPin = messageActionPin
        self.messageActionPinSelf = messageActionPinSelf
        self.messageActionUnpin = messageActionUnpin
        self.messageActionCopy = messageActionCopy
        self.messageActionPreview = messageActionPreview
        self.messageActionSave = messageActionSave
        self.messageActionEdit = messageActionEdit
        self.messageActionDelete = messageActionDelete
        self.workspaceFrameLoading = workspaceFrameLoading
        self.workspaceFrameEmpty = workspaceFrameEmpty
        self.workspaceFrameFailure = workspaceFrameFailure
        self.workspaceFrameRetry = workspaceFrameRetry
        self.conversationWorkspaceChatEmpty = conversationWorkspaceChatEmpty
        self.conversationWorkspaceDetailEmpty = conversationWorkspaceDetailEmpty
        self.conversationWorkspaceListFailure = conversationWorkspaceListFailure
        self.conversationWorkspaceChatFailure = conversationWorkspaceChatFailure
        self.conversationWorkspaceDetailFailure = conversationWorkspaceDetailFailure
        self.conversationWorkspaceListLoading = conversationWorkspaceListLoading
        self.conversationWorkspaceChatLoading = conversationWorkspaceChatLoading
        self.conversationWorkspaceDetailLoading = conversationWorkspaceDetailLoading
        self.searchDateRangeFilterCustom = searchDateRangeFilterCustom
        self.searchDateRangeFilterFrom = searchDateRangeFilterFrom
        self.searchDateRangeFilterTo = searchDateRangeFilterTo
        self.searchDateRangeFilterUnlimited = searchDateRangeFilterUnlimited
        self.searchDateRangeFilterInvalid = searchDateRangeFilterInvalid
        self.composerPlaceholder = composerPlaceholder
        self.composerReply = composerReply
        self.voiceHoldButtonLabel = voiceHoldButtonLabel
        self.voiceHoldButtonRecording = voiceHoldButtonRecording
        self.unknownUserPlaceholderUnknown = unknownUserPlaceholderUnknown
        self.unknownUserPlaceholderDeactivated = unknownUserPlaceholderDeactivated
        self.unknownUserPlaceholderBlocked = unknownUserPlaceholderBlocked
        self.unknownUserPlaceholderUnreachable = unknownUserPlaceholderUnreachable
        self.unknownUserPlaceholderId = unknownUserPlaceholderId
        self.newFriendRequestsEmpty = newFriendRequestsEmpty
        self.newFriendRequestsAccept = newFriendRequestsAccept
        self.newFriendRequestsPending = newFriendRequestsPending
        self.newFriendRequestsWithdraw = newFriendRequestsWithdraw
        self.unknownMessageHint = unknownMessageHint
        self.unknownMessageUnsupported = unknownMessageUnsupported
        self.unknownMessageDiagnostic = unknownMessageDiagnostic
        self.conversationRowDraft = conversationRowDraft
        self.conversationRowMention = conversationRowMention
        self.messageListEmpty = messageListEmpty
        self.messageListLoadOlder = messageListLoadOlder
        self.messageRecalledSelf = messageRecalledSelf
        self.messageRecalledPeer = messageRecalledPeer
        self.messageRecalledGroupOther = messageRecalledGroupOther
        self.messageQuoteLabel = messageQuoteLabel
        self.jumpedToMessage = jumpedToMessage
        self.conversationHeaderIdentityLabel = conversationHeaderIdentityLabel
        self.yesterday = yesterday
        self.startConversationSearchPlaceholder = startConversationSearchPlaceholder
        self.groupDetailTitle = groupDetailTitle
        self.groupDetailUnavailable = groupDetailUnavailable
        self.groupDetailUnavailableHint = groupDetailUnavailableHint
        self.groupDetailMemberCountSuffix = groupDetailMemberCountSuffix
        self.groupDetailNotSet = groupDetailNotSet
        self.groupDetailSettingUnavailable = groupDetailSettingUnavailable
        self.groupDetailSectionInfo = groupDetailSectionInfo
        self.groupDetailSectionMyInGroup = groupDetailSectionMyInGroup
        self.groupDetailSectionManage = groupDetailSectionManage
        self.groupDetailSectionPerms = groupDetailSectionPerms
        self.groupDetailGroupName = groupDetailGroupName
        self.groupDetailAnnouncementEmpty = groupDetailAnnouncementEmpty
        self.groupDetailMyNickname = groupDetailMyNickname
        self.groupDetailMuteNotif = groupDetailMuteNotif
        self.groupDetailPinGroup = groupDetailPinGroup
        self.groupDetailJoinMode = groupDetailJoinMode
        self.groupDetailJoinRequests = groupDetailJoinRequests
        self.groupDetailMuteAll = groupDetailMuteAll
        self.groupDetailInviteLink = groupDetailInviteLink
        self.groupDetailOnlyAdminAtAll = groupDetailOnlyAdminAtAll
        self.groupDetailOnlyAdminPin = groupDetailOnlyAdminPin
        self.groupDetailShareCard = groupDetailShareCard
        self.groupDetailJoinOpen = groupDetailJoinOpen
        self.groupDetailJoinApproval = groupDetailJoinApproval
        self.groupDetailJoinInvite = groupDetailJoinInvite
        self.groupDetailEditName = groupDetailEditName
        self.groupDetailEditAnnouncement = groupDetailEditAnnouncement
        self.groupDetailNicknamePlaceholder = groupDetailNicknamePlaceholder
        self.groupDetailMemberManage = groupDetailMemberManage
        self.groupDetailSetAdmin = groupDetailSetAdmin
        self.groupDetailUnsetAdmin = groupDetailUnsetAdmin
        self.groupDetailMute = groupDetailMute
        self.groupDetailUnmute = groupDetailUnmute
        self.groupDetailTransferOwner = groupDetailTransferOwner
        self.groupDetailTransferConfirm = groupDetailTransferConfirm
        self.groupDetailRemoveMember = groupDetailRemoveMember
        self.groupDetailNoRequests = groupDetailNoRequests
        self.groupDetailRequestDefaultMessage = groupDetailRequestDefaultMessage
        self.groupDetailApprove = groupDetailApprove
        self.groupDetailInvite = groupDetailInvite
        self.groupDetailInviteEmpty = groupDetailInviteEmpty
        self.groupDetailInviteLinkHint = groupDetailInviteLinkHint
        self.groupDetailInviteCodeTitle = groupDetailInviteCodeTitle
        self.groupDetailCopyCode = groupDetailCopyCode
        self.groupDetailCopied = groupDetailCopied
        self.groupDetailCannotGenerate = groupDetailCannotGenerate
        self.groupDetailLeave = groupDetailLeave
        self.groupDetailDissolve = groupDetailDissolve
        self.groupDetailSave = groupDetailSave
        self.groupDetailDone = groupDetailDone
        self.momentAudienceSheetPublic = momentAudienceSheetPublic
        self.momentAudienceSheetPublicHint = momentAudienceSheetPublicHint
        self.momentAudienceSheetFriends = momentAudienceSheetFriends
        self.momentAudienceSheetFriendsHint = momentAudienceSheetFriendsHint
        self.momentAudienceSheetPrivate = momentAudienceSheetPrivate
        self.momentAudienceSheetPrivateHint = momentAudienceSheetPrivateHint
        self.momentAudienceSheetInclude = momentAudienceSheetInclude
        self.momentAudienceSheetIncludeHint = momentAudienceSheetIncludeHint
        self.momentAudienceSheetExclude = momentAudienceSheetExclude
        self.momentAudienceSheetExcludeHint = momentAudienceSheetExcludeHint
        self.momentAudienceSheetPick = momentAudienceSheetPick
        self.momentAudienceSheetDone = momentAudienceSheetDone
        self.momentAudienceSheetSelected = momentAudienceSheetSelected
        self.momentsVisibilityRuleListHideFromTitle = momentsVisibilityRuleListHideFromTitle
        self.momentsVisibilityRuleListHideFromHint = momentsVisibilityRuleListHideFromHint
        self.momentsVisibilityRuleListMuteTitle = momentsVisibilityRuleListMuteTitle
        self.momentsVisibilityRuleListMuteHint = momentsVisibilityRuleListMuteHint
        self.momentsVisibilityRuleListEmpty = momentsVisibilityRuleListEmpty
        self.momentsVisibilityRuleListRemove = momentsVisibilityRuleListRemove
        self.contactMatchListAdd = contactMatchListAdd
        self.contactMatchListEmpty = contactMatchListEmpty
        self.announcementReadBarConfirmRead = announcementReadBarConfirmRead
        self.announcementReadBarViewUnread = announcementReadBarViewUnread
        self.announcementReadBarReadCount = announcementReadBarReadCount
        self.contactDetailInfo = contactDetailInfo
        self.contactDetailFlareId = contactDetailFlareId
        self.contactDetailRemark = contactDetailRemark
        self.contactDetailDescription = contactDetailDescription
        self.contactDetailStar = contactDetailStar
        self.contactDetailNotSet = contactDetailNotSet
        self.contactDetailVoice = contactDetailVoice
        self.contactDetailVideo = contactDetailVideo
        self.contactDetailBlock = contactDetailBlock
        self.contactDetailRemove = contactDetailRemove
        self.conversationDetailsMessages = conversationDetailsMessages
        self.conversationDetailsMute = conversationDetailsMute
        self.conversationDetailsPin = conversationDetailsPin
        self.conversationDetailsMarkRead = conversationDetailsMarkRead
        self.conversationDetailsMarkUnread = conversationDetailsMarkUnread
        self.conversationDetailsSync = conversationDetailsSync
        self.conversationDetailsArchive = conversationDetailsArchive
        self.conversationDetailsUnarchive = conversationDetailsUnarchive
        self.conversationDetailsClearHistory = conversationDetailsClearHistory
        self.conversationDetailsDelete = conversationDetailsDelete
        self.profileEditorNickname = profileEditorNickname
        self.profileEditorNicknamePlaceholder = profileEditorNicknamePlaceholder
        self.profileEditorBio = profileEditorBio
        self.profileEditorBioPlaceholder = profileEditorBioPlaceholder
        self.profileEditorSave = profileEditorSave
        self.composerEmoji = composerEmoji
        self.composerMention = composerMention
        self.composerVoice = composerVoice
        self.composerImage = composerImage
        self.composerRichText = composerRichText
        self.composerMore = composerMore
        self.composerExpandInput = composerExpandInput
        self.composerCollapseInput = composerCollapseInput
        self.composerFormatBold = composerFormatBold
        self.composerFormatItalic = composerFormatItalic
        self.composerFormatStrike = composerFormatStrike
        self.composerFormatCode = composerFormatCode
        self.composerFormatLink = composerFormatLink
        self.composerFormatHeading = composerFormatHeading
        self.composerFormatQuote = composerFormatQuote
        self.composerFormatBullet = composerFormatBullet
        self.composerFormatOrdered = composerFormatOrdered
        self.inlineVoiceComposerKeyboard = inlineVoiceComposerKeyboard
        self.inlineVoiceComposerPause = inlineVoiceComposerPause
        self.inlineVoiceComposerStart = inlineVoiceComposerStart
        self.inlineVoiceComposerPreview = inlineVoiceComposerPreview
        self.inlineVoiceComposerResume = inlineVoiceComposerResume
        self.inlineVoiceComposerDiscard = inlineVoiceComposerDiscard
        self.inlineVoiceComposerMicDenied = inlineVoiceComposerMicDenied
        self.inlineVoiceComposerSendFailed = inlineVoiceComposerSendFailed
        self.cancelRecording = cancelRecording
        self.sendVoice = sendVoice
        self.pause = pause
        self.download = download
        self.imagePreviewClose = imagePreviewClose
        self.imagePreviewPrevious = imagePreviewPrevious
        self.imagePreviewNext = imagePreviewNext
        self.imagePreviewPosition = imagePreviewPosition
        self.exitMultiSelect = exitMultiSelect
        self.scrollToLatest = scrollToLatest
        self.callMinimize = callMinimize
        self.callDeviceOn = callDeviceOn
        self.callDeviceOff = callDeviceOff
        self.callReturn = callReturn
        self.conversationHeaderAddActions = conversationHeaderAddActions
        self.conversationHeaderMoreActions = conversationHeaderMoreActions
        self.messageImage = messageImage
        self.messageVideo = messageVideo
        self.messageVoice = messageVoice
        self.voiceSeconds = voiceSeconds
        self.voicePlaybackFailed = voicePlaybackFailed
        self.imageLoadFailed = imageLoadFailed
        self.videoLoadFailed = videoLoadFailed
        self.announcementBannerDismiss = announcementBannerDismiss
        self.removeImage = removeImage
        self.momentActions = momentActions
        self.momentsVisibilityRuleListAdd = momentsVisibilityRuleListAdd
        self.myQrCode = myQrCode
        self.rating = rating
        self.ratingStar = ratingStar
        self.conversationHeaderSearch = conversationHeaderSearch
        self.conversationHeaderAudioCall = conversationHeaderAudioCall
        self.conversationHeaderVideoCall = conversationHeaderVideoCall
        self.conversationHeaderAddMember = conversationHeaderAddMember
        self.conversationHeaderShare = conversationHeaderShare
        self.conversationHeaderDetails = conversationHeaderDetails
        self.presenceOnline = presenceOnline
        self.presenceOffline = presenceOffline
        self.presenceBusy = presenceBusy
        self.presenceAway = presenceAway
        self.connectionConnecting = connectionConnecting
        self.connectionReconnecting = connectionReconnecting
        self.connectionOffline = connectionOffline
        self.connectionDisconnected = connectionDisconnected
        self.connectionDisconnectedReason = connectionDisconnectedReason
        self.connectionKicked = connectionKicked
        self.connectionExpired = connectionExpired
        self.connectionReconnect = connectionReconnect
        self.connectionSignIn = connectionSignIn
        self.groupDetailMembersTitle = groupDetailMembersTitle
        self.groupDetailSearchMembers = groupDetailSearchMembers
        self.groupDetailNoMatchingMembers = groupDetailNoMatchingMembers
        self.profilePanelEditProfile = profilePanelEditProfile
        self.momentReplyToComment = momentReplyToComment
        self.previewMessage = previewMessage
        self.previewRichText = previewRichText
        self.previewGif = previewGif
        self.previewImage = previewImage
        self.previewImageNamed = previewImageNamed
        self.previewVideo = previewVideo
        self.previewAudio = previewAudio
        self.previewFile = previewFile
        self.previewFileNamed = previewFileNamed
        self.previewLocation = previewLocation
        self.previewLocationNamed = previewLocationNamed
        self.previewCard = previewCard
        self.previewCardNamed = previewCardNamed
        self.previewSticker = previewSticker
        self.previewEmoji = previewEmoji
        self.previewQuote = previewQuote
        self.previewLink = previewLink
        self.previewForward = previewForward
        self.previewForwardCount = previewForwardCount
        self.previewThread = previewThread
        self.previewMiniProgram = previewMiniProgram
        self.previewImageGroup = previewImageGroup
        self.previewImageGroupCount = previewImageGroupCount
        self.previewSystem = previewSystem
        self.previewNotification = previewNotification
        self.previewVote = previewVote
        self.previewTask = previewTask
        self.previewSchedule = previewSchedule
        self.previewAnnouncement = previewAnnouncement
        self.previewCustom = previewCustom
        self.previewPlaceholder = previewPlaceholder
        self.previewUnknown = previewUnknown
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
