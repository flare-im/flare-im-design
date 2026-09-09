<script setup lang="ts">
// Relation action bar for the bottom of a contact detail page. The host owns the
// relation state and every command; the bar only decides which buttons exist —
// via the shared `relationActions` contract — and emits intent. It never mutates
// the relation, never retries, and keeps the previous failure reason on screen
// until the host or the user dismisses it.
import { computed, ref, watch } from "vue";
import { NIcon } from "naive-ui";
import {
  AlertCircleOutline,
  BanOutline,
  ChatbubbleEllipsesOutline,
  CheckmarkCircleOutline,
  CheckmarkOutline,
  CloseOutline,
  PersonAddOutline,
  TimeOutline,
  TrashOutline,
} from "../../shared/icon-glyphs";
import {
  relationActions,
  relationShowsPending,
  type RelationAction,
  type RelationActionPayload,
  type RelationCapabilities,
  type RelationState,
} from "../../shared/contracts/relation";

const props = withDefaults(
  defineProps<{
    relation: RelationState;
    capabilities?: RelationCapabilities;
    /** Host sets this synchronously before dispatching; disables every button. */
    busy?: boolean;
    /** Reason the previous command failed; kept until dismissed, never auto-cleared. */
    error?: string;
    addText?: string;
    acceptText?: string;
    rejectText?: string;
    removeText?: string;
    blockText?: string;
    unblockText?: string;
    messageText?: string;
    pendingText?: string;
    busyText?: string;
    dismissErrorText?: string;
    /** Shown when the host grants no capability, so the bar is never blank. */
    emptyText?: string;
  }>(),
  {
    capabilities: () => ({}),
    busy: false,
    error: "",
    addText: "添加好友",
    acceptText: "接受",
    rejectText: "拒绝",
    removeText: "删除好友",
    blockText: "加入黑名单",
    unblockText: "移出黑名单",
    messageText: "发消息",
    pendingText: "等待对方验证",
    busyText: "处理中",
    dismissErrorText: "关闭错误提示",
    emptyText: "暂无可用操作",
  },
);

const emit = defineEmits<{
  (event: "action", payload: RelationActionPayload): void;
  (event: "dismissError"): void;
}>();

const glyphs: Record<RelationAction, unknown> = {
  add: PersonAddOutline,
  accept: CheckmarkOutline,
  reject: CloseOutline,
  remove: TrashOutline,
  block: BanOutline,
  unblock: CheckmarkCircleOutline,
  message: ChatbubbleEllipsesOutline,
};

const entries = computed(() => relationActions(props.relation, props.capabilities));
const safe = computed(() => entries.value.filter((e) => !e.destructive));
const destructive = computed(() => entries.value.filter((e) => e.destructive));
const pendingNotice = computed(() => relationShowsPending(props.relation));
const isEmpty = computed(() => entries.value.length === 0 && !pendingNotice.value);

// Which button the user triggered, so only that one shows progress.
const pending = ref<RelationAction | null>(null);
watch(
  () => props.busy,
  (busy) => {
    if (!busy) pending.value = null;
  },
);

function labelFor(action: RelationAction): string {
  switch (action) {
    case "add": return props.addText;
    case "accept": return props.acceptText;
    case "reject": return props.rejectText;
    case "remove": return props.removeText;
    case "block": return props.blockText;
    case "unblock": return props.unblockText;
    case "message": return props.messageText;
  }
}

function trigger(action: RelationAction): void {
  if (props.busy) return;
  pending.value = action;
  emit("action", { action });
}

function dismiss(): void {
  if (props.busy) return;
  emit("dismissError");
}
</script>

