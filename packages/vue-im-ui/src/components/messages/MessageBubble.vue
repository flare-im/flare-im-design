<script setup lang="ts">
import { computed, getCurrentInstance, h, ref, useId, type Component } from "vue";
import type { FlareConversationKind } from "../../shared/contracts/conversation";
import type { MessageMediaDownloadUiState } from "../../shared/contracts/media";
import {
  DownloadOutline,
  EllipsisHorizontalOutline,
  FolderOpenOutline,
  PinOutline,
  RefreshOutline,
} from "../../shared/icon-glyphs";
import { NIcon } from "naive-ui";
import type { DropdownOption } from "naive-ui";
import { messageContentTypeForUi } from "../../utils/messageContent";
import { avatarTint } from "../../shared/avatar-tint";
import { useLongPress } from "../../composables/useLongPress";
import { useMessageMenuInteraction } from "../../composables/chat/useMessageMenuInteraction";
import MessageContentView from "./MessageContentView.vue";
import type { FlareLocationValue } from "../../shared/contracts/location";
import MessageBubbleHoverToolbar from "./MessageBubbleHoverToolbar.vue";
import MessageMenu from "./MessageMenu.vue";
import MessageMeta from "./MessageMeta.vue";
import { injectTimelineFocus, messageTakesFocus } from "./timelineFocus";
import { resolveMessageId, type MessageLike } from "../../shared/contracts/messageRow";
import {
  isMessageMenuActionEnabled,
  mergeMessageMenuConfig,
  type MessageMenuConfig,
  type MessageMenuMediaAction,
} from "../../shared/config/messageMenu";
import { buildMessageMenuContext, type MessageMenuExtension } from "../../utils/buildMessageMenuOptions";
import { MESSAGE_QUICK_REACTIONS } from "../../shared/constants/messageReactions";
import { messageSurfaceOf } from "../../utils/messageSurface";
import { previewTextFromMessageContent } from "../../utils/messagePreview";
import { provideFlareMessageQuote, useFlareMessageRenderers } from "../../shared/message-renderers";
import MessageCardQuote from "./MessageCardQuote.vue";
import { resolveMessageStatus } from "../../utils/messageStatus";
import {
  flareMessageMetaPlacement,
  flareMessageMetaTone,
  type FlareMessageSurface,
} from "../../shared/contracts/message-surface";
import {
  flareMessageAccessibilityLabel,
  flareMessageReceiptPresentation,
} from "../../shared/contracts/message-receipt";
import { formatMessageTime } from "../../shared/timeline-label";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type {
  FlareMessageGroupPosition,
  FlareMessageRowPresentation,
} from "../../shared/contracts/message-grouping";

export type { MessageLike } from "../../shared/contracts/messageRow";

export type { MessageMediaDownloadUiState } from "../../shared/contracts/media";

const props = defineProps<{
  message: MessageLike;
  currentUserId: string;
  self?: boolean;
  multiSelectMode?: boolean;
  selected?: boolean;
  menuConfig?: MessageMenuConfig;
  /** Host actions (report, translate, ...) listed in the message menu; selecting one emits `action`. */
  actions?: readonly MessageMenuExtension[];
  conversationKind?: FlareConversationKind;
  groupPosition?: FlareMessageGroupPosition;
  rowPresentation?: FlareMessageRowPresentation;
  /**
   * The surface the content is drawn on (spec/message-surface-vectors.json). Absent: derived from the content, the
   * quote, the recall / delete state and the renderer registry. MessageList passes the one it grouped by.
   */
  surface?: FlareMessageSurface;
  mediaDownloadState?: MessageMediaDownloadUiState;
  /** Just-arrived (appended at the tail) — plays a one-shot entrance animation. */
  fresh?: boolean;
  /**
   * Will a tap on this message's quote reach the quoted message? False draws the quote as text
   * rather than a control. The list decides it (it knows its rows and whether the host listens);
   * a bubble used on its own assumes the host can act.
   */
  quoteLocatable?: boolean;
}>();

