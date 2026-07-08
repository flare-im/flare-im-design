<script setup>
import DemoIcon from "./DemoIcon.vue";
import { tint } from "./tint.js";
const av = tint("Henry Ford");
</script>

<template>
  <div class="cd">
    <div class="av" :style="{ background: av.bg, color: av.fg }">HF</div>
    <div class="n">Henry Ford</div>
    <div class="s">在设计新版本</div>
    <div class="id">@henry_f</div>
    <div class="acts">
      <button class="primary"><DemoIcon name="message" :size="18" /><span>发消息</span></button>
      <button><DemoIcon name="call" :size="18" /><span>语音</span></button>
      <button><DemoIcon name="video" :size="18" /><span>视频</span></button>
    </div>
  </div>
</template>

<style scoped>
.cd { width: 100%; max-width: 380px; display: flex; flex-direction: column; align-items: center; padding: 28px 20px 20px; border: 1px solid var(--flare-color-border-primary); border-radius: 14px; background: var(--flare-color-bg-primary); }
.av { width: 84px; height: 84px; border-radius: 24px; display: flex; align-items: center; justify-content: center; font-size: 30px; font-weight: 600; }
.n { margin-top: 14px; font-size: 21px; font-weight: 600; color: var(--flare-color-text-primary); }
.s { margin-top: 3px; font-size: 14px; color: var(--flare-color-text-tertiary); }
.id { margin-top: 2px; font-size: 12px; color: var(--flare-color-text-disabled); }
.acts { display: flex; gap: 10px; margin-top: 22px; width: 100%; }
.acts button { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 5px; padding: 11px 0; border-radius: 10px; border: 1px solid var(--flare-color-border-primary); background: none; color: var(--flare-color-text-secondary); font-size: 12px; cursor: pointer; }
.acts .primary { background: var(--flare-color-primary); border-color: transparent; color: #fff; }
</style>
