<script setup lang="ts">
import { computed, getCurrentInstance, h, ref, useId, type Component } from "vue";
import type { FlareConversationKind } from "../../shared/contracts/conversation";
import {
  CloudDoneOutline,
  DownloadOutline,
  EllipsisHorizontalOutline,
  FolderOpenOutline,
  PinOutline,
  RefreshOutline,
} from "../../shared/icon-glyphs";
import { NButton, NIcon } from "naive-ui";
import type { DropdownOption } from "naive-ui";
import { messageContentTypeForUi } from "../../utils/messageContent";
import { avatarTint } from "../../shared/avatar-tint";
import { useLongPress } from "../../composables/useLongPress";
import { useMessageMenuInteraction } from "../../composables/chat/useMessageMenuInteraction";
import MessageContentView from "./MessageContentView.vue";
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
import {
  isChromelessCardBubble,
  isChromelessMediaBubble,
} from "../../utils/messageBubbleChromeless";
import { resolveMessageStatus } from "../../utils/messageStatus";
import { formatMessageTime } from "../../shared/timeline-label";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type {
  FlareMessageGroupPosition,
  FlareMessageRowPresentation,
} from "../../shared/contracts/message-grouping";

export type { MessageLike } from "../../shared/contracts/messageRow";

export type MessageMediaDownloadUiState =
  | "idle"
  | "downloading"
  | "downloaded"
  | "openFolder";

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
// System notices ("群聊 X 已创建", "Y 加入群聊") carry a human-readable `body`; show
// it as centered muted text rather than a chat bubble with a placeholder.
const systemText = computed(() => {
  const c = props.message.content as Record<string, unknown> | undefined;
  return String(c?.body ?? c?.text ?? "").trim();
});
const isRecalled = computed(() => props.message.isRecalled);
const deliveryStatus = computed(() => resolveMessageStatus(props.message));
const reactions = computed(() => (isRecalled.value ? [] : props.message.reactions ?? []));
const isChromelessMedia = computed(() =>
  isChromelessMediaBubble(props.message),
);
const isChromelessCard = computed(() =>
  isChromelessCardBubble(props.message),
);
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
const uploadProgress = computed(() => {
  const n = Number(props.message.localState?.uploadProgress) || 0;
  return Math.max(0, Math.min(100, Math.round(n)));
});
const showUploadProgress = computed(() =>
  !isSystemLike.value &&
  !isRecalled.value &&
  Boolean(props.message.localState?.uploading || (uploadProgress.value > 0 && uploadProgress.value < 100)),
);
const uploadProgressOnMedia = computed(() =>
  showUploadProgress.value &&
  ["image", "image_group", "video", "audio", "file"].includes(contentType.value),
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
  if (state === "downloaded") {
    return {
      id: "downloadMedia",
      action: null,
      label: t("messageMenu.downloadedMedia"),
      icon: CloudDoneOutline,
      state,
    };
  }
  if (state === "openFolder") {
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

// Files show the action inline; images offer the download inside their full-screen preview.
const fileInlineMediaAction = computed<MediaHoverActionModel | null>(() => {
  if (contentType.value !== "file" && contentType.value !== "image") return null;
  const stateModel = mediaStateModel(props.mediaDownloadState ?? "idle");
  if (stateModel) return stateModel;
  return resolvedMediaActionId.value ? mediaActionModel(resolvedMediaActionId.value) : null;
});

const bubbleClassNames = computed(() => [
  `message-bubble--${contentType.value}`,
  {
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

function bubbleA11yLabel(): string {
  return `${senderLabel.value}, ${timeText(props.message.createdAt || props.message.clientCreatedAt)}`;
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
    @focusin="onRowFocusin"
    @focusout="onRowFocusout"
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

    <div v-else-if="isRecalled" class="message-recalled-hint">
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
            @dblclick="emit('preview', messageId())"
            @keydown="onBubbleKeydown"
          >
            <div :id="bubbleBodyId" class="message-bubble-body">
              <MessageContentView
                :content="message.content"
                :self="self"
                :message-id="messageId()"
                :message-extra="messageExtraForContent"
                :sender-name="senderLabel"
                :media-action="fileInlineMediaAction?.action"
                :media-state="fileInlineMediaAction?.state"
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
              :tone="self && !isChromelessMedia && !isFailed ? 'onOutgoing' : 'default'"
              :overlay="isChromelessCard"
              @resend="emit('resend', message.clientMsgId)"
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
            @dblclick="emit('preview', messageId())"
            @keydown="onBubbleKeydown"
          >
            <div :id="bubbleBodyId" class="message-bubble-body">
              <MessageContentView
                :content="message.content"
                :self="self"
                :message-id="messageId()"
                :message-extra="messageExtraForContent"
                :sender-name="senderLabel"
                :media-action="fileInlineMediaAction?.action"
                :media-state="fileInlineMediaAction?.state"
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
              :tone="self && !isChromelessMedia && !isFailed ? 'onOutgoing' : 'default'"
              :overlay="isChromelessCard"
              @resend="emit('resend', message.clientMsgId)"
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
