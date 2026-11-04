<script setup lang="ts">
import { computed, ref } from "vue";
import { NQrCode } from "naive-ui";
import { flareDesignTokens } from "@flare-im/tokens";

defineProps<{ payload: string; label: string }>();

// Use the light palette in every theme to preserve scanner contrast.
const modulesColor = flareDesignTokens.colors.text.primary;
const panelColor = flareDesignTokens.colors.bg.primary;
const code = ref<InstanceType<typeof NQrCode> | null>(null);
const moduleCount = computed(() => code.value?.svgInfo.numCells ?? 21);
// On a square with N modules plus 8 modules of padding, each side gets 4/(N+8).
const quietZone = computed(() => `${400 / (moduleCount.value + 8)}%`);
</script>

<template>
  <div class="flare-qr-matrix" role="img" :aria-label="label" :style="{ padding: quietZone, background: panelColor }">
    <NQrCode
      ref="code"
      class="flare-qr-matrix__svg"
      aria-hidden="true"
      type="svg"
      error-correction-level="M"
      :value="payload"
      :size="200"
      :padding="0"
      :color="modulesColor"
      :background-color="panelColor"
    />
  </div>
</template>

<style scoped>
.flare-qr-matrix {
  display: block;
  box-sizing: border-box;
  border-radius: var(--flare-size-radius-lg);
  forced-color-adjust: none;
}
.flare-qr-matrix__svg {
  display: block;
  width: 100% !important;
  height: auto !important;
  border-radius: 0;
}
.flare-qr-matrix__svg :deep(svg) {
  display: block;
  width: 100%;
  height: auto;
}
</style>
