<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import {
  lifecycleToMessageStatus,
  type MessageLifecycle,
  type MessageStatusState,
} from "../../shared/contracts/message-lifecycle";
import MessageDoubleCheckIcon from "./MessageDoubleCheckIcon.vue";

const props = withDefaults(
  defineProps<{
    status: MessageStatusState;
    lifecycle?: MessageLifecycle;
    variant?: "inline" | "bubbleOverlay";
    tone?: "default" | "onOutgoing";
  }>(),
  { variant: "inline", tone: "default" },
);

const emit = defineEmits<{
  (event: "resend"): void;
}>();

const { t } = useFlareI18n();
const instance = getCurrentInstance();

const resendLabel = computed(() => t("message.resendAria"));
const effectiveStatus = computed<MessageStatusState>(() => {
  if (props.lifecycle) return lifecycleToMessageStatus(props.lifecycle);
  return props.status;
});
const stateLabel = computed(() => t(`message.${effectiveStatus.value}`));
const canResend = computed(() => Boolean(instance?.vnode.props?.onResend));
const toneClass = computed(() => props.tone === "onOutgoing" ? "on-outgoing" : "default");
</script>

<template>
  <div
    class="message-status"
    :class="[`message-status--${effectiveStatus}`, `message-status--${toneClass}`, { 'message-status--bubble-overlay': variant === 'bubbleOverlay' }]"
    role="status"
    :aria-label="stateLabel"
  >
    <div v-if="effectiveStatus === 'pending'" class="status-pending" :title="stateLabel" aria-hidden="true">
      <svg class="status-icon" viewBox="0 0 16 16" fill="none">
        <circle cx="8" cy="8" r="5.5" stroke="currentColor" stroke-width="1.5" />
        <path d="M8 4.75V8L10.25 9.25" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
      </svg>
    </div>

    <div v-else-if="effectiveStatus === 'sending' || effectiveStatus === 'retrying'" class="status-progress" :title="stateLabel" aria-hidden="true">
      <svg class="status-icon rotating" viewBox="0 0 16 16" fill="none" aria-hidden="true">
        <circle cx="8" cy="8" r="6" stroke="currentColor" stroke-width="1.5" stroke-dasharray="3 3" />
      </svg>
    </div>

    <div v-else-if="effectiveStatus === 'sent'" class="status-sent" :title="stateLabel" aria-hidden="true">
      <svg class="status-icon status-one-check" viewBox="0 0 16 16" fill="none" aria-hidden="true">
        <path
          d="M12 4L6 10L4 8"
          stroke="currentColor"
          stroke-width="1.5"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </svg>
    </div>

    <div v-else-if="effectiveStatus === 'delivered'" class="status-delivered" :title="stateLabel" aria-hidden="true">
      <MessageDoubleCheckIcon class="status-icon" />
    </div>

    <div v-else-if="effectiveStatus === 'read'" class="status-read" :title="stateLabel" aria-hidden="true">
      <MessageDoubleCheckIcon class="status-icon" />
    </div>

    <button
      v-else-if="effectiveStatus === 'failed' && canResend"
      type="button"
      class="status-failed"
      :title="resendLabel"
      :aria-label="resendLabel"
      @click.stop="emit('resend')"
    >
      <svg class="status-icon" viewBox="0 0 16 16" fill="none" aria-hidden="true">
        <circle cx="8" cy="8" r="6" stroke="currentColor" stroke-width="1.5" />
        <path d="M8 5V8M8 11H8.01" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
      </svg>
    </button>

    <div v-else-if="effectiveStatus === 'failed'" class="status-failed" :title="stateLabel" aria-hidden="true">
      <svg class="status-icon" viewBox="0 0 16 16" fill="none">
        <circle cx="8" cy="8" r="6" stroke="currentColor" stroke-width="1.5" />
        <path d="M8 5V8M8 11H8.01" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
      </svg>
    </div>
  </div>
</template>

<style scoped>
.message-status {
  display: flex;
  align-items: center;
  flex-shrink: 0;
  font-size: 0;
}

.message-status.message-status--bubble-overlay {
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
  border-radius: var(--flare-size-radius-full);
  background: rgba(0, 0, 0, 0.48);
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
}

.status-icon {
  width: var(--flare-size-icon-size-sm);
  height: var(--flare-size-icon-size-sm);
  display: block;
}

.status-failed {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  border: 0;
  background: transparent;
  color: var(--flare-color-message-status-failed);
  cursor: pointer;
  position: relative;
}

.status-failed::before {
  content: "";
  position: absolute;
  width: var(--flare-size-layout-touch-target);
  height: var(--flare-size-layout-touch-target);
}

.status-text {
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
}

@keyframes rotate {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.rotating {
  animation: rotate 1s linear infinite;
}

.message-status--pending .status-icon,
.message-status--sending .status-icon,
.message-status--retrying .status-icon {
  opacity: 0.72;
  color: var(--flare-color-message-status-pending);
}

.status-sent .status-icon {
  color: var(--flare-color-message-status-sent);
  opacity: 0.92;
}

.status-delivered .status-icon {
  color: var(--flare-color-message-status-delivered);
}

.status-read .status-icon {
  color: var(--flare-color-message-status-read);
}

.status-failed .status-icon circle,
.status-failed .status-icon path {
  stroke: currentColor;
}

.message-status--bubble-overlay .status-icon {
  color: var(--flare-color-message-status-on-outgoing);
  opacity: 1;
}

.message-status--on-outgoing .status-icon {
  color: var(--flare-color-message-status-on-outgoing);
}

.message-status--on-outgoing.message-status--read .status-icon {
  color: var(--flare-color-message-status-read-on-outgoing);
}

.message-status--on-outgoing.message-status--failed .status-icon {
  color: var(--flare-color-message-status-failed);
}

.message-status--bubble-overlay .status-failed .status-icon {
  color: var(--flare-color-message-status-failed);
}

@media (prefers-reduced-motion: reduce) {
  .rotating { animation: none; }
}
</style>
