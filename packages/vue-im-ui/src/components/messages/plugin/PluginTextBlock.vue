<script setup lang="ts">
import { computed } from "vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";
import { useClampedText } from "./useClampedText";
import type { FlarePluginTextBlock } from "../../../shared/contracts/plugin-ui";

// Text cut at `maxLines` (or the host's `clamp`), with "expand" when it overflows.
const props = defineProps<{ block: FlarePluginTextBlock; clamp?: number }>();
const { t } = useFlareI18nOptional();
const cap = computed(() => props.clamp ?? props.block.maxLines);
const { el, expanded, lines, overflows, toggle } = useClampedText(cap, () => props.block.text);
</script>

<template>
  <div class="flare-plugin-text">
    <p
      ref="el"
      class="flare-plugin-text__body"
      :class="`is-${block.style ?? 'body'}`"
      :style="lines ? { '-webkit-line-clamp': String(lines), 'line-clamp': String(lines) } : undefined"
      :data-clamped="lines ? 'true' : undefined"
    >{{ block.text }}</p>
    <button
      v-if="overflows"
      type="button"
      class="flare-plugin-text__toggle"
      :aria-expanded="expanded"
      data-text-toggle="true"
      @click="toggle"
    >
      {{ expanded ? t("pluginView.collapse") : t("pluginView.expand") }}
    </button>
  </div>
</template>

<style scoped>
.flare-plugin-text { display: grid; justify-items: start; gap: var(--flare-size-spacing-3xs); min-width: 0; }
.flare-plugin-text__body {
  margin: 0;
  max-width: 100%;
  white-space: pre-line;
  overflow-wrap: anywhere;
  font-size: var(--flare-plugin-body-size, var(--flare-size-font-size-lg));
  line-height: var(--flare-size-line-height-normal);
  color: var(--flare-color-text-primary);
}
.flare-plugin-text__body[data-clamped] { display: -webkit-box; -webkit-box-orient: vertical; overflow: hidden; }
.flare-plugin-text__body.is-title { font-size: var(--flare-plugin-title-size, var(--flare-size-font-size-2xl)); font-weight: var(--flare-size-font-weight-semibold); line-height: var(--flare-size-line-height-snug); }
.flare-plugin-text__body.is-secondary { font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-secondary); }
.flare-plugin-text__toggle {
  position: relative;
  padding: 0;
  border: 0;
  background: none;
  font: inherit;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-primary-text);
  cursor: pointer;
}
/* A text-sized key whose target reaches the touch-target size around it. */
.flare-plugin-text__toggle::after {
  content: "";
  position: absolute;
  inset: calc(var(--flare-size-spacing-md) * -1) calc(var(--flare-size-spacing-sm) * -1);
}
.flare-plugin-text__toggle:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
</style>
