<script setup lang="ts">
import { computed, type Component } from "vue";
import { NIcon } from "naive-ui";
import type { FlareControlSize } from "../../shared/contracts";
import { useFlareConfig } from "../../shared/useFlareConfig";

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
    /** Foreground/icon color override (overrides variant/active colors, incl. hover). */
    tint?: string;
    /** Background color override (overrides variant/active background). */
    background?: string;
    /** Dimension override in px; glyph size = round(customSize * 0.46). */
    customSize?: number;
  }>(),
  { variant: "plain", shape: "circle", disabled: false, active: false },
);
const emit = defineEmits<{ (e: "click"): void }>();
const config = useFlareConfig();
const rsize = computed(() => props.size ?? config.size.value);
const overrideStyle = computed(() => {
  const s: Record<string, string> = {};
  if (props.tint) s.color = props.tint;
  if (props.background) s.background = props.background;
  if (props.customSize != null) {
    s.width = `${props.customSize}px`;
    s.height = `${props.customSize}px`;
    s.fontSize = `${Math.round(props.customSize * 0.46)}px`;
  }
  return s;
});
</script>

<template>
  <button
    type="button"
    class="flare-icon-button"
    :class="[`flare-icon-button--${rsize}`, `flare-icon-button--${variant}`, `is-${shape}`, { 'is-active': active }]"
    :style="overrideStyle"
    :aria-label="ariaLabel"
    :aria-pressed="active"
    :disabled="disabled"
    @click="emit('click')"
  >
    <n-icon :component="icon" />
  </button>
</template>

<style scoped>
.flare-icon-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  cursor: pointer;
  color: var(--flare-color-text-secondary, #626978);
  background: transparent;
  transition: background var(--flare-transition-fast, 150ms cubic-bezier(0.22, 1, 0.36, 1)), color var(--flare-transition-fast, 150ms cubic-bezier(0.22, 1, 0.36, 1)), transform var(--flare-transition-fast, 150ms cubic-bezier(0.22, 1, 0.36, 1));
}
.flare-icon-button:active:not(:disabled) { transform: scale(0.92); }
.flare-icon-button:disabled { opacity: 0.45; cursor: not-allowed; }
.is-circle { border-radius: 50%; }
.is-square { border-radius: var(--flare-size-radius-md, 8px); }

.flare-icon-button--sm { width: 30px; height: 30px; font-size: 16px; }
.flare-icon-button--md { width: 38px; height: 38px; font-size: 19px; }
.flare-icon-button--lg { width: 46px; height: 46px; font-size: 22px; }

.flare-icon-button--plain:hover:not(:disabled) { background: var(--flare-color-bg-secondary, #F7F8FA); color: var(--flare-color-text-primary, #20232D); }
.flare-icon-button--tinted { background: var(--flare-color-bg-secondary, #F7F8FA); }
.flare-icon-button--tinted:hover:not(:disabled) { background: var(--flare-color-bg-selected, #F0ECFC); color: var(--flare-color-primary, #7047D6); }
.flare-icon-button--solid { background: var(--im-brand-gradient, var(--flare-color-primary, #7047D6)); color: #fff; }
.flare-icon-button--solid:hover:not(:disabled) { filter: brightness(0.97); }
.flare-icon-button.is-active { background: var(--flare-color-bg-selected, #F0ECFC); color: var(--flare-color-primary, #7047D6); }
</style>
