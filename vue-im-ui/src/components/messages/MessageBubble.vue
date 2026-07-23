<script setup lang="ts">
import { computed, h, ref, type Component } from "vue";
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
import MessageStatus from "./MessageStatus.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import {
  isMessageMenuActionEnabled,
  mergeMessageMenuConfig,
  type MessageMenuConfig,
  type MessageMenuMediaAction,
} from "../../shared/config/messageMenu";
import { buildMessageMenuContext } from "../../utils/buildMessageMenuOptions";
import { MESSAGE_QUICK_REACTIONS } from "../../shared/constants/messageReactions";
import {
  isChromelessCardBubble,
  isChromelessMediaBubble,
} from "../../utils/messageBubbleChromeless";
import { messageStateToNumber } from "../../utils/messageState";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

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
  conversationType?: "single" | "group" | "ai" | string;
  groupStart?: boolean;
  groupEnd?: boolean;
  mediaDownloadState?: MessageMediaDownloadUiState;
  /** Just-arrived (appended at the tail) — plays a one-shot entrance animation. */
  fresh?: boolean;
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
}>();

const { profile } = useMessageMenuInteraction();
const { t, locale } = useFlareI18n();
const menuRef = ref<InstanceType<typeof MessageMenu> | null>(null);
const bubbleAnchorRef = ref<HTMLElement | null>(null);

function messageId(): string {
  return props.message.clientMsgId || props.message.serverId;
}

function isPinned(message: MessageLike): boolean {
  return message.attributes?.pinned === "true";
}

