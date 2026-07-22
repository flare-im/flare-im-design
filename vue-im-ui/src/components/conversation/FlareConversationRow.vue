<script setup lang="ts">
import { computed, h, nextTick, ref, type Component } from "vue";
import {
  ArchiveOutline,
  ChatbubbleEllipsesOutline,
  CheckmarkDoneOutline,
  MailUnreadOutline,
  NotificationsOffOutline,
  PinOutline,
  TrashOutline,
} from "../../shared/icon-glyphs";
import { NDropdown, NIcon } from "naive-ui";
import { resolveEmojiPackAssetUrlByKey } from "../composer/ComposerEmojiStickerPopover/composerEmojiAssets";
import { resolveStickerUrlByPackageAndId } from "../composer/ComposerEmojiStickerPopover/composerStickers";
import FrozenStickerThumb from "../composer/FrozenStickerThumb/index.vue";
import PlainTextEmojiRich from "../shared/PlainTextEmojiRich.vue";
import type { FlareConversationAction, FlareConversationRowModel } from "../../shared/contracts/conversation";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import {
  displayTextFromStoredPreview,
  previewVisualFromMessageContent,
  previewVisualFromStoredPreview,
  type MessagePreviewVisual,
} from "../../utils/messagePreview";
import FlareAvatar from "./FlareAvatar.vue";

type AssetUrlLoader = () => Promise<string | undefined>;

const props = withDefaults(
  defineProps<{
    item: FlareConversationRowModel;
    active?: boolean;
    draftPreview?: string;
  }>(),
  {
    active: false,
    draftPreview: "",
  },
);

const emit = defineEmits<{
  (event: "select", id: string): void;
  (event: "action", action: FlareConversationAction, id: string): void;
}>();

const { t, locale } = useFlareI18n();

