<script setup lang="ts">
import MsgIcon from "./MsgIcon.vue";
export interface FlareVoteOption { text: string; pct: number }
// Presentational — emits `select` with the chosen option + index; the host casts
// the actual vote.
withDefaults(
  defineProps<{ title?: string; options?: FlareVoteOption[]; total?: string }>(),
  { title: "vote", options: () => [], total: "" },
);
const emit = defineEmits<{ (e: "select", option: FlareVoteOption, index: number): void }>();
</script>
<template>
  <div class="fm-vote">
    <div class="vt"><MsgIcon name="poll" :size="16" />{{ title }}</div>
    <button v-for="(o, i) in options" :key="o.text" class="opt" @click="emit('select', o, i)">
      <div class="bar" :style="{ width: o.pct + '%' }" /><span class="t">{{ o.text }}</span><span class="p">{{ o.pct }}%</span>
    </button>
    <div v-if="total" class="total">{{ total }}</div>
  </div>
</template>
<style scoped>
.fm-vote { display: inline-flex; flex-direction: column; gap: 8px; min-width: 220px; padding: 10px 12px; border-radius: 16px 16px 16px 4px; background: var(--im-bg-surface, #fff); border: 1px solid var(--im-border-subtle, #eef0f4); box-shadow: var(--im-bubble-shadow, 0 2px 10px rgba(0,0,0,.05)); }
.vt { display: flex; align-items: center; gap: 6px; font-weight: 600; font-size: 14px; color: var(--im-text-primary, #111318); }
.opt { position: relative; display: flex; align-items: center; height: 30px; padding: 0 10px; border: none; border-radius: 7px; background: var(--im-bg-surface-alt, #f2f3f5); overflow: hidden; cursor: pointer; text-align: left; }
.bar { position: absolute; left: 0; top: 0; bottom: 0; background: color-mix(in srgb, var(--im-primary, #7c3aed) 16%, transparent); }
.t { position: relative; flex: 1; font-size: 13px; color: var(--im-text-primary, #111318); }
.p { position: relative; font-size: 12px; color: var(--im-text-secondary, #6b7280); font-variant-numeric: tabular-nums; }
.total { font-size: 11px; color: var(--im-text-tertiary, #a3a7ae); }
</style>
