<script setup lang="ts">
// A linear progress bar: a value from 0 to 1, or a sliding fill while the length of the work is not known. A value that
// is missing or not finite reads as indeterminate (`spec/update-prompt-vectors.json`, the same in every kit). It is not
// a live region: a screen reader reads its number when it reaches it, and whoever owns the work announces the milestones.
import { computed } from "vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { flareProgressBarValue, type FlareProgressBarTone } from "../../utils/updatePrompt";

const props = withDefaults(
  defineProps<{
    /** How far along, 0 to 1. */
    value?: number | null;
    /** The length of the work is not known: the fill slides instead. */
    indeterminate?: boolean;
    /** What the colour says. */
    tone?: FlareProgressBarTone;
    /** What is progressing, for a screen reader. */
    label?: string;
  }>(),
  { value: null, indeterminate: false, tone: "primary", label: undefined },
);
const { t } = useFlareI18nOptional();

const shown = computed(() => flareProgressBarValue(props.value, props.indeterminate));
const valueText = computed(() => (shown.value.percent === null ? t("progressBar.loading") : `${shown.value.percent}%`));
const fillStyle = computed(() => (shown.value.value === null ? undefined : { width: `${shown.value.value * 100}%` }));
</script>

<template>
  <div
    class="flare-progress-bar"
    :class="[`flare-progress-bar--${tone}`, { 'is-indeterminate': shown.value === null }]"
    role="progressbar"
    :aria-label="label ?? t('progressBar.label')"
    aria-valuemin="0"
    aria-valuemax="100"
    :aria-valuenow="shown.percent ?? undefined"
    :aria-valuetext="valueText"
  >
    <span class="flare-progress-bar__fill" :style="fillStyle" />
  </div>
</template>

<style scoped>
.flare-progress-bar {
  --flare-progress-bar-fill: var(--flare-color-primary-text);
  position: relative;
  width: 100%;
  min-width: 0;
  height: var(--flare-size-spacing-xs);
  overflow: hidden;
  border-radius: var(--flare-size-radius-full);
  background: var(--flare-color-bg-tertiary);
}
.flare-progress-bar--success { --flare-progress-bar-fill: var(--flare-color-success-text); }
.flare-progress-bar--warning { --flare-progress-bar-fill: var(--flare-color-warning-text); }
.flare-progress-bar--danger { --flare-progress-bar-fill: var(--flare-color-error-text); }
.flare-progress-bar--neutral { --flare-progress-bar-fill: var(--flare-color-text-secondary); }
.flare-progress-bar__fill {
  position: absolute;
  inset-block: 0;
  inset-inline-start: 0;
  border-radius: inherit;
  background: var(--flare-progress-bar-fill);
  transition: width var(--flare-transition-normal);
}
.flare-progress-bar.is-indeterminate .flare-progress-bar__fill {
  width: 40%;
  animation: flare-progress-bar-slide 1.4s ease-in-out infinite;
}
@keyframes flare-progress-bar-slide {
  from { inset-inline-start: -40%; }
  to { inset-inline-start: 100%; }
}
@media (prefers-reduced-motion: reduce) {
  .flare-progress-bar__fill { transition: none; }
  /* Nothing to measure and nothing may move: a still, muted fill says the work is under way. */
  .flare-progress-bar.is-indeterminate .flare-progress-bar__fill {
    width: 100%;
    opacity: var(--flare-opacity-muted);
    animation: none;
  }
}
@media (forced-colors: active) {
  .flare-progress-bar { outline: 1px solid Highlight; }
  .flare-progress-bar__fill { background: Highlight; }
}
</style>
