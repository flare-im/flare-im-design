export { default as FlareUiProvider } from "../design-system/provider/FlareUiProvider.vue";
export { default as FlareAvatar } from "./conversation/FlareAvatar.vue";
export type { FlarePresence } from "./conversation/FlareAvatar.vue";
export { default as FlareConversationList } from "./conversation/FlareConversationList.vue";
export { default as FlareConversationRow } from "./conversation/FlareConversationRow.vue";
export { default as FlareConversationDetails } from "./shell/ConversationDetails.vue";
export { default as FlareConversationHeader } from "./messages/ConversationHeader.vue";
export { default as FlareMessageBubble } from "./messages/MessageBubble.vue";
export { default as FlareMessageList } from "./messages/MessageList.vue";
export { default as FlareMessageContentView } from "./messages/MessageContentView.vue";
export { default as FlareMessageStatus } from "./messages/MessageStatus.vue";
export { default as FlareMessageMeta } from "./messages/MessageMeta.vue";
// Standalone, presentational per-type message bodies with no transport or media
// coupling. A host-driven dispatcher
// above (FlareMessageContentView) stays the batteries-included path.
export { default as FlareTextMessage } from "./messages/standalone/FlareTextMessage.vue";
export { default as FlareRichTextMessage } from "./messages/standalone/FlareRichTextMessage.vue";
export { default as FlareImageMessage } from "./messages/standalone/FlareImageMessage.vue";
export { default as FlareImageGroupMessage } from "./messages/standalone/FlareImageGroupMessage.vue";
export type { FlareImageGroupItem } from "./messages/standalone/FlareImageGroupMessage.vue";
export { default as FlareVideoMessage } from "./messages/standalone/FlareVideoMessage.vue";
export { default as FlareVoiceMessage } from "./messages/standalone/FlareVoiceMessage.vue";
export { default as FlareFileMessage } from "./messages/standalone/FlareFileMessage.vue";
export { default as FlareLocationMessage } from "./messages/standalone/FlareLocationMessage.vue";
export { default as FlareContactMessage } from "./messages/standalone/FlareContactMessage.vue";
export { default as FlareLinkCardMessage } from "./messages/standalone/FlareLinkCardMessage.vue";
export { default as FlareVoteMessage } from "./messages/standalone/FlareVoteMessage.vue";
export { default as FlareTaskMessage } from "./messages/standalone/FlareTaskMessage.vue";
export { default as FlareStickerMessage } from "./messages/standalone/FlareStickerMessage.vue";
export { default as FlareEmojiMessage } from "./messages/standalone/FlareEmojiMessage.vue";
export { default as FlareSystemMessage } from "./messages/standalone/FlareSystemMessage.vue";
export { default as FlarePinnedMessageBar } from "./messages/PinnedMessageBar.vue";
export { default as FlareImagePreview } from "./message-preview/ImagePreviewModal.vue";
export { default as FlareVideoPreview } from "./message-preview/VideoPlayerModal.vue";
export { default as FlareMarkdownPreview } from "./message-preview/MarkdownPreview.vue";
export { default as FlareComposer } from "./composer/EnhancedComposer.vue";
export type {
  FlareComposerAttachAction,
  FlareComposerActionTone,
  FlareComposerMentionCandidate,
  FlareComposerUploadPreview,
} from "./composer/EnhancedComposer.vue";
export { default as FlareEmojiStickerPicker } from "./composer/EmojiStickerPicker/index.vue";
export { default as FlareComposerRichInput } from "./composer/ComposerRichMarkdownInput.vue";
export { default as FlareMessageActionSheet } from "./messages/MessageActionSheet.vue";
export { default as FlareStartConversationDialog } from "./shell/FlareStartConversationDialog.vue";

