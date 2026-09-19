<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { NIcon } from "naive-ui";
import {
  AlertCircleOutline,
  CheckmarkCircleOutline,
  ChevronDownOutline,
  ChevronUpOutline,
  CloseOutline,
  RefreshOutline,
} from "../../shared/icon-glyphs";
import { flareIcons } from "../../shared/icons";
import {
  batchActionsAvailable,
  batchSelectionExceeded,
  conversationBatchActions,
  summarizeBatchResult,
  type ConversationBatchAction,
  type ConversationBatchCapabilities,
  type ConversationBatchResult,
} from "../../shared/contracts/conversation-batch";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

// Multi-select batch bar for the conversation list. Same bar / count / actions / cancel
// visual as FlareMessageBatchToolbar, plus a partial-failure strip with per-item recovery.
// The toolbar only emits intents: the host owns busy, result and any DangerConfirm for delete.
const props = withDefaults(
  defineProps<{
    selectedIds: string[];
    capabilities: ConversationBatchCapabilities;
    busy?: boolean;
    result?: ConversationBatchResult | null;
    maxSelection?: number | null;
    selectedText?: string;
    emptyText?: string;
    markReadText?: string;
    muteText?: string;
    archiveText?: string;
    deleteText?: string;
    cancelText?: string;
    busyText?: string;
    succeededSummaryText?: string;
    failedSummaryText?: string;
    retryFailedText?: string;
    dismissText?: string;
    expandText?: string;
    collapseText?: string;
    maxSelectionText?: string;
  }>(),
  {
    busy: false,
    result: null,
    maxSelection: null,
  },
);
const { t } = useFlareI18n();
const strings = computed(() => ({
  selectedText: props.selectedText ?? t("conversationBatchToolbar.selected"),
  emptyText: props.emptyText ?? t("conversationBatchToolbar.empty"),
  markReadText: props.markReadText ?? t("conversationBatchToolbar.markRead"),
  muteText: props.muteText ?? t("conversationBatchToolbar.mute"),
  archiveText: props.archiveText ?? t("conversationBatchToolbar.archive"),
  deleteText: props.deleteText ?? t("conversationBatchToolbar.delete"),
  cancelText: props.cancelText ?? t("conversationBatchToolbar.cancel"),
  busyText: props.busyText ?? t("conversationBatchToolbar.busy"),
  succeededSummaryText: props.succeededSummaryText ?? t("conversationBatchToolbar.succeededSummary"),
  failedSummaryText: props.failedSummaryText ?? t("conversationBatchToolbar.failedSummary"),
  retryFailedText: props.retryFailedText ?? t("conversationBatchToolbar.retryFailed"),
  dismissText: props.dismissText ?? t("conversationBatchToolbar.dismiss"),
  expandText: props.expandText ?? t("conversationBatchToolbar.expand"),
  collapseText: props.collapseText ?? t("conversationBatchToolbar.collapse"),
  maxSelectionText: props.maxSelectionText ?? t("conversationBatchToolbar.maxSelection"),
}));
const emit = defineEmits<{
  action: [value: { action: ConversationBatchAction; ids: string[] }];
  retryFailed: [ids: string[]];
  clearSelection: [];
  dismissResult: [];
}>();

type Pending = ConversationBatchAction | "retry" | null;
const pending = ref<Pending>(null);
const expanded = ref(false);
watch(
  () => props.busy,
  (busy) => {
    if (!busy) pending.value = null;
  },
);
watch(
  () => props.result,
  () => {
    expanded.value = false;
  },
);

const count = computed(() => props.selectedIds.length);
const exceeded = computed(() => batchSelectionExceeded(count.value, props.maxSelection));
const available = computed(() => batchActionsAvailable(props.selectedIds, props.capabilities, props.busy, props.maxSelection));
const summary = computed(() => summarizeBatchResult(props.result));
const hasResult = computed(() => summary.value.failedCount > 0 || summary.value.succeededCount > 0);
const fill = (template: string, n: number) => template.replace("{n}", String(n));

const hint = computed(() => {
  if (props.busy) return strings.value.busyText;
  if (count.value === 0) return strings.value.emptyText;
  if (exceeded.value) return fill(strings.value.maxSelectionText, props.maxSelection as number);
  return "";
});

const actionMeta = {
  markRead: { icon: flareIcons.read, label: () => strings.value.markReadText },
  mute: { icon: flareIcons.mute, label: () => strings.value.muteText },
  archive: { icon: flareIcons.archive, label: () => strings.value.archiveText },
  delete: { icon: flareIcons.delete, label: () => strings.value.deleteText },
} as const;

/** Capability-enabled actions keep their slot even while disabled so the bar does not jump. */
const visibleActions = computed(() => conversationBatchActions.filter((a) => props.capabilities?.[a] === true));
const isEnabled = (action: ConversationBatchAction) => available.value.includes(action);
const isPending = (key: Pending) => props.busy && pending.value === key;

