<script setup lang="ts">
import MsgIcon from "./MsgIcon.vue";
// Presentational — emits `toggle` when the checkbox is tapped; the host flips the
// task's done state.
withDefaults(defineProps<{ title?: string; meta?: string; done?: boolean }>(), { title: "task" });
const emit = defineEmits<{ (e: "toggle"): void }>();
</script>
<template>
  <div class="fm-task">
    <button class="box" :class="{ done }" aria-label="Toggle done" @click="emit('toggle')">
      <MsgIcon v-if="done" name="check" :size="13" />
    </button>
    <span class="meta"><b :class="{ done }">{{ title }}</b><small v-if="meta">{{ meta }}</small></span>
  </div>
</template>
<style scoped>
.fm-task { display: inline-flex; align-items: center; gap: 10px; min-width: 220px; padding: 9px 14px; border-radius: 16px 16px 16px 4px; background: var(--im-bg-surface, #fff); border: 1px solid var(--im-border-subtle, var(--flare-color-border-secondary, #ECEEF2)); box-shadow: var(--im-bubble-shadow, 0 2px 10px rgba(0,0,0,.05)); }
.box { padding: 0; width: 20px; height: 20px; border-radius: 6px; flex: none; display: grid; place-items: center; border: 1.5px solid var(--im-border, var(--flare-color-border-primary, #E3E5EB)); background: none; color: #fff; cursor: pointer; }
.box.done { background: var(--im-primary, var(--flare-color-primary, #7047D6)); border-color: var(--im-primary, var(--flare-color-primary, #7047D6)); }
.meta { flex: 1; display: flex; flex-direction: column; }
.meta b { font-size: 14px; font-weight: 500; color: var(--im-text-primary, var(--flare-color-text-primary, #20232D)); }
.meta b.done { text-decoration: line-through; color: var(--im-text-tertiary, var(--flare-color-text-tertiary, #687182)); }
.meta small { font-size: 11px; color: var(--im-text-tertiary, var(--flare-color-text-tertiary, #687182)); }
</style>
