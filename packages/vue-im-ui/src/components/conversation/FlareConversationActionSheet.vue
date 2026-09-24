<script setup lang="ts">
// Conversation action menu — the body of a long-press / right-click / "more"
// popover for ONE conversation. It owns no positioning: hosts place it inside
// FlareBottomSheet (app mode) or a popover (desktop). The host passes the
// conversation snapshot + the capabilities it can honour; visible actions are
// computed by the shared `conversationActions` contract so all four platforms
// agree on set, order and grouping.
import { computed, ref } from "vue";
import { NIcon } from "naive-ui";
import {
  conversationActions,
  type ConversationActionCapabilities,
  type ConversationActionEntry,
  type ConversationActionPayload,
  type ConversationActionSnapshot,
  type FlareConversationAction,
} from "../../shared/contracts/conversation-actions";
import { conversationActionGlyphs as glyphs, conversationActionLabelKey } from "./conversationActionPresentation";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { useFlareAdaptiveSafe } from "../../composables/useAdaptiveMode";
const { isH5 } = useFlareAdaptiveSafe();

const props = withDefaults(
  defineProps<{
    conversation: ConversationActionSnapshot;
    capabilities?: ConversationActionCapabilities;
    /** Host sets this synchronously before dispatching a command; disables every row. */
    busy?: boolean;
    pinText?: string;
    unpinText?: string;
    muteText?: string;
    unmuteText?: string;
    markReadText?: string;
    archiveText?: string;
    unarchiveText?: string;
    hideText?: string;
    deleteText?: string;
    /** Shown when no capability is granted, so the menu never opens blank. */
    emptyText?: string;
  }>(),
  {
    capabilities: () => ({}),
    busy: false,
  },
);
const { t } = useFlareI18n();
const strings = computed(() => ({
  pinText: props.pinText ?? t("conversationActionSheet.pin"),
  unpinText: props.unpinText ?? t("conversationActionSheet.unpin"),
  muteText: props.muteText ?? t("conversationActionSheet.mute"),
  unmuteText: props.unmuteText ?? t("conversationActionSheet.unmute"),
  markReadText: props.markReadText ?? t("conversationActionSheet.markRead"),
  archiveText: props.archiveText ?? t("conversationActionSheet.archive"),
  unarchiveText: props.unarchiveText ?? t("conversationActionSheet.unarchive"),
  hideText: props.hideText ?? t("conversationActionSheet.hide"),
  deleteText: props.deleteText ?? t("conversationActionSheet.delete"),
  emptyText: props.emptyText ?? t("conversationActionSheet.empty"),
}));

const emit = defineEmits<{
  (event: "action", payload: ConversationActionPayload): void;
  (event: "close"): void;
}>();

const entries = computed(() => conversationActions(props.conversation, props.capabilities));
const primary = computed(() => entries.value.filter((e) => !e.danger));
const danger = computed(() => entries.value.filter((e) => e.danger));

function labelFor(action: FlareConversationAction): string {
  switch (action) {
    case "pin": return strings.value.pinText;
    case "unpin": return strings.value.unpinText;
    case "mute": return strings.value.muteText;
    case "unmute": return strings.value.unmuteText;
    case "markRead": return strings.value.markReadText;
    case "archive": return strings.value.archiveText;
    case "unarchive": return strings.value.unarchiveText;
    case "hide": return strings.value.hideText;
    case "delete": return strings.value.deleteText;
    default: return t(conversationActionLabelKey(action));
  }
}

function select(entry: ConversationActionEntry): void {
  if (props.busy) return;
  emit("action", { id: props.conversation.id, action: entry.action });
}

// Keyboard: Escape closes; ArrowUp/Down roam the enabled rows (Tab still works).
const rootEl = ref<HTMLElement | null>(null);
function onKeydown(e: KeyboardEvent): void {
  if (e.key === "Escape") {
    e.preventDefault();
    emit("close");
    return;
  }
  if (e.key !== "ArrowDown" && e.key !== "ArrowUp") return;
  const rows = Array.from(
    rootEl.value?.querySelectorAll<HTMLButtonElement>("button:not(:disabled)") ?? [],
  );
  if (!rows.length) return;
  e.preventDefault();
  const idx = rows.indexOf(document.activeElement as HTMLButtonElement);
  const next = e.key === "ArrowDown" ? (idx + 1) % rows.length : (idx - 1 + rows.length) % rows.length;
  rows[next]?.focus();
}
</script>