const emit = defineEmits<{
  (event: "react", messageId: string, emoji: string): void;
  (event: "edit", messageId: string): void;
  (event: "delete", messageId: string): void;
  (event: "pin", messageId: string, pinned: boolean, scope: "conversation" | "self"): void;
  (event: "mark", messageId: string): void;
  (event: "preview", messageId: string): void;
  (event: "mediaAction", messageId: string, action: "download" | "openFolder"): void;
  (event: "reply", messageId: string): void;
  (event: "forward", messageId: string): void;
  (event: "multiSelect", messageId: string): void;
  (event: "recall", messageId: string): void;
  (event: "resend", clientMsgId: string): void;
  (event: "toggle-select", messageId: string): void;
  (event: "locate-message", messageId: string): void;
  (event: "action", actionId: string, messageId: string): void;
  (event: "copy", messageId: string, copied: boolean): void;
  /** A tapped poll option, by its index. Without a listener, or while selecting, polls are read-only. */
  (event: "vote", messageId: string, optionIndex: number): void;
  /** A tapped task checkbox, with the done state asked for. Without a listener, or while selecting, tasks are read-only. */
  (event: "taskToggle", messageId: string, done: boolean): void;
  /** A tapped person's card, with its user id. Without a listener, or while selecting, cards only display. */
  (event: "cardOpen", messageId: string, userId: string): void;
  /** A tapped location card. Without a listener the card links to the web map; while selecting it does nothing. */
  (event: "locationOpen", messageId: string, location: FlareLocationValue): void;
  /** The group read summary was tapped ("3 unread"); the host opens ReadReceiptSheet. Without a listener it is text. */
  (event: "readReceiptOpen", messageId: string): void;
}>();

const { profile } = useMessageMenuInteraction();
const { t, locale } = useFlareI18n();
const menuRef = ref<InstanceType<typeof MessageMenu> | null>(null);
const bubbleAnchorRef = ref<HTMLElement | null>(null);

function messageId(): string {
  return resolveMessageId(props.message);
}

// Selecting taps select the row: a poll or a task is not a control then.
const bubbleInstance = getCurrentInstance();
const bodyIntentListeners = computed(() => {
  const listeners = bubbleInstance?.vnode.props;
  if (props.multiSelectMode) return {};
  return {
    ...(listeners?.onVote ? { vote: (optionIndex: number) => emit("vote", messageId(), optionIndex) } : {}),
    ...(listeners?.onTaskToggle ? { taskToggle: (done: boolean) => emit("taskToggle", messageId(), done) } : {}),
    ...(listeners?.onCardOpen ? { cardOpen: (userId: string) => emit("cardOpen", messageId(), userId) } : {}),
    ...(listeners?.onLocationOpen
      ? { locationOpen: (location: FlareLocationValue) => emit("locationOpen", messageId(), location) }
      : {}),
  };
});

function isPinned(message: MessageLike): boolean {
  return message.pinned === true;
}

