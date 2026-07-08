<script setup>
import DemoIcon from "./DemoIcon.vue";
</script>

<template>
  <div class="es">
    <div class="ico"><DemoIcon name="inbox" :size="40" /></div>
    <div class="title">还没有会话</div>
    <div class="desc">发起一个聊天，或从通讯录里找人开始对话。</div>
    <button class="act">发起聊天</button>
  </div>
</template>

<style scoped>
.es { display: flex; flex-direction: column; align-items: center; gap: 8px; padding: 24px; }
.ico { color: var(--flare-color-text-tertiary); margin-bottom: 4px; }
.title { font-size: 16px; color: var(--flare-color-text-primary); }
.desc { font-size: 13px; color: var(--flare-color-text-tertiary); text-align: center; max-width: 240px; }
.act { margin-top: 8px; padding: 7px 18px; border-radius: 8px; border: 1px solid var(--flare-color-primary); background: none; color: var(--flare-color-primary); font-size: 13px; cursor: pointer; }
</style>
