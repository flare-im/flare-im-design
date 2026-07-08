<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
const log = ref("");
const actions = [
  { k: "image", label: "图片", icon: "image" },
  { k: "camera", label: "拍摄", icon: "camera" },
  { k: "file", label: "文件", icon: "folder" },
  { k: "location", label: "位置", icon: "location" },
  { k: "card", label: "名片", icon: "person" },
  { k: "vote", label: "投票", icon: "poll" },
  { k: "task", label: "任务", icon: "task" },
  { k: "schedule", label: "日程", icon: "calendar" },
];
</script>
<template>
  <div class="wrap">
    <div class="grid">
      <button v-for="a in actions" :key="a.k" class="tile" @click="log = `action · ${a.label}`">
        <span class="ic"><DemoIcon :name="a.icon" :size="23" /></span>
        <span class="lb">{{ a.label }}</span>
      </button>
    </div>
    <div class="echo">{{ log || "点任一项 —— action 回调带回所选项" }}</div>
  </div>
</template>
<style scoped>
.wrap { width: 100%; max-width: 460px; }
.grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; padding: 16px; border-radius: 14px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-primary); }
.tile { display: flex; flex-direction: column; align-items: center; gap: 6px; border: none; background: none; cursor: pointer; }
.ic { width: 52px; height: 52px; border-radius: 12px; background: var(--flare-color-bg-secondary); display: grid; place-items: center; color: var(--flare-color-text-secondary); }
.lb { font-size: 12px; color: var(--flare-color-text-secondary); }
.echo { margin-top: 10px; font-size: 12px; color: var(--flare-color-text-tertiary); }
</style>
