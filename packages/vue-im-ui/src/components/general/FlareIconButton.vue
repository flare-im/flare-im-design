<script setup lang="ts">
import { computed, type Component } from "vue";
import { NIcon } from "naive-ui";
import type { FlareControlSize } from "../../shared/contracts";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { useFlareConfig } from "../../shared/useFlareConfig";
import { useFlareAdaptiveSafe } from "../../composables/useAdaptiveMode";

const props = withDefaults(
  defineProps<{
    icon: Component;
    ariaLabel: string;
    /** Falls back to the global config size when omitted. */
    size?: FlareControlSize;
    /** Visual weight. */
    variant?: "plain" | "tinted" | "solid";
    shape?: "circle" | "square";
    disabled?: boolean;
    /** Toggle-active look (e.g. a selected filter). */
    active?: boolean;
    /** Exposes aria-pressed for controls that genuinely toggle state. */
    toggle?: boolean;
    /** Foreground/icon color override (overrides variant/active colors, incl. hover). */
    tint?: string;
    /** Background color override (overrides variant/active background). */
    background?: string;
    /** Dimension override in px; the glyph uses the nearest standard icon size. */
    customSize?: number;
    /** Red dot: something new behind the button, nothing to count. Said with the button's name. */
    dot?: boolean;
  }>(),
  { variant: "plain", shape: "circle", disabled: false, active: false, toggle: false, dot: false },
);
const emit = defineEmits<{ (e: "click"): void }>();
const config = useFlareConfig();
const { isH5 } = useFlareAdaptiveSafe();
const { t } = useFlareI18nOptional();
const rsize = computed(() => props.size ?? config.size.value);
/** `aria-label` replaces the button's content, so a label on the dot itself would never be read. */
const label = computed(() => (props.dot ? `${props.ariaLabel}, ${t("settingsRow.badge")}` : props.ariaLabel));
const ariaPressed = computed(() => props.toggle || props.active ? props.active : undefined);
const overrideStyle = computed(() => {
  const s: Record<string, string> = {};
  if (props.tint) s.color = props.tint;
  if (props.background) s.background = props.background;
  if (props.customSize != null) {
    s["--flare-icon-button-side"] = `${props.customSize}px`;
    const glyphSize = [16, 20, 24, 32].reduce((best, size) =>
      Math.abs(size - props.customSize! * 0.46) < Math.abs(best - props.customSize! * 0.46) ? size : best, 16);
    s["--flare-icon-button-glyph"] = `var(--flare-size-icon-size-${({ 16: "sm", 20: "md", 24: "lg", 32: "xl" } as const)[glyphSize as 16 | 20 | 24 | 32]})`;
  }
  return s;
});
</script>

<template>
  <button
    type="button"
    class="flare-icon-button"
    :class="[`flare-icon-button--${rsize}`, `flare-icon-button--${variant}`, `is-${shape}`, { 'is-active': active, 'is-phone': isH5 }]"
    :style="overrideStyle"
    :aria-label="label"
    :aria-pressed="ariaPressed"
    :disabled="disabled"
    @click="emit('click')"
  >
    <n-icon aria-hidden="true" :component="icon" />
    <span v-if="dot" class="flare-icon-button__dot" aria-hidden="true" />
  </button>
</template>

<style scoped>
.flare-icon-button {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: var(--flare-icon-button-side);
  height: var(--flare-icon-button-side);
  min-width: max(var(--flare-icon-button-side), var(--flare-icon-button-target-min, 0px));
  min-height: max(var(--flare-icon-button-side), var(--flare-icon-button-target-min, 0px));
  font-size: max(var(--flare-icon-button-glyph), var(--flare-icon-button-glyph-min, 0px));
  padding: 0;
  border: none;
  cursor: pointer;
  color: var(--flare-color-text-secondary);
  background: transparent;
  transition: background var(--flare-transition-fast), color var(--flare-transition-fast), transform var(--flare-transition-fast);
}
.flare-icon-button::after {
  content: "";
  position: absolute;
  width: max(100%, var(--flare-icon-button-hit-floor, var(--flare-size-layout-touch-target)));
  height: max(100%, var(--flare-icon-button-hit-floor, var(--flare-size-layout-touch-target)));
}
.flare-icon-button.is-phone {
  --flare-icon-button-hit-floor: 0px;
  --flare-icon-button-target-min: var(--flare-header-action-target, var(--flare-size-layout-touch-target-min));
  --flare-icon-button-glyph-min: var(--flare-header-action-glyph, var(--flare-size-icon-size-md));
}
@media (pointer: coarse) {
  .flare-icon-button {
    --flare-icon-button-hit-floor: 0px;
    --flare-icon-button-target-min: var(--flare-header-action-target, var(--flare-size-layout-touch-target-min));
    --flare-icon-button-glyph-min: var(--flare-header-action-glyph, var(--flare-size-icon-size-md));
  }
}
.flare-icon-button:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-icon-button:active:not(:disabled) { transform: scale(0.92); }
.flare-icon-button:disabled { opacity: var(--flare-opacity-disabled); cursor: not-allowed; }
.is-circle { border-radius: 50%; }
.is-square { border-radius: var(--flare-size-radius-md); }

.flare-icon-button--sm { --flare-icon-button-side: var(--flare-size-component-icon-button-side-sm); --flare-icon-button-glyph: var(--flare-size-component-icon-button-glyph-sm); }
.flare-icon-button--md { --flare-icon-button-side: var(--flare-size-component-icon-button-side-md); --flare-icon-button-glyph: var(--flare-size-component-icon-button-glyph-md); }
.flare-icon-button--lg { --flare-icon-button-side: var(--flare-size-component-icon-button-side-lg); --flare-icon-button-glyph: var(--flare-size-component-icon-button-glyph-lg); }

.flare-icon-button--tinted { background: var(--flare-color-bg-secondary); }
.flare-icon-button--solid { background: var(--flare-color-primary); color: #fff; }
@media (hover: hover) {
  .flare-icon-button--plain:hover:not(:disabled) { background: var(--flare-color-bg-secondary); color: var(--flare-color-text-primary); }
  .flare-icon-button--tinted:hover:not(:disabled) { background: var(--flare-color-bg-selected); color: var(--flare-color-primary-text); }
  .flare-icon-button--solid:hover:not(:disabled) { background: var(--flare-color-primary-hover); }
}
.flare-icon-button--plain:active:not(:disabled),
.flare-icon-button--tinted:active:not(:disabled) { background: var(--flare-color-bg-hover); }
.flare-icon-button--solid:active:not(:disabled) { background: var(--flare-color-primary-active); }
.flare-icon-button.is-active { background: var(--flare-color-bg-selected); color: var(--flare-color-primary-text); }
/* 和 FlareSettingsRow 的红点同一画法，贴在右上角。 */
.flare-icon-button__dot {
  position: absolute;
  top: var(--flare-size-spacing-xs);
  inset-inline-end: var(--flare-size-spacing-xs);
  width: var(--flare-size-spacing-sm);
  height: var(--flare-size-spacing-sm);
  border-radius: var(--flare-size-radius-full);
  background: var(--flare-color-error);
}
@media (prefers-reduced-motion: reduce) {
  .flare-icon-button { transition: none; }
  .flare-icon-button:active:not(:disabled) { transform: none; }
}
</style>
