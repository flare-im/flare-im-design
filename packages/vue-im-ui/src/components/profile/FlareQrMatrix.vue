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
function exportSvg(): string | null {
  const info = code.value?.svgInfo;
  if (!info) return null;
  const side = info.numCells + 8;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="-4 -4 ${side} ${side}" width="${side * 16}" height="${side * 16}"><rect x="-4" y="-4" width="${side}" height="${side}" fill="${panelColor}"/>${info.innerHtml}</svg>`;
}
async function exportPng(): Promise<Blob> {
  const svg = exportSvg(); if (!svg) throw new Error("QR unavailable");
  const url = URL.createObjectURL(new Blob([svg], { type: "image/svg+xml" }));
  try {
    const image = new Image(); image.src = url; await image.decode();
    const canvas = document.createElement("canvas"); canvas.width = image.naturalWidth; canvas.height = image.naturalHeight;
    const context = canvas.getContext("2d"); if (!context) throw new Error("PNG unavailable");
    context.imageSmoothingEnabled = false; context.drawImage(image, 0, 0);
    return await new Promise<Blob>((resolve, reject) => canvas.toBlob(blob => blob ? resolve(blob) : reject(new Error("PNG unavailable")), "image/png"));
  } finally { URL.revokeObjectURL(url); }
}
defineExpose({ exportSvg, exportPng });
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