<template>
  <div class="flare-relation-bar" :class="{ 'flare-relation-bar--busy': busy }" :aria-busy="busy || undefined">
    <div v-if="error" class="flare-relation-bar__error" role="alert">
      <n-icon :size="16" :component="AlertCircleOutline as any" class="flare-relation-bar__error-icon" aria-hidden="true" />
      <span class="flare-relation-bar__error-text">{{ error }}</span>
      <button
        type="button"
        class="flare-relation-bar__btn flare-relation-bar__btn--icon"
        :disabled="busy"
        :aria-label="dismissErrorText"
        :title="dismissErrorText"
        @click="dismiss"
      >
        <n-icon :size="16" :component="CloseOutline as any" />
      </button>
    </div>

    <div class="flare-relation-bar__row" role="group" :aria-label="pendingNotice ? pendingText : undefined">
      <p v-if="pendingNotice" class="flare-relation-bar__pending" role="status">
        <n-icon :size="16" :component="TimeOutline as any" aria-hidden="true" />
        <span>{{ pendingText }}</span>
      </p>

      <p v-if="isEmpty" class="flare-relation-bar__empty" role="status">{{ emptyText }}</p>

      <button
        v-for="entry in safe"
        :key="entry.action"
        type="button"
        class="flare-relation-bar__btn"
        :class="{ 'flare-relation-bar__btn--primary': entry.primary, 'flare-relation-bar__btn--pending': busy && pending === entry.action }"
        :disabled="busy"
        :aria-busy="busy && pending === entry.action"
        :aria-label="busy && pending === entry.action ? `${labelFor(entry.action)} · ${busyText}` : undefined"
        @click="trigger(entry.action)"
      >
        <span v-if="busy && pending === entry.action" class="flare-relation-bar__spinner" aria-hidden="true" />
        <n-icon v-else :size="16" :component="glyphs[entry.action] as any" />
        <span>{{ labelFor(entry.action) }}</span>
      </button>

      <div v-if="destructive.length" class="flare-relation-bar__danger-group">
        <button
          v-for="entry in destructive"
          :key="entry.action"
          type="button"
          class="flare-relation-bar__btn flare-relation-bar__btn--danger"
          :class="{ 'flare-relation-bar__btn--pending': busy && pending === entry.action }"
          :disabled="busy"
          :aria-busy="busy && pending === entry.action"
          :aria-label="busy && pending === entry.action ? `${labelFor(entry.action)} · ${busyText}` : undefined"
          @click="trigger(entry.action)"
        >
          <span v-if="busy && pending === entry.action" class="flare-relation-bar__spinner" aria-hidden="true" />
          <n-icon v-else :size="16" :component="glyphs[entry.action] as any" />
          <span>{{ labelFor(entry.action) }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.flare-relation-bar {
  display: grid;
  gap: 0;
  min-width: 0;
  border-top: 1px solid var(--flare-color-border-secondary);
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-text-primary);
}
.flare-relation-bar__error {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm, 8px);
  padding: var(--flare-size-spacing-sm, 8px) var(--flare-size-spacing-lg, 16px);
  background: color-mix(in srgb, var(--flare-color-error) 10%, var(--flare-color-bg-primary));
  border-bottom: 1px solid var(--flare-color-border-secondary);
}
.flare-relation-bar__error-icon {
  flex: none;
  color: var(--flare-color-error);
}
.flare-relation-bar__error-text {
  flex: 1 1 auto;
  min-width: 0;
  font-size: var(--flare-size-font-size-md, 13px);
  color: var(--flare-color-error);
  overflow-wrap: anywhere;
}
.flare-relation-bar__row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-sm, 8px);
  padding: var(--flare-size-spacing-sm, 8px) var(--flare-size-spacing-lg, 16px);
  min-width: 0;
}
.flare-relation-bar__danger-group {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-sm, 8px);
  margin-inline-start: auto;
  padding-inline-start: var(--flare-size-spacing-sm, 8px);
  border-inline-start: 1px solid var(--flare-color-border-secondary);
}
.flare-relation-bar__pending,
.flare-relation-bar__empty {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin: 0;
  min-height: var(--flare-size-layout-touch-target, 48px);
  min-width: 0;
  font-size: var(--flare-size-font-size-md, 13px);
  color: var(--flare-color-text-tertiary);
  overflow-wrap: anywhere;
}
.flare-relation-bar__pending {
  padding: 0 var(--flare-size-spacing-md, 12px);
  border-radius: var(--flare-size-radius-md, 8px);
  background: var(--flare-color-bg-disabled);
  color: var(--flare-color-text-disabled);
  font-weight: 600;
}
.flare-relation-bar__btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  min-height: var(--flare-size-layout-touch-target, 48px);
  min-width: var(--flare-size-layout-touch-target, 48px);
  padding: 0 var(--flare-size-spacing-md, 12px);
  border: none;
  border-radius: var(--flare-size-radius-md, 8px);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  font: inherit;
  font-size: var(--flare-size-font-size-md, 13px);
  font-weight: 500;
  cursor: pointer;
  white-space: nowrap;
  transition: filter var(--flare-transition-fast, 150ms ease);
}
.flare-relation-bar__btn:hover:not(:disabled) {
  filter: brightness(0.97);
}
.flare-relation-bar__btn:focus-visible {
  outline: 2px solid var(--flare-color-focus-ring, var(--flare-color-primary));
  outline-offset: 2px;
}
.flare-relation-bar__btn:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.flare-relation-bar__btn:disabled.flare-relation-bar__btn--pending {
  opacity: 0.85;
  cursor: progress;
}
.flare-relation-bar__btn--primary {
  flex: 1 1 auto;
  background: var(--flare-color-primary);
  color: #fff;
}
.flare-relation-bar__btn--danger {
  color: var(--flare-color-error);
  background: color-mix(in srgb, var(--flare-color-error) 10%, var(--flare-color-bg-primary));
}
.flare-relation-bar__btn--icon {
  flex: none;
  padding: 0 var(--flare-size-spacing-sm, 8px);
  background: transparent;
  color: var(--flare-color-text-secondary);
}
.flare-relation-bar__spinner {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  border: 2px solid currentColor;
  border-right-color: transparent;
  animation: flare-relation-bar-spin 0.8s linear infinite;
  flex: none;
}
@keyframes flare-relation-bar-spin {
  to { transform: rotate(360deg); }
}
@media (prefers-reduced-motion: reduce) {
  .flare-relation-bar__spinner { animation-duration: 2s; }
}
</style>
