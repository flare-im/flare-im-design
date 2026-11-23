<script setup lang="ts">
import { computed, ref } from "vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { useFlareFormControl } from "../../shared/useFlareFormField";

const props = withDefaults(
  defineProps<{
    min?: number;
    max?: number;
    step?: number;
    disabled?: boolean;
    /** Accessible name for sliders outside a labelled form field. */
    ariaLabel?: string;
    /** Human-readable value, for example an audio playback time. */
    ariaValueText?: string;
    /** Show a value bubble above the thumb while dragging. */
    showValue?: boolean;
  }>(),
  { min: 0, max: 100, step: 1, disabled: false, showValue: false },
);
const value = defineModel<number>({ default: 0 });
const emit = defineEmits<{ (e: "change", value: number): void }>();

const { t } = useFlareI18n();
// Inside a labelled FlareFormField the field label names the range; the generic name is the fallback.
const control = useFlareFormControl({});
const dragging = ref(false);
const pct = computed(() => {
  const span = props.max - props.min || 1;
  return Math.min(100, Math.max(0, ((value.value - props.min) / span) * 100));
});

function onInput(e: Event): void {
  value.value = Number((e.target as HTMLInputElement).value);
}
function onChange(): void {
  emit("change", value.value);
}
</script>

<template>
  <div class="flare-slider" :class="{ 'is-disabled': disabled, 'is-dragging': dragging }">
    <div class="flare-slider__track">
      <div class="flare-slider__fill" :style="{ width: `${pct}%` }" />
    </div>
    <div v-if="showValue" class="flare-slider__bubble" :style="{ left: `${pct}%` }">{{ value }}</div>
    <input
      class="flare-slider__input"
      type="range"
      :min="min"
      :max="max"
      :step="step"
      :value="value"
      :disabled="disabled"
      :id="control.id"
      :aria-label="ariaLabel || (control.labelId ? undefined : t('slider.label'))"
      :aria-valuetext="ariaValueText"
      :aria-describedby="control.describedBy"
      :aria-invalid="control.invalid || undefined"
      @input="onInput"
      @change="onChange"
      @pointerdown="dragging = true"
      @pointerup="dragging = false"
      @blur="dragging = false"
    />
  </div>
</template>

<style scoped>
.flare-slider { --slider-track-height: 6px; --slider-thumb-size: 18px; position: relative; display: flex; align-items: center; height: 28px; width: 100%; }
.flare-slider.is-disabled { opacity: 0.5; }
.flare-slider__track {
  position: absolute;
  left: 0; right: 0;
  height: var(--slider-track-height);
  border-radius: 999px;
  background: var(--flare-color-border-hover);
  overflow: hidden;
}
.flare-slider__fill { height: 100%; border-radius: 999px; background: var(--flare-component-brand-primary); }
.flare-slider__input {
  position: relative;
  width: 100%;
  margin: 0;
  height: 100%;
  padding: 0;
  background: transparent;
  -webkit-appearance: none;
  appearance: none;
  cursor: pointer;
}
.flare-slider__input:disabled { cursor: not-allowed; }
.flare-slider__input::-webkit-slider-runnable-track { height: var(--slider-track-height); border: 0; background: transparent; }
.flare-slider__input::-moz-range-track { height: var(--slider-track-height); border: 0; background: transparent; }
.flare-slider__input::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  margin-top: calc((var(--slider-track-height) - var(--slider-thumb-size)) / 2);
  box-sizing: border-box;
  width: var(--slider-thumb-size); height: var(--slider-thumb-size);
  border-radius: 50%;
  background: #fff;
  border: 2px solid var(--flare-color-primary);
  box-shadow: 0 1px 4px rgba(21, 18, 32, 0.24);
  transition: transform var(--flare-transition-fast);
}
.flare-slider.is-dragging .flare-slider__input::-webkit-slider-thumb { transform: scale(1.14); }
.flare-slider__input:focus-visible::-webkit-slider-thumb { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; box-shadow: 0 0 0 4px var(--flare-color-focus-ring); }
.flare-slider__input:focus-visible::-moz-range-thumb { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; box-shadow: 0 0 0 4px var(--flare-color-focus-ring); }
.flare-slider__input::-moz-range-thumb {
  box-sizing: border-box;
  width: var(--slider-thumb-size); height: var(--slider-thumb-size);
  border-radius: 50%;
  background: #fff;
  border: 2px solid var(--flare-color-primary);
  box-shadow: 0 1px 4px rgba(21, 18, 32, 0.24);
}
.flare-slider__bubble {
  position: absolute;
  bottom: 100%;
  transform: translateX(-50%);
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 12px;
  font-variant-numeric: tabular-nums;
  color: #fff;
  background: var(--flare-color-primary);
  white-space: nowrap;
  pointer-events: none;
}
</style>
