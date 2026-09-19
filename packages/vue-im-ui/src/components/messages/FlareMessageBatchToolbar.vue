<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { flareIcons } from "../../shared/icons";
import {
  messageBatchActions,
  messageBatchActionsAvailable,
  type MessageBatchAction,
  type MessageBatchCapabilities,
} from "../../shared/contracts/message-batch";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

// Multi-select batch bar for the timeline. Same contract as FlareConversationBatchToolbar (FR-034):
// the host declares what it can do over the selection, the toolbar reports one action with the ids.
// Selecting all and clearing the selection stay their own events: they change the selection, not the world.
const props = withDefaults(
  defineProps<{
    selectedIds: string[];
    total: number;
    capabilities: MessageBatchCapabilities;
    busy?: boolean;
    floating?: boolean;
  }>(),
  { busy: false, floating: false },
);
const emit = defineEmits<{
  action: [value: { action: MessageBatchAction; ids: string[] }];
  selectAll: [];
  clearSelection: [];
  exit: [];
}>();

const { t } = useFlareI18n();
const count = computed(() => props.selectedIds.length);
const available = computed(() => messageBatchActionsAvailable(props.selectedIds, props.capabilities, props.busy));
const visibleActions = computed(() => messageBatchActions.filter((action) => props.capabilities?.[action] === true));
const icons: Record<MessageBatchAction, keyof typeof flareIcons> = {
  forwardEach: "forward",
  forwardMerged: "merge-forward",
  pin: "pin",
  pinSelf: "pin-self",
  delete: "delete",
};
</script>

<template>
  <div
    class="flare-batch-toolbar"
    :class="{ 'flare-batch-toolbar--floating': floating }"
    role="toolbar"
    :aria-label="t('batch.title')"
  >
    <div class="flare-batch-toolbar__meta">
      <strong>{{ count }}</strong>
      <span>/ {{ total }} · {{ t("batch.selected") }}</span>
    </div>
    <div class="flare-batch-toolbar__actions">
      <button
        type="button"
        class="flare-batch-btn"
        :aria-label="t('batch.selectAll')"
        :title="t('batch.selectAll')"
        :disabled="busy || total === 0"
        @click="emit('selectAll')"
      >
        <n-icon aria-hidden="true" :size="16" :component="flareIcons.check" />
        <span>{{ t("batch.selectAll") }}</span>
      </button>
      <button
        type="button"
        class="flare-batch-btn flare-batch-btn--text"
        :aria-label="t('batch.clear')"
        :title="t('batch.clear')"
        :disabled="busy || count === 0"
        @click="emit('clearSelection')"
      >
        <span>{{ t("batch.clear") }}</span>
      </button>
      <button
        v-for="action in visibleActions"
        :key="action"
        type="button"
        class="flare-batch-btn"
        :class="{ 'flare-batch-btn--danger': action === 'delete' }"
        :aria-label="t(`batch.${action}`)"
        :title="t(`batch.${action}`)"
        :disabled="!available.includes(action)"
        @click="emit('action', { action, ids: [...selectedIds] })"
      >
        <n-icon aria-hidden="true" :size="16" :component="flareIcons[icons[action]]" />
        <span>{{ t(`batch.${action}`) }}</span>
      </button>
      <button
        type="button"
        class="flare-batch-btn flare-batch-btn--icon"
        :disabled="busy"
        :aria-label="t('batch.exit')"
        @click="emit('exit')"
      >
        <n-icon aria-hidden="true" :size="18" :component="flareIcons.close" />
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-batch-toolbar {
  display: flex;
  align-items: center;
  gap: 14px;
  flex-wrap: wrap;
  padding: 10px 14px;
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-md);
}
.flare-batch-toolbar--floating {
  position: absolute;
  right: 16px;
  bottom: 14px;
  left: 16px;
  z-index: 6;
  min-height: 52px;
  flex-wrap: nowrap;
  box-sizing: border-box;
}
.flare-batch-toolbar__meta {
  display: inline-flex;
  align-items: baseline;
  gap: 5px;
  font-size: 13px;
  color: var(--flare-color-text-secondary);
}
.flare-batch-toolbar__meta strong {
  font-size: 16px;
  color: var(--flare-color-primary-text);
  font-variant-numeric: tabular-nums;
}
.flare-batch-toolbar__actions {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
  margin-left: auto;
}
/* Floating over the timeline the bar cannot grow a second line, so the keys scroll sideways instead. */
.flare-batch-toolbar--floating .flare-batch-toolbar__actions {
  min-width: 0;
  flex-wrap: nowrap;
  overflow-x: auto;
  overscroll-behavior-inline: contain;
  scrollbar-width: none;
}
.flare-batch-toolbar--floating .flare-batch-toolbar__actions::-webkit-scrollbar {
  display: none;
}
.flare-batch-btn {
  flex: none;
  white-space: nowrap;
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 32px;
  padding: 0 10px;
  border: none;
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  font-size: 13px;
  cursor: pointer;
  transition: filter var(--flare-transition-fast), transform var(--flare-transition-fast);
}
.flare-batch-btn:hover:not(:disabled) {
  filter: brightness(0.97);
}
.flare-batch-btn:active:not(:disabled) {
  transform: scale(0.97);
}
.flare-batch-btn:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}
.flare-batch-btn:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.flare-batch-btn--danger {
  color: var(--flare-color-error-text);
}
.flare-batch-btn--icon {
  padding: 0 8px;
}
/* The host decides where this mounts, so there is no container it is guaranteed to sit inside,
   and a named container query that matches nothing applies nothing. It is sized against the
   window on purpose (100vw / 100dvh below), so the window is what it asks. */
@media (max-width: 599px) {
  .flare-batch-toolbar--floating {
    right: 10px;
    left: 10px;
    gap: 8px;
    padding: 8px 10px;
  }
  .flare-batch-toolbar {
    flex-wrap: nowrap;
    gap: 8px;
  }
  .flare-batch-toolbar__meta {
    flex: none;
  }
  .flare-batch-toolbar__actions {
    min-width: 0;
    flex-wrap: nowrap;
    overflow-x: auto;
    overscroll-behavior-inline: contain;
    scrollbar-width: none;
  }
  .flare-batch-toolbar__actions::-webkit-scrollbar {
    display: none;
  }
}
@media (prefers-reduced-motion: reduce) {
  .flare-batch-btn {
    transition: none;
  }
  .flare-batch-btn:active:not(:disabled) {
    transform: none;
  }
}
</style>
