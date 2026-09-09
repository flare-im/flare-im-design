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
  ArchiveOutline,
  CheckmarkDoneOutline,
  EyeOffOutline,
  FileTrayOutline,
  NotificationsOffOutline,
  NotificationsOutline,
  PinOutline,
  TrashOutline,
} from "../../shared/icon-glyphs";
import {
  conversationActions,
  type ConversationActionCapabilities,
  type ConversationActionEntry,
  type ConversationActionIcon,
  type ConversationActionId,
  type ConversationActionPayload,
  type ConversationActionSnapshot,
} from "../../shared/contracts/conversation-actions";

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
    pinText: "置顶",
    unpinText: "取消置顶",
    muteText: "免打扰",
    unmuteText: "取消免打扰",
    markReadText: "标为已读",
    archiveText: "归档",
    unarchiveText: "取消归档",
    hideText: "隐藏",
    deleteText: "删除",
    emptyText: "暂无可用操作",
  },
);

const emit = defineEmits<{
  (event: "action", payload: ConversationActionPayload): void;
  (event: "close"): void;
}>();

const glyphs: Record<ConversationActionIcon, unknown> = {
  pin: PinOutline,
  unpin: PinOutline,
  mute: NotificationsOffOutline,
  unmute: NotificationsOutline,
  markRead: CheckmarkDoneOutline,
  archive: ArchiveOutline,
  unarchive: FileTrayOutline,
  hide: EyeOffOutline,
  delete: TrashOutline,
};

const entries = computed(() => conversationActions(props.conversation, props.capabilities));
const primary = computed(() => entries.value.filter((e) => !e.danger));
const danger = computed(() => entries.value.filter((e) => e.danger));

function labelFor(action: ConversationActionId): string {
  switch (action) {
    case "pin": return props.pinText;
    case "unpin": return props.unpinText;
    case "mute": return props.muteText;
    case "unmute": return props.unmuteText;
    case "markRead": return props.markReadText;
    case "archive": return props.archiveText;
    case "unarchive": return props.unarchiveText;
    case "hide": return props.hideText;
    case "delete": return props.deleteText;
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
    role="menu"
    :aria-label="conversation.title"
    :aria-busy="busy || undefined"
    @keydown="onKeydown"
  >
    <div class="flare-conv-actions__title" :title="conversation.title">{{ conversation.title }}</div>

    <p v-if="!entries.length" class="flare-conv-actions__empty" role="status">{{ emptyText }}</p>

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
          <n-icon :size="20" :component="glyphs[entry.icon] as any" />
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
          <n-icon :size="20" :component="glyphs[entry.icon] as any" />
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
  gap: var(--flare-size-spacing-sm, 8px);
  min-width: 0;
  padding: var(--flare-size-spacing-xs, 4px) var(--flare-size-spacing-sm, 8px);
  color: var(--flare-color-text-primary);
}
.flare-conv-actions__title {
  padding: var(--flare-size-spacing-xs, 4px) var(--flare-size-spacing-md, 12px);
  font-size: var(--flare-size-font-size-sm, 12px);
  font-weight: 500;
  color: var(--flare-color-text-tertiary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-conv-actions__empty {
  margin: 0;
  padding: var(--flare-size-spacing-md, 12px);
  font-size: var(--flare-size-font-size-lg, 14px);
  color: var(--flare-color-text-secondary);
  text-align: center;
}
.flare-conv-actions__group {
  display: flex;
  flex-direction: column;
  padding: var(--flare-size-spacing-xs, 4px) 0;
  border-radius: var(--flare-size-radius-2xl, 18px);
  background: var(--flare-color-bg-primary);
}
.flare-conv-actions__group--danger {
  border-top: 1px solid var(--flare-color-border-secondary);
}
.flare-conv-actions__row {
  display: grid;
  grid-template-columns: 44px minmax(0, 1fr);
  align-items: center;
  gap: var(--flare-size-spacing-md, 12px);
  width: 100%;
  min-height: var(--flare-size-layout-touch-target, 48px);
  padding: var(--flare-size-spacing-sm, 8px) var(--flare-size-spacing-md, 12px);
  border: 0;
  border-radius: var(--flare-size-radius-xl, 14px);
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
  outline: 2px solid var(--flare-color-focus-ring, var(--flare-color-primary));
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
  border-radius: var(--flare-size-radius-full, 999px);
  color: var(--flare-color-primary);
  background: color-mix(in srgb, var(--flare-color-primary) 10%, var(--flare-color-bg-primary));
}
.flare-conv-actions__row:disabled .flare-conv-actions__icon {
  color: var(--flare-color-text-disabled);
  background: var(--flare-color-bg-disabled);
}
.flare-conv-actions__label {
  font-size: var(--flare-size-font-size-2xl, 16px);
  font-weight: 600;
  line-height: var(--flare-size-line-height-tight, 1.2);
  overflow-wrap: anywhere;
}
.flare-conv-actions__row--danger:not(:disabled),
.flare-conv-actions__row--danger:not(:disabled) .flare-conv-actions__icon {
  color: var(--flare-color-error);
}
.flare-conv-actions__row--danger:not(:disabled) .flare-conv-actions__icon {
  background: color-mix(in srgb, var(--flare-color-error) 12%, var(--flare-color-bg-primary));
}
</style>
