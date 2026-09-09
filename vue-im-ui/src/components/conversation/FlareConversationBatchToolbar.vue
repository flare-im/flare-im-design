<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { NIcon } from "naive-ui";
import {
  AlertCircleOutline,
  ArchiveOutline,
  CheckmarkCircleOutline,
  CheckmarkDoneOutline,
  ChevronDownOutline,
  ChevronUpOutline,
  CloseOutline,
  NotificationsOffOutline,
  RefreshOutline,
  TrashOutline,
} from "../../shared/icon-glyphs";
import {
  batchActionsAvailable,
  batchSelectionExceeded,
  conversationBatchActions,
  summarizeBatchResult,
  type ConversationBatchAction,
  type ConversationBatchCapabilities,
  type ConversationBatchResult,
} from "../../shared/contracts/conversation-batch";

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
    selectedText: "已选",
    emptyText: "请选择会话",
    markReadText: "标为已读",
    muteText: "免打扰",
    archiveText: "归档",
    deleteText: "删除",
    cancelText: "取消选择",
    busyText: "处理中",
    succeededSummaryText: "成功 {n} 项",
    failedSummaryText: "{n} 项失败",
    retryFailedText: "重试失败项",
    dismissText: "关闭结果",
    expandText: "查看详情",
    collapseText: "收起",
    maxSelectionText: "最多可选 {n} 项",
  },
);
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
  if (props.busy) return props.busyText;
  if (count.value === 0) return props.emptyText;
  if (exceeded.value) return fill(props.maxSelectionText, props.maxSelection as number);
  return "";
});

