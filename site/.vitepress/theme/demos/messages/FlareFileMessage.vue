<script setup>
import DemoIcon from "../DemoIcon.vue";
defineProps({ name: { type: String, default: "文件.pdf" }, size: { type: String, default: "2.4 MB" }, ext: String });
const emit = defineEmits(["open", "download"]);
</script>
<template>
  <div class="bubble file" @click="emit('open')">
    <span class="fic"><slot name="icon"><DemoIcon name="folder" :size="20" /></slot></span>
    <span class="fmeta"><b>{{ name }}</b><small>{{ size }}<template v-if="ext"> · {{ ext }}</template></small></span>
    <button class="dl" aria-label="下载" @click.stop="emit('download')"><DemoIcon name="download" :size="17" /></button>
  </div>
</template>
<style scoped>
.bubble { display: inline-flex; align-items: center; gap: 10px; max-width: 300px; padding: 9px 14px; border-radius: 16px 16px 16px 4px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-secondary); box-shadow: 0 2px 10px rgba(0,0,0,.05); cursor: pointer; }
.fic { color: var(--flare-color-primary); display: flex; }
.fmeta { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.fmeta b { font-size: 14px; font-weight: 500; color: var(--flare-color-text-primary); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.fmeta small { font-size: 11px; color: var(--flare-color-text-tertiary); }
.dl { flex: none; border: none; background: none; padding: 0; display: flex; color: var(--flare-color-text-tertiary); cursor: pointer; }
</style>
