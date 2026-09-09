<script setup lang="ts">
import MsgIcon from "./MsgIcon.vue";
// Presentational — emits `open`; the host opens the link.
withDefaults(defineProps<{ title?: string; domain?: string; thumb?: string; description?: string }>(), { title: "link", domain: "" });
const emit = defineEmits<{ (e: "open"): void }>();
</script>
<template>
  <div class="fm-link" @click="emit('open')">
    <div class="thumb"><img v-if="thumb" :src="thumb" alt="" /><MsgIcon v-else name="image" :size="22" /></div>
    <div class="meta">
      <b>{{ title }}</b>
      <span v-if="description" class="desc">{{ description }}</span>
      <small><MsgIcon name="link" :size="12" />{{ domain }}</small>
    </div>
  </div>
</template>
<style scoped>
.fm-link { display: inline-flex; gap: 10px; align-items: center; max-width: 300px; padding: 8px 10px; border-radius: 16px 16px 16px 4px; background: var(--im-bg-surface, #fff); border: 1px solid var(--im-border-subtle, var(--flare-color-border-secondary, #ECEEF2)); box-shadow: var(--im-bubble-shadow, 0 2px 10px rgba(0,0,0,.05)); cursor: pointer; }
.thumb { width: 48px; height: 48px; border-radius: 8px; flex: none; overflow: hidden; background: var(--im-bg-surface-alt, var(--flare-color-bg-tertiary, #F1F2F5)); display: grid; place-items: center; color: var(--im-text-tertiary, var(--flare-color-text-tertiary, #687182)); }
.thumb img { width: 100%; height: 100%; object-fit: cover; }
.meta { min-width: 0; display: flex; flex-direction: column; gap: 3px; }
.meta b { font-size: 14px; font-weight: 500; color: var(--im-text-primary, var(--flare-color-text-primary, #20232D)); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.meta .desc { font-size: 12px; color: var(--im-text-secondary, var(--flare-color-text-secondary, #626978)); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.meta small { display: flex; align-items: center; gap: 3px; color: var(--im-text-tertiary, var(--flare-color-text-tertiary, #687182)); }
</style>
