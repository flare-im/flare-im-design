<script setup>
import { ref, onUnmounted } from "vue";
import DemoIcon from "./DemoIcon.vue";
const playing = ref(false);
const t = ref(0);
const total = 42;
let timer = null;
function toggle() {
  playing.value = !playing.value;
  clearInterval(timer);
  if (playing.value) {
    timer = setInterval(() => {
      t.value += 1;
      if (t.value >= total) { t.value = total; playing.value = false; clearInterval(timer); }
    }, 220);
  }
}
onUnmounted(() => clearInterval(timer));
const fmt = (s) => `${String(Math.floor(s / 60)).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`;
</script>

<template>
  <div class="stage">
    <div class="bar">
      <span class="t">周会录屏.mp4</span>
      <button class="x"><DemoIcon name="close" :size="18" /></button>
    </div>
    <div class="canvas" @click="toggle">
      <div class="poster"><DemoIcon name="video" :size="34" /></div>
      <button class="play" :class="{ hide: playing }"><DemoIcon name="play" :size="34" /></button>
    </div>
    <div class="ctl">
      <button @click="toggle">
        <DemoIcon :name="playing ? 'volume' : 'play'" :size="16" />
      </button>
      <span class="time">{{ fmt(t) }}</span>
      <div class="track" @click="t = 0"><span :style="{ width: (t / total) * 100 + '%' }" /></div>
      <span class="time">{{ fmt(total) }}</span>
    </div>
  </div>
</template>

<style scoped>
.stage { width: 100%; max-width: 420px; border-radius: 14px; overflow: hidden; background: #0E0F13; color: #fff; }
.bar { display: flex; align-items: center; justify-content: space-between; padding: 12px 14px; }
.t { font-size: 13px; color: rgba(255,255,255,.8); }
.x { border: none; background: none; color: rgba(255,255,255,.7); cursor: pointer; display: flex; }
.canvas { position: relative; height: 190px; display: flex; align-items: center; justify-content: center; background: rgba(255,255,255,.05); cursor: pointer; }
.poster { color: rgba(255,255,255,.28); }
.play { position: absolute; border: none; background: rgba(0,0,0,.35); color: #fff; width: 62px; height: 62px; border-radius: 50%; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: opacity .2s; }
.play.hide { opacity: 0; pointer-events: none; }
.ctl { display: flex; align-items: center; gap: 10px; padding: 12px 14px; }
.ctl button { border: none; background: rgba(255,255,255,.12); color: #fff; width: 30px; height: 30px; border-radius: 50%; display: flex; align-items: center; justify-content: center; cursor: pointer; }
.time { font-size: 11px; color: rgba(255,255,255,.7); font-variant-numeric: tabular-nums; }
.track { flex: 1; height: 3px; border-radius: 3px; background: rgba(255,255,255,.18); cursor: pointer; }
.track span { display: block; height: 100%; border-radius: 3px; background: var(--flare-color-primary); }
</style>
