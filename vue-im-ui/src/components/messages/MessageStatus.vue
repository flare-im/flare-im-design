<script setup lang="ts">
import { computed } from "vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    status: number;
    variant?: "inline" | "bubbleOverlay";
  }>(),
  { variant: "inline" },
);

const emit = defineEmits<{
  (event: "resend"): void;
}>();

const { t } = useFlareI18n();

const resendLabel = computed(() => t("message.resendAria"));
</script>

<template>
  <div class="message-status" :class="{ 'message-status--bubble-overlay': variant === 'bubbleOverlay' }">
    <div v-if="status === 1" class="status-sending" :title="t('message.sending')">
      <svg class="status-icon rotating" viewBox="0 0 16 16" fill="none" aria-hidden="true">
        <circle cx="8" cy="8" r="6" stroke="currentColor" stroke-width="1.5" stroke-dasharray="3 3" />
      </svg>
    </div>

    <div v-else-if="status === 2" class="status-sent" :title="t('message.sent')">
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

    <div v-else-if="status === 3" class="status-delivered" :title="t('message.delivered')">
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

    <div v-else-if="status === 4" class="status-read" :title="t('message.read')">
      <svg class="status-icon status-two-checks" viewBox="0 0 18 16" fill="none" aria-hidden="true">
        <path
          class="status-read-path"
          d="M1.5 8.5L4.5 11.5L8 7"
          stroke="currentColor"
          stroke-width="1.5"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          class="status-read-path"
          d="M7 8.5L10 11.5L16 4.5"
          stroke="currentColor"
          stroke-width="1.5"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </svg>
    </div>

    <button
      v-else-if="status === 5"
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

    <div v-else-if="status === 6" class="status-recalled">
      <span class="status-text">{{ t("message.recalled") }}</span>
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
  padding: 4px 9px;
  border-radius: 999px;
  background: rgba(0, 0, 0, 0.48);
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
}

.status-icon {
  width: 18px;
  height: 18px;
  display: block;
}

.status-failed {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  border: 0;
  background: transparent;
  color: var(--im-danger, var(--flare-color-error, #ef4444));
  cursor: pointer;
}

.status-text {
  font-size: 12px;
  color: var(--im-text-secondary, #888888);
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

.status-sending .status-icon {
  opacity: 0.72;
  color: var(--im-text-tertiary, var(--flare-color-text-tertiary, #a3a7ae));
}

.status-sent .status-icon {
  color: var(--im-text-tertiary, var(--flare-color-text-tertiary, #a3a7ae));
  opacity: 0.92;
}

.status-delivered .status-icon,
.status-read .status-icon {
  color: var(--im-success, var(--flare-color-success, #22c55e));
}

.status-read-path {
  stroke: var(--im-success, var(--flare-color-success, #22c55e)) !important;
}

.status-failed .status-icon circle,
.status-failed .status-icon path {
  stroke: currentColor;
}

.message-status--bubble-overlay.status-sending .status-icon {
  color: rgba(255, 255, 255, 0.85);
  opacity: 1;
}

.message-status--bubble-overlay .status-sent .status-icon,
.message-status--bubble-overlay .status-delivered .status-icon {
  color: rgba(255, 255, 255, 0.92);
}

.message-status--bubble-overlay .status-read-path {
  stroke: #ffffff !important;
}
</style>
