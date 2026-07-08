<script setup>
import { tint } from "./tint.js";
const people = [
  { n: "Henry Ford", i: "HF", s: "在设计新版本", p: "online" },
  { n: "Ivy Chen", i: "IC", s: "产品经理", p: "busy" },
  { n: "Kai Wang", i: "KW", s: "工程师", p: "away" },
  { n: "Lena Wu", i: "LW", s: "设计师", p: "offline" },
].map((p) => ({ ...p, av: tint(p.n) }));
const tone = {
  online: "var(--flare-color-success)",
  busy: "var(--flare-color-error)",
  away: "var(--flare-color-warning)",
  offline: "var(--flare-color-text-disabled)",
};
</script>

<template>
  <div class="wrap">
    <div v-for="p in people" :key="p.n" class="row">
      <div class="avw">
        <div class="av" :style="{ background: p.av.bg, color: p.av.fg }">{{ p.i }}</div>
        <span class="dot" :style="{ background: tone[p.p] }" />
      </div>
      <div class="meta">
        <div class="n">{{ p.n }}</div>
        <div class="s">{{ p.s }}</div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.wrap { width: 100%; max-width: 380px; border: 1px solid var(--flare-color-border-primary); border-radius: 12px; background: var(--flare-color-bg-primary); overflow: hidden; }
.row { display: flex; align-items: center; gap: 12px; padding: 10px 14px; }
.row + .row { border-top: 1px solid var(--flare-color-border-secondary); }
.avw { position: relative; }
.av { width: 42px; height: 42px; border-radius: 50%; font-weight: 600; font-size: 14px; display: flex; align-items: center; justify-content: center; }
.dot { position: absolute; right: -1px; bottom: -1px; width: 12px; height: 12px; border-radius: 50%; border: 2px solid var(--flare-color-bg-primary); }
.n { color: var(--flare-color-text-primary); font-weight: 500; }
.s { font-size: 12px; color: var(--flare-color-text-tertiary); }
</style>