const contentType = computed(() =>
  messageContentTypeForUi(props.message.content?.contentType ?? "text"),
);
const isSystemLike = computed(() =>
  ["system", "notification"].includes(contentType.value),
);
// A deleted message is a centred notice in place of its content, like a recall.
const isDeleted = computed(() => props.message.lifecycle?.mutation === "deleted" && !props.message.isRecalled);
// System notices ("群聊 X 已创建", "Y 加入群聊") carry a human-readable `body`; show
// it as centered muted text rather than a chat bubble with a placeholder.
const systemText = computed(() => {
  const c = props.message.content as Record<string, unknown> | undefined;
  return String(c?.body ?? c?.text ?? "").trim();
});
const isRecalled = computed(() => props.message.isRecalled || isDeleted.value);
const deliveryStatus = computed(() => resolveMessageStatus(props.message));
const reactions = computed(() => (isRecalled.value ? [] : props.message.reactions ?? []));
const messageRenderers = useFlareMessageRenderers();
// The surface (C1): bubble, bareMedia (the media is the surface), card (the content's own shell is the surface: no
// bubble background, border, padding or tail around it) or centered (a notice line).
const surface = computed<FlareMessageSurface>(() => props.surface ?? messageSurfaceOf(props.message, messageRenderers));
const isChromelessMedia = computed(() => surface.value === "bareMedia");
const isChromelessCard = computed(() => surface.value === "card");
// A card that replies keeps its surface and draws the quote inside its shell, at the top: a shell that knows how
// (PluginView) claims it; for the others the row draws the same strip on top of the card.
const cardQuoteClaimed = ref(false);
const hasCardQuote = computed(() =>
  isChromelessCard.value && Boolean(props.message.replyTo?.trim() || props.message.quotePreview?.trim()),
);
function locateCardQuote(): (() => void) | undefined {
  const target = props.message.replyTo?.trim();
  if (!target || props.quoteLocatable === false || props.multiSelectMode) return undefined;
  return () => emit("locate-message", target);
}
provideFlareMessageQuote({
  active: () => hasCardQuote.value,
  preview: () => props.message.quotePreview?.trim() ?? "",
  locate: locateCardQuote,
  claim: () => { cardQuoteClaimed.value = true; },
});
// The id a custom renderer is handed: the server id the SDK and plugins key by, else the client id.
const rendererMessageId = computed(() => props.message.serverId || props.message.clientMsgId);
const isFailed = computed(() => deliveryStatus.value === "failed");
const messagePinned = computed(() => isPinned(props.message));
const isEdited = computed(() =>
  Boolean(
    props.message.isEdited,
  ),
);
const messageExtraForContent = computed(() => ({
  ...(props.message.attributes ?? {}),
  textPreview: props.message.textPreview,
  quotePreview: props.message.quotePreview,
  // "0" when nothing would happen on a tap: the quote is then text, not a button.
  quoteLocatable: props.quoteLocatable === false ? "0" : "1",
  // Lets text bodies tell a mention of the reader from other mentions.
  currentUserId: props.currentUserId,
}));
const senderLabel = computed(
  () =>
    props.message.senderDisplayName?.trim() ||
    props.message.senderId ||
    t("composer.replyFallback"),
);
const senderAvatarUrl = computed(
  () => props.message.senderAvatar?.trim() || "",
);
const senderInitial = computed(() => {
  const source = senderLabel.value.trim() || props.message.senderId || "?";
  return Array.from(source)[0]?.toUpperCase() ?? "?";
});
// Same deterministic pastel FlareAvatar uses, seeded by the display name — so a
// sender's bubble avatar matches their avatar in the list + chat header (was a
// fixed blue-cyan gradient for everyone).
const senderTint = computed(() =>
  avatarTint(props.message.senderDisplayName || props.message.senderId),
);
const recalledHint = computed(() => {
  if (isDeleted.value) return t("message.deleted");
  if (props.self) return t("message.recalledSelf");
  if (props.conversationKind === "group") {
    return t("message.recalledGroupOther", { name: senderLabel.value });
  }
  return t("message.recalledPeer");
});
const messageTimeText = computed(() =>
  timeText(props.message.createdAt || props.message.clientCreatedAt),
);
const groupPosition = computed(() => props.groupPosition ?? "single");
const isGroupStart = computed(() => groupPosition.value === "single" || groupPosition.value === "first");
const isGroupEnd = computed(() => groupPosition.value === "single" || groupPosition.value === "last");
const rowPresentation = computed<FlareMessageRowPresentation>(() => props.rowPresentation ?? ({
  showAvatar: false,
  reserveAvatarSpace: false,
  showSenderName: false,
  avatarPlacement: props.self ? "trailing" : "leading",
  tail: surface.value === "bubble" && isGroupEnd.value,
}));
const showSenderMeta = computed(
  () =>
    !isSystemLike.value
    && !isRecalled.value
    && !props.multiSelectMode
    && rowPresentation.value.showSenderName,
);
const showSenderAvatar = computed(
  () =>
    !isSystemLike.value
    && !isRecalled.value
    && !props.multiSelectMode
    && rowPresentation.value.showAvatar,
);
const reserveAvatarSpace = computed(() =>
  !isSystemLike.value && !isRecalled.value && !props.multiSelectMode && rowPresentation.value.reserveAvatarSpace,
);
const showMessageStatus = computed(() => {
  if (!props.self || isSystemLike.value || isRecalled.value) return false;
  return true;
});
const messageEphemeral = computed(() => {
  const value = props.message.attributes?.ephemeralState;
  return value === "readOnce" || value === "burnAfterRead" || value === "expired" ? value : "none";
});
const showMessageMeta = computed(() => Boolean(messageTimeText.value || isEdited.value || messageEphemeral.value !== "none" || showMessageStatus.value));
// Where the time and receipt sit (C2): inline after a text, inside other bubbles, below a picture or a card.
const metaPlacement = computed(() => flareMessageMetaPlacement(surface.value, contentType.value));
const metaTone = computed(() => flareMessageMetaTone(metaPlacement.value, Boolean(props.self), deliveryStatus.value));
// The SDK's read summary belongs to the viewer's own group messages only (C3).
const readSummary = computed(() =>
  props.self && props.conversationKind === "group" ? props.message.readSummary : undefined,
);
// Retry and the read summary are keys only while the host listens for them (listeners are read at render).
const metaListeners = computed(() => {
  const listeners = bubbleInstance?.vnode.props;
  return {
    ...(listeners?.onResend ? { onResend: () => emit("resend", props.message.clientMsgId) } : {}),
    ...(listeners?.onReadReceiptOpen ? { onReadReceiptOpen: () => emit("readReceiptOpen", messageId()) } : {}),
  };
});
const uploadProgress = computed(() => {
  const n = Number(props.message.localState?.uploadProgress) || 0;
  return Math.max(0, Math.min(100, Math.round(n)));
});
const showUploadProgress = computed(() =>
  !isSystemLike.value &&
  !isRecalled.value &&
  Boolean(props.message.localState?.uploading || (uploadProgress.value > 0 && uploadProgress.value < 100)),
);
// Over the picture for images and video; under the body for a file or a voice note, whose name and size are what
// the sender checks while it uploads — a pill over them hid the size line.
const uploadProgressOnMedia = computed(() =>
  showUploadProgress.value &&
  ["image", "image_group", "video"].includes(contentType.value),
);

