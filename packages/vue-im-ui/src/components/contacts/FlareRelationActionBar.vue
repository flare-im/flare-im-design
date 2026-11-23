<script setup lang="ts">
// Relation action bar for the bottom of a contact detail page. The host owns the
// relation state and every command; the bar only decides which buttons exist —
// via the shared `relationActions` contract — and emits intent. It never mutates
// the relation, never retries, and keeps the previous failure reason on screen
// until the host or the user dismisses it.
import { computed, ref, watch } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import { useScreenLayout } from "../../shared/screenLayout";
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
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

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
  },
);
const { t } = useFlareI18n();
const { detail } = useScreenLayout();
const strings = computed(() => ({
  addText: props.addText ?? t("relationActionBar.add"),
  acceptText: props.acceptText ?? t("relationActionBar.accept"),
  rejectText: props.rejectText ?? t("relationActionBar.reject"),
  removeText: props.removeText ?? t("relationActionBar.remove"),
  blockText: props.blockText ?? t("relationActionBar.block"),
  unblockText: props.unblockText ?? t("relationActionBar.unblock"),
  messageText: props.messageText ?? t("relationActionBar.message"),
  pendingText: props.pendingText ?? t("relationActionBar.pending"),
  busyText: props.busyText ?? t("relationActionBar.busy"),
  dismissErrorText: props.dismissErrorText ?? t("relationActionBar.dismissError"),
  emptyText: props.emptyText ?? t("relationActionBar.empty"),
}));

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
    case "add": return strings.value.addText;
    case "accept": return strings.value.acceptText;
    case "reject": return strings.value.rejectText;
    case "remove": return strings.value.removeText;
    case "block": return strings.value.blockText;
    case "unblock": return strings.value.unblockText;
    case "message": return strings.value.messageText;
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
  <div class="flare-relation-bar" :class="{ 'flare-relation-bar--busy': busy, 'is-detail': detail }" :aria-busy="busy || undefined">
    <div v-if="error" class="flare-relation-bar__error" role="alert">
      <n-icon :size="16" :component="AlertCircleOutline as any" class="flare-relation-bar__error-icon" aria-hidden="true" />
      <span class="flare-relation-bar__error-text">{{ error }}</span>
      <FlareIconButton :icon="CloseOutline" :ariaLabel="strings.dismissErrorText" size="sm" :disabled="busy" @click="dismiss" />
    </div>

    <div class="flare-relation-bar__row" role="group" :aria-label="pendingNotice ? strings.pendingText : undefined">
      <p v-if="pendingNotice" class="flare-relation-bar__pending" role="status">
        <n-icon :size="16" :component="TimeOutline as any" aria-hidden="true" />
        <span>{{ strings.pendingText }}</span>
      </p>

      <p v-if="isEmpty" class="flare-relation-bar__empty" role="status">{{ strings.emptyText }}</p>

      <FlareButton
        v-for="entry in safe" :key="entry.action" size="sm"
        class="flare-relation-bar__btn" :class="{ 'flare-relation-bar__btn--primary': entry.primary }"
        :variant="entry.primary ? 'primary' : 'secondary'" :icon="glyphs[entry.action] as any"
        :label="labelFor(entry.action)" :loading="busy && pending === entry.action" :disabled="busy"
        :aria-label="busy && pending === entry.action ? `${labelFor(entry.action)} · ${strings.busyText}` : undefined"
        @click="trigger(entry.action)"
      />

      <div v-if="destructive.length" class="flare-relation-bar__danger-group">
        <FlareButton
          v-for="entry in destructive" :key="entry.action" size="sm" variant="danger" appearance="text"
          class="flare-relation-bar__btn" :icon="glyphs[entry.action] as any" :label="labelFor(entry.action)"
          :loading="busy && pending === entry.action" :disabled="busy"
          :aria-label="busy && pending === entry.action ? `${labelFor(entry.action)} · ${strings.busyText}` : undefined"
          @click="trigger(entry.action)"
        />
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
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg);
  background: color-mix(in srgb, var(--flare-color-error) 10%, var(--flare-color-bg-primary));
  border-bottom: 1px solid var(--flare-color-border-secondary);
}
.flare-relation-bar__error-icon {
  flex: none;
  color: var(--flare-color-error-text);
}
.flare-relation-bar__error-text {
  flex: 1 1 auto;
  min-width: 0;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-error-text);
  overflow-wrap: anywhere;
}
/* 与它上面那一列(联系人详情的 发消息 / 举报此人 / 加入黑名单)同一条左右留白 16,
   免得两块各自为政地缩进。 */
.flare-relation-bar__row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  min-width: 0;
}
/* 原来这一组被 `margin-inline-start:auto` 推到最右、还用一条竖线隔开,于是一排里出现
   「撑满的 + 随字宽的 + 靠右的」三种宽度。它们是同一层级的三个选择,等分就好。 */
.flare-relation-bar__danger-group {
  display: flex;
  align-items: center;
  flex: 1 1 0;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
.flare-relation-bar__danger-group > * { flex: 1 1 0; min-width: 0; }
.flare-relation-bar__pending,
.flare-relation-bar__empty {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin: 0;
  min-height: var(--flare-size-layout-control-height-sm);
  min-width: 0;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-text-tertiary);
  overflow-wrap: anywhere;
}
.flare-relation-bar__pending {
  padding: 0 var(--flare-size-spacing-md);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-disabled);
  /* 这是一条 role="status" 的真状态文字，不是禁用控件：disabled 色(1.68:1)读不出来。 */
  color: var(--flare-color-text-tertiary);
  font-weight: 600;
}
.flare-relation-bar__btn--primary { flex: 1 1 0; }
.flare-relation-bar.is-detail { background: transparent; }
.flare-relation-bar.is-detail .flare-relation-bar__row,
.flare-relation-bar.is-detail .flare-relation-bar__error { padding-inline: 0; }
</style>
