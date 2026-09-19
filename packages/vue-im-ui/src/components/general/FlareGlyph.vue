<script setup lang="ts">
/**
 * Lenient icon renderer for host-supplied `icon` strings. If the value is a
 * canonical Flare semantic name it renders the crisp line glyph via FlareIcon;
 * otherwise it falls back to rendering the string as-is (emoji / single char)
 * for back-compat. Use this wherever a component accepts an open `icon?: string`.
 */
import { computed } from "vue";
import FlareIcon from "./FlareIcon.vue";
import { flareIcons, type FlareIconName } from "../../shared/icons";

const props = withDefaults(defineProps<{ icon?: string; size?: number }>(), { size: 20 });
const semantic = computed(() => (props.icon && props.icon in flareIcons ? (props.icon as FlareIconName) : null));
// A word that is not an icon name ("bell") is a host mistake: showing it would put the word
// on screen and into the control's accessible name. Emoji and single characters still render,
// hidden from assistive technology like every icon.
const fallback = computed(() => {
  const value = props.icon?.trim() ?? "";
  if (!value || semantic.value) return "";
  if (/^[A-Za-z][A-Za-z0-9-]*$/.test(value)) {
    if (import.meta.env?.DEV) console.warn(`[flare-im] "${value}" is not a Flare icon name`);
    return "";
  }
  return value;
});
</script>

<template>
  <FlareIcon v-if="semantic" :name="semantic" :size="size" />
  <span v-else-if="fallback" aria-hidden="true">{{ fallback }}</span>
</template>
