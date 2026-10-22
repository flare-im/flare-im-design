<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import type {
  MessageEphemeralState,
  MessageLifecycle,
  MessageStatusState,
} from "../../shared/contracts/message-lifecycle";
import { lifecycleToMessageStatus } from "../../shared/contracts/message-lifecycle";
import type { FlareMessageMetaPlacement } from "../../shared/contracts/message-surface";
import {
  flareMessageReceiptPresentation,
  type FlareMessageReadSummary,
} from "../../shared/contracts/message-receipt";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import MessageStatus from "./MessageStatus.vue";

// The time, edited / ephemeral labels and the receipt of one message (spec/message-meta-placement-vectors.json,
// spec/message-receipt-vectors.json). `placement` says where the row sits; the bubble lays it out. Below a card or a
// picture a failure is the text key "Failed to send. Retry"; inside a bubble the failed glyph is the retry key. A
// group read summary replaces the check glyph of the viewer's own sent / read message.
const props = withDefaults(defineProps<{
  timestamp?: string;
  edited?: boolean;
  status?: MessageStatusState;
  lifecycle?: MessageLifecycle;
  ephemeral?: MessageEphemeralState;
  density?: "compact" | "normal";
  tone?: "default" | "onOutgoing";
  placement?: FlareMessageMetaPlacement;
  readSummary?: FlareMessageReadSummary;
}>(), {
  timestamp: "",
  edited: false,
  ephemeral: "none",
  density: "compact",
  tone: "default",
  placement: "bubbleFooter",
  readSummary: undefined,
});

const emit = defineEmits<{ (event: "resend"): void; (event: "readReceiptOpen"): void }>();
const { t } = useFlareI18n();
const instance = getCurrentInstance();
const toneClass = computed(() => props.tone === "onOutgoing" ? "on-outgoing" : "default");
const resolvedEphemeral = computed(() => props.lifecycle?.ephemeral ?? props.ephemeral);
const ephemeralLabel = computed(() => {
  if (resolvedEphemeral.value === "readOnce") return t("message.readOnce");
  if (resolvedEphemeral.value === "burnAfterRead") return t("message.burned");
  if (resolvedEphemeral.value === "expired") return t("message.expired");
  return "";
});
const hasReceipt = computed(() => props.status !== undefined || Boolean(props.lifecycle));
const effectiveStatus = computed<MessageStatusState>(() =>
  props.lifecycle ? lifecycleToMessageStatus(props.lifecycle) : props.status ?? "sent",
);
// The summary only reaches the meta of the viewer's own group messages (the bubble decides); here it only has to
// give way to pending, sending and failed.
const receipt = computed(() => flareMessageReceiptPresentation({
  conversationKind: props.readSummary ? "group" : undefined,
  self: true,
  status: effectiveStatus.value,
  readSummary: props.readSummary,
}));
const summaryText = computed(() => {
  const summary = receipt.value.summary;
  if (!hasReceipt.value || !summary) return "";
  return summary.allRead ? t("message.readSummaryAllRead") : t("message.readSummaryUnread", { count: summary.count ?? 0 });
});
const summaryTappable = computed(() => Boolean(instance?.vnode.props?.onReadReceiptOpen));
const canResend = computed(() => Boolean(instance?.vnode.props?.onResend));
const failedBelow = computed(() => hasReceipt.value && props.placement === "below" && effectiveStatus.value === "failed");
const showGlyph = computed(() => hasReceipt.value && !summaryText.value && !failedBelow.value);
</script>

<template>
  <footer
    v-if="placement !== 'none'"
    class="message-meta-row"
    :class="[`message-meta-row--${density}`, `message-meta-row--${toneClass}`, `message-meta-row--${placement}`]"
    :data-placement="placement"
  >
    <template v-if="failedBelow">
      <button
        v-if="canResend"
        type="button"
        class="message-meta-row__retry"
        data-meta-retry="text"
        @click.stop="emit('resend')"
      >{{ t("message.sendFailedRetry") }}</button>
      <span v-else class="message-meta-row__failed" role="status">{{ t("message.failed") }}</span>
    </template>
    <span v-if="timestamp" class="message-meta-row__text">{{ timestamp }}</span>
    <span v-if="edited" class="message-meta-row__text">{{ t("message.edited") }}</span>
    <span v-if="ephemeralLabel" class="message-meta-row__text">{{ ephemeralLabel }}</span>
    <template v-if="summaryText">
      <button
        v-if="summaryTappable"
        type="button"
        class="message-meta-row__summary"
        :class="{ 'is-all-read': receipt.summary?.allRead }"
        :aria-label="t('message.readReceiptAria', { summary: summaryText })"
        data-read-summary="true"
        @click.stop="emit('readReceiptOpen')"
      >{{ summaryText }}</button>
      <span
        v-else
        class="message-meta-row__summary"
        :class="{ 'is-all-read': receipt.summary?.allRead }"
        data-read-summary="true"
      >{{ summaryText }}</span>
    </template>
    <MessageStatus
      v-if="showGlyph"
      :status="effectiveStatus"
      :tone="tone"
      variant="inline"
      v-bind="canResend ? { onResend: () => emit('resend') } : {}"
    />
  </footer>
</template>

<style scoped>
.message-meta-row {
  display: flex;
  width: fit-content;
  max-width: 100%;
  margin-inline-start: auto;
  align-items: center;
  justify-content: flex-end;
  align-self: flex-end;
  min-height: var(--flare-size-icon-size-sm);
  gap: var(--flare-size-spacing-xs);
  color: var(--flare-color-text-tertiary);
  white-space: nowrap;
}

.message-meta-row--normal { gap: var(--flare-size-spacing-2xs); }
.message-meta-row--on-outgoing { color: var(--flare-color-message-status-on-outgoing); }
/* Under a card or a picture: the timeline's own palette at the trailing edge, never over the content. */
.message-meta-row--below { color: var(--flare-color-message-meta-foreground); }

.message-meta-row__text {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  font-size: var(--flare-size-font-size-xs);
  line-height: var(--flare-size-line-height-tight);
  color: currentColor;
}

.message-meta-row__text + .message-meta-row__text::before {
  content: "·";
  margin-inline-end: var(--flare-size-spacing-xs);
}

/* Text keys sized to their words whose hit area reaches the touch target around them. */
.message-meta-row__summary,
.message-meta-row__retry {
  position: relative;
  padding: 0;
  border: 0;
  background: none;
  font: inherit;
  font-size: var(--flare-size-font-size-xs);
  line-height: var(--flare-size-line-height-tight);
  color: currentColor;
}

button.message-meta-row__summary,
.message-meta-row__retry { cursor: pointer; }

button.message-meta-row__summary::after,
.message-meta-row__retry::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  width: max(100%, var(--flare-size-layout-touch-target));
  height: var(--flare-size-layout-touch-target);
  transform: translate(-50%, -50%);
}

button.message-meta-row__summary:focus-visible,
.message-meta-row__retry:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
  border-radius: var(--flare-size-radius-xs);
}

.message-meta-row__summary.is-all-read { color: var(--flare-color-message-status-read); }
.message-meta-row--on-outgoing .message-meta-row__summary.is-all-read { color: var(--flare-color-message-status-read-on-outgoing); }

.message-meta-row__retry,
.message-meta-row__failed {
  font-size: var(--flare-size-font-size-xs);
  font-weight: var(--flare-size-font-weight-medium);
  color: var(--flare-color-message-status-failed);
}
</style>