const actionMeta = {
  markRead: { icon: CheckmarkDoneOutline, label: () => props.markReadText },
  mute: { icon: NotificationsOffOutline, label: () => props.muteText },
  archive: { icon: ArchiveOutline, label: () => props.archiveText },
  delete: { icon: TrashOutline, label: () => props.deleteText },
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
    <div class="flare-conv-batch__bar" role="toolbar" :aria-label="selectedText" :aria-busy="busy">
      <div class="flare-conv-batch__meta">
        <strong>{{ count }}</strong>
        <span>{{ selectedText }}</span>
      </div>
      <p v-if="hint" class="flare-conv-batch__hint" :class="{ 'flare-conv-batch__hint--warn': exceeded && !busy }" role="status" aria-live="polite">
        <span v-if="busy" class="flare-conv-batch__spinner" aria-hidden="true" />
        <n-icon v-else-if="exceeded" :size="14" :component="AlertCircleOutline" aria-hidden="true" />
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
          :aria-label="isPending(action) ? `${actionMeta[action].label()} · ${busyText}` : undefined"
          @click="trigger(action)"
        >
          <span v-if="isPending(action)" class="flare-conv-batch__spinner" aria-hidden="true" />
          <n-icon v-else :size="16" :component="actionMeta[action].icon" />
          <span>{{ actionMeta[action].label() }}</span>
        </button>
        <button
          type="button"
          class="flare-conv-batch__btn flare-conv-batch__btn--icon"
          :disabled="busy"
          :aria-label="cancelText"
          :title="cancelText"
          @click="clear"
        >
          <n-icon :size="18" :component="CloseOutline" />
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
          <strong v-if="summary.failedCount > 0">{{ fill(failedSummaryText, summary.failedCount) }}</strong>
          <span v-if="summary.failedCount > 0 && summary.succeededCount > 0" aria-hidden="true"> · </span>
          <span v-if="summary.succeededCount > 0 || summary.failedCount === 0">{{ fill(succeededSummaryText, summary.succeededCount) }}</span>
        </span>
        <div class="flare-conv-batch__result-actions">
          <button
            v-if="summary.failedCount > 0"
            type="button"
            class="flare-conv-batch__btn flare-conv-batch__btn--ghost"
            :aria-expanded="expanded"
            @click="expanded = !expanded"
          >
            <n-icon :size="14" :component="expanded ? ChevronUpOutline : ChevronDownOutline" />
            <span>{{ expanded ? collapseText : expandText }}</span>
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
            <n-icon v-else :size="14" :component="RefreshOutline" />
            <span>{{ retryFailedText }} ({{ summary.retryIds.length }})</span>
          </button>
          <button
            type="button"
            class="flare-conv-batch__btn flare-conv-batch__btn--icon"
            :disabled="busy"
            :aria-label="dismissText"
            :title="dismissText"
            @click="dismiss"
          >
            <n-icon :size="16" :component="CloseOutline" />
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
  border-radius: var(--flare-size-radius-lg, 10px);
  background: var(--flare-color-bg-primary, #FFFFFF);
  border: 1px solid var(--flare-color-border-primary, #E3E5EB);
  box-shadow: var(--flare-shadow-md, 0 6px 18px rgba(21, 18, 32, 0.1));
  color: var(--flare-color-text-primary, #20232D);
  overflow: hidden;
}
.flare-conv-batch__bar {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md, 12px);
  flex-wrap: wrap;
  padding: 10px 14px;
}
.flare-conv-batch__meta {
  display: inline-flex;
  align-items: baseline;
  gap: 5px;
  font-size: var(--flare-size-font-size-md, 13px);
  color: var(--flare-color-text-secondary, #626978);
  white-space: nowrap;
}
.flare-conv-batch__meta strong {
  font-size: var(--flare-size-font-size-2xl, 16px);
  color: var(--flare-color-primary, #7047D6);
  font-variant-numeric: tabular-nums;
}
.flare-conv-batch__hint {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin: 0;
  font-size: var(--flare-size-font-size-sm, 12px);
  color: var(--flare-color-text-tertiary, #687182);
  min-width: 0;
  overflow-wrap: anywhere;
}
.flare-conv-batch__hint--warn { color: var(--flare-color-warning, #f59e0b); }
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
  border-radius: var(--flare-size-radius-md, 8px);
  background: var(--flare-color-bg-secondary, #F7F8FA);
  color: var(--flare-color-text-primary, #20232D);
  font: inherit;
  font-size: var(--flare-size-font-size-md, 13px);
  cursor: pointer;
  white-space: nowrap;
  transition: filter var(--flare-transition-fast, 150ms cubic-bezier(0.22, 1, 0.36, 1)), transform var(--flare-transition-fast, 150ms cubic-bezier(0.22, 1, 0.36, 1));
}
@media (pointer: coarse) {
  .flare-conv-batch__btn { min-height: var(--flare-size-layout-touch-target, 48px); min-width: var(--flare-size-layout-touch-target, 48px); }
}
.flare-conv-batch__btn:hover:not(:disabled) { filter: brightness(0.97); }
.flare-conv-batch__btn:active:not(:disabled) { transform: scale(0.97); }
.flare-conv-batch__btn:disabled { opacity: 0.45; cursor: not-allowed; }
.flare-conv-batch__btn:disabled.flare-conv-batch__btn--pending { opacity: 0.85; cursor: progress; }
.flare-conv-batch__btn:focus-visible { outline: 2px solid var(--flare-color-primary, #7047D6); outline-offset: 2px; }
.flare-conv-batch__btn--danger { color: var(--flare-color-error, #ef4444); }
.flare-conv-batch__btn--icon { padding: 0 8px; }
.flare-conv-batch__btn--ghost { background: transparent; color: var(--flare-color-text-secondary, #626978); }
.flare-conv-batch__btn--primary { background: var(--flare-color-primary, #7047D6); color: #fff; }
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
  border-top: 1px solid var(--flare-color-border-secondary, #ECEEF2);
  background: var(--flare-color-bg-secondary, #F7F8FA);
  padding: 8px 14px;
  display: grid;
  gap: 8px;
}
.flare-conv-batch__result--failed .flare-conv-batch__result-icon { color: var(--flare-color-error, #ef4444); }
.flare-conv-batch__result:not(.flare-conv-batch__result--failed) .flare-conv-batch__result-icon { color: var(--flare-color-success, #22c55e); }
.flare-conv-batch__result-head {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}
.flare-conv-batch__result-text {
  font-size: var(--flare-size-font-size-md, 13px);
  min-width: 0;
  overflow-wrap: anywhere;
}
.flare-conv-batch__result-text strong { color: var(--flare-color-error, #ef4444); font-weight: 600; }
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
  border-radius: var(--flare-size-radius-sm, 6px);
  background: var(--flare-color-bg-primary, #FFFFFF);
  font-size: var(--flare-size-font-size-sm, 12px);
}
.flare-conv-batch__failure-title {
  font-weight: 500;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-conv-batch__failure-reason {
  color: var(--flare-color-text-secondary, #626978);
  overflow-wrap: anywhere;
  min-width: 0;
}
</style>
