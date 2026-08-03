<script setup>
import { ref } from "vue";
import FlareImageGrid from "@flare-im/vue-ui/components/messages/FlareImageGrid.vue";
import DemoStage from "./DemoStage.vue";
// deterministic gradient placeholders (no external images)
const swatch = (a, b) => `data:image/svg+xml;utf8,` + encodeURIComponent(
  `<svg xmlns='http://www.w3.org/2000/svg' width='120' height='120'><defs><linearGradient id='g' x1='0' y1='0' x2='1' y2='1'><stop offset='0' stop-color='${a}'/><stop offset='1' stop-color='${b}'/></linearGradient></defs><rect width='120' height='120' fill='url(%23g)'/></svg>`.replace(/#/g, "%23"),
);
const pal = [["#a78bfa","#7c3aed"],["#f0abfc","#c026d3"],["#fca5a5","#ef4444"],["#93c5fd","#2563eb"],["#6ee7b7","#059669"],["#fcd34d","#d97706"],["#f9a8d4","#db2777"],["#a5b4fc","#4f46e5"],["#5eead4","#0d9488"],["#fdba74","#ea580c"],["#c4b5fd","#7c3aed"],["#67e8f9","#0891b2"]];
const mk = (n) => Array.from({ length: n }, (_, i) => ({ url: swatch(...pal[i % pal.length]) }));
const three = mk(3), four = mk(4), nine = mk(12); // 12 → shows 9 + "+3"
</script>
<template>
  <DemoStage>
    <div class="stack">
      <div class="row"><span class="cap">1 张</span><FlareImageGrid :images="mk(1)" /></div>
      <div class="row"><span class="cap">3 张</span><FlareImageGrid :images="three" /></div>
      <div class="row"><span class="cap">4 张 (2×2)</span><FlareImageGrid :images="four" /></div>
      <div class="row"><span class="cap">12 张 (9 + N)</span><FlareImageGrid :images="nine" /></div>
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 18px; padding: 22px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.row { display: flex; align-items: flex-start; gap: 16px; }
.cap { width: 92px; flex: 0 0 auto; font-size: 12px; color: var(--flare-color-text-tertiary); padding-top: 4px; }
</style>
