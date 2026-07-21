<script lang="ts">
export type FlareToastVariant = "info" | "success" | "error" | "warning" | "loading";
</script>

<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import {
  InformationCircle,
  CheckmarkCircle,
  CloseCircle,
  WarningOutline,
  SyncOutline,
} from "../../shared/icon-glyphs";

const props = withDefaults(
  defineProps<{
    message: string;
    variant?: FlareToastVariant;
    /** Optional trailing action (e.g. "Undo"). */
    actionLabel?: string;
  }>(),
  { variant: "info" },
);
const emit = defineEmits<{
  (e: "action"): void;
  (e: "close"): void;
}>();

const icon = computed(
  () =>
    ({
      info: InformationCircle,
      success: CheckmarkCircle,
      error: CloseCircle,
      warning: WarningOutline,
      loading: SyncOutline,
    })[props.variant],
);
</script>

<template>
  <div class="flare-toast" :class="`flare-toast--${variant}`" role="status">
    <n-icon
      :size="18"
      :component="icon"
      class="flare-toast__icon"
      :class="{ 'is-spin': variant === 'loading' }"
    />
    <span class="flare-toast__message">{{ message }}</span>
    <button v-if="actionLabel" type="button" class="flare-toast__action" @click="emit('action')">
      {{ actionLabel }}
    </button>
  </div>
</template>

<style scoped>
.flare-toast {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  max-width: 420px;
  padding: 11px 14px;
  border-radius: var(--flare-size-radius-lg, 12px);
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-lg, 0 12px 28px rgba(21, 18, 32, 0.16));
  color: var(--flare-color-text-primary, #15131c);
  font-size: 14px;
}
.flare-toast__icon { flex: 0 0 auto; }
.flare-toast--info .flare-toast__icon { color: var(--flare-color-primary, #7c3aed); }
.flare-toast--success .flare-toast__icon { color: var(--flare-color-success, #22c55e); }
.flare-toast--error .flare-toast__icon { color: var(--flare-color-error, #ef4444); }
.flare-toast--warning .flare-toast__icon { color: var(--flare-color-warning, #f59e0b); }
.flare-toast--loading .flare-toast__icon { color: var(--flare-color-text-secondary, #6b6780); }
.flare-toast__message {
  flex: 1;
  min-width: 0;
  line-height: 1.4;
}
.flare-toast__action {
  flex: 0 0 auto;
  border: none;
  background: transparent;
  color: var(--flare-color-primary, #7c3aed);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  padding: 0 2px;
}
.flare-toast__action:hover { text-decoration: underline; }
.is-spin { animation: flare-toast-spin 0.9s linear infinite; }
@media (prefers-reduced-motion: reduce) {
  .is-spin { animation: none; }
}
@keyframes flare-toast-spin {
  to { transform: rotate(360deg); }
}
</style>
