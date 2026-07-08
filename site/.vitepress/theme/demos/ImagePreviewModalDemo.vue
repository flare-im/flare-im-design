<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
const zoom = ref(1);
const pct = ref(0);
const downloading = ref(false);
function dl() {
  if (downloading.value) return;
  downloading.value = true; pct.value = 0;
  const t = setInterval(() => {
    pct.value += 12;
    if (pct.value >= 100) { pct.value = 100; clearInterval(t); setTimeout(() => (downloading.value = false), 500); }
  }, 110);
}
const clamp = (v) => Math.min(3, Math.max(0.5, +v.toFixed(2)));
</script>

<template>
  <div class="stage">
    <div class="bar">
      <span class="t">设计稿-v2.png</span>
      <button class="x"><DemoIcon name="close" :size="18" /></button>
    </div>
    <div class="canvas">
      <div class="img" :style="{ transform: `scale(${zoom})` }">
        <DemoIcon name="image" :size="40" />
      </div>
    </div>
    <div v-if="downloading" class="prog"><span :style="{ width: pct + '%' }" /></div>
    <div class="ctl">
      <button @click="zoom = clamp(zoom - 0.25)"><DemoIcon name="zoomOut" :size="18" /></button>
      <span class="z">{{ Math.round(zoom * 100) }}%</span>
      <button @click="zoom = clamp(zoom + 0.25)"><DemoIcon name="zoomIn" :size="18" /></button>
      <span class="sp" />
      <button @click="dl">
        <DemoIcon name="download" :size="18" />
        <span>{{ downloading ? `${pct}%` : "保存" }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.stage { width: 100%; max-width: 420px; border-radius: 14px; overflow: hidden; background: #0E0F13; color: #fff; }
.bar { display: flex; align-items: center; justify-content: space-between; padding: 12px 14px; }
.t { font-size: 13px; color: rgba(255,255,255,.8); }
.x { border: none; background: none; color: rgba(255,255,255,.7); cursor: pointer; display: flex; }
.canvas { height: 190px; display: flex; align-items: center; justify-content: center; overflow: hidden; }
.img { width: 140px; height: 100px; border-radius: 8px; background: rgba(255,255,255,.1); display: flex; align-items: center; justify-content: center; color: rgba(255,255,255,.55); transition: transform .18s; }
.prog { height: 2px; background: rgba(255,255,255,.15); }
.prog span { display: block; height: 100%; background: var(--flare-color-primary); transition: width .1s linear; }
.ctl { display: flex; align-items: center; gap: 10px; padding: 12px 14px; }
.ctl button { display: flex; align-items: center; gap: 6px; border: none; background: rgba(255,255,255,.12); color: #fff; border-radius: 8px; padding: 6px 10px; font-size: 12px; cursor: pointer; }
.z { font-size: 12px; color: rgba(255,255,255,.75); font-variant-numeric: tabular-nums; min-width: 40px; text-align: center; }
.sp { flex: 1; }
</style>
