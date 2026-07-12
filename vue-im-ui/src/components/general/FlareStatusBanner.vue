<script setup lang="ts">
// A compact status strip (connection / sync / runtime state) with an optional
// pulsing dot and an optional inline action. Replaces the per-app bespoke
// runtime/connection/sync banners.
withDefaults(
  defineProps<{
    text: string;
    tone?: "info" | "success" | "warning" | "danger" | "neutral";
    dot?: boolean;
    pulse?: boolean;
    actionText?: string;
  }>(),
  { tone: "info", dot: true, pulse: false },
);
const emit = defineEmits<{ (e: "action"): void }>();
</script>

<template>
  <div class="flare-status-banner" :class="`flare-status-banner--${tone}`" role="status">
    <span
      v-if="dot"
      class="flare-status-banner__dot"
      :class="{ 'flare-status-banner__dot--pulse': pulse }"
    />
    <span class="flare-status-banner__text">{{ text }}</span>
    <button
      v-if="actionText"
      type="button"
      class="flare-status-banner__action"
      @click="emit('action')"
    >
      {{ actionText }}
    </button>
  </div>
</template>

<style scoped>
.flare-status-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  font-size: 13px;
  line-height: 1.4;
  border-radius: 10px;
  color: var(--flare-tone, var(--flare-color-info));
  background: color-mix(in srgb, var(--flare-tone, var(--flare-color-info)) 10%, transparent);
  border: 1px solid color-mix(in srgb, var(--flare-tone, var(--flare-color-info)) 24%, transparent);
}

.flare-status-banner--info {
  --flare-tone: var(--flare-color-info);
}
.flare-status-banner--success {
  --flare-tone: var(--flare-color-success);
}
.flare-status-banner--warning {
  --flare-tone: var(--flare-color-warning);
}
.flare-status-banner--danger {
  --flare-tone: var(--flare-color-error);
}
.flare-status-banner--neutral {
  --flare-tone: var(--flare-color-text-secondary);
}

.flare-status-banner__dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex: none;
  background: currentColor;
}

.flare-status-banner__dot--pulse {
  animation: flare-status-pulse 1.4s ease-in-out infinite;
}

.flare-status-banner__text {
  flex: 1;
  min-width: 0;
}

.flare-status-banner__action {
  flex: none;
  font: inherit;
  font-weight: 600;
  cursor: pointer;
  color: currentColor;
  background: none;
  border: none;
  padding: 0;
  text-decoration: underline;
  text-underline-offset: 2px;
}

@keyframes flare-status-pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.35;
  }
}

@media (prefers-reduced-motion: reduce) {
  .flare-status-banner__dot--pulse {
    animation: none;
  }
}
</style>
