<script setup lang="ts">
/**
 * Lenient icon renderer for host-supplied `icon` strings. A canonical Flare semantic name renders its line glyph via
 * FlareIcon; any other word renders the shared fallback glyph (`plugin`), with a development warning once per name —
 * never the word itself, never a blank (spec/me-menu-vectors.json iconFallback). An emoji or a single character still
 * renders as given, hidden from assistive technology like every icon.
 */
import { computed } from "vue";
import FlareIcon from "./FlareIcon.vue";
import { flareIconNameOrFallback } from "../../shared/icons";

const props = withDefaults(defineProps<{ icon?: string; size?: number }>(), { size: 20 });
const value = computed(() => props.icon?.trim() ?? "");
// A word-like value is meant as an icon name: the registry's glyph, or the fallback for a name it does not have.
const semantic = computed(() => (/^[A-Za-z][A-Za-z0-9-]*$/.test(value.value) ? flareIconNameOrFallback(value.value) : null));
const literal = computed(() => (value.value && !semantic.value ? value.value : ""));
</script>

<template>
  <FlareIcon v-if="semantic" :name="semantic" :size="size" />
  <span v-else-if="literal" aria-hidden="true">{{ literal }}</span>
</template>
