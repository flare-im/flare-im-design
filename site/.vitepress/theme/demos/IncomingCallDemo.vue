<script setup>
import DemoIcon from "./DemoIcon.vue";
import { tint } from "./tint.js";
const av = tint("Ivy Chen");
</script>

<template>
  <div class="flare-callframe">
    <div class="top">
      <div class="av" :style="{ background: av.bg, color: av.fg }">IC</div>
      <div class="name">Ivy Chen</div>
      <div class="state">邀请你视频通话</div>
    </div>
    <div class="acts">
      <div class="col">
        <span class="ico reject"><DemoIcon name="callEnd" :size="24" /></span>
        <span class="lbl">拒绝</span>
      </div>
      <div class="col">
        <span class="ico accept"><DemoIcon name="video" :size="24" /></span>
        <span class="lbl">接听</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.top { position: absolute; top: 96px; left: 0; right: 0; display: flex; flex-direction: column; align-items: center; gap: 10px; }
.av { width: 96px; height: 96px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 36px; font-weight: 600; }
.name { font-size: 22px; font-weight: 600; }
.state { color: rgba(255,255,255,.7); font-size: 14px; }
.acts { position: absolute; bottom: 44px; left: 0; right: 0; display: flex; justify-content: space-evenly; }
.col { display: flex; flex-direction: column; align-items: center; gap: 8px; }
.ico { width: 60px; height: 60px; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #fff; }
.ico.reject { background: #EF4444; }
.ico.accept { background: #22C55E; }
.lbl { font-size: 13px; color: rgba(255,255,255,.8); }
</style>