const contentType = computed(() =>
  messageContentTypeForUi(props.message.content?.contentType ?? "text"),
);
const isSystemLike = computed(() =>
  ["system", "notification"].includes(contentType.value),
);
const isRecalled = computed(() => props.message.isRecalled);
const deliveryStatus = computed(() => messageStateToNumber(props.message));
const reactions = computed(() => (isRecalled.value ? [] : props.message.reactions ?? []));
const isChromelessMedia = computed(() =>
  isChromelessMediaBubble(props.message),
);
const isChromelessCard = computed(() =>
  isChromelessCardBubble(props.message),
);
const isFailed = computed(() => deliveryStatus.value === 5);
const messagePinned = computed(() => isPinned(props.message));
const isEdited = computed(() =>
  Boolean(
    props.message.isEdited || props.message.attributes?.edited === "true",
  ),
);
const messageExtraForContent = computed(() => ({
  ...(props.message.attributes ?? {}),
  textPreview: props.message.textPreview,
  quotePreview: props.message.quotePreview,
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
  if (props.conversationType === "group") {
    return t("message.recalledGroupOther", { name: senderLabel.value });
  }
  return t("message.recalledPeer");
});
const messageTimeText = computed(() =>
  timeText(props.message.createdAt || props.message.clientCreatedAt),
);
const isGroupStart = computed(() => props.groupStart ?? true);
const isGroupEnd = computed(() => props.groupEnd ?? true);
const showSenderMeta = computed(
  () =>
    !isSystemLike.value
    && !isRecalled.value
    && !props.multiSelectMode
    && !props.self
    // Name only in GROUPS. In a 1:1 the peer is already named in the header, so
    // repeating it over every run reads as clutter (Feishu/WeChat hide it too).
    && props.conversationType === "group"
    && isGroupStart.value,
);
const showSenderAvatar = computed(
  () =>
    !isSystemLike.value
    && !isRecalled.value
    && !props.multiSelectMode
    && !props.self
    // Avatar + name only in GROUPS (matches native iOS/Android/Flutter, and the
    // modern 1:1 convention — Telegram/iMessage/WhatsApp show neither). In a 1:1
    // the peer is obvious from the header, so incoming rows are just clean bubbles.
    && props.conversationType === "group"
    && isGroupStart.value,
);
const showFloatingHoverTime = computed(
  () => Boolean(messageTimeText.value) && (props.self || !showSenderMeta.value),
);

const showMessageStatus = computed(() => {
  if (!props.self || isSystemLike.value || isRecalled.value) return false;
  const n = deliveryStatus.value;
  return n >= 1 && n <= 5;
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
const uploadProgressOnMedia = computed(() =>
  showUploadProgress.value &&
  ["image", "image_group", "video", "audio", "file"].includes(contentType.value),
);

const showSelectControl = computed(
  () => Boolean(props.multiSelectMode) && !isSystemLike.value && !isRecalled.value,
);

const statusLayoutIsTrailing = computed(() => {
  if (!props.self) return false;
  if (isChromelessCard.value) return false;
  const ct = contentType.value;
  return ct === "text" || ct === "rich_text" || ct === "file" || ct === "quote";
});

const statusOverlayPersistent = computed(() => {
  const n = deliveryStatus.value;
  return n === 1 || n === 5;
});

const showMenuChrome = computed(
  () => !isSystemLike.value && !props.multiSelectMode && !isRecalled.value,
);

const bubbleKeyboardEnabled = computed(() => showMenuChrome.value);

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
      label: "Downloading",
      icon: RefreshOutline,
      state,
    };
  }
  if (state === "downloaded") {
    return {
      id: "downloadMedia",
      action: null,
      label: "Downloaded",
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

const fileInlineMediaAction = computed<MediaHoverActionModel | null>(() => {
  if (contentType.value !== "file") return null;
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
  if (!timestamp) return "";
  const localeTag = locale.value === "en-US" ? "en-US" : "zh-CN";
  return new Date(timestamp).toLocaleTimeString(localeTag, {
    hour: "2-digit",
    minute: "2-digit",
  });
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
  if (!bubbleKeyboardEnabled.value) return;
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
      'message-row--fresh': fresh,
      'message-row--with-meta': showSenderMeta,
      'message-row--with-avatar': showSenderAvatar,
    }"
    :data-menu-surface="profile.mode"
    :data-message-id="messageId()"
  >
    <button
      v-if="showSelectControl"
      type="button"
      class="message-select"
      :class="{ 'message-select--on': selected }"
      @click="emit('toggle-select', messageId())"
    >
      <span v-if="selected" class="message-select__check" aria-hidden="true" />
    </button>

    <div
      v-if="showSenderAvatar"
      class="message-avatar"
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
      <span v-if="messageTimeText" class="message-meta__time">
        {{ messageTimeText }}
      </span>
    </div>

    <div v-if="isRecalled" class="message-recalled-hint">
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
          @react="(emoji: string) => emit('react', messageId(), emoji)"
        >
          <div
            ref="bubbleAnchorRef"
            class="message-bubble"
            :class="[
              ...bubbleClassNames,
              { 'message-bubble--focusable': bubbleKeyboardEnabled },
            ]"
            :tabindex="bubbleKeyboardEnabled ? 0 : undefined"
            :aria-label="bubbleKeyboardEnabled ? bubbleA11yLabel() : undefined"
            @dblclick="emit('preview', messageId())"
            @keydown="onBubbleKeydown"
          >
            <div
              class="message-bubble-body"
              :class="{
                'message-bubble-body--trailing-status':
                  statusLayoutIsTrailing && showMessageStatus,
              }"
            >
              <MessageContentView
                :content="message.content"
                :self="self"
                :message-id="messageId()"
                :message-extra="messageExtraForContent"
                :sender-name="senderLabel"
                :media-action="fileInlineMediaAction?.action"
                :media-state="fileInlineMediaAction?.state"
                @locate-message="emit('locate-message', $event)"
                @media-action="(action: 'download' | 'openFolder') => emit('mediaAction', messageId(), action)"
              />
              <MessageStatus
                v-if="showMessageStatus && statusLayoutIsTrailing"
                class="bubble-inline-status"
                variant="inline"
                :status="deliveryStatus"
                @resend="emit('resend', message.clientMsgId)"
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
              :disabled="!mediaHoverAction.action"
              @click.stop="emitMediaHoverAction"
            >
              <n-icon :component="mediaHoverAction.icon" />
            </button>
            <footer
              v-if="isEdited && !isRecalled"
              class="message-bubble-footer"
            >
              <span class="message-edited-tag">{{ t("message.edited") }}</span>
            </footer>
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
              <n-icon :component="PinOutline" />
            </span>
            <MessageStatus
              v-if="showMessageStatus && !statusLayoutIsTrailing"
              class="message-status-bubble-overlay"
              :class="{
                'message-status-bubble-overlay--persistent':
                  statusOverlayPersistent,
              }"
              variant="bubbleOverlay"
              :status="deliveryStatus"
              @resend="emit('resend', message.clientMsgId)"
            />
          </div>
        </MessageMenu>
        <MessageBubbleHoverToolbar
          beside
          :message="message"
          :current-user-id="currentUserId"
          :reaction-options="reactionPickerOptions"
          :menu-config="menuConfig"
          @quick-reply="emit('reply', messageId())"
          @reaction-select="onReactionSelect"
          @reply="emit('reply', $event)"
          @forward="emit('forward', $event)"
          @multi-select="emit('multiSelect', $event)"
          @edit="emit('edit', $event)"
          @recall="emit('recall', $event)"
          @pin="(id: string, pinned: boolean, scope: 'conversation' | 'self') => emit('pin', id, pinned, scope)"
          @mark="emit('mark', $event)"
          @preview="emit('preview', $event)"
          @media-action="(id: string, action: 'download' | 'openFolder') => emit('mediaAction', id, action)"
          @delete="emit('delete', $event)"
        />
        <span v-if="showFloatingHoverTime" class="message-hover-time">
          {{ messageTimeText }}
        </span>
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
          @react="(emoji: string) => emit('react', messageId(), emoji)"
        >
          <div
            ref="bubbleAnchorRef"
            class="message-bubble"
            :class="[
              ...bubbleClassNames,
              { 'message-bubble--focusable': bubbleKeyboardEnabled },
            ]"
            :tabindex="bubbleKeyboardEnabled ? 0 : undefined"
            :aria-label="bubbleKeyboardEnabled ? bubbleA11yLabel() : undefined"
            @dblclick="emit('preview', messageId())"
            @keydown="onBubbleKeydown"
          >
            <div
              class="message-bubble-body"
              :class="{
                'message-bubble-body--trailing-status':
                  statusLayoutIsTrailing && showMessageStatus,
              }"
            >
              <MessageContentView
                :content="message.content"
                :self="self"
                :message-id="messageId()"
                :message-extra="messageExtraForContent"
                :sender-name="senderLabel"
                :media-action="fileInlineMediaAction?.action"
                :media-state="fileInlineMediaAction?.state"
                @locate-message="emit('locate-message', $event)"
                @media-action="(action: 'download' | 'openFolder') => emit('mediaAction', messageId(), action)"
              />
              <MessageStatus
                v-if="showMessageStatus && statusLayoutIsTrailing"
                class="bubble-inline-status"
                variant="inline"
                :status="deliveryStatus"
                @resend="emit('resend', message.clientMsgId)"
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
              :disabled="!mediaHoverAction.action"
              @click.stop="emitMediaHoverAction"
            >
              <n-icon :component="mediaHoverAction.icon" />
            </button>
            <footer
              v-if="isEdited && !isRecalled"
              class="message-bubble-footer"
            >
              <span class="message-edited-tag">{{ t("message.edited") }}</span>
            </footer>
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
              <n-icon :component="PinOutline" />
            </span>
            <MessageStatus
              v-if="showMessageStatus && !statusLayoutIsTrailing"
              class="message-status-bubble-overlay"
              :class="{
                'message-status-bubble-overlay--persistent':
                  statusOverlayPersistent,
              }"
              variant="bubbleOverlay"
              :status="deliveryStatus"
              @resend="emit('resend', message.clientMsgId)"
            />
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
          @click.stop="openTouchMenu"
        >
          <n-icon :component="EllipsisHorizontalOutline" />
        </button>
      </template>
    </div>

    <div v-if="reactions.length" class="message-reactions">
      <span v-for="reaction in reactions" :key="reaction.emoji">
        {{ reaction.emoji }} {{ reaction.count }}
      </span>
    </div>
  </article>
</template>
