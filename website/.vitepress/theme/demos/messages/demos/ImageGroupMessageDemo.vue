<script setup>
import { FlareImageGroupMessage as C } from "@flare-im/vue-ui/components";
const tile = (hue) => `data:image/svg+xml;utf8,${encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="120" height="120"><rect width="120" height="120" fill="hsl(${hue} 55% 62%)"/></svg>`)}`;
const images = [210, 150, 30, 280, 0, 90, 330, 60, 180, 240, 120].map((hue, index) => ({ src: tile(hue), alt: `照片 ${index + 1}` }));
</script>
<template>
  <C :images="images" description="周末爬山" />
</template>
