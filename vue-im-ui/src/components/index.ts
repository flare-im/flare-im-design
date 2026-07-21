export { default as FlareUiProvider } from "../design-system/provider/FlareUiProvider.vue";
export { default as FlareAvatar } from "./conversation/FlareAvatar.vue";
export { default as FlareConversationList } from "./conversation/FlareConversationList.vue";
export { default as FlareConversationRow } from "./conversation/FlareConversationRow.vue";
export { default as FlareConversationDetails } from "./shell/ConversationDetails.vue";
export { default as FlareChatHeader } from "./messages/ChatConversationHeader.vue";
export { default as FlareChatHeaderIdentity } from "./messages/ChatConversationHeaderIdentity.vue";
export { default as FlareMessageBubble } from "./messages/MessageBubble.vue";
export { default as FlareMessageList } from "./messages/MessageList.vue";
export { default as FlareMessageContentView } from "./messages/MessageContentView.vue";
export { default as FlareMessageStatus } from "./messages/MessageStatus.vue";
export { default as FlareMessageContentRenderer } from "./messages/MessagesView/ContentView.vue";
export { ContentView as FlareContentView } from "./messages/MessagesView";
// Standalone, presentational per-type message bodies (clean props, no SDK/media
// coupling) — drop any single one into your own layout. The SDK-driven dispatcher
// above (FlareMessageContentView) stays the batteries-included path.
export { default as FlareTextMessage } from "./messages/standalone/FlareTextMessage.vue";
export { default as FlareImageMessage } from "./messages/standalone/FlareImageMessage.vue";
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
export { default as FlareTimeStamp } from "./messages/TimeStamp.vue";
export { default as FlareMessagePreviewModal } from "./message-preview/MessagePreviewModal.vue";
export { default as FlareImagePreview } from "./message-preview/ImagePreviewModal.vue";
export { default as FlareVideoPreview } from "./message-preview/VideoPlayerModal.vue";
export { default as FlareMarkdownPreview } from "./message-preview/MarkdownPreview.vue";
export { default as FlareComposer } from "./composer/EnhancedComposer.vue";
export type {
  FlareComposerAttachAction,
  FlareComposerActionTone,
  FlareComposerMentionCandidate,
} from "./composer/EnhancedComposer.vue";
export { default as FlareComposerEmojiStickerPanel } from "./composer/ComposerEmojiStickerPanel/index.vue";
export { default as FlareStickerPicker } from "./composer/FlareStickerPicker.vue";
export { default as FlareComposerRichInput } from "./composer/ComposerRichMarkdownInput.vue";
export { default as FlareMessageActionSheet } from "./composer/MessageActionSheet.vue";
export { default as FlareBusinessDetailBlock } from "./messages/FlareBusinessDetailBlock.vue";
export { default as FlareTaskMessageView } from "./messages/business/FlareTaskMessageView.vue";
export { default as FlareScheduleMessageView } from "./messages/business/FlareScheduleMessageView.vue";
export { default as FlareVoteMessageView } from "./messages/business/FlareVoteMessageView.vue";
export { default as FlareAnnouncementMessageView } from "./messages/business/FlareAnnouncementMessageView.vue";
export { default as FlareMiniProgramMessageView } from "./messages/business/FlareMiniProgramMessageView.vue";
export { default as FlareDiagnosticsConsole } from "./shell/FlareDiagnosticsConsole.vue";
export { default as FlareStartConversationSheet } from "./shell/FlareStartConversationSheet.vue";
export { default as FlareStartConversationDialog } from "./shell/FlareStartConversationDialog.vue";
export { default as FlareAuthScreen } from "./shell/FlareAuthScreen.vue";
export { default as FlareWorkbenchShell } from "./shell/FlareWorkbenchShell.vue";

// Phase C — general / contacts / theming
export { default as FlareThemeProvider } from "../design-system/provider/FlareThemeProvider.vue";
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

// Feishu-parity IM primitives (reactions, read receipts, mention, batch, search, skeleton, quick phrases)
export { default as FlareReactionSummary } from "./messages/FlareReactionSummary.vue";
export { default as FlareReadReceiptSheet } from "./messages/FlareReadReceiptSheet.vue";
export { default as FlareMessageBatchToolbar } from "./messages/FlareMessageBatchToolbar.vue";
export { default as FlareMentionPicker } from "./composer/FlareMentionPicker.vue";
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
export type { FlareToastVariant } from "./general/FlareToast.vue";
export { default as FlareCallDock } from "./call/FlareCallDock.vue";
export { default as FlareAnnouncementBanner } from "./messages/FlareAnnouncementBanner.vue";
export { default as FlareDatePill } from "./messages/FlareDatePill.vue";
export type { FlareForwardTarget } from "../shared/contracts";

// Batch 3 — red packet, slash-command menu, inline translation, QR name card
export { default as FlareRedPacketCard } from "./messages/FlareRedPacketCard.vue";
export { default as FlareTranslationView } from "./messages/FlareTranslationView.vue";
export { default as FlareSlashCommandMenu } from "./composer/FlareSlashCommandMenu.vue";
export { default as FlareQRCard } from "./profile/FlareQRCard.vue";
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
export { default as FlareAppShell } from "./layout/FlareAppShell.vue";
export { default as FlareResponsiveLayout } from "./layout/FlareResponsiveLayout.vue";
export { default as FlareScreenHeader } from "./layout/FlareScreenHeader.vue";

// General primitives surfaced by the example-app migration (button / segmented control)
export { default as FlarePrimaryButton } from "./general/FlarePrimaryButton.vue";
export { default as FlareSegmentedControl } from "./general/FlareSegmentedControl.vue";

// Foundation — buttons + form controls
export { default as FlareButton } from "./general/FlareButton.vue";
export { default as FlareIconButton } from "./general/FlareIconButton.vue";
export { default as FlareIcon } from "./general/FlareIcon.vue";
export { default as FlareGlyph } from "./general/FlareGlyph.vue";
export { default as FlareConfigProvider } from "./general/FlareConfigProvider.vue";
export { default as FlareBottomSheet } from "./general/FlareBottomSheet.vue";
export { flareIcons, flareIconNames, type FlareIconName } from "../shared/icons";
export {
  provideFlareConfig,
  useFlareConfig,
  type FlareConfigApi,
  type FlareDensity,
} from "../shared/useFlareConfig";
export { default as FlareFormField } from "./form/FlareFormField.vue";
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
export {
  provideFlareOverlayContainer,
  useFlareOverlayContainer,
  type FlareOverlayTarget,
} from "../shared/useOverlayContainer";
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
