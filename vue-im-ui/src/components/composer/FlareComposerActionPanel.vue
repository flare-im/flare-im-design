<script setup lang="ts">
export interface FlareComposerActionItem {
  key: string;
  label: string;
  icon?: string;
}

const defaultActions: FlareComposerActionItem[] = [
  { key: "image", label: "图片", icon: "🖼️" },
  { key: "camera", label: "拍摄", icon: "📷" },
  { key: "file", label: "文件", icon: "📁" },
  { key: "location", label: "位置", icon: "📍" },
  { key: "card", label: "名片", icon: "👤" },
  { key: "vote", label: "投票", icon: "🗳️" },
  { key: "task", label: "任务", icon: "✅" },
  { key: "schedule", label: "日程", icon: "📅" },
];

withDefaults(
  defineProps<{ actions?: FlareComposerActionItem[]; columns?: number }>(),
  { actions: () => defaultActions, columns: 4 },
);
const emit = defineEmits<{ (e: "action", action: FlareComposerActionItem): void }>();
</script>

<template>
  <div class="flare-action-panel" :style="{ gridTemplateColumns: `repeat(${columns}, 1fr)` }">
    <button
      v-for="a in actions"
      :key="a.key"
      class="flare-action-panel__tile"
      @click="emit('action', a)"
    >
      <span class="flare-action-panel__ico">{{ a.icon || "＋" }}</span>
      <span class="flare-action-panel__label">{{ a.label }}</span>
    </button>
  </div>
</template>

<style scoped>
.flare-action-panel {
  display: grid;
  gap: 16px;
  padding: 16px;
  background: var(--flare-color-bg-primary);
}
.flare-action-panel__tile {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  border: none;
  background: none;
  cursor: pointer;
}
.flare-action-panel__ico {
  width: 52px;
  height: 52px;
  border-radius: var(--flare-size-radius-lg, 8px);
  background: var(--flare-color-bg-secondary);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
}
.flare-action-panel__label {
  font-size: 12px;
  color: var(--flare-color-text-secondary);
}
</style>
