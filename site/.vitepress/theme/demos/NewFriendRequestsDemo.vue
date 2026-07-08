<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
import { tint } from "./tint.js";
const items = ref([
  { id: "r1", n: "Mika Sun", i: "MS", msg: "我是设计组的 Mika", state: "pending" },
  { id: "r2", n: "Leo Zhang", i: "LZ", msg: "在活动上见过～", state: "pending" },
  { id: "r3", n: "Nora Li", i: "NL", msg: "同事推荐", state: "accepted" },
].map((r) => ({ ...r, av: tint(r.n) })));
function set(r, s) { r.state = s; }
</script>

<template>
  <div class="wrap">
    <div class="hd"><DemoIcon name="personAdd" :size="17" /><span>新的朋友</span><span class="badge">2</span></div>
    <div v-for="r in items" :key="r.id" class="row">
      <div class="av" :style="{ background: r.av.bg, color: r.av.fg }">{{ r.i }}</div>
      <div class="meta">
        <div class="n">{{ r.n }}</div>
        <div class="m">{{ r.msg }}</div>
      </div>
      <div v-if="r.state === 'pending'" class="acts">
        <button class="rej" @click="set(r, 'rejected')">拒绝</button>
        <button class="acc" @click="set(r, 'accepted')">接受</button>
      </div>
      <span v-else class="state">{{ r.state === "accepted" ? "已添加" : "已拒绝" }}</span>
    </div>
  </div>
</template>

<style scoped>
.wrap { width: 100%; max-width: 420px; border: 1px solid var(--flare-color-border-primary); border-radius: 12px; background: var(--flare-color-bg-primary); overflow: hidden; }
.hd { display: flex; align-items: center; gap: 8px; padding: 11px 14px; font-size: 13px; font-weight: 600; color: var(--flare-color-text-secondary); background: var(--flare-color-bg-secondary); }
.badge { margin-left: auto; background: var(--flare-color-primary); color: #fff; font-size: 11px; min-width: 18px; height: 18px; border-radius: 999px; display: flex; align-items: center; justify-content: center; padding: 0 5px; }
.row { display: flex; align-items: center; gap: 12px; padding: 11px 14px; }
.row + .row { border-top: 1px solid var(--flare-color-border-secondary); }
.av { width: 40px; height: 40px; border-radius: 50%; font-weight: 600; font-size: 13px; display: flex; align-items: center; justify-content: center; }
.meta { flex: 1; min-width: 0; }
.n { color: var(--flare-color-text-primary); font-weight: 500; }
.m { font-size: 12px; color: var(--flare-color-text-tertiary); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.acts { display: flex; gap: 6px; }
.acts button { padding: 5px 12px; border-radius: 7px; font-size: 12px; cursor: pointer; }
.rej { border: 1px solid var(--flare-color-border-primary); background: none; color: var(--flare-color-text-secondary); }
.acc { border: none; background: var(--flare-color-primary); color: #fff; }
.state { font-size: 12px; color: var(--flare-color-text-tertiary); }
</style>