function trigger(action: ConversationBatchAction) {
  if (!isEnabled(action)) return;
  pending.value = action;
  emit("action", { action, ids: [...props.selectedIds] });
}
function retry() {
  if (props.busy || summary.value.retryIds.length === 0) return;
  pending.value = "retry";
  emit("retryFailed", [...summary.value.retryIds]);
}
function clear() {
  if (props.busy) return;
  emit("clearSelection");
}
function dismiss() {
  if (props.busy) return;
  expanded.value = false;
  emit("dismissResult");
}
</script>

<template>
  <div class="flare-conv-batch" :class="{ 'flare-conv-batch--busy': busy }" @keydown.esc.prevent="clear">
    <div class="flare-conv-batch__bar" role="toolbar" :aria-label="strings.selectedText" :aria-busy="busy">
      <div class="flare-conv-batch__meta">
        <strong>{{ count }}</strong>
        <span>{{ strings.selectedText }}</span>
      </div>
      <p v-if="hint" class="flare-conv-batch__hint" :class="{ 'flare-conv-batch__hint--warn': exceeded && !busy }" role="status" aria-live="polite">
        <span v-if="busy" class="flare-conv-batch__spinner" aria-hidden="true" />
        <n-icon v-else-if="exceeded" :size="14" :component="flareIcons.error" aria-hidden="true" />
        {{ hint }}
      </p>
      <div class="flare-conv-batch__actions">
        <button
          v-for="action in visibleActions"
          :key="action"
          type="button"
          class="flare-conv-batch__btn"
          :class="{ 'flare-conv-batch__btn--danger': action === 'delete', 'flare-conv-batch__btn--pending': isPending(action) }"
          :disabled="!isEnabled(action)"
          :aria-busy="isPending(action)"
          :aria-label="isPending(action) ? `${actionMeta[action].label()} · ${strings.busyText}` : undefined"
          @click="trigger(action)"
        >
          <span v-if="isPending(action)" class="flare-conv-batch__spinner" aria-hidden="true" />
          <n-icon aria-hidden="true" v-else :size="16" :component="actionMeta[action].icon" />
          <span>{{ actionMeta[action].label() }}</span>
        </button>
        <button
          type="button"
          class="flare-conv-batch__btn flare-conv-batch__btn--icon"
          :disabled="busy"
          :aria-label="strings.cancelText"
          :title="strings.cancelText"
          @click="clear"
        >
          <n-icon aria-hidden="true" :size="18" :component="CloseOutline" />
        </button>
      </div>
    </div>

    <div
      v-if="hasResult"
      class="flare-conv-batch__result"
      :class="{ 'flare-conv-batch__result--failed': summary.failedCount > 0 }"
      role="status"
      aria-live="polite"
    >
      <div class="flare-conv-batch__result-head">
        <n-icon
          :size="16"
          :component="summary.failedCount > 0 ? AlertCircleOutline : CheckmarkCircleOutline"
          class="flare-conv-batch__result-icon"
          aria-hidden="true"
        />
        <span class="flare-conv-batch__result-text">
          <strong v-if="summary.failedCount > 0">{{ fill(strings.failedSummaryText, summary.failedCount) }}</strong>
          <span v-if="summary.failedCount > 0 && summary.succeededCount > 0" aria-hidden="true"> · </span>
          <span v-if="summary.succeededCount > 0 || summary.failedCount === 0">{{ fill(strings.succeededSummaryText, summary.succeededCount) }}</span>
        </span>
        <div class="flare-conv-batch__result-actions">
          <button
            v-if="summary.failedCount > 0"
            type="button"
            class="flare-conv-batch__btn flare-conv-batch__btn--ghost"
            :aria-expanded="expanded"
            @click="expanded = !expanded"
          >
            <n-icon aria-hidden="true" :size="14" :component="expanded ? ChevronUpOutline : ChevronDownOutline" />
            <span>{{ expanded ? strings.collapseText : strings.expandText }}</span>
          </button>
          <button
            v-if="summary.retryIds.length > 0"
            type="button"
            class="flare-conv-batch__btn flare-conv-batch__btn--primary"
            :class="{ 'flare-conv-batch__btn--pending': isPending('retry') }"
            :disabled="busy"
            :aria-busy="isPending('retry')"
            @click="retry"
          >
            <span v-if="isPending('retry')" class="flare-conv-batch__spinner" aria-hidden="true" />
            <n-icon aria-hidden="true" v-else :size="14" :component="RefreshOutline" />
            <span>{{ strings.retryFailedText }} ({{ summary.retryIds.length }})</span>
          </button>
          <button
            type="button"
            class="flare-conv-batch__btn flare-conv-batch__btn--icon"
            :disabled="busy"
            :aria-label="strings.dismissText"
            :title="strings.dismissText"
            @click="dismiss"
          >
            <n-icon aria-hidden="true" :size="16" :component="CloseOutline" />
          </button>
        </div>
      </div>
      <ul v-if="expanded && result && result.failed.length" class="flare-conv-batch__failures">
        <li v-for="(item, index) in result.failed" :key="`${item.id}-${index}`" class="flare-conv-batch__failure">
          <span class="flare-conv-batch__failure-title">{{ item.title }}</span>
          <span class="flare-conv-batch__failure-reason">{{ item.reason }}</span>
        </li>
      </ul>
    </div>
  </div>
