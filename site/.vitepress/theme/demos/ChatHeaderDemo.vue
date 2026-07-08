<script setup>
import DemoIcon from "./DemoIcon.vue";
import { tint } from "./tint.js";
const av = tint("Henry Ford");
</script>

<template>
  <div class="hdr">
    <span class="back"><DemoIcon name="chevronLeft" :size="22" /></span>
    <div class="av" :style="{ background: av.bg, color: av.fg }">HF</div>
    <div class="meta">
      <div class="title">Henry Ford</div>
      <div class="sub">在线</div>
    </div>
    <div class="actions">
      <DemoIcon name="search" :size="19" />
      <DemoIcon name="call" :size="19" />
      <DemoIcon name="moreHoriz" :size="19" />
    </div>
  </div>
</template>

<style scoped>
.hdr { width: 100%; max-width: 460px; display: flex; align-items: center; gap: 10px; padding: 0 12px; height: 60px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-primary); border-radius: 12px; }
.back { color: var(--flare-color-text-primary); display: flex; }
.av { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 600; font-size: 13px; }
.meta { flex: 1; }
.title { font-weight: 600; color: var(--flare-color-text-primary); }
.sub { font-size: 12px; color: var(--flare-color-success); }
.actions { display: flex; gap: 14px; color: var(--flare-color-text-secondary); }
</style>