const showSelectControl = computed(
  () => Boolean(props.multiSelectMode) && !isSystemLike.value && !isRecalled.value,
);

const showMenuChrome = computed(
  () => !props.multiSelectMode && messageTakesFocus(props.message),
);

const bubbleKeyboardEnabled = computed(() => showMenuChrome.value);

// In a message list only one bubble takes Tab (see timelineFocus.ts); the hover controls repeat
// what the menu offers, so there they join the Tab sequence only while focus is inside this message.
const timelineFocus = injectTimelineFocus();
const rowFocused = ref(false);
const bubbleBodyId = `flare-message-body-${useId()}`;
const bubbleTabindex = computed(() => {
  if (!bubbleKeyboardEnabled.value) return undefined;
  return !timelineFocus || timelineFocus.target.value === messageId() ? 0 : -1;
});
const hoverControlsTabbable = computed(() => !timelineFocus || rowFocused.value);

function onRowFocusin(): void {
  rowFocused.value = true;
  if (bubbleKeyboardEnabled.value) timelineFocus?.activate(messageId());
}

function onRowFocusout(event: FocusEvent): void {
  const next = event.relatedTarget as Node | null;
  if (next && (event.currentTarget as HTMLElement).contains(next)) return;
  rowFocused.value = false;
}

// A reaction pill toggles the viewer's reaction when reacting is on for this message (same
// gate as the reaction picker, so a host that does not handle `react` gets display-only pills).
const canToggleReaction = computed(
  () =>
    showMenuChrome.value &&
    isMessageMenuActionEnabled(
      mergeMessageMenuConfig(props.menuConfig),
      "react",
      buildMessageMenuContext(props.message, props.currentUserId),
    ),
);

type MediaHoverActionModel = {
  id: MessageMenuMediaAction;
  action: "download" | "openFolder" | null;
  label: string;
  icon: Component;
  state: MessageMediaDownloadUiState;
};

function translateOrFallback(key: string, fallback: string): string {
  const resolved = t(key);
  return resolved === key ? fallback : resolved;
}

function mediaActionModel(id: MessageMenuMediaAction): MediaHoverActionModel {
  if (id === "openMediaFolder") {
    return {
      id,
      action: "openFolder",
      label: translateOrFallback("messageMenu.openMediaFolder", "Open containing folder"),
      icon: FolderOpenOutline,
      state: "openFolder",
    };
  }
  return {
    id,
    action: "download",
    label: translateOrFallback("messageMenu.downloadMedia", "Download"),
    icon: DownloadOutline,
    state: "idle",
  };
}

function mediaStateModel(state: MessageMediaDownloadUiState): MediaHoverActionModel | null {
  if (state === "downloading") {
    return {
      id: "downloadMedia",
      action: null,
      label: t("messageMenu.downloadingMedia"),
      icon: RefreshOutline,
      state,
    };
  }
  // Saved: the key shows the file in its folder, never a spent "downloaded" tick.
  if (state === "downloaded" || state === "openFolder") {
    return mediaActionModel("openMediaFolder");
  }
  return null;
}

const resolvedMediaActionId = computed<MessageMenuMediaAction | null>(() => {
  if (!showMenuChrome.value) return null;
  const merged = mergeMessageMenuConfig(props.menuConfig);
  const ctx = buildMessageMenuContext(props.message, props.currentUserId);
  if (!ctx.hasDownloadableMedia) return null;
  const id = merged.resolveMediaAction?.(ctx);
  if (!id || !isMessageMenuActionEnabled(merged, id, ctx)) return null;
  return id;
});

const mediaHoverAction = computed<MediaHoverActionModel | null>(() => {
  if (!["image", "video"].includes(contentType.value)) {
    return null;
  }
  const stateModel = mediaStateModel(props.mediaDownloadState ?? "idle");
  if (stateModel) return stateModel;
  return resolvedMediaActionId.value ? mediaActionModel(resolvedMediaActionId.value) : null;
});

// Files show the action inline; pictures and videos offer it inside their full-screen preview and player.
const fileInlineMediaAction = computed<MediaHoverActionModel | null>(() => {
  if (!["file", "image", "video"].includes(contentType.value)) return null;
  const stateModel = mediaStateModel(props.mediaDownloadState ?? "idle");
  if (stateModel) return stateModel;
  return resolvedMediaActionId.value ? mediaActionModel(resolvedMediaActionId.value) : null;
});