</template>

<style scoped>
.flare-conv-batch {
  display: grid;
  gap: 0;
  min-width: 0;
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-md);
  color: var(--flare-color-text-primary);
  overflow: hidden;
}
.flare-conv-batch__bar {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  flex-wrap: wrap;
  padding: 10px 14px;
}
.flare-conv-batch__meta {
  display: inline-flex;
  align-items: baseline;
  gap: 5px;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-text-secondary);
  white-space: nowrap;
}
.flare-conv-batch__meta strong {
  font-size: var(--flare-size-font-size-2xl);
  color: var(--flare-color-primary-text);
  font-variant-numeric: tabular-nums;
}
.flare-conv-batch__hint {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin: 0;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-tertiary);
  min-width: 0;
  overflow-wrap: anywhere;
}
.flare-conv-batch__hint--warn { color: var(--flare-color-warning-text); }
.flare-conv-batch__actions {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
  margin-inline-start: auto;
  min-width: 0;
}
.flare-conv-batch__btn {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  min-height: 40px;
  min-width: 40px;
  padding: 0 10px;
  border: none;
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  font: inherit;
  font-size: var(--flare-size-font-size-md);
  cursor: pointer;
  white-space: nowrap;
  transition: filter var(--flare-transition-fast), transform var(--flare-transition-fast);
}
@media (pointer: coarse) {
  .flare-conv-batch__btn { min-height: var(--flare-size-layout-touch-target); min-width: var(--flare-size-layout-touch-target); }
}
.flare-conv-batch__btn:hover:not(:disabled) { filter: brightness(0.97); }
.flare-conv-batch__btn:active:not(:disabled) { transform: scale(0.97); }
.flare-conv-batch__btn:disabled { opacity: 0.45; cursor: not-allowed; }
.flare-conv-batch__btn:disabled.flare-conv-batch__btn--pending { opacity: 0.85; cursor: progress; }
.flare-conv-batch__btn:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-conv-batch__btn--danger { color: var(--flare-color-error-text); }
.flare-conv-batch__btn--icon { padding: 0 8px; }
.flare-conv-batch__btn--ghost { background: transparent; color: var(--flare-color-text-secondary); }
.flare-conv-batch__btn--primary { background: var(--flare-color-primary); color: #fff; }
.flare-conv-batch__spinner {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  border: 2px solid currentColor;
  border-right-color: transparent;
  animation: flare-conv-batch-spin 0.8s linear infinite;
  flex: none;
}
@keyframes flare-conv-batch-spin { to { transform: rotate(360deg); } }
@media (prefers-reduced-motion: reduce) {
  .flare-conv-batch__spinner { animation-duration: 2s; }
}
.flare-conv-batch__result {
  border-top: 1px solid var(--flare-color-border-secondary);
  background: var(--flare-color-bg-secondary);
  padding: 8px 14px;
  display: grid;
  gap: 8px;
}
.flare-conv-batch__result--failed .flare-conv-batch__result-icon { color: var(--flare-color-error-text); }
.flare-conv-batch__result:not(.flare-conv-batch__result--failed) .flare-conv-batch__result-icon { color: var(--flare-color-success-text); }
.flare-conv-batch__result-head {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}
.flare-conv-batch__result-text {
  font-size: var(--flare-size-font-size-md);
  min-width: 0;
  overflow-wrap: anywhere;
}
.flare-conv-batch__result-text strong { color: var(--flare-color-error-text); font-weight: 600; }
.flare-conv-batch__result-actions {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
  margin-inline-start: auto;
}
.flare-conv-batch__failures {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 4px;
  max-height: 200px;
  overflow: auto;
  overscroll-behavior: contain;
}
.flare-conv-batch__failure {
  display: flex;
  gap: 8px;
  align-items: baseline;
  flex-wrap: wrap;
  padding: 6px 8px;
  border-radius: var(--flare-size-radius-sm);
  background: var(--flare-color-bg-primary);
  font-size: var(--flare-size-font-size-sm);
}
.flare-conv-batch__failure-title {
  font-weight: 500;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-conv-batch__failure-reason {
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
  min-width: 0;
}
</style>
