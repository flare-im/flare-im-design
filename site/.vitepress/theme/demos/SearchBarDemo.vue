<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
const q = ref("");
</script>

<template>
  <div class="sb">
    <span class="ico"><DemoIcon name="search" :size="18" /></span>
    <input v-model="q" class="in" placeholder="搜索联系人、群组、消息" />
    <button v-if="q" class="clr" aria-label="清除" @click="q = ''"><DemoIcon name="cancel" :size="18" /></button>
  </div>
</template>

<style scoped>
.sb { display: flex; align-items: center; gap: 8px; width: 100%; max-width: 420px; padding: 9px 14px; border-radius: 10px; background: var(--flare-color-bg-secondary); }
.ico { color: var(--flare-color-text-tertiary); display: flex; }
.in { flex: 1; border: none; outline: none; background: none; font-size: 14px; color: var(--flare-color-text-primary); }
.clr { border: none; background: none; padding: 0; display: flex; color: var(--flare-color-text-tertiary); cursor: pointer; }
</style>
