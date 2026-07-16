<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { flareIcons, type FlareIconName } from "../../shared/icons";

const props = withDefaults(
  defineProps<{
    /** A canonical Flare icon name (see the gallery). */
    name: FlareIconName;
    size?: number;
  }>(),
  { size: 20 },
);
const glyph = computed(() => flareIcons[props.name]);
</script>

<template>
  <n-icon :size="size" :component="glyph" />
</template>
