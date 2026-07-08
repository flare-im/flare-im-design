<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
const muted = ref(false);
const cam = ref(true);
</script>

<template>
  <div class="bar">
    <button class="c" @click="muted = !muted">
      <span class="ico" :class="{ on: muted }"><DemoIcon :name="muted ? 'micOff' : 'mic'" :size="22" /></span>
      <span class="lbl">麦克风</span>
    </button>
    <button class="c" @click="cam = !cam">
      <span class="ico" :class="{ on: !cam }"><DemoIcon :name="cam ? 'video' : 'videoOff'" :size="22" /></span>
      <span class="lbl">摄像头</span>
    </button>
    <button class="c">
      <span class="ico"><DemoIcon name="sync" :size="22" /></span>
      <span class="lbl">翻转</span>
    </button>
    <button class="c">
      <span class="ico end"><DemoIcon name="callEnd" :size="22" /></span>
      <span class="lbl">挂断</span>
    </button>
  </div>
</template>

<style scoped>
.bar { display: flex; gap: 18px; padding: 20px 24px; background: #111318; border-radius: 16px; }
.c { display: flex; flex-direction: column; align-items: center; gap: 6px; border: none; background: none; cursor: pointer; }
.ico { width: 52px; height: 52px; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: rgba(255,255,255,.16); color: #fff; }
.ico.on { background: #fff; color: #111318; }
.ico.end { background: #EF4444; }
.lbl { font-size: 11px; color: rgba(255,255,255,.75); }
</style>
