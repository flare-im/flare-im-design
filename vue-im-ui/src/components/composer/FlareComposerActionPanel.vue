<script setup lang="ts">
import FlareGlyph from "../general/FlareGlyph.vue";
export interface FlareComposerActionItem {
  key: string;
  label: string;
  /** A canonical Flare semantic icon name (preferred), or any raw string / emoji. */
  icon?: string;
}

// Neutral English sample set — the host passes its own `actions` (with its own
// labels / i18n). Kept minimal so the component carries no product wording.

withDefaults(
  defineProps<{ actions?: FlareComposerActionItem[]; columns?: number }>(),
  { actions: () =>   [
    { key: "image", label: "Image", icon: "image" },
    { key: "camera", label: "Camera", icon: "camera" },
    { key: "file", label: "File", icon: "file" },
    { key: "location", label: "Location", icon: "location" },
    { key: "card", label: "Card", icon: "person" },
    { key: "poll", label: "Poll", icon: "poll" },
    { key: "task", label: "Task", icon: "check" },
    { key: "schedule", label: "Schedule", icon: "calendar" },
  ], columns: 4 },
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
      <span class="flare-action-panel__ico"><FlareGlyph :icon="a.icon || 'add'" :size="24" /></span>
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
