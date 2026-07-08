<script setup>
import DemoIcon from "./DemoIcon.vue";
import { tint } from "./tint.js";
const groups = [
  { id: "g1", n: "产品设计群", i: "产", m: 12, owner: true },
  { id: "g2", n: "Flare 核心研发", i: "F", m: 34 },
  { id: "g3", n: "周会纪要", i: "周", m: 8 },
].map((g) => ({ ...g, av: tint(g.n) }));
</script>

<template>
  <div class="wrap">
    <div v-for="g in groups" :key="g.id" class="row">
      <div class="av" :style="{ background: g.av.bg, color: g.av.fg }">{{ g.i }}</div>
      <div class="meta">
        <div class="line"><span class="n">{{ g.n }}</span><span v-if="g.owner" class="tag">群主</span></div>
        <div class="m"><DemoIcon name="users" :size="13" />{{ g.m }} 位成员</div>
      </div>
      <DemoIcon name="chevronRight" :size="16" class="chev" />
    </div>
  </div>
</template>

<style scoped>
.wrap { width: 100%; max-width: 400px; border: 1px solid var(--flare-color-border-primary); border-radius: 12px; background: var(--flare-color-bg-primary); overflow: hidden; }
.row { display: flex; align-items: center; gap: 12px; padding: 11px 14px; cursor: pointer; }
.row + .row { border-top: 1px solid var(--flare-color-border-secondary); }
.av { width: 42px; height: 42px; border-radius: 12px; font-weight: 600; display: flex; align-items: center; justify-content: center; }
.meta { flex: 1; min-width: 0; }
.line { display: flex; align-items: center; gap: 6px; }
.n { color: var(--flare-color-text-primary); font-weight: 500; }
.tag { font-size: 10px; padding: 1px 5px; border-radius: 4px; background: var(--flare-color-bg-selected); color: var(--flare-color-primary); }
.m { display: flex; align-items: center; gap: 4px; font-size: 12px; color: var(--flare-color-text-tertiary); margin-top: 2px; }
.chev { color: var(--flare-color-text-tertiary); }
</style>
