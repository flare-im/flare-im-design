<script setup lang="ts">
import { computed, nextTick, ref } from "vue";
import { CheckmarkOutline, NotificationsOffOutline, PinOutline } from "../../shared/icon-glyphs";
import { NIcon } from "naive-ui";
import { resolveEmojiPackAssetUrlByKey } from "../composer/ComposerEmojiStickerPopover/composerEmojiAssets";
import { resolveStickerUrlByPackageAndId } from "../composer/ComposerEmojiStickerPopover/composerStickers";
import FrozenStickerThumb from "../composer/FrozenStickerThumb/index.vue";
import PlainTextEmojiRich from "../shared/PlainTextEmojiRich.vue";
import type { FlareConversationRowModel } from "../../shared/contracts/conversation";
import { conversationActions, type ConversationActionCapabilities, type FlareConversationAction } from "../../shared/contracts/conversation-actions";
import type { FlareActionItem } from "../../shared/contracts/action-menu";
import type { Component } from "vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import {
  displayTextFromStoredPreview,
  previewVisualFromMessageContent,
  previewVisualFromStoredPreview,
  type MessagePreviewVisual,
} from "../../utils/messagePreview";
import FlareAvatar from "./FlareAvatar.vue";
import { useFlareAdaptiveSafe } from "../../composables/useAdaptiveMode";
import { useLongPress } from "../../composables/useLongPress";
import FlareActionMenu from "../general/FlareActionMenu.vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareConversationActionSheet from "./FlareConversationActionSheet.vue";
import { conversationActionGlyphs, conversationActionLabelKey } from "./conversationActionPresentation";
import { conversationPreviewKind, conversationTitleEmphasis, conversationUnreadCount, conversationUnreadLabel } from "../../shared/contracts/conversation-presentation";
import { formatConversationTime } from "../../shared/timeline-label";

type AssetUrlLoader = () => Promise<string | undefined>;

const props = withDefaults(
  defineProps<{
    item: FlareConversationRowModel;
    active?: boolean;
    draftPreview?: string;
    /**
     * The conversation actions the host implements. The row offers a menu (right-click,
     * Shift+F10, long-press) with exactly the actions these allow; without it there is no menu.
     */
    capabilities?: ConversationActionCapabilities;
    /** Batch selection: the row is a checkbox that emits toggleSelect instead of select. */
    selectable?: boolean;
    selected?: boolean;
  }>(),
  {
    active: false,
    selectable: false,
    selected: false,
  },
);

const emit = defineEmits<{
  (event: "select", id: string): void;
  (event: "action", action: FlareConversationAction, id: string): void;
  (event: "toggleSelect", id: string): void;
}>();

const { t, locale } = useFlareI18n();
const { isH5 } = useFlareAdaptiveSafe();

