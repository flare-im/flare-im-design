<script lang="ts">
import type { FlareToastVariant as ToastVariant } from "../../shared/contracts/tone";
export type FlareToastVariant = ToastVariant;
</script>

<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import {
  InformationCircleOutline,
  CheckmarkCircleOutline,
  WarningOutline,
  SyncOutline,
} from "../../shared/icon-glyphs";
import { flareIcons } from "../../shared/icons";
import { toastVariantFromTone, toneFromToastVariant, type FlareTone } from "../../shared/contracts/tone";

const props = withDefaults(
  defineProps<{
    message: string;
    /** Form of the toast; kept because `loading` also carries the spinner. Mapped to `tone`. */
    variant?: FlareToastVariant;
    /** Semantic tone (shared enum). Overrides the tone derived from `variant` when set. */
    tone?: FlareTone;
    /** Optional trailing action (e.g. "Undo"). */
    actionLabel?: string;
  }>(),
  { variant: "info", tone: undefined },
);
const emit = defineEmits<{
  (e: "action"): void;
  (e: "close"): void;
}>();

/** Effective tone: explicit `tone` wins, else derived from `variant` (error → danger). */
const resolvedTone = computed<FlareTone>(() => props.tone ?? toneFromToastVariant(props.variant));
/** Effective variant: an explicit `tone` re-derives the form (danger → error); `loading` only via `variant`. */
const resolvedVariant = computed<FlareToastVariant>(() => (props.tone ? toastVariantFromTone(props.tone) : props.variant));

const icon = computed(
  () =>
    ({
      info: InformationCircleOutline,
      success: CheckmarkCircleOutline,
      error: flareIcons.error,
      warning: WarningOutline,
      loading: SyncOutline,
    })[resolvedVariant.value],
);
</script>

<template>
  <div class="flare-toast" :class="`flare-toast--${resolvedVariant}`" :data-tone="resolvedTone" role="status">
    <n-icon aria-hidden="true"
      :size="18"
      :component="icon"
      class="flare-toast__icon"
      :class="{ 'is-spin': resolvedVariant === 'loading' }"
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
  gap: var(--flare-size-spacing-2sm);
  max-width: 420px;
  padding: 11px var(--flare-size-spacing-2md);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-lg);
  color: var(--flare-color-text-primary);
  font-size: 14px;
}
.flare-toast__icon { flex: 0 0 auto; }
.flare-toast--info .flare-toast__icon { color: var(--flare-color-primary-text); }
.flare-toast--success .flare-toast__icon { color: var(--flare-color-success-text); }
.flare-toast--error .flare-toast__icon { color: var(--flare-color-error-text); }
.flare-toast--warning .flare-toast__icon { color: var(--flare-color-warning-text); }
.flare-toast--loading .flare-toast__icon { color: var(--flare-color-text-secondary); }
.flare-toast__message {
  flex: 1;
  min-width: 0;
  line-height: 1.4;
}
.flare-toast__action {
  flex: 0 0 auto;
  border: none;
  background: transparent;
  color: var(--flare-color-primary-text);
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
