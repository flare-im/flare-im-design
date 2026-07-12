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
export { default as FlareComposerEmojiStickerPanel } from "./composer/ComposerEmojiStickerPanel/index.vue";
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
export { default as FlareCallView } from "./call/FlareCallView.vue";
export { default as FlareIncomingCall } from "./call/FlareIncomingCall.vue";
export { default as FlareCallControls } from "./call/FlareCallControls.vue";
export { default as FlareAppShell } from "./layout/FlareAppShell.vue";
export { default as FlareResponsiveLayout } from "./layout/FlareResponsiveLayout.vue";

// composer parts (freely composable)
export { default as FlareVoiceHoldButton } from "./composer/FlareVoiceHoldButton.vue";
export { default as FlareComposerActionPanel } from "./composer/FlareComposerActionPanel.vue";
export { default as FlareComposerSendButton } from "./composer/FlareComposerSendButton.vue";
export { default as FlareComposerReplyStrip } from "./composer/FlareComposerReplyStrip.vue";
