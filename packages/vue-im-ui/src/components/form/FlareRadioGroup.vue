<script setup lang="ts">
import { computed, ref, useId } from "vue";
import FlareIcon from "../general/FlareIcon.vue";
import type { FlareSelectOption } from "../../shared/contracts";

const props = withDefaults(
  defineProps<{
    options: (FlareSelectOption & { description?: string })[];
    /** Stack vertically instead of inline. */
    vertical?: boolean;
    /**
     * Full-row choices for settings sheets (`list`), or one 48-high card per option (`cards`: plugin forms, a select
     * with at most 4 choices — stacked on phones, equal columns on PC), without changing the selected value contract.
     */
    optionLayout?: "compact" | "list" | "cards";
    /** Combine list choices into one settings surface with a trailing radio indicator. */
    grouped?: boolean;
  }>(),
  { vertical: false, optionLayout: "compact" },
);
const root = ref<HTMLElement | null>(null);
const id = useId();
const value = defineModel<string>({ default: "" });
const emit = defineEmits<{ (e: "change", value: string): void }>();
const tabValue = computed(() => props.options.find(option => option.value === value.value && !option.disabled)?.value
  ?? props.options.find(option => !option.disabled)?.value);

function select(o: FlareSelectOption): void {
  if (o.disabled) return;
  value.value = o.value;
  emit("change", o.value);
}
// Both visual layouts share one keyboard contract and one tab stop.
function navigate(event: KeyboardEvent): void {
  if (event.isComposing || event.altKey || event.ctrlKey || event.metaKey || !["ArrowDown", "ArrowUp", "ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
  const buttons = [...(root.value?.querySelectorAll<HTMLButtonElement>('button[role="radio"]') ?? [])];
  const enabled = buttons.filter(button => !button.disabled);
  if (!enabled.length) return;
  const index = enabled.indexOf(event.target as HTMLButtonElement);
  if (index < 0) return;
  event.preventDefault();
  const next = event.key === "Home" ? 0 : event.key === "End" ? enabled.length - 1
    : (index + (["ArrowUp", "ArrowLeft"].includes(event.key) ? -1 : 1) + enabled.length) % enabled.length;
  const button = enabled[next];
  button.focus();
  select(props.options[buttons.indexOf(button)]);
}
</script>

<template>
  <div ref="root" class="flare-radio-group" :class="{ 'is-vertical': vertical && optionLayout !== 'cards', 'is-list': optionLayout === 'list', 'is-cards': optionLayout === 'cards', 'is-grouped': grouped && optionLayout === 'list' }" role="radiogroup" @keydown="navigate">
    <button
      v-for="(o, index) in options"
      :key="o.value"
      type="button"
      role="radio"
      class="flare-radio"
      :class="{ 'is-on': value === o.value, 'is-disabled': o.disabled }"
      :aria-checked="value === o.value"
      :aria-labelledby="o.description ? `${id}-label-${index}` : undefined"
      :aria-describedby="o.description ? `${id}-description-${index}` : undefined"
      :tabindex="o.value === tabValue ? 0 : -1"
      :disabled="o.disabled"
      @click="select(o)"
    >
      <span v-if="optionLayout !== 'cards'" class="flare-radio__dot" />
      <span class="flare-radio__copy">
        <span :id="`${id}-label-${index}`" class="flare-radio__label">{{ o.label }}</span>
        <span v-if="o.description" :id="`${id}-description-${index}`" class="flare-radio__description">{{ o.description }}</span>
      </span>
      <FlareIcon v-if="optionLayout === 'cards' && value === o.value" class="flare-radio__check" name="check" size="sm" aria-hidden="true" />
    </button>
  </div>
</template>

<style scoped>
.flare-radio-group { display: inline-flex; gap: var(--flare-size-component-radio-indicator); flex-wrap: wrap; }
.flare-radio-group.is-vertical { flex-direction: column; gap: var(--flare-size-spacing-xs); align-items: stretch; }
.flare-radio {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  border: none;
  background: none;
  padding: 0;
  cursor: pointer;
  min-height: var(--flare-size-layout-control-height-sm);
  border-radius: var(--flare-size-radius-sm);
  font: inherit;
  font-size: var(--flare-size-font-size-lg);
  text-align: start;
  color: var(--flare-color-text-primary);
}
.flare-radio.is-disabled { opacity: 0.5; cursor: not-allowed; }
.flare-radio:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-radio__copy { display: grid; flex: 1; min-width: 0; gap: var(--flare-size-spacing-3xs); }
.flare-radio__label { min-width: 0; overflow-wrap: anywhere; line-height: var(--flare-size-line-height-normal); }
.flare-radio__description { color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); line-height: var(--flare-size-line-height-normal); overflow-wrap: anywhere; }
@media (hover: hover) {
  .flare-radio:hover:not(:disabled) { background: var(--flare-color-bg-hover); }
}
.flare-radio__dot {
  box-sizing: border-box;
  width: var(--flare-size-component-radio-indicator);
  height: var(--flare-size-component-radio-indicator);
  flex: 0 0 auto;
  border-radius: 50%;
  border: 1.5px solid var(--flare-color-border-hover);
  background: var(--flare-color-bg-primary);
  position: relative;
  transition: border-color var(--flare-transition-fast);
}
.flare-radio.is-on .flare-radio__dot { border-color: var(--flare-color-primary); }
.flare-radio.is-on .flare-radio__dot::after {
  content: "";
  position: absolute;
  inset: 50% auto auto 50%;
  width: var(--flare-size-component-radio-dot);
  height: var(--flare-size-component-radio-dot);
  transform: translate(-50%, -50%);
  border-radius: 50%;
  background: var(--flare-color-primary);
}
@media (pointer: coarse) {
  .flare-radio-group.is-vertical { display: flex; width: 100%; gap: 0; }
  .flare-radio {
    min-width: var(--flare-size-layout-touch-target);
    min-height: var(--flare-size-layout-touch-target);
  }
}
.flare-radio-group.is-list { display: flex; flex-direction: column; gap: 0; width: 100%; }
.is-list .flare-radio {
  box-sizing: border-box;
  width: 100%;
  min-height: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-md);
  gap: var(--flare-size-spacing-md);
  border-radius: var(--flare-size-radius-lg);
  font-size: var(--flare-size-font-size-lg);
  text-align: start;
}
.is-list .flare-radio__label { min-width: 0; overflow-wrap: anywhere; line-height: var(--flare-size-line-height-normal); }
.is-list .flare-radio.is-on { background: var(--flare-color-bg-selected); }
.is-list .flare-radio:hover:not(:disabled) { background: var(--flare-color-bg-hover); }
.is-list .flare-radio:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-radio-group.is-grouped {
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-elevated);
  overflow: hidden;
}
.is-grouped .flare-radio {
  position: relative;
  min-height: var(--flare-size-layout-control-height-lg);
  padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg);
  border-radius: 0;
}
.is-grouped .flare-radio + .flare-radio::before {
  content: "";
  position: absolute;
  inset: 0 var(--flare-size-spacing-lg) auto;
  border-top: 1px solid var(--flare-color-border-secondary);
}
.is-grouped .flare-radio.is-on { background: transparent; }
.is-grouped .flare-radio__dot { order: 1; }
.is-grouped .flare-radio__label { font-weight: var(--flare-size-font-weight-medium); }
.is-grouped .flare-radio.is-on .flare-radio__label { color: var(--flare-color-primary-text); }
/* cards: one bordered 48-high card per option; the selected card takes the selected border and a check. */
.flare-radio-group.is-cards { display: grid; grid-template-columns: minmax(0, 1fr); gap: var(--flare-size-spacing-sm); width: 100%; }
.is-cards .flare-radio {
  box-sizing: border-box;
  justify-content: space-between;
  width: 100%;
  min-height: var(--flare-size-layout-control-height-lg);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary);
}
.is-cards .flare-radio.is-on { border-color: var(--flare-color-border-selected); box-shadow: inset 0 0 0 1px var(--flare-color-border-selected); }
.is-cards .flare-radio__check { flex: none; color: var(--flare-color-primary-text); }
.is-cards .flare-radio:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
@media (min-width: 900px) {
  .flare-radio-group.is-cards { grid-auto-flow: column; grid-auto-columns: minmax(0, 1fr); grid-template-columns: none; }
}
</style>