// Phase C — general / contacts
export { default as FlareSearchBar } from "./general/FlareSearchBar.vue";
export { default as FlareInput } from "./general/FlareInput.vue";
export { default as FlareEmptyState } from "./general/FlareEmptyState.vue";
export { default as FlareStatusBanner } from "./general/FlareStatusBanner.vue";
export { default as FlareFilterTabs } from "./general/FlareFilterTabs.vue";
export type { FlareFilterTabOption } from "./general/FlareFilterTabs.vue";
export { default as FlareContactItem } from "./contacts/FlareContactItem.vue";
export { default as FlareContactList } from "./contacts/FlareContactList.vue";
export { default as FlareContactDetail } from "./contacts/FlareContactDetail.vue";
export { default as FlareNewFriendRequests } from "./contacts/FlareNewFriendRequests.vue";
export { default as FlareGroupList } from "./contacts/FlareGroupList.vue";
export { default as FlareProfilePanel } from "./profile/FlareProfilePanel.vue";
export { default as FlareProfileEditor } from "./profile/FlareProfileEditor.vue";
export { default as FlareSettingsList } from "./profile/FlareSettingsList.vue";
export { default as FlareSettingsRow } from "./profile/FlareSettingsRow.vue";
export { default as FlareCallView } from "./call/FlareCallView.vue";
export { default as FlareGroupCallView } from "./call/FlareGroupCallView.vue";
export { default as FlareIncomingCall } from "./call/FlareIncomingCall.vue";
export { default as FlareCallControls } from "./call/FlareCallControls.vue";
export { default as FlareTypingIndicator } from "./messages/FlareTypingIndicator.vue";
export { default as FlareUnreadDivider } from "./messages/FlareUnreadDivider.vue";
export { default as FlareScrollToLatest } from "./messages/FlareScrollToLatest.vue";
export { default as FlareProfileCard } from "./profile/FlareProfileCard.vue";
export { default as FlareGroupMemberGrid } from "./contacts/FlareGroupMemberGrid.vue";
export { default as FlareGroupDetail } from "./contacts/FlareGroupDetail.vue";

// Feishu-parity IM primitives (reactions, read receipts, mention, batch, search, skeleton, quick phrases)
export { default as FlareReactionSummary } from "./messages/FlareReactionSummary.vue";
export { default as FlareReadReceiptSheet } from "./messages/FlareReadReceiptSheet.vue";
export { default as FlareMessageBatchToolbar } from "./messages/FlareMessageBatchToolbar.vue";
export { default as FlareQuickPhrases } from "./composer/FlareQuickPhrases.vue";
export { default as FlareSearchResults } from "./general/FlareSearchResults.vue";
export { default as FlareSkeleton } from "./general/FlareSkeleton.vue";

export type { FlareReactionGroup } from "../shared/contracts";
export type { FlareMentionCandidate } from "../shared/contracts";
export type { FlareQuickPhrase, FlareQuickPhraseGroup } from "../shared/contracts";
export type {
  FlareSearchResultKind,
  FlareSearchResultItem,
  FlareSearchResultGroup,
} from "../shared/contracts";

// Batch 2 — forward picker, toast, minimized call dock, announcement banner, date pill
export { default as FlareForwardPicker } from "./conversation/FlareForwardPicker.vue";
export { default as FlareToast } from "./general/FlareToast.vue";
// FlareToastVariant 的真源是 shared/contracts/tone.ts（根入口从那里导出；
// 这里再导一次会让 `export *` 出现同名二义，TS2308）。
export { default as FlareCallDock } from "./call/FlareCallDock.vue";
export { default as FlareAnnouncementBanner } from "./messages/FlareAnnouncementBanner.vue";
export { default as FlareDatePill } from "./messages/FlareDatePill.vue";
export type { FlareForwardTarget } from "../shared/contracts";

// Batch 3 — red packet, slash-command menu, inline translation, QR name card
export { default as FlareRedPacketCard } from "./messages/FlareRedPacketCard.vue";
export { default as FlareTranslationView } from "./messages/FlareTranslationView.vue";
export { default as FlareSlashCommandMenu } from "./composer/FlareSlashCommandMenu.vue";
export { default as FlareQRCard } from "./profile/FlareQRCard.vue";
export { default as FlareMyInvitePanel } from "./profile/FlareMyInvitePanel.vue";
export type { FlareSlashCommand } from "../shared/contracts";