function oneLine(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

const displayName = computed(() => props.item.displayName?.trim() || props.item.id);
const draft = computed(() => oneLine(displayTextFromStoredPreview(props.draftPreview ?? props.item.draft ?? "", locale.value)));
const previewKind = computed(() => conversationPreviewKind({ ...props.item, draft: draft.value }));
const previewPrefix = computed(() => {
  if (previewKind.value === "failed") return `[${t("chat.sendFailed")}]`;
  if (previewKind.value === "draft") return `[${t("conversation.draftTag")}]`;
  if (previewKind.value === "mention") return t("conversation.mentionPrefix");
  return "";
});
const contentPreviewVisual = computed(() =>
  previewVisualFromMessageContent(props.item.lastMessage?.content ?? null, locale.value),
);
const storedPreviewVisual = computed(() => previewVisualFromStoredPreview(props.item.lastMessagePreview, locale.value));
const previewVisual = computed<MessagePreviewVisual>(() => {
  if (previewKind.value === "draft") return { kind: "text", text: draft.value };
  if (previewKind.value === "typing") return { kind: "text", text: t("chat.typing") };
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
const unread = computed(() => conversationUnreadCount(props.item.unreadCount));
const unreadText = computed(() => conversationUnreadLabel(props.item.unreadCount));
const strongTitle = computed(() => conversationTitleEmphasis(props.item) === "strong");
// The menu is a dropdown at the pointer on wide layouts and the action sheet on phones.
const menuMode = ref<"dropdown" | "sheet" | null>(null);
const menuX = ref(0);
const menuY = ref(0);
const rowRoot = ref<HTMLElement | null>(null);
useLongPress(rowRoot, {
  enabled: () => menuEntries.value.length > 0,
  onLongPress: (event) => {
    const touch = event.touches[0];
    openMenuAt(touch?.clientX ?? 0, touch?.clientY ?? 0);
  },
});
const timeText = computed(() => {
  if (props.item.timestampLabel !== undefined) return props.item.timestampLabel;
  const raw = Number(props.item.lastMessage?.time ?? props.item.updatedAt ?? 0);
  if (!raw) return "";
  const date = new Date(raw);
  if (!Number.isFinite(date.getTime())) return "";
  return formatConversationTime(date.getTime(), locale.value, t("timeline.yesterday"));
});

const actionSnapshot = computed(() => ({
  id: props.item.id,
  title: displayName.value,
  pinned: props.item.pinned,
  muted: props.item.muted,
  unreadCount: unread.value,
  archived: props.item.archived,
}));
const menuEntries = computed(() => (props.selectable ? [] : conversationActions(actionSnapshot.value, props.capabilities)));
// Destructive actions form their own group, so the menu separates them from the rest.
const menuItems = computed<FlareActionItem<Component>[]>(() =>
  menuEntries.value.map((entry) => ({
    id: entry.action,
    label: t(conversationActionLabelKey(entry.action)),
    icon: conversationActionGlyphs[entry.icon],
    danger: entry.danger,
    group: entry.danger ? "danger" : undefined,
  })),
);

const accessibilityLabel = computed(() => [
  displayName.value,
  unread.value ? `${unread.value} ${t("conversation.filterUnread")}` : "",
  props.item.mentioned ? t("conversation.filterMention") : "",
  props.item.pinned ? t("conversation.pinTag") : "",
  props.item.muted ? t("conversation.muteTag") : "",
  previewPrefix.value,
  previewVisual.value.kind === "text" ? previewVisual.value.text : previewMediaLabel.value,
  timeText.value,
].filter(Boolean).join(", "));

function activateRow(): void {
  if (menuMode.value) return;
  if (props.selectable) emit("toggleSelect", props.item.id);
  else emit("select", props.item.id);
}

function handleAction(action: string): void {
  menuMode.value = null;
  emit("action", action as FlareConversationAction, props.item.id);
}

function onPointerMenuOpen(open: boolean): void {
  if (!open && menuMode.value === "dropdown") menuMode.value = null;
}

function openMenuAt(x: number, y: number): void {
  if (!menuEntries.value.length) return;
  menuX.value = x;
  menuY.value = y;
  menuMode.value = null;
  void nextTick(() => {
    menuMode.value = isH5.value ? "sheet" : "dropdown";
  });
}

function openKeyboardMenu(event: KeyboardEvent): void {
  if (!menuEntries.value.length) return;
  event.preventDefault();
  const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
  openMenuAt(rect.left + 16, rect.top + 40);
}

function openContextMenu(event: MouseEvent): void {
  if (!menuEntries.value.length) return;
  event.preventDefault();
  event.stopPropagation();
  openMenuAt(event.clientX, event.clientY);
}
</script>

<template>
  <article
    ref="rowRoot"
    class="im-conv-item"
    role="listitem"
    :data-conversation-id="item.id"
    :data-preview-kind="previewKind"
    :class="{
      'im-conv-item--active': active,
      'im-conv-item--unread': unread,
      'im-conv-item--muted': item.muted,
      'im-conv-item--pinned': item.pinned,
      'im-conv-item--mobile': isH5,
      'im-conv-item--mentioned': item.mentioned,
      'im-conv-item--strong': strongTitle,
      'im-conv-item--selectable': selectable,
      'im-conv-item--selected': selectable && selected,
    }"
    :aria-current="active ? 'true' : undefined"
    @contextmenu="openContextMenu"
    @keydown.shift.f10="openKeyboardMenu"
    @keydown="($event.key === 'ContextMenu') && openKeyboardMenu($event)"
    @keydown.esc="menuMode = null"
  >
    <button
      type="button"
      class="im-conv-item__select"
      :role="selectable ? 'checkbox' : undefined"
      :aria-checked="selectable ? selected : undefined"
      :aria-label="accessibilityLabel"
      @click="activateRow"
    >
      <span v-if="selectable" class="im-conv-item__check" :class="{ 'is-on': selected }" aria-hidden="true">
        <n-icon v-if="selected" aria-hidden="true" :size="13" :component="CheckmarkOutline" />
      </span>
      <span class="im-conv-item__avatar">
        <FlareAvatar :user-id="item.id" :display-name="displayName" :avatar-url="item.avatarUrl" :size="isH5 ? 44 : 40" />
      </span>
      <span class="im-conv-item__body">
        <span class="im-conv-item__top">
          <span class="im-conv-item__title">{{ displayName }}</span>
          <span v-if="item.pinned || item.muted" class="im-conv-item__marks" aria-hidden="true">
            <n-icon aria-hidden="true" v-if="item.pinned" :component="PinOutline" />
            <n-icon aria-hidden="true" v-if="item.muted" :component="NotificationsOffOutline" />
          </span>
        </span>
        <span class="im-conv-item__bottom">
          <span v-if="previewPrefix" class="im-conv-item__prefix" :class="`is-${previewKind}`">{{ previewPrefix }}</span>
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
        </span>
      </span>
      <span class="im-conv-item__meta" aria-hidden="true">
        <span class="im-conv-item__time" :title="timeText">{{ timeText }}</span>
        <span v-if="unread" class="im-conv-item__unread-pill">{{ unreadText }}</span>
      </span>
    </button>
  </article>
  <FlareActionMenu
    v-if="menuMode === 'dropdown'"
    open
    trigger="manual"
    presentation="anchored"
    placement="bottom-start"
    :x="menuX"
    :y="menuY"
    :items="menuItems"
    :label="displayName"
    @select="handleAction"
    @update:open="onPointerMenuOpen"
  />
  <FlareBottomSheet v-else-if="menuEntries.length" :open="menuMode === 'sheet'" @close="menuMode = null">
    <FlareConversationActionSheet
      :conversation="actionSnapshot"
      :capabilities="capabilities"
      @action="handleAction($event.action)"
      @close="menuMode = null"
    />
  </FlareBottomSheet>
</template>

<style scoped>
.im-conv-item { position: relative; flex: 0 0 auto; width: 100%; min-width: 0; box-sizing: border-box; border-radius: var(--flare-size-radius-md); background: transparent; color: var(--flare-color-text-primary); container-type: inline-size; }
.im-conv-item__select { display: grid; grid-template-columns: auto minmax(0, 1fr) minmax(7ch, max-content); align-items: center; gap: 10px; width: 100%; height: 72px; padding: 10px; box-sizing: border-box; border: 0; border-radius: inherit; background: transparent; color: inherit; cursor: pointer; font: inherit; text-align: start; }
.im-conv-item--mobile .im-conv-item__select { height: 80px; padding-block: 14px; }
@media (hover: hover) { .im-conv-item:hover { background: var(--flare-color-bg-hover); } }
.im-conv-item--active, .im-conv-item--active:hover { background: var(--flare-color-bg-selected); }
.im-conv-item--active .im-conv-item__time { color: var(--flare-color-text-secondary); }
.im-conv-item__select:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.im-conv-item--selectable .im-conv-item__select { grid-template-columns: auto auto minmax(0, 1fr) minmax(7ch, max-content); }
.im-conv-item--selected, .im-conv-item--selected:hover { background: var(--flare-color-bg-selected); }
.im-conv-item__check { display: grid; place-items: center; width: var(--flare-size-icon-size-md); height: var(--flare-size-icon-size-md); box-sizing: border-box; border: 1.5px solid var(--flare-color-border-hover); border-radius: var(--flare-size-radius-sm); background: var(--flare-color-bg-primary); color: var(--flare-color-message-outgoing-foreground); }
.im-conv-item__check.is-on { border-color: var(--flare-color-primary); background: var(--flare-color-primary); }
.im-conv-item__avatar { display: flex; flex-shrink: 0; }
.im-conv-item__body { display: grid; gap: 4px; min-width: 0; }
.im-conv-item__top, .im-conv-item__bottom { display: flex; align-items: center; gap: 4px; min-width: 0; height: 20px; }
.im-conv-item__title { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: var(--flare-size-font-size-lg); font-weight: 500; }
.im-conv-item--strong .im-conv-item__title { font-weight: 700; }
.im-conv-item__marks { display: inline-flex; flex-shrink: 0; gap: 4px; color: var(--flare-color-text-tertiary); font-size: 12px; }
.im-conv-item__meta { display: grid; grid-template-rows: 20px 20px; justify-items: end; align-items: center; gap: 4px; min-width: 0; font-size: var(--flare-size-font-size-sm); }
.im-conv-item__time { white-space: nowrap; text-align: end; font-variant-numeric: tabular-nums; font-size: var(--flare-size-font-size-xs); color: var(--flare-color-text-tertiary); }
.im-conv-item__prefix { flex: 0 1 auto; min-width: 0; max-width: 65%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-primary-text); }
.im-conv-item__prefix.is-failed, .im-conv-item__prefix.is-mention { color: var(--flare-color-error-text); }
.im-conv-item__preview { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); }
.im-conv-item__preview :deep(.pte-rich), .im-conv-item__preview :deep(.pte-fallback), .im-conv-item__preview :deep(.pte-plain) { display: block; max-width: 100%; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.im-conv-item__preview :deep(.pte-run) { display: inline; white-space: inherit; }
.im-conv-item__preview--media { display: inline-flex; align-items: center; gap: 5px; }
.im-conv-item__preview-thumb { flex: 0 0 auto; }
.im-conv-item__preview-text { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.im-conv-item__preview-fallback-icon { display: none; }
.im-conv-item__unread-pill { min-width: 18px; max-width: 100%; height: 18px; box-sizing: border-box; padding-inline: 5px; border-radius: var(--flare-size-radius-full); background: var(--flare-color-primary); color: var(--flare-color-message-outgoing-foreground); font-size: var(--flare-size-font-size-xs); font-weight: 600; line-height: 18px; text-align: center; font-variant-numeric: tabular-nums; }
.im-conv-item--muted:not(.im-conv-item--mentioned) .im-conv-item__unread-pill { background: var(--flare-color-bg-tertiary); color: var(--flare-color-text-secondary); }
@container (max-width: 300px) {
  .im-conv-item__select { gap: 8px; grid-template-columns: auto minmax(0, 1fr) minmax(6ch, max-content); }
  .im-conv-item--selectable .im-conv-item__select { grid-template-columns: auto auto minmax(0, 1fr) minmax(6ch, max-content); }
}
</style>
