<script setup lang="ts">
import MsgIcon from "./MsgIcon.vue";
withDefaults(defineProps<{ seconds?: number }>(), { seconds: 1 });
</script>
<template>
  <div class="fm-voice">
    <MsgIcon name="volume" :size="17" />
    <span class="wave"><i v-for="n in 9" :key="n" :style="{ height: 4 + ((n * 5) % 13) + 'px' }" /></span>
    <span class="dur">{{ seconds }}&quot;</span>
  </div>
</template>
<style scoped>
.fm-voice { display: inline-flex; align-items: center; gap: 8px; padding: 9px 14px; border-radius: 16px 16px 16px 4px; background: var(--im-bg-surface, #fff); border: 1px solid var(--im-border-subtle, #eef0f4); box-shadow: var(--im-bubble-shadow, 0 2px 10px rgba(0,0,0,.05)); color: var(--im-text-secondary, #6b7280); }
.wave { display: flex; align-items: center; gap: 2px; }
.wave i { width: 2px; border-radius: 2px; background: var(--im-primary, #7c3aed); }
.dur { font-size: 12px; color: var(--im-text-tertiary, #a3a7ae); }
</style>