// Batch 4 — adaptive image grid, voice-recording bar, poll composer, wallpaper picker
export { default as FlareImageGrid } from "./messages/FlareImageGrid.vue";
export { default as FlareVoiceRecordingBar } from "./composer/FlareVoiceRecordingBar.vue";
export { default as FlarePollComposer } from "./composer/FlarePollComposer.vue";
export { default as FlareChatWallpaperPicker } from "./conversation/FlareChatWallpaperPicker.vue";
export type { FlareGridImage, FlareWallpaperOption } from "../shared/contracts";

// Batch 5 (deepen) — rich voice player, full emoji picker, categorized sticker panel
export { default as FlareVoicePlayer } from "./messages/FlareVoicePlayer.vue";
export { default as FlareEmojiPicker } from "./composer/FlareEmojiPicker.vue";
export { default as FlareStickerPanel } from "./composer/FlareStickerPanel.vue";
export type { FlareEmojiCategory, FlareStickerItem, FlareStickerPack } from "../shared/contracts";

export type { FlareCallMode, FlareCallState, FlareCallParticipant } from "../shared/contracts";
export { default as FlareResponsiveLayout } from "./layout/FlareResponsiveLayout.vue";
export { default as FlareScreenHeader } from "./layout/FlareScreenHeader.vue";
export { default as FlareScreen } from "./layout/FlareScreen.vue";
export { default as FlareAuthShell } from "./layout/FlareAuthShell.vue";

// General primitives surfaced by the example-app migration (button / segmented control)
export { default as FlareSegmentedControl } from "./general/FlareSegmentedControl.vue";

// Foundation — buttons + form controls
export { default as FlareButton } from "./general/FlareButton.vue";
export { default as FlareIconButton } from "./general/FlareIconButton.vue";
export { default as FlareIcon } from "./general/FlareIcon.vue";
export { default as FlareBrandLogo } from "./general/FlareBrandLogo.vue";
export { default as FlareBottomSheet } from "./general/FlareBottomSheet.vue";
export { default as FlareActionMenu } from "./general/FlareActionMenu.vue";
export type { FlareSheetPresentation } from "./general/FlareBottomSheet.vue";
export { flareIcons, flareIconNames, type FlareIconName } from "../shared/icons";
export { default as FlareFormField } from "./form/FlareFormField.vue";
export { default as FlareInviteCodeField } from "./form/FlareInviteCodeField.vue";
export { default as FlareSwitch } from "./form/FlareSwitch.vue";
export { default as FlareCheckbox } from "./form/FlareCheckbox.vue";
export { default as FlareRadioGroup } from "./form/FlareRadioGroup.vue";
export { default as FlareSelect } from "./form/FlareSelect.vue";
export { default as FlareTextarea } from "./form/FlareTextarea.vue";
export { default as FlareStepper } from "./form/FlareStepper.vue";
export { default as FlareSlider } from "./form/FlareSlider.vue";
export { default as FlareRating } from "./form/FlareRating.vue";
export { default as FlareTimePicker } from "./form/FlareTimePicker.vue";
export { default as FlareDatePicker } from "./form/FlareDatePicker.vue";
export type { FlareButtonVariant, FlareControlSize, FlareSelectOption } from "../shared/contracts";

// Moments (圈子) — social feed
export { default as FlareMomentCard } from "./moments/FlareMomentCard.vue";
export { default as FlareMomentComposer } from "./moments/FlareMomentComposer.vue";
export { default as FlareMomentActionPopover } from "./moments/FlareMomentActionPopover.vue";
export { default as FlareMomentsCoverHeader } from "./moments/FlareMomentsCoverHeader.vue";
export { default as FlareCommentThread } from "./moments/FlareCommentThread.vue";
export { default as FlareTopicChip } from "./moments/FlareTopicChip.vue";
export type {
  FlareMomentAuthor,
  FlareMomentLike,
  FlareMomentComment,
  FlareMoment,
} from "../shared/contracts";

