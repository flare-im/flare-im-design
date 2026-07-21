<script setup lang="ts">
import FlareGlyph from "./FlareGlyph.vue";
withDefaults(
  defineProps<{ title: string; description?: string; actionText?: string; icon?: string }>(),
  { icon: "📭" },
);
const emit = defineEmits<{ (e: "action"): void }>();
</script>

<template>
  <div class="flare-empty">
    <div class="flare-empty__ico"><FlareGlyph :icon="icon" :size="44" /></div>
    <div class="flare-empty__title">{{ title }}</div>
    <div v-if="description" class="flare-empty__desc">{{ description }}</div>
    <button v-if="actionText" class="flare-empty__act" @click="emit('action')">{{ actionText }}</button>
  </div>
</template>

<style scoped>
.flare-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 24px;
  text-align: center;
}
.flare-empty__ico { font-size: 44px; opacity: 0.8; }
.flare-empty__title { font-size: 16px; color: var(--flare-color-text-primary); }
.flare-empty__desc { font-size: 13px; color: var(--flare-color-text-tertiary); max-width: 260px; }
.flare-empty__act {
  margin-top: 8px;
  padding: 7px 18px;
  border-radius: var(--flare-size-radius-md, 6px);
  border: 1px solid var(--flare-color-primary);
  background: none;
  color: var(--flare-color-primary);
  font-size: 13px;
  cursor: pointer;
}
</style>
