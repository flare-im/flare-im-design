<script setup>
import { tint, initials as ini } from "./tint.js";
const groups = [
  { letter: "H", people: [{ n: "Henry Ford", s: "在设计新版本 🎨" }] },
  { letter: "I", people: [{ n: "Ivy Chen", s: "产品经理" }] },
  { letter: "K", people: [
    { n: "Kai Wang", s: "工程师" },
    { n: "Kelly Zhao", s: "运营" },
  ] },
].map((g) => ({ ...g, people: g.people.map((p) => ({ ...p, av: tint(p.n) })) }));
const index = ["A", "H", "I", "K", "Z"];
</script>

<template>
  <div class="cl">
    <div class="list">
      <template v-for="g in groups" :key="g.letter">
        <div class="head">{{ g.letter }}</div>
        <div v-for="p in g.people" :key="p.n" class="row">
          <div class="av" :style="{ background: p.av.bg, color: p.av.fg }">{{ ini(p.n) }}</div>
          <div class="meta">
            <div class="name">{{ p.n }}</div>
            <div class="sig">{{ p.s }}</div>
          </div>
        </div>
      </template>
    </div>
    <div class="idx">
      <span v-for="l in index" :key="l" :class="{ hot: groups.some(g => g.letter === l) }">{{ l }}</span>
    </div>
  </div>
</template>

<style scoped>
.cl { position: relative; width: 100%; max-width: 420px; border: 1px solid var(--flare-color-border-primary); border-radius: 12px; overflow: hidden; background: var(--flare-color-bg-primary); }
.head { position: sticky; top: 0; padding: 4px 14px; font-size: 12px; font-weight: 600; color: var(--flare-color-text-tertiary); background: var(--flare-color-bg-secondary); }
.row { display: flex; align-items: center; gap: 12px; padding: 10px 14px; }
.row + .row { border-top: 1px solid var(--flare-color-border-secondary); }
.av { width: 40px; height: 40px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 600; font-size: 14px; }
.name { color: var(--flare-color-text-primary); font-weight: 500; }
.sig { font-size: 12px; color: var(--flare-color-text-tertiary); }
.idx { position: absolute; right: 4px; top: 50%; transform: translateY(-50%); display: flex; flex-direction: column; gap: 2px; font-size: 10px; color: var(--flare-color-text-tertiary); }
.idx .hot { color: var(--flare-color-primary); font-weight: 700; }
</style>