/**
 * 时间戳与状态跟在最后一行右侧，而不是自己另起一行。
 *
 * `.message-bubble-body` 是块级的，而 `MessageMeta` 就在它里面，所以每条消息的
 * 时间戳都会独占一行：一条两行的中文消息实测 42px 文本 + 13px 时间戳 = 78px 气泡，
 * 约四分之一的高度花在一行只有「21:15」的行上。时间线是这个产品看得最多的一屏。
 *
 * kit 里本来就有这套机制（`.message-bubble-body--trailing-status` +
 * `.bubble-inline-status`），但没有任何组件加过这两个类 —— 是写完没接上的死样式。
 *
 * 只对纯文本开：媒体、卡片、富文本各有自己的排版，把 meta 塞进它们的行尾会挤坏。
 */
const inlineMeta = computed(() => showMessageMeta.value && metaPlacement.value === "inline");

const bubbleClassNames = computed(() => [
  `message-bubble--${contentType.value}`,
  {
    "message-bubble--inline-meta": inlineMeta.value,
    "message-bubble-self": props.self,
    "message-bubble--pinned": isPinned(props.message),
    "message-bubble--chromeless-media": isChromelessMedia.value,
    "message-bubble--chromeless-card": isChromelessCard.value,
  },
]);

const bubbleHostClassNames = computed(() => ({
  "message-bubble-host--self": props.self,
  "message-bubble-host--toolbar-beside":
    showMenuChrome.value && profile.value.showHoverToolbar,
  "message-bubble-host--chromeless-card": isChromelessCard.value,
}));

const dropdownPlacement = computed(() =>
  profile.value.mode === "tablet" ? "right-start" : "bottom-start",
);

// Reaction quick-set — shared with the mobile long-press sheet so PC hover and
// mobile show the exact same emoji (single source: MESSAGE_QUICK_REACTIONS).
const reactionPickerOptions: DropdownOption[] = MESSAGE_QUICK_REACTIONS.map((emoji) => ({
  label: emoji,
  key: emoji,
  icon: () => h("span", { style: "font-size:16px" }, emoji),
}));

useLongPress(bubbleAnchorRef, {
  enabled: () => showMenuChrome.value && profile.value.enableLongPress,
  delayMs: () => profile.value.longPressMs,
  onLongPress: () => {
    menuRef.value?.openMenu();
  },
});

function timeText(timestamp: number): string {
  return timestamp ? formatMessageTime(timestamp, locale.value) : "";
}

function onReactionSelect(emoji: string): void {
  emit("react", messageId(), emoji);
}

function openTouchMenu(): void {
  menuRef.value?.openMenu();
}

function emitMediaHoverAction(): void {
  const model = mediaHoverAction.value;
  if (!model?.action) return;
  emit("mediaAction", messageId(), model.action);
}

function onBubbleKeydown(event: KeyboardEvent): void {
  if (!bubbleKeyboardEnabled.value || event.target !== event.currentTarget) return;
  if (event.key === "Enter" || event.key === " ") {
    event.preventDefault();
    openTouchMenu();
  }
}

/** The row's reading unit (spec/message-receipt-vectors.json accessibility): sender, summary, time, status. */
function bubbleA11yLabel(): string {
  let status = "";
  if (showMessageStatus.value) {
    const receipt = flareMessageReceiptPresentation({
      conversationKind: props.conversationKind,
      self: true,
      status: deliveryStatus.value,
      readSummary: readSummary.value,
    });
    if (receipt.summary) {
      status = receipt.summary.allRead
        ? t("message.readSummaryAllRead")
        : t("message.readSummaryUnread", { count: receipt.summary.count ?? 0 });
    } else {
      status = deliveryStatus.value === "failed" ? t("message.sendFailedRetry") : t(`message.${deliveryStatus.value}`);
    }
  }
  const summary = previewTextFromMessageContent(props.message.content, locale.value) || props.message.textPreview || "";
  return flareMessageAccessibilityLabel(
    [senderLabel.value, summary, timeText(props.message.createdAt || props.message.clientCreatedAt), status],
    locale.value,
  );
}

// In multi-select the content is inert and the whole row is the target: a tap anywhere toggles the selection.
function onRowClick(event: MouseEvent): void {
  if (!showSelectControl.value) return;
  if ((event.target as HTMLElement | null)?.closest?.(".message-select")) return;
  emit("toggle-select", messageId());
}
</script>

