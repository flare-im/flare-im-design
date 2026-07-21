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
</script>

<template>
  <FlareIcon v-if="semantic" :name="semantic" :size="size" />
  <template v-else>{{ icon }}</template>
</template>
