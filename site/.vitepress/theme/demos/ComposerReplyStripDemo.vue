<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
const shown = ref(true);
</script>
<template>
  <div class="wrap">
    <div v-if="shown" class="reply">
      <div class="body">
        <div class="who">回复 Ivy Chen</div>
        <div class="sum">新版设计稿已经上传啦，帮忙看下交互细节～</div>
      </div>
      <button class="x" aria-label="取消回复" @click="shown = false"><DemoIcon name="close" :size="18" /></button>
    </div>
    <button v-else class="reset" @click="shown = true">再次回复</button>
  </div>
</template>
<style scoped>
.wrap { width: 100%; max-width: 420px; }
.reply { display: flex; align-items: center; gap: 8px; padding: 6px 8px; border-radius: var(--flare-size-radius-md, 6px); background: var(--flare-color-bg-secondary); border-left: 3px solid var(--flare-color-primary); }
.body { flex: 1; min-width: 0; }
.who { font-size: 11px; font-weight: 600; color: var(--flare-color-primary); }
.sum { font-size: 12px; color: var(--flare-color-text-secondary); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.x { flex: none; border: none; background: none; padding: 0; display: flex; color: var(--flare-color-text-tertiary); cursor: pointer; }
.reset { padding: 6px 14px; border-radius: 8px; border: 1px solid var(--flare-color-border-primary); background: none; color: var(--flare-color-text-secondary); font-size: 13px; cursor: pointer; }
</style>