function oneLine(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

const displayName = computed(() => props.item.displayName?.trim() || props.item.id);
const draft = computed(() => oneLine(displayTextFromStoredPreview(props.draftPreview, locale.value)));
const contentPreviewVisual = computed(() =>
  previewVisualFromMessageContent(props.item.lastMessage?.content ?? null, locale.value),
);
const storedPreviewVisual = computed(() => previewVisualFromStoredPreview(props.item.lastMessagePreview, locale.value));
const previewVisual = computed<MessagePreviewVisual>(() => {
  if (draft.value) return { kind: "text", text: draft.value };
  const visual = contentPreviewVisual.value ?? storedPreviewVisual.value;
  if (visual?.kind === "text") return { kind: "text", text: oneLine(visual.text) };
  if (visual) return visual;
  return {
    kind: "text",
    text: props.item.previewPending ? t("conversation.previewPending") : t("conversation.noMessagePreview"),
  };
});
const previewIsMedia = computed(() => previewVisual.value.kind === "emoji" || previewVisual.value.kind === "sticker");
const previewMediaLabel = computed(() => {
  const visual = previewVisual.value;
  if (visual.kind === "sticker") return t("conversation.previewSticker");
  if (visual.kind === "emoji") return visual.label || t("conversation.previewEmoji");
  return "";
});
const previewEmojiLoadSrc = computed<AssetUrlLoader | undefined>(() => {
  const visual = previewVisual.value;
  if (visual.kind !== "emoji") return undefined;
  return () => resolveEmojiPackAssetUrlByKey(visual.key);
});
const previewStickerSrc = computed(() => {
  const visual = previewVisual.value;
  if (visual.kind !== "sticker") return "";
  return visual.url?.trim() ?? "";
});
const previewStickerLoadSrc = computed<AssetUrlLoader | undefined>(() => {
  const visual = previewVisual.value;
  if (visual.kind !== "sticker" || !visual.packageId || !visual.stickerId) return undefined;
  return () => resolveStickerUrlByPackageAndId(visual.packageId ?? "", visual.stickerId ?? "");
});
const unread = computed(() => Math.max(0, Math.floor(Number(props.item.unreadCount ?? 0))));
const unreadText = computed(() => (unread.value > 99 ? "99+" : String(unread.value)));
const menuOpen = ref(false);
const menuX = ref(0);
const menuY = ref(0);
const timeText = computed(() => {
  const raw = Number(props.item.lastMessage?.time ?? props.item.updatedAt ?? 0);
  if (!raw) return "";
  const date = new Date(raw);
  const today = new Date();
  const localeTag = locale.value === "en-US" ? "en-US" : "zh-CN";
  if (date.toDateString() === today.toDateString()) {
    return date.toLocaleTimeString(localeTag, { hour: "2-digit", minute: "2-digit" });
  }
  return date.toLocaleDateString(localeTag, { month: "2-digit", day: "2-digit" });
});

function menuIcon(icon: Component) {
  return () => h(NIcon, { class: "im-conv-menu-icon", component: icon });
}

const menuOptions = computed(() => [
  { label: t("conversation.open"), key: "open", icon: menuIcon(ChatbubbleEllipsesOutline) },
  {
    label: unread.value ? t("conversation.markRead") : t("conversation.markUnread"),
    key: unread.value ? "mark_read" : "mark_unread",
    icon: menuIcon(unread.value ? CheckmarkDoneOutline : MailUnreadOutline),
  },
  { type: "divider", key: "state-divider" },
  {
    label: props.item.pinned ? t("conversation.unpin") : t("conversation.pin"),
    key: props.item.pinned ? "unpin" : "pin",
    icon: menuIcon(PinOutline),
  },
  {
    label: props.item.muted ? t("conversation.unmute") : t("conversation.mute"),
    key: props.item.muted ? "unmute" : "mute",
    icon: menuIcon(NotificationsOffOutline),
  },
  {
    label: props.item.archived ? t("conversation.unarchive") : t("conversation.archive"),
    key: props.item.archived ? "unarchive" : "archive",
    icon: menuIcon(ArchiveOutline),
  },
  { type: "divider", key: "danger-divider" },
  { label: t("conversation.clearHistory"), key: "clear_history", icon: menuIcon(TrashOutline) },
  {
    label: t("conversation.delete"),
    key: "delete",
    icon: menuIcon(TrashOutline),
    props: { class: "im-conv-menu-option--danger" },
  },
]);

function selectConversation(): void {
  emit("select", props.item.id);
}

function handleAction(key: string | number): void {
  menuOpen.value = false;
  emit("action", key as FlareConversationAction, props.item.id);
}

function openMenuAt(x: number, y: number): void {
  menuX.value = x;
  menuY.value = y;
  menuOpen.value = false;
  void nextTick(() => {
    menuOpen.value = true;
  });
}

function openContextMenu(event: MouseEvent): void {
  event.preventDefault();
  event.stopPropagation();
  openMenuAt(event.clientX, event.clientY);
}
</script>

<template>
  <article
    class="im-conv-item"
    role="listitem"
    :class="{
      'im-conv-item--active': active,
      'im-conv-item--unread': unread,
      'im-conv-item--muted': item.muted,
      'im-conv-item--pinned': item.pinned,
    }"
    :aria-current="active ? 'true' : undefined"
    @contextmenu="openContextMenu"
  >
    <button
      type="button"
      class="im-conv-item__select"
      @click="selectConversation"
    >
      <span class="im-conv-item__avatar">
        <FlareAvatar :user-id="item.id" :display-name="displayName" :avatar-url="item.avatarUrl" :size="42" />
      </span>
      <span class="im-conv-item__body">
        <span class="im-conv-item__top">
          <span class="im-conv-item__title">{{ displayName }}</span>
          <span
            v-for="(tag, ti) in (item.tags ?? [])"
            :key="ti"
            class="im-conv-item__tag"
            :class="`im-conv-item__tag--tone-${tag.tone ?? 'neutral'}`"
          >{{ tag.text }}</span>
          <span v-if="draft" class="im-conv-item__tag im-conv-item__tag--draft">{{ t("conversation.draftTag") }}</span>
          <span v-if="item.muted" class="im-conv-item__tag im-conv-item__tag--muted">{{ t("conversation.muteTag") }}</span>
          <span class="im-conv-item__time">{{ timeText }}</span>
        </span>
        <span class="im-conv-item__bottom">
          <span class="im-conv-item__preview" :class="{ 'im-conv-item__preview--media': previewIsMedia }">
            <template v-if="previewVisual.kind === 'emoji'">
              <FrozenStickerThumb
                class="im-conv-item__preview-thumb"
                :load-src="previewEmojiLoadSrc"
                :alt="previewMediaLabel"
                :em-size="1.65"
                object-fit="contain"
                :lazy="false"
              />
              <span class="im-conv-item__preview-text">{{ previewMediaLabel }}</span>
            </template>
            <template v-else-if="previewVisual.kind === 'sticker'">
              <FrozenStickerThumb
                v-if="previewStickerSrc || previewStickerLoadSrc"
                class="im-conv-item__preview-thumb"
                :src="previewStickerSrc"
                :load-src="previewStickerLoadSrc"
                :alt="previewMediaLabel"
                :em-size="1.72"
                object-fit="contain"
                :lazy="false"
              />
              <span v-else class="im-conv-item__preview-fallback-icon" aria-hidden="true" />
              <span class="im-conv-item__preview-text">{{ previewMediaLabel }}</span>
            </template>
            <PlainTextEmojiRich v-else :text="previewVisual.text" :inline-em-size="1.36" />
          </span>
          <span v-if="unread" class="im-conv-item__unread-pill">{{ unreadText }}</span>
        </span>
      </span>
    </button>
    <span v-if="item.pinned" class="im-conv-item__pin" :title="t('conversation.pinTag')" aria-hidden="true">
      <n-icon :component="PinOutline" />
    </span>
  </article>
  <n-dropdown
    class="im-conv-dropdown"
    trigger="manual"
    placement="bottom-end"
    :show="menuOpen"
    :x="menuX"
    :y="menuY"
    :options="menuOptions"
    @select="handleAction"
    @clickoutside="menuOpen = false"
  >
    <span class="im-conv-item__menu-anchor" />
  </n-dropdown>
