export type { FlareCallMode, FlareCallState, FlareCallParticipant } from "./call";
export * from "./application";
export type {
  FlareConversationRowModel,
  FlareConversationListSection,
  FlareConversationFilter,
  FlareForwardTarget,
  FlareConversationDetailsModel,
} from "./conversation";
export type {
  FlareContentElem,
  FlareMessageContentLike,
  FlareBusinessDetailRow,
  FlareReactionGroup,
} from "./message";
export type {
  FlareSearchResultKind,
  FlareSearchResultItem,
  FlareSearchResultGroup,
  FlareSearchResultTarget,
} from "./search";
export type {
  FlareViewportKind,
  FlareLayoutMode,
  FlareDensityMode,
} from "./layout";
export {
  FLARE_BREAKPOINT_H5_MAX,
  FLARE_BREAKPOINT_TABLET_MIN,
  FLARE_BREAKPOINT_IPAD_MAX,
  FLARE_BREAKPOINT_DESKTOP_MIN,
} from "./layout";
export type {
  FlareComposerAction,
  FlareComposerActionId,
  FlareComposerCapabilities,
  ResolveComposerActionsOptions,
  FlareComposerState,
  FlareQuickPhrase,
  FlareQuickPhraseGroup,
  FlareSlashCommand,
  FlareEmojiCategory,
  FlareStickerItem,
  FlareStickerPack,
} from "./composer";
export { FLARE_COMPOSER_ACTION_IDS, FLARE_DEFAULT_COMPOSER_ACTION_IDS, resolveComposerActions } from "./composer";
export type { FlareTone, FlareToastVariant } from "./tone";
export {
  FLARE_TONES,
  isFlareTone,
  toneFromLegacyConnectionTone,
  toneFromToastVariant,
  toastVariantFromTone,
  type FlareLegacyConnectionTone,
} from "./tone";
export type { MessageLike } from "./messageRow";
export { findMessage, resolveMessageId } from "./messageRow";
export {
  defaultMessageLifecycle,
  lifecycleToMessageStatus,
  type MessageLifecycle,
  type MessageSendState,
  type MessageDeliveryState,
  type MessageReadState,
  type MessageMutationState,
  type MessageEphemeralState,
} from "./message-lifecycle";
export type {
  FlareMediaKind,
  FlareMediaResolveRequest,
  FlareMediaResolver,
  FlareGridImage,
  FlareWallpaperOption,
} from "./media";
export type {
  FlareMomentAuthor,
  FlareMomentLike,
  FlareMomentComment,
  FlareMoment,

  FlareMomentsVisibilityRuleKind,
  FlareMomentVisibility,
  FlareMomentAudienceMode,
  FlareMomentHistoryRange,} from "./moments";
export {
  flareMomentAudienceApplies,
  flareMomentAudienceModes,
  flareMomentHistoryRanges,
  flareMomentVisibilities,
} from "./moments";
export type {
  FlareButtonVariant,
  FlareControlSize,
  FlareSelectOption,
} from "./form";
export type {
  FlareContact,
  FlareFriendRequest,
  FlareGroupSummary,
  FlareUserProfile,
  FlareSettingKind,
  FlareSettingsItem,
  FlareSettingsSection,
  FlareMentionCandidate,
  FlareGroupDetailModel,
  FlareGroupJoinRequestView,

  FlareContactBrief,
  FlareMatchedContact,
  FlareDetailExtraAction,
} from "./directory";

export { transferActions, transferProgress, type TransferState, type TransferAction } from "./transfer";

export * from './search-panel';

export { retryableTransferIds, type TransferQueueItem } from './transfer';

export * from './scenes';

export * from "./call-devices";

export * from "./permission-prompt";
export { actionMenuEntries, type FlareActionIntent, type FlareActionItem, type FlareActionMenuEntry, type FlareActionMenuPresentation } from "./action-menu";
export { conversationActions, type FlareConversationAction, type ConversationActionSnapshot, type ConversationActionCapabilities, type ConversationActionEntry, type ConversationActionPayload } from "./conversation-actions";
export { batchActionsAvailable, batchSelectionExceeded, conversationBatchActions, summarizeBatchResult, type ConversationBatchAction, type ConversationBatchCapabilities, type ConversationBatchFailure, type ConversationBatchResult, type ConversationBatchSummary } from "./conversation-batch";
export { messageBatchActions, messageBatchActionsAvailable, messageBatchMinimumSelection, type MessageBatchAction, type MessageBatchCapabilities } from "./message-batch";

export { unknownMessagePresentation, type UnknownMessageInput, type UnknownMessagePresentation } from "./unknown-message";

export { datesFromRange, dayEndMs, dayStartMs, matchedOptionId, rangeFromDates, shouldOpenCustomRange, unrestrictedRange, type FlareSearchDateDraft } from './search-date-range';
export { unknownUserPresentation, shortenUserId, UNKNOWN_USER_ID_MAX_LENGTH, relationActions, relationShowsPending, type UnknownUserKind, type UnknownUserDensity, type UnknownUserIcon, type UnknownUserTone, type UnknownUserPresentation, type RelationState, type RelationAction, type RelationCapabilities, type RelationActionEntry, type RelationActionPayload } from "./relation";
export { groupPermissionRows, groupPermissionKeys, groupJoinPolicies, type FlareGroupJoinPolicy, type GroupPermissionKey, type GroupPermissionRowKind, type GroupPermissionRow, type GroupPermissionSettings, type GroupPermissionChangePayload } from "./group-permissions";
export { memberRoleActions, memberRoleActionOrder, type GroupMemberRole, type MemberRoleActionId, type GroupMemberSnapshot, type MemberRoleCapabilities, type MemberMuteDuration, type MemberRoleActionEntry, type MemberRoleActionPayload } from "./group-permissions";

export { screenShareActions, screenShareIconName, screenShareStates, screenShareTone, type ScreenShareAction, type ScreenShareActionOptions, type ScreenShareActions, type ScreenShareState, type ScreenShareTone } from './screen-share';
export { formatBytes, storageTotals, storageShare, canClearStorage, type StorageCategory, type StorageTotals } from "./storage-usage";

export * from "./conversation-workspace";
export * from "./conversation-header";
export * from "./message-grouping";
export * from "./desktop-workbench";
export * from "./command-palette";
export * from "./interaction-state";
export * from "./message-content-contract";
export * from "./form-behavior";
export {
  FLARE_PLATFORM_ERROR_CODES,
  FLARE_DEFAULT_PLATFORM_CAPABILITIES,
  adapterSupport,
  callPlatform,
  isPlatformError,
  normalizePlatformError,
  platformErr,
  platformError,
  platformOk,
  withPlatformTimeout,
  type FlareCapabilitySupport,
  type FlarePickFilesOptions,
  type FlarePickImagesOptions,
  type FlarePickedFile,
  type FlarePlatformAdapter,
  type FlarePlatformCapabilities,
  type FlarePlatformError,
  type FlarePlatformErrorCode,
  type FlarePlatformKind,
  type FlarePlatformResult,
  type FlarePointerKind,
  type FlareSafeAreaInsets,
  type FlareSharePayload,
} from "../platform/contract";
// P0-11 security boundary: the host applies the same URL rule the kit's own anchors use
// (docs/release/security-boundary.md, public-api-2.0.md). Flutter, Compose and SwiftUI
// already export it; the Vue entry had omitted it.
export { FLARE_SAFE_URL_PROTOCOLS, isSafeExternalUrl, safeExternalUrl } from "./url-safety";
