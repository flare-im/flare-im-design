<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
const text = ref("Flare IM 组件库");
const max = 40;
</script>

<template>
  <div class="wrap">
    <div class="field">
      <input v-model="text" :maxlength="max" class="in" placeholder="请输入…" />
      <button v-if="text" class="clr" aria-label="清除" @click="text = ''"><DemoIcon name="cancel" :size="18" /></button>
    </div>
    <div class="count">{{ text.length }}/{{ max }}</div>
  </div>
</template>

<style scoped>
.wrap { width: 100%; max-width: 420px; }
.field { display: flex; align-items: center; gap: 8px; padding: 10px 14px; border-radius: 10px; background: var(--flare-color-bg-secondary); border-bottom: 2px solid var(--flare-color-primary); }
.in { flex: 1; border: none; outline: none; background: none; font-size: 14px; color: var(--flare-color-text-primary); }
.clr { border: none; background: none; padding: 0; display: flex; color: var(--flare-color-text-tertiary); cursor: pointer; }
.count { text-align: right; font-size: 12px; color: var(--flare-color-text-tertiary); margin-top: 4px; }
</style>
