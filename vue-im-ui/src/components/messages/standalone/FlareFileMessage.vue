<script setup lang="ts">
import MsgIcon from "./MsgIcon.vue";
// Presentational — the host owns the file URL and does the actual fetch on
// `download` (and `open` for the whole card). Override the leading icon via the
// `icon` slot to show a per-file-type glyph.
withDefaults(defineProps<{ name?: string; size?: string; ext?: string }>(), { name: "file", size: "" });
const emit = defineEmits<{ (e: "open"): void; (e: "download"): void }>();
</script>
<template>
  <div class="fm-file" @click="emit('open')">
    <span class="ic">
      <slot name="icon"><MsgIcon name="folder" :size="20" /></slot>
    </span>
    <span class="meta"><b>{{ name }}</b><small>{{ size }}<template v-if="ext"> · {{ ext }}</template></small></span>
    <button class="dl" aria-label="Download" @click.stop="emit('download')"><MsgIcon name="download" :size="17" /></button>
  </div>
</template>
<style scoped>
.fm-file { display: inline-flex; align-items: center; gap: 10px; max-width: 300px; padding: 9px 14px; border-radius: 16px 16px 16px 4px; background: var(--im-bg-surface, #fff); border: 1px solid var(--im-border-subtle, #eef0f4); box-shadow: var(--im-bubble-shadow, 0 2px 10px rgba(0,0,0,.05)); cursor: pointer; }
.ic { color: var(--im-primary, #7c3aed); display: flex; }
.meta { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.meta b { font-size: 14px; font-weight: 500; color: var(--im-text-primary, #111318); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.meta small { font-size: 11px; color: var(--im-text-tertiary, #a3a7ae); }
.dl { flex: none; border: none; background: none; padding: 0; display: flex; color: var(--im-text-tertiary, #a3a7ae); cursor: pointer; }
</style>