// composer parts (freely composable)
export { default as FlareVoiceHoldButton } from "./composer/FlareVoiceHoldButton.vue";
export { default as FlareComposerActionPanel } from "./composer/FlareComposerActionPanel.vue";
export { default as FlareComposerSendButton } from "./composer/FlareComposerSendButton.vue";
export { default as FlareComposerReplyStrip } from "./composer/FlareComposerReplyStrip.vue";
export { default as FlareAnnouncementReadBar } from "./general/FlareAnnouncementReadBar.vue";
export { default as FlareContactMatchList } from "./contacts/FlareContactMatchList.vue";
export { default as FlareMomentAudienceSheet } from "./moments/FlareMomentAudienceSheet.vue";
export { default as FlareMomentsVisibilityRuleList } from "./moments/FlareMomentsVisibilityRuleList.vue";

export { default as FlareMentionPicker } from "./composer/FlareMentionPicker.vue";

export { default as FlareTransferProgress } from "./media/FlareTransferProgress.vue";

export { default as FlareSearchPanel } from './general/FlareSearchPanel.vue';
export { default as FlareRecentSearches } from './general/FlareRecentSearches.vue';
export { default as FlareCommandPalette } from './general/FlareCommandPalette.vue';
export type { FlareCommandPaletteCommand, FlareCommandPaletteGroup } from '../shared/contracts/command-palette';

export { default as FlareTransferQueue } from './media/FlareTransferQueue.vue';

export { default as FlareMemberPanel } from './scenes/FlareMemberPanel.vue';

export { default as FlareDeviceSessions } from './scenes/FlareDeviceSessions.vue';

export { default as FlareMediaCenter } from './scenes/FlareMediaCenter.vue';

export { default as FlareCapabilityBoundary } from './scenes/FlareCapabilityBoundary.vue';

export { default as FlareNotificationPreferences } from './scenes/FlareNotificationPreferences.vue';

export { default as FlareDangerConfirm } from './scenes/FlareDangerConfirm.vue';

export { default as FlareCallDevicePicker } from "./call/FlareCallDevicePicker.vue";

export { default as FlarePermissionPrompt } from "./general/FlarePermissionPrompt.vue";
export { default as FlareConversationActionSheet } from "./conversation/FlareConversationActionSheet.vue";
export { default as FlareConversationBatchToolbar } from "./conversation/FlareConversationBatchToolbar.vue";

export { default as FlareUnknownMessage } from "./messages/FlareUnknownMessage.vue";

export { default as FlareSearchDateRangeFilter } from './general/FlareSearchDateRangeFilter.vue';
export { default as FlareUnknownUserPlaceholder } from "./contacts/FlareUnknownUserPlaceholder.vue";
export { default as FlareRelationActionBar } from "./contacts/FlareRelationActionBar.vue";
export { default as FlareGroupPermissionMatrix } from "./contacts/FlareGroupPermissionMatrix.vue";
export { default as FlareMemberRoleSheet } from "./contacts/FlareMemberRoleSheet.vue";

export { default as FlareScreenShare } from './call/FlareScreenShare.vue';
export { default as FlareStorageUsage } from "./profile/FlareStorageUsage.vue";

export { default as FlareConversationWorkspace } from "./layout/FlareConversationWorkspace.vue";
export { default as FlareChatWorkspace } from "./layout/FlareChatWorkspace.vue";

// Application composition. These surfaces consume host-owned state and intents;
// none imports a router, repository, network client, or IM SDK.
export { default as FlareAppLayout } from "./layout/FlareAppLayout.vue";
export { default as FlareAdaptiveNavigation } from "./layout/FlareAdaptiveNavigation.vue";
export { default as FlareMobileAppShell } from "./layout/FlareMobileAppShell.vue";
export { default as FlareDesktopAppShell } from "./layout/FlareDesktopAppShell.vue";
export { default as FlareWorkspaceFrame } from "./layout/FlareWorkspaceFrame.vue";
export { default as FlareIMAppKit } from "./layout/FlareIMAppKit.vue";
export { default as FlareConversationListContainer } from "./conversation/FlareConversationListContainer.vue";
export { default as FlareFriendListContainer } from "./contacts/FlareFriendListContainer.vue";

export { default as FlareFormSheet } from "./general/FlareFormSheet.vue";
export { default as FlareComposerMediaPreview } from "./composer/FlareComposerMediaPreview.vue";
export type { FlareComposerMediaPreviewItem } from "./composer/FlareComposerMediaPreview.vue";