</template>

<style scoped>
.im-conv-item {
  position: relative;
  display: block;
  width: 100%;
  min-height: var(--im-conversation-row-height, 70px);
  padding: 4px 8px 4px 0;
  border: 1px solid transparent;
  border-radius: 8px;
  background: transparent;
  text-align: left;
  color: inherit;
  font: inherit;
  transition:
    background-color var(--transition-fast, 140ms ease),
    border-color var(--transition-fast, 140ms ease),
    box-shadow var(--transition-fast, 140ms ease);
}

.im-conv-item__select {
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
  min-width: 0;
  min-height: 62px;
  padding: 8px 6px 8px 10px;
  border: 0;
  background: transparent;
  color: inherit;
  cursor: pointer;
  font: inherit;
  text-align: left;
}

.im-conv-item:hover {
  background: var(--im-conv-item-hover, var(--bg-hover));
}

.im-conv-item--active {
  background: var(--im-conv-item-active, var(--bg-selected));
  border-color: color-mix(in srgb, var(--im-conv-item-active-border, var(--primary)) 28%, transparent);
  box-shadow: inset 3px 0 0 var(--im-conv-item-active-border, var(--primary));
}

.im-conv-item--pinned {
  padding-right: 30px;
  /* Pinned rows read as a group — a whisper of violet tint (hover still wins). */
  background: color-mix(in srgb, var(--im-primary, var(--primary, #7c3aed)) 5%, transparent);
}

.im-conv-item--pinned .im-conv-item__top {
  padding-right: 0;
}

.im-conv-item__avatar {
  position: relative;
  flex-shrink: 0;
}

.im-conv-item__body {
  min-width: 0;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.im-conv-item__top,
.im-conv-item__bottom {
  display: flex;
  align-items: center;
  gap: 6px;
  min-width: 0;
}

.im-conv-item__title {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 14px;
  font-weight: 600;
  color: var(--im-conv-title, var(--text-primary));
}

.im-conv-item--unread .im-conv-item__title {
  font-weight: 800;
}

.im-conv-item__time {
  flex-shrink: 0;
  font-size: 11px;
  color: var(--im-conv-meta, var(--text-tertiary));
}

.im-conv-item__tag {
  flex-shrink: 0;
  padding: 0 6px;
  border-radius: 999px;
  font-size: 10px;
  line-height: 18px;
  color: var(--im-primary, var(--primary));
  background: var(--im-primary-soft, rgba(124, 77, 255, 0.12));
}

.im-conv-item__tag--draft {
  color: var(--warning);
  background: rgba(245, 158, 11, 0.12);
}

.im-conv-item__tag--muted {
  color: var(--text-secondary);
  background: var(--bg-tertiary);
}

.im-conv-item__tag--tone-info {
  color: var(--im-info, var(--info, #6d5df6));
  background: color-mix(in srgb, var(--im-info, var(--info, #6d5df6)) 12%, transparent);
}

.im-conv-item__tag--tone-warning {
  color: var(--warning, #f59e0b);
  background: color-mix(in srgb, var(--warning, #f59e0b) 12%, transparent);
}

.im-conv-item__tag--tone-neutral {
  color: var(--text-tertiary, #86909c);
  background: var(--bg-tertiary);
}

.im-conv-item__preview {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 12px;
  color: var(--im-conv-preview, var(--text-secondary));
}

.im-conv-item--unread .im-conv-item__preview {
  color: var(--im-text-primary, var(--text-primary));
}

.im-conv-item__preview :deep(.pte-rich),
.im-conv-item__preview :deep(.pte-fallback),
.im-conv-item__preview :deep(.pte-plain),
.im-conv-item__preview :deep(.pte-run) {
  display: inline-flex;
  max-width: 100%;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  vertical-align: bottom;
}

.im-conv-item__preview--media {
  display: inline-flex;
  align-items: center;
  gap: 5px;
}

.im-conv-item__preview-thumb {
  flex: 0 0 auto;
}

.im-conv-item__preview-text {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.im-conv-item__preview-fallback-icon {
  position: relative;
  width: 18px;
  height: 18px;
  flex: 0 0 auto;
  border-radius: 5px;
  border: 1px solid rgba(124, 77, 255, 0.26);
  background:
    linear-gradient(135deg, rgba(124, 77, 255, 0.16), rgba(124, 77, 255, 0.04)),
    var(--bg-panel, #fff);
}

.im-conv-item__preview-fallback-icon::before,
.im-conv-item__preview-fallback-icon::after {
  content: "";
  position: absolute;
  border-radius: 999px;
  background: var(--im-primary, var(--primary));
  opacity: 0.72;
}

.im-conv-item__preview-fallback-icon::before {
  width: 3px;
  height: 3px;
  left: 5px;
  top: 6px;
}

.im-conv-item__preview-fallback-icon::after {
  width: 7px;
  height: 2px;
  left: 6px;
  bottom: 5px;
}

.im-conv-item__unread-pill {
  --im-unread: var(--im-conv-unread-bg, var(--primary, var(--flare-color-primary, #7c3aed)));

  flex: 0 0 auto;
  min-width: 20px;
  height: 20px;
  padding: 0 6px;
  border-radius: 999px;
  /* A mini Aurora light source — echoes the glowing message bubble: a violet
     gradient, a luminous top edge, and a soft glow (over the surface ring). */
  background: linear-gradient(
    135deg,
    color-mix(in srgb, var(--im-unread) 82%, #ffffff 18%),
    var(--im-unread) 55%,
    color-mix(in srgb, var(--im-unread) 88%, #000000 12%)
  );
  color: #fff;
  font-size: 11px;
  font-weight: 800;
  line-height: 20px;
  text-align: center;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.28),
    0 0 0 2px var(--im-bg-surface, #fff),
    0 2px 8px -1px color-mix(in srgb, var(--im-unread) 46%, transparent);
}

/* Muted conversations don't shout: an unread there is a quiet neutral dot, not
   the loud violet badge (standard IM semantics). */
.im-conv-item--muted .im-conv-item__unread-pill {
  min-width: 9px;
  width: 9px;
  height: 9px;
  padding: 0;
  background: var(--im-text-tertiary, var(--text-tertiary, #98a2b3));
  color: transparent;
  font-size: 0;
  box-shadow: 0 0 0 2px var(--im-bg-surface, #fff);
}

.im-conv-item__pin {
  position: absolute;
  top: 10px;
  right: 10px;
  z-index: 1;
  display: grid;
  place-items: center;
  width: 16px;
  height: 16px;
  color: var(--im-primary, var(--flare-color-primary, #7c3aed));
  background: transparent;
  font-size: 13px;
  opacity: 0.6;
  pointer-events: none;
}

.im-conv-item__menu-anchor {
  position: fixed;
  width: 0;
  height: 0;
  overflow: hidden;
  pointer-events: none;
}

:global(.im-conv-dropdown) {
  min-width: 190px;
  padding: 6px !important;
  border: 1px solid color-mix(in srgb, var(--im-border, #e5e7eb) 72%, transparent);
  border-radius: 10px !important;
  background: color-mix(in srgb, var(--im-bg-surface, #fff) 96%, var(--im-bg-app, #f3f4f8));
  box-shadow:
    0 18px 44px rgba(15, 23, 42, 0.16),
    0 2px 8px rgba(15, 23, 42, 0.08);
}

:global(.im-conv-dropdown .n-dropdown-option) {
  min-height: 40px;
  padding: 0 !important;
  border-radius: 8px;
}

:global(.im-conv-dropdown .n-dropdown-option-body) {
  display: grid !important;
  grid-template-columns: 28px minmax(0, 1fr);
  align-items: center !important;
  gap: 8px;
  height: 40px;
  min-height: 40px;
  padding: 0 10px !important;
  border-radius: 8px;
}

:global(.im-conv-dropdown .n-dropdown-option-body--pending) {
  background: color-mix(in srgb, var(--im-primary, var(--flare-color-primary, #7c3aed)) 9%, transparent) !important;
}

:global(.im-conv-dropdown .n-dropdown-option-body__prefix) {
  display: grid !important;
  place-items: center;
  width: 28px !important;
  margin: 0 !important;
  color: var(--im-text-tertiary, #98a2b3);
}

:global(.im-conv-dropdown .im-conv-menu-icon) {
  font-size: 20px;
}

:global(.im-conv-dropdown .n-dropdown-option-body__label) {
  display: flex !important;
  align-items: center;
  min-width: 0;
  height: 100%;
  color: var(--im-text-primary, var(--flare-color-text-primary, #111318));
  font-size: 14px;
  font-weight: 650;
  line-height: 1.25;
  white-space: nowrap;
}

:global(.im-conv-dropdown .n-dropdown-divider) {
  margin: 6px 4px;
  background: color-mix(in srgb, var(--im-border, #e5e7eb) 72%, transparent);
}

:global(.im-conv-dropdown .im-conv-menu-option--danger .n-dropdown-option-body__prefix),
:global(.im-conv-dropdown .im-conv-menu-option--danger .n-dropdown-option-body__label) {
  color: var(--im-danger, var(--flare-color-error, #ef4444)) !important;
}

@media (hover: none) {
  .im-conv-item__menu {
    opacity: 1;
  }
}
</style>
