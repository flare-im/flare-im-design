<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
const log = ref("");
</script>
<template>
  <div class="wrap">
    <div class="row">
      <span class="lbl">禁用</span>
      <button class="send" disabled><DemoIcon name="send" :size="16" /></button>
      <span class="lbl">可发送</span>
      <button class="send active" @click="log = 'send · 已发送'"><DemoIcon name="send" :size="16" /></button>
    </div>
    <div class="echo">{{ log || "active 时才可点，抛 send 回调" }}</div>
  </div>
</template>
<style scoped>
.wrap { width: 100%; max-width: 320px; }
.row { display: flex; align-items: center; gap: 12px; }
.lbl { font-size: 12px; color: var(--flare-color-text-tertiary); }
.send { width: 34px; height: 34px; border: none; border-radius: 50%; display: grid; place-items: center; background: var(--flare-color-bg-disabled); color: var(--flare-color-text-disabled); cursor: not-allowed; }
.send.active { background: var(--flare-color-primary); color: #fff; cursor: pointer; }
.echo { margin-top: 10px; font-size: 12px; color: var(--flare-color-text-tertiary); }
</style>
