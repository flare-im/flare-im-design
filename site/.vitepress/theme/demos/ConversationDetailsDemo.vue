<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
import { tint } from "./tint.js";
const av = tint("产品设计群");
const tones = [
  { k: "ok", text: "已连接", color: "var(--flare-color-success)" },
  { k: "warn", text: "连接中…", color: "var(--flare-color-warning)" },
  { k: "error", text: "已断开", color: "var(--flare-color-error)" },
];
const i = ref(0);
</script>

<template>
  <div class="cd">
    <div class="hero">
      <div class="av" :style="{ background: av.bg, color: av.fg }">产</div>
      <div class="name">产品设计群</div>
      <button class="pill" @click="i = (i + 1) % tones.length">
        <span class="dot" :style="{ background: tones[i].color }" />{{ tones[i].text }}
      </button>
    </div>
    <div class="stats">
      <div><b>128</b><small>消息</small></div>
      <div><b>6</b><small>成员</small></div>
      <div><b>2</b><small>置顶</small></div>
    </div>
    <div class="acts">
      <button><DemoIcon name="search" :size="18" /><span>查找消息</span></button>
      <button><DemoIcon name="bellOff" :size="18" /><span>免打扰</span></button>
      <button><DemoIcon name="pin" :size="18" /><span>置顶会话</span></button>
      <button class="danger"><DemoIcon name="trash" :size="18" /><span>清空记录</span></button>
    </div>
    <div class="foot">最新消息 ID：<code>msg_8f21c</code></div>
  </div>
</template>

<style scoped>
.cd { width: 100%; max-width: 340px; border: 1px solid var(--flare-color-border-primary); border-radius: 14px; background: var(--flare-color-bg-primary); overflow: hidden; }
.hero { display: flex; flex-direction: column; align-items: center; gap: 8px; padding: 22px 16px 16px; }
.av { width: 64px; height: 64px; border-radius: 16px; display: flex; align-items: center; justify-content: center; font-size: 24px; font-weight: 600; }
.name { font-size: 17px; font-weight: 600; color: var(--flare-color-text-primary); }
.pill { display: flex; align-items: center; gap: 6px; padding: 3px 10px; border-radius: 999px; border: 1px solid var(--flare-color-border-secondary); background: var(--flare-color-bg-secondary); font-size: 12px; color: var(--flare-color-text-secondary); cursor: pointer; }
.dot { width: 6px; height: 6px; border-radius: 50%; }
.stats { display: flex; border-top: 1px solid var(--flare-color-border-secondary); border-bottom: 1px solid var(--flare-color-border-secondary); }
.stats div { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 2px; padding: 12px 0; }
.stats b { font-size: 17px; font-weight: 600; color: var(--flare-color-text-primary); font-variant-numeric: tabular-nums; }
.stats small { font-size: 11px; color: var(--flare-color-text-tertiary); }
.acts { display: flex; flex-direction: column; }
.acts button { display: flex; align-items: center; gap: 12px; padding: 12px 16px; border: none; background: none; color: var(--flare-color-text-primary); font-size: 14px; cursor: pointer; text-align: left; }
.acts button + button { border-top: 1px solid var(--flare-color-border-secondary); }
.acts .danger { color: var(--flare-color-error); }
.foot { padding: 10px 16px; font-size: 11px; color: var(--flare-color-text-tertiary); border-top: 1px solid var(--flare-color-border-secondary); }
.foot code { font-size: 11px; }
</style>
