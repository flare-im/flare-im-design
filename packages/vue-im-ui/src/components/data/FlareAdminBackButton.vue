<script setup lang="ts">
import FlareButton from "../general/FlareButton.vue";
import { ArrowBackOutline } from "../../shared/icon-glyphs";

defineProps<{ label: string; disabled?: boolean }>();
</script>

<template>
  <FlareButton
    class="flare-admin-back-button"
    variant="ghost"
    size="md"
    :icon="ArrowBackOutline"
    :label="label"
    :disabled="disabled"
  />
</template>

<style scoped>
.flare-button.flare-admin-back-button {
  align-self: flex-start;
  max-inline-size: 100%;
  block-size: auto;
  padding-block: var(--flare-size-spacing-xs);
  text-align: start;
  white-space: normal;
  overflow-wrap: anywhere;
}

@media (pointer: coarse) {
  .flare-button.flare-admin-back-button { min-block-size: var(--flare-size-layout-touch-target-min); }
}
</style>
