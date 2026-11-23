<script setup lang="ts">
import { computed } from "vue";
import { flareIcons } from "../../shared/icons";
const props = defineProps<{ size?: number }>();
const dimension = computed(() => props.size == null ? "var(--flare-size-icon-size-sm)" : `${props.size}px`);
</script>

<template>
  <component :is="flareIcons.read" class="message-double-check" :style="{ width: dimension, height: dimension }" aria-hidden="true" focusable="false" />
</template>

<style scoped>
.message-double-check { display: block; flex: none; overflow: visible; }
</style>