<template>
  <div
    ref="rootEl"
    class="flare-conv-actions"
    :class="{ 'flare-conv-actions--desktop': !isH5 }"
    role="menu"
    :aria-label="conversation.title"
    :aria-busy="busy || undefined"
    @keydown="onKeydown"
  >
    <div class="flare-conv-actions__title" :title="conversation.title">{{ conversation.title }}</div>

    <p v-if="!entries.length" class="flare-conv-actions__empty" role="status">{{ strings.emptyText }}</p>

    <div v-if="primary.length" class="flare-conv-actions__group">
      <button
        v-for="entry in primary"
        :key="entry.action"
        type="button"
        role="menuitem"
        class="flare-conv-actions__row"
        :disabled="busy"
        @click="select(entry)"
      >
        <span class="flare-conv-actions__icon" aria-hidden="true">
          <n-icon aria-hidden="true" :size="20" :component="glyphs[entry.icon]" />
        </span>
        <span class="flare-conv-actions__label">{{ labelFor(entry.action) }}</span>
      </button>
    </div>

    <div v-if="danger.length" class="flare-conv-actions__group flare-conv-actions__group--danger">
      <button
        v-for="entry in danger"
        :key="entry.action"
        type="button"
        role="menuitem"
        class="flare-conv-actions__row flare-conv-actions__row--danger"
        :disabled="busy"
        @click="select(entry)"
      >
        <span class="flare-conv-actions__icon" aria-hidden="true">
          <n-icon aria-hidden="true" :size="20" :component="glyphs[entry.icon]" />
        </span>
        <span class="flare-conv-actions__label">{{ labelFor(entry.action) }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-conv-actions {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
  color: var(--flare-color-text-primary);
}
.flare-conv-actions__title {
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-md);
  font-size: var(--flare-size-font-size-sm);
  font-weight: 500;
  color: var(--flare-color-text-tertiary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-conv-actions__empty {
  margin: 0;
  padding: var(--flare-size-spacing-md);
  font-size: var(--flare-size-font-size-lg);
  color: var(--flare-color-text-secondary);
  text-align: center;
}
.flare-conv-actions__group {
  display: flex;
  flex-direction: column;
  padding: var(--flare-size-spacing-xs) 0;
  border-radius: var(--flare-size-radius-2xl);
  background: var(--flare-color-bg-primary);
}
.flare-conv-actions__group--danger {
  border-top: 1px solid var(--flare-color-border-secondary);
}
.flare-conv-actions__row {
  display: grid;
  grid-template-columns: 44px minmax(0, 1fr);
  align-items: center;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  min-height: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  border: 0;
  border-radius: var(--flare-size-radius-xl);
  background: transparent;
  color: inherit;
  cursor: pointer;
  font: inherit;
  text-align: start;
}
.flare-conv-actions__row:hover:not(:disabled),
.flare-conv-actions__row:active:not(:disabled) {
  background: var(--flare-color-bg-hover);
}
.flare-conv-actions__row:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: -2px;
  background: var(--flare-color-bg-hover);
}
.flare-conv-actions__row:disabled {
  color: var(--flare-color-text-disabled);
  cursor: default;
}
.flare-conv-actions__icon {
  display: grid;
  place-items: center;
  width: 44px;
  height: 44px;
  border-radius: var(--flare-size-radius-full);
  color: var(--flare-color-primary-text);
  background: color-mix(in srgb, var(--flare-color-primary) 10%, var(--flare-color-bg-primary));
}
.flare-conv-actions__row:disabled .flare-conv-actions__icon {
  color: var(--flare-color-text-disabled);
  background: var(--flare-color-bg-disabled);
}
.flare-conv-actions__label {
  font-size: var(--flare-size-font-size-2xl);
  font-weight: 600;
  line-height: var(--flare-size-line-height-tight);
  overflow-wrap: anywhere;
}
.flare-conv-actions__row--danger:not(:disabled),
.flare-conv-actions__row--danger:not(:disabled) .flare-conv-actions__icon {
  color: var(--flare-color-error-text);
}
.flare-conv-actions__row--danger:not(:disabled) .flare-conv-actions__icon {
  background: color-mix(in srgb, var(--flare-color-error) 12%, var(--flare-color-bg-primary));
}
.flare-conv-actions--desktop .flare-conv-actions__row { grid-template-columns: 18px minmax(0, 1fr); min-height: 36px; padding: 6px var(--flare-size-spacing-2sm); gap: var(--flare-size-spacing-2sm); border-radius: var(--flare-size-radius-md); }
.flare-conv-actions--desktop .flare-conv-actions__icon { width: 18px; height: 18px; background: transparent; color: var(--flare-color-text-secondary); }
.flare-conv-actions--desktop .flare-conv-actions__label { font-size: var(--flare-size-font-size-md); font-weight: 500; }
.flare-conv-actions--desktop .flare-conv-actions__group { border-radius: 0; padding: 4px 0; }
.flare-conv-actions--desktop .flare-conv-actions__row--danger .flare-conv-actions__icon { background: transparent; color: var(--flare-color-error-text); }
</style>