<template>
  <article
    class="message-row"
    :class="{
      'message-row--self': self,
      'message-row--selected': selected,
      'message-row--system': isSystemLike,
      'message-row--recalled': isRecalled,
      'message-row--selectable': showSelectControl,
      'message-row--failed': isFailed,
      'message-row--group-start': isGroupStart,
      'message-row--group-end': isGroupEnd,
      [`message-row--group-${groupPosition}`]: true,
      'message-row--fresh': fresh,
      'message-row--with-meta': showSenderMeta,
      'message-row--with-avatar': showSenderAvatar,
      'message-row--avatar-gutter': reserveAvatarSpace,
      'message-row--avatar-trailing': reserveAvatarSpace && rowPresentation.avatarPlacement === 'trailing',
    }"
    :data-menu-surface="profile.mode"
    :data-message-id="messageId()"
    :data-surface="surface"
    @focusin="onRowFocusin"
    @focusout="onRowFocusout"
    @click="onRowClick"
  >
    <button
      v-if="showSelectControl"
      type="button"
      role="checkbox"
      class="message-select"
      :class="{ 'message-select--on': selected }"
      :aria-checked="Boolean(selected)"
      :aria-label="t('message.selectMessage', { label: bubbleA11yLabel() })"
      @click="emit('toggle-select', messageId())"
    >
      <span v-if="selected" class="message-select__check" aria-hidden="true" />
    </button>

    <div
      v-if="showSenderAvatar"
      class="message-avatar"
      :class="{ 'message-avatar--trailing': rowPresentation.avatarPlacement === 'trailing' }"
      :style="senderAvatarUrl ? undefined : { background: senderTint.bg, color: senderTint.fg }"
      aria-hidden="true"
    >
      <img
        v-if="senderAvatarUrl"
        :src="senderAvatarUrl"
        :alt="senderLabel"
        loading="lazy"
      />
      <span v-else>{{ senderInitial }}</span>
    </div>

    <div v-if="showSenderMeta" class="message-meta">
      <span class="message-meta__name">{{ senderLabel }}</span>
    </div>

    <div v-if="isSystemLike" class="message-recalled-hint">
      {{ systemText }}
    </div>

    <div v-else-if="isRecalled" class="message-recalled-hint" :data-deleted="isDeleted || undefined">
      {{ recalledHint }}
    </div>

    <div
      v-else
      class="message-bubble-host"
      :class="bubbleHostClassNames"
    >
      <div
        v-if="showMenuChrome && profile.showHoverToolbar"
        class="message-bubble-toolbar-row"
        :class="{ 'message-bubble-toolbar-row--self': self }"
      >
        <MessageMenu
          ref="menuRef"
          :message="message"
          :current-user-id="currentUserId"
          :presentation="profile.menuPresentation"
          :enable-context-menu="profile.enableContextMenu"
          :suppress-menu="!showMenuChrome"
          :menu-config="menuConfig"
          :actions="actions"
          :dropdown-placement="dropdownPlacement"
          @reply="emit('reply', $event)"
          @forward="emit('forward', $event)"
          @multi-select="emit('multiSelect', $event)"
          @edit="emit('edit', $event)"
          @recall="emit('recall', $event)"
          @resend="emit('resend', $event)"
          @pin="(id: string, pinned: boolean, scope: 'conversation' | 'self') => emit('pin', id, pinned, scope)"
          @mark="emit('mark', $event)"
          @preview="emit('preview', $event)"
          @media-action="(id: string, action: 'download' | 'openFolder') => emit('mediaAction', id, action)"
          @delete="emit('delete', $event)"
          @action="(actionId: string, id: string) => emit('action', actionId, id)"
          @copy="(id: string, copied: boolean) => emit('copy', id, copied)"
          @react="(emoji: string) => emit('react', messageId(), emoji)"
        >
          <div
            ref="bubbleAnchorRef"
            class="message-bubble"
            :class="[
              ...bubbleClassNames,
              { 'message-bubble--focusable': bubbleKeyboardEnabled },
            ]"
            :tabindex="bubbleTabindex"
            :role="bubbleKeyboardEnabled ? 'group' : undefined"
            :aria-label="bubbleKeyboardEnabled ? bubbleA11yLabel() : undefined"
            :aria-describedby="bubbleKeyboardEnabled ? bubbleBodyId : undefined"
            @dblclick="!multiSelectMode && emit('preview', messageId())"
            @keydown="onBubbleKeydown"
          >
            <div
              :id="bubbleBodyId"
              class="message-bubble-body"
              :class="{ 'message-bubble-body--inert': multiSelectMode }"
              :inert="multiSelectMode ? true : undefined"
            >
              <MessageCardQuote
                v-if="hasCardQuote && !cardQuoteClaimed"
                class="message-bubble-card-quote"
                :preview="message.quotePreview ?? ''"
                :locate="locateCardQuote()"
              />
              <MessageContentView
                :content="message.content"
                :self="self"
                :message-id="messageId()"
                :renderer-message-id="rendererMessageId"
                :conversation-id="message.conversationId"
                :message-extra="messageExtraForContent"
                :sender-name="senderLabel"
                :media-action="fileInlineMediaAction?.action"
                :media-state="fileInlineMediaAction?.state"
                :selection-mode="Boolean(multiSelectMode)"
                @locate-message="emit('locate-message', $event)"
                v-on="bodyIntentListeners"
                @media-action="(action: 'download' | 'openFolder') => emit('mediaAction', messageId(), action)"
              />
            </div>
            <button
              v-if="mediaHoverAction"
              type="button"
              class="message-media-hover-action"
              :class="{
                'message-media-hover-action--folder':
                  mediaHoverAction.action === 'openFolder',
                [`message-media-hover-action--${mediaHoverAction.state}`]: true,
              }"
              :aria-label="mediaHoverAction.label"
              :tabindex="hoverControlsTabbable ? undefined : -1"
              :disabled="!mediaHoverAction.action"
              @click.stop="emitMediaHoverAction"
            >
              <n-icon aria-hidden="true" :component="mediaHoverAction.icon" />
            </button>
            <MessageMeta
              v-if="showMessageMeta"
              :timestamp="messageTimeText"
              :edited="isEdited"
              :ephemeral="messageEphemeral"
              :status="showMessageStatus ? deliveryStatus : undefined"
              :tone="metaTone"
              :placement="metaPlacement"
              :read-summary="readSummary"
              v-bind="metaListeners"
            />
            <div
              v-if="showUploadProgress"
              class="message-upload-progress"
              :class="{ 'message-upload-progress--media': uploadProgressOnMedia }"
              :aria-label="`upload ${uploadProgress}%`"
            >
              <span class="message-upload-progress__bar">
                <span
                  class="message-upload-progress__value"
                  :style="{ width: `${Math.max(4, uploadProgress)}%` }"
                />
              </span>
              <span class="message-upload-progress__text">{{ uploadProgress }}%</span>
            </div>
            <span
              v-if="messagePinned"
              class="message-pin-marker"
              :title="t('message.pinnedTitle')"
            >
              <n-icon aria-hidden="true" :component="PinOutline" />
            </span>
          </div>
        </MessageMenu>
        <MessageBubbleHoverToolbar
          beside
          :message="message"
          :current-user-id="currentUserId"
          :reaction-options="reactionPickerOptions"
          :menu-config="menuConfig"
          :actions="actions"
          :focusable="hoverControlsTabbable"
          @quick-reply="emit('reply', messageId())"
          @reaction-select="onReactionSelect"
          @reply="emit('reply', $event)"
          @forward="emit('forward', $event)"
          @multi-select="emit('multiSelect', $event)"
          @edit="emit('edit', $event)"
          @recall="emit('recall', $event)"
          @resend="emit('resend', $event)"
          @action="(actionId: string, id: string) => emit('action', actionId, id)"
          @copy="(id: string, copied: boolean) => emit('copy', id, copied)"
          @pin="(id: string, pinned: boolean, scope: 'conversation' | 'self') => emit('pin', id, pinned, scope)"
          @mark="emit('mark', $event)"
          @preview="emit('preview', $event)"
          @media-action="(id: string, action: 'download' | 'openFolder') => emit('mediaAction', id, action)"
          @delete="emit('delete', $event)"
        />
      </div>

      <template v-else>
        <MessageMenu
          ref="menuRef"
          :message="message"
          :current-user-id="currentUserId"
          :presentation="profile.menuPresentation"
          :enable-context-menu="profile.enableContextMenu"
          :suppress-menu="!showMenuChrome"
          :menu-config="menuConfig"
          :actions="actions"
          :dropdown-placement="dropdownPlacement"
          @reply="emit('reply', $event)"
          @forward="emit('forward', $event)"
          @multi-select="emit('multiSelect', $event)"
          @edit="emit('edit', $event)"
          @recall="emit('recall', $event)"
          @resend="emit('resend', $event)"
          @pin="(id: string, pinned: boolean, scope: 'conversation' | 'self') => emit('pin', id, pinned, scope)"
          @mark="emit('mark', $event)"
          @preview="emit('preview', $event)"
          @media-action="(id: string, action: 'download' | 'openFolder') => emit('mediaAction', id, action)"
          @delete="emit('delete', $event)"
          @action="(actionId: string, id: string) => emit('action', actionId, id)"
          @copy="(id: string, copied: boolean) => emit('copy', id, copied)"
          @react="(emoji: string) => emit('react', messageId(), emoji)"
        >
          <div
            ref="bubbleAnchorRef"
            class="message-bubble"
            :class="[
              ...bubbleClassNames,
              { 'message-bubble--focusable': bubbleKeyboardEnabled },
            ]"
            :tabindex="bubbleTabindex"
            :role="bubbleKeyboardEnabled ? 'group' : undefined"
            :aria-label="bubbleKeyboardEnabled ? bubbleA11yLabel() : undefined"
            :aria-describedby="bubbleKeyboardEnabled ? bubbleBodyId : undefined"
            @dblclick="!multiSelectMode && emit('preview', messageId())"
            @keydown="onBubbleKeydown"
          >
            <div
              :id="bubbleBodyId"
              class="message-bubble-body"
              :class="{ 'message-bubble-body--inert': multiSelectMode }"
              :inert="multiSelectMode ? true : undefined"
            >
              <MessageCardQuote
                v-if="hasCardQuote && !cardQuoteClaimed"
                class="message-bubble-card-quote"
                :preview="message.quotePreview ?? ''"
                :locate="locateCardQuote()"
              />
              <MessageContentView
                :content="message.content"
                :self="self"
                :message-id="messageId()"
                :renderer-message-id="rendererMessageId"
                :conversation-id="message.conversationId"
                :message-extra="messageExtraForContent"
                :sender-name="senderLabel"
                :media-action="fileInlineMediaAction?.action"
                :media-state="fileInlineMediaAction?.state"
                :selection-mode="Boolean(multiSelectMode)"
                @locate-message="emit('locate-message', $event)"
                v-on="bodyIntentListeners"
                @media-action="(action: 'download' | 'openFolder') => emit('mediaAction', messageId(), action)"
              />
            </div>
            <button
              v-if="mediaHoverAction"
              type="button"
              class="message-media-hover-action"
              :class="{
                'message-media-hover-action--folder':
                  mediaHoverAction.action === 'openFolder',
                [`message-media-hover-action--${mediaHoverAction.state}`]: true,
              }"
              :aria-label="mediaHoverAction.label"
              :tabindex="hoverControlsTabbable ? undefined : -1"
              :disabled="!mediaHoverAction.action"
              @click.stop="emitMediaHoverAction"
            >
              <n-icon aria-hidden="true" :component="mediaHoverAction.icon" />
            </button>
            <MessageMeta
              v-if="showMessageMeta"
              :timestamp="messageTimeText"
              :edited="isEdited"
              :ephemeral="messageEphemeral"
              :status="showMessageStatus ? deliveryStatus : undefined"
              :tone="metaTone"
              :placement="metaPlacement"
              :read-summary="readSummary"
              v-bind="metaListeners"
            />
            <div
              v-if="showUploadProgress"
              class="message-upload-progress"
              :class="{ 'message-upload-progress--media': uploadProgressOnMedia }"
              :aria-label="`upload ${uploadProgress}%`"
            >
              <span class="message-upload-progress__bar">
                <span
                  class="message-upload-progress__value"
                  :style="{ width: `${Math.max(4, uploadProgress)}%` }"
                />
              </span>
              <span class="message-upload-progress__text">{{ uploadProgress }}%</span>
            </div>
            <span
              v-if="messagePinned"
              class="message-pin-marker"
              :title="t('message.pinnedTitle')"
            >
              <n-icon aria-hidden="true" :component="PinOutline" />
            </span>
          </div>
        </MessageMenu>

        <button
          v-if="
            showMenuChrome &&
            profile.showBubbleMoreButton &&
            !profile.enableLongPress
          "
          type="button"
          class="message-bubble-more"
          :aria-label="t('message.menuAria')"
          :tabindex="hoverControlsTabbable ? undefined : -1"
          @click.stop="openTouchMenu"
        >
          <n-icon aria-hidden="true" :component="EllipsisHorizontalOutline" />
        </button>
      </template>
    </div>

    <div v-if="reactions.length" class="message-reactions">
      <template v-if="canToggleReaction">
        <button
          v-for="reaction in reactions"
          :key="reaction.emoji"
          type="button"
          :class="{ 'is-selected': reaction.selected }"
          :aria-pressed="Boolean(reaction.selected)"
          @click.stop="emit('react', messageId(), reaction.emoji)"
        >
          {{ reaction.emoji }} {{ reaction.count }}
        </button>
      </template>
      <template v-else>
        <span v-for="reaction in reactions" :key="reaction.emoji" :class="{ 'is-selected': reaction.selected }">
          {{ reaction.emoji }} {{ reaction.count }}
        </span>
      </template>
    </div>
  </article>
</template>
