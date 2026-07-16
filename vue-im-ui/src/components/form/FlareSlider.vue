<script setup lang="ts">
import { computed, ref } from "vue";

const props = withDefaults(
  defineProps<{
    min?: number;
    max?: number;
    step?: number;
    disabled?: boolean;
    /** Show a value bubble above the thumb while dragging. */
    showValue?: boolean;
  }>(),
  { min: 0, max: 100, step: 1, disabled: false, showValue: false },
);
const value = defineModel<number>({ default: 0 });
const emit = defineEmits<{ (e: "change", value: number): void }>();

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
      aria-label="Slider"
      @input="onInput"
      @change="onChange"
      @pointerdown="dragging = true"
      @pointerup="dragging = false"
      @blur="dragging = false"
    />
  </div>
</template>

<style scoped>
.flare-slider { position: relative; display: flex; align-items: center; height: 28px; width: 100%; }
.flare-slider.is-disabled { opacity: 0.5; }
.flare-slider__track {
  position: absolute;
  left: 0; right: 0;
  height: 6px;
  border-radius: 999px;
  background: var(--flare-color-border-hover, #d5d1e0);
  overflow: hidden;
}
.flare-slider__fill { height: 100%; border-radius: 999px; background: var(--im-brand-gradient, var(--flare-color-primary, #7c3aed)); }
.flare-slider__input {
  position: relative;
  width: 100%;
  margin: 0;
  background: transparent;
  -webkit-appearance: none;
  appearance: none;
  cursor: pointer;
}
.flare-slider__input:disabled { cursor: not-allowed; }
.flare-slider__input::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 18px; height: 18px;
  border-radius: 50%;
  background: #fff;
  border: 2px solid var(--flare-color-primary, #7c3aed);
  box-shadow: 0 1px 4px rgba(21, 18, 32, 0.24);
  transition: transform var(--flare-transition-fast, 150ms ease);
}
.flare-slider.is-dragging .flare-slider__input::-webkit-slider-thumb { transform: scale(1.14); }
.flare-slider__input::-moz-range-thumb {
  width: 18px; height: 18px;
  border-radius: 50%;
  background: #fff;
  border: 2px solid var(--flare-color-primary, #7c3aed);
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
  background: var(--flare-color-primary, #7c3aed);
  white-space: nowrap;
  pointer-events: none;
}
</style>
