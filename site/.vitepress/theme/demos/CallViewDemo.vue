<script setup>
import DemoIcon from "./DemoIcon.vue";
import { tint } from "./tint.js";
const av = tint("Henry Ford");
</script>

<template>
  <div class="flare-callframe">
    <div class="top">
      <div class="av" :style="{ background: av.bg, color: av.fg }">HF</div>
      <div class="name">Henry Ford</div>
      <div class="state">02:14</div>
    </div>
    <div class="ctrls">
      <span class="ico"><DemoIcon name="mic" /></span>
      <span class="ico"><DemoIcon name="video" /></span>
      <span class="ico"><DemoIcon name="sync" /></span>
      <span class="ico end"><DemoIcon name="callEnd" /></span>
    </div>
    <div class="pip">IC</div>
  </div>
</template>

<style scoped>
.top { position: absolute; top: 56px; left: 0; right: 0; display: flex; flex-direction: column; align-items: center; gap: 8px; }
.av { width: 88px; height: 88px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 32px; font-weight: 600; }
.name { font-size: 22px; font-weight: 600; }
.state { color: rgba(255,255,255,.7); font-size: 14px; }
.ctrls { position: absolute; bottom: 40px; left: 0; right: 0; display: flex; justify-content: center; gap: 16px; }
.ico { width: 48px; height: 48px; border-radius: 50%; background: rgba(255,255,255,.16); display: flex; align-items: center; justify-content: center; color: #fff; }
.ico.end { background: #EF4444; }
.pip { position: absolute; top: 16px; right: 16px; width: 56px; height: 78px; border-radius: 10px; background: #6D5DF6; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 600; border: 2px solid rgba(255,255,255,.2); }
</style>
